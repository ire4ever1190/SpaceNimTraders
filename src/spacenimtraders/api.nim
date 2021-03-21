import types
import requester
import routes
from utils import getVolume, shipInLocation

import std/tables
import std/asyncdispatch
import std/httpcore
import std/json
import std/macros
import std/strformat
import std/options

template reqParse(url: string, verb: HttpMethod, to: typedesc, body: string = "", params: seq[(string, string)] = @[]) = 
    ## Calls a endpoint and then parses the result
    let response = await client.request(url, verb, body, params)
    result = await response.parseJson(to)

macro callEvent(eventName: static[string], parameters: varargs[untyped]): untyped =
    ## Calls an event if it isn't nil
    let callee = parseExpr("client.events." & eventName)
    result = quote do:
        if not `callee`.isNil:
            when client is AsyncClient:
                await unpackVarargs(`callee`, `parameters`)
            else:
                waitFor unpackVarargs(`callee`, `parameters`)
#
# Update functions
#

proc update*(client: Client | AsyncClient, user: User) =
    ## Updates a client with the details from a user object
    for loan in user.loans: # Update the loans
        client.loans[loan.id] = loan

    for ship in user.ships: # Update the ships
        client.ships[ship.id] = ship
        
    client.credits = user.credits

proc update*(ship: UserShip, purchase: PurchaseOrder) =
    ## Updates the cargo that a ship has along with how much space it has left after fufilling a `purchaseOrder`
    ship.cargo = purchase.ship.cargo
    ship.spaceAvailable = purchase.ship.spaceAvailable

proc update*(client: Client | AsyncClient, purchase: PurchaseOrder) =
    ## Updates a client with the correct amout of credits after a purchase order
    ## Also updates the ship that was used to make the order
    client.credits = purchase.credits
    client.ships[purchase.ship.id].update purchase

proc update*(ship: UserShip, plan: FlightPlan) =
    ## Updates the location of the ship and how much fuel it has remaining.
    ## BE WARNED: This updates the location immediately and so it is best to keep track of the time the journey takes seperately.
    ship.location = some plan.destination
    for cargo in ship.cargo: # Find the fuel in the cargo and update the fuel
        if cargo.good == FUEL:
            cargo.quantity = plan.fuelRemaining

proc update*(client: Client | AsyncClient, plan: FlightPlan) =
    ## Updates the ship that was used to perform a `flightPlan`
    client.ships[plan.ship].update(plan)

proc update*(client: Client | AsyncClient, market: MarketPlace) =
    client.cache.market[market.symbol] = market

proc getUser*(client: Client | AsyncClient): Future[User] {.multisync.} =
    ## Returns current users info
    reqParse(client.getUserRoute(), HttpGet, User)
    client.update(result)
    callEvent("receivedUser", result)
    
#
# Loans
#

proc getLoans*(client: Client | AsyncClient): Future[seq[Loan]] {.multisync.} =
    ## Returns list of loans available to the user
    reqParse(client.getLoansRoute(), HttpGet, seq[Loan])
    callEvent("receivedLoans", result)

proc applyLoan*(client: Client | AsyncClient, loanType: LoanType): Future[User] {.multisync.} =
    ## Apply for a loan
    ## Returns the current user with updated info
    reqParse(client.applyLoanRoute(), HttpPost, User, $ %* {"type": $loanType})
    client.update(result)

proc apply*(client: Client | AsyncClient, loan: Loan): Future[User] {.multisync.} =
    ## Apply for the passed in loan
    result = await client.applyLoan(loan.`type`)

proc payLoan*(client: Client | AsyncClient, loan: string): Future[User] {.multisync.} =
    ## Pays off a loan all at once (I don't think you can specify how much you want to pay off)
    reqParse(client.payLoanRoute(loan), HttpPut, User)
    client.update(result)

#
# Ship Buying
#

proc getShips*(client: Client | AsyncClient, class: ShipClass = AnyClass): Future[seq[Ship]] {.multisync.} =
    ## Gets a list of all the ships
    ## Can be filtered to just a certain class by passing in a `ShipClass`
    let params = if class != AnyClass:
                @{"class": $class}
            else: @[]
            
    reqParse(client.getShipsRoute(), HttpGet, seq[Ship], params = params)

proc buyShip*(client: Client | AsyncClient, location: string, shipType: string): Future[User] {.multisync.} =
    ## Buys a ship at `location`
    let body = $ %* {
        "location": location,
        "type": shipType
    }
    reqParse(client.buyShipRoute(), HttpPost, User, body)
    client.update(result)


#
# Navigation
#

proc getLocations*(client: Client | AsyncClient, system: string, locationType: LocationType = AnyLocation): Future[seq[Location]] {.multisync.} =
    ## Gets all locations in the system of a certain type
    ## By default it gives you all types in the system
    let params = if locationType != AnyLocation:
            @{"type": $locationType}
        else: @[]
    reqParse(client.getLocationsRoute(system), HttpGet, seq[Location], params = params)

proc createFlightPlan*(client: Client | AsyncClient, shipID: string, destination: string): Future[FlightPlan] {.multisync.} =
    ## creates a `FlightPlan` for a ship to go to `destination`
    let body = $ %* {
        "shipId": shipID,
        "destination": destination
    }
    reqParse(client.createFlightPlanRoute(), HttpPost, FlightPlan, body)
    client.update(result)

proc createFlightPlan*(client: Client | AsyncClient, ship: UserShip, destination: string): Future[FlightPlan] {.multisync.} =
    ## Creates a flight plan for `ship` to go to `destination`
    if ship.location.get() == destination:
        raise newException(FlightError, "You are already at that location")
    result = await client.createFlightPlan(ship.id, destination)
    ship.update(result)

proc createFlightPlan*(client: Client | AsyncClient, ship: UserShip, destination: Location): Future[FlightPlan] {.multisync.} =
    ## Creates a flight plan for `ship` to go to `destination`
    result = await client.createFlightPlan(ship, destination.symbol)
    ship.update(result)

proc getFlightPlan*(client: Client | AsyncClient, shipID: string, flightID: string): Future[FlightPlan] {.multisync.} =
    reqParse(client.getFlightPlanRoute(flightID), HttpGet, FlightPlan)
    client.update(result)

proc getFlightPlan*(client: Client | AsyncClient, ship: UserShip, flightID: string): Future[FlightPlan] {.multisync.} =
    result = await client.getFlightPlan(ship.id, flightID)
    ship.update(result)

proc getFlightPlan*(client: Client | AsyncClient, ship: UserShip, flight: FlightPlan): Future[FlightPlan] {.multisync.} =
    result = await client.getFlightPlan(ship, flight.id)
    
#
# Market Viewing
#

proc getMarket*(client: Client | AsyncClient, location: string): Future[MarketPlace] {.multisync.} =
    ## Returns the market data for a location
    ## If there is no ship at the location but you have been there before then it will return market cache
    if not client.shipInLocation(location) and client.cache.market.hasKey(location):
        return client.cache.market[location]
    
    reqParse(client.getMarketRoute(location), HttpGet, MarketPlace) 
    client.update(result)

proc getMarket*(client: Client | AsyncClient, location: Location): Future[MarketPlace] {.multisync.} =
    result = await client.getMarket(location.symbol)

proc getMarket*(client: Client | AsyncClient, ship: UserShip): Future[MarketPlace] {.multisync.} =
    result = await client.getMarket(ship.location.get())

#
# Market Selling
#

proc sellGoods*(client: Client | AsyncClient, shipID: string, good: Goods, amount: int): Future[PurchaseOrder] {.multisync.} =
    let body = $ %* {
        "shipId": shipID,
        "good": $good,
        "quantity": $amount
    }
    reqParse(client.sellMarketRoute(), HttpPost, PurchaseOrder, body = body)
    client.update(result)

proc sellGoods*(client: Client | AsyncClient, ship: UserShip, good: Goods, amount: int): Future[PurchaseOrder] {.multisync.} =
    result = await client.sellGoods(ship.id, good, amount)
    ship.update(result)

#
# Market Buying
#
    
proc buyGoods*(client: Client | AsyncClient, shipID: string, good: Goods, amount: int): Future[PurchaseOrder] {.multisync.} =
    ## Buys a certain good from the current location of a ship
    let body = $ %* {
        "shipId": shipID,
        "good": $good,
        "quantity": amount
    }
    reqParse(client.buyMarketRoute(), HttpPost, PurchaseOrder, body)
    client.update(result)

proc buyGoods*(client: Client | AsyncClient, ship: UserShip, good: Goods, amount: int): Future[PurchaseOrder] {.multisync.} =
    ## Buys a certain good from the current location of a ship
    ## It is recommended to use this proc over the other one since this does client side verification
    let
        availableStorage = ship.spaceAvailable
        totalVolume = good.getVolume() * amount
    if availableStorage < totalVolume:
        raise newException(StorageError, fmt"Not enough storage to handle that order: {availableStorage} < {totalVolume}")
    
    result = await client.buyGoods(ship.id, good, amount)
    ship.update(result)

