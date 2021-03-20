import types
import requester
import routes
from utils import getVolume

import std/tables
import std/asyncdispatch
import std/httpcore
import std/json
import std/macros
import std/strformat

template reqParse(url: string, verb: HttpMethod, to: typedesc, body: string = "", params: seq[(string, string)] = @[]) = 
    ## Calls a endpoint and then parses the result
    let response = await client.request(url, verb, body, params)
    result = await response.parseJson(to)

macro callEvent(eventName: static[string], parameters: varargs[untyped]): untyped =
    ## Calls an event if it isn't nil
    let callee = parseExpr("client.events." & eventName)
    result = quote do:
        if not `callee`.isNil:
            await unpackVarargs(`callee`, `parameters`)

#
# Update functions
#

proc update*(client: Client, user: User) =
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

proc update*(client: Client, purchase: PurchaseOrder) =
    ## Updates a client with the correct amout of credits after a purchase order
    ## Also updates the ship that was used to make the order
    client.credits = purchase.credits
    client.ships[purchase.ship.id].update purchase

proc update*(ship: UserShip, plan: FlightPlan) =
    ## Updates the location of the ship and how much fuel it has remaining.
    ## BE WARNED: This updates the location immediately and so it is best to keep track of the time the journey takes seperately.
    ship.location = plan.destination
    for cargo in ship.cargo: # Find the fuel in the cargo and update the fuel
        if cargo.good == FUEL:
            cargo.quantity = plan.fuelRemaining

proc update*(client: Client, plan: FlightPlan) =
    ## Updates the ship that was used to perform a `flightPlan`
    client.ships[plan.ship].update(plan)


proc getUser*(client: Client): Future[User] {.async.} =
    ## Returns current users info
    reqParse(client.getUserRoute(), HttpGet, User)
    client.update(result)
    callEvent("receivedUser", result)
    
#
# Loans
#

proc getLoans*(client: Client): Future[seq[Loan]] {.async.} =
    ## Returns list of loans available to the user
    reqParse(client.getLoansRoute(), HttpGet, seq[Loan])
    callEvent("receivedLoans", result)

proc applyLoan*(client: Client, loanType: LoanType): Future[User] {.async.} =
    ## Apply for a loan
    ## Returns the current user with updated info
    reqParse(client.applyLoanRoute(), HttpPost, User, $ %* {"type": $loanType})
    client.update(result)

proc apply*(client: Client, loan: Loan): Future[User] {.async.} =
    ## Apply for the passed in loan
    result = await client.applyLoan(loan.`type`)

proc payLoan*(client: Client, loan: string): Future[User] {.async.} =
    ## Pays off a loan all at once (I don't think you can specify how much you want to pay off)
    reqParse(client.payLoanRoute(loan), HttpPut, User)
    client.update(result)

#
# Ship Buying
#

proc getShips*(client: Client, class: ShipClass = AnyClass): Future[seq[Ship]] {.async.} =
    ## Gets a list of all the ships
    ## Can be filtered to just a certain class by passing in a `ShipClass`
    let params = if class != AnyClass:
                @{"class": $class}
            else: @[]
            
    reqParse(client.getShipsRoute(), HttpGet, seq[Ship], params = params)

proc buyShip*(client: Client, location: string, shipType: string): Future[User] {.async.} =
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

proc getLocations*(client: Client, system: string, locationType: LocationType = AnyLocation): Future[seq[Location]] {.async.} =
    ## Gets all locations in the system of a certain type
    ## By default it gives you all types in the system
    let params = if locationType != AnyLocation:
            @{"type": $locationType}
        else: @[]
    reqParse(client.getLocationsRoute(system), HttpGet, seq[Location], params = params)

proc createFlightPlan*(client: Client, shipID: string, destination: string): Future[FlightPlan] {.async.} =
    ## creates a `FlightPlan` for a ship to go to `destination`
    let body = $ %* {
        "shipId": shipID,
        "destination": destination
    }
    reqParse(client.createFlightPlanRoute(), HttpPost, FlightPlan, body)
    client.update(result)

proc createFlightPlan*(client: Client, ship: UserShip, destination: string): Future[FlightPlan] {.async.} =
    ## Creates a flight plan for `ship` to go to `destination`
    if ship.location == destination:
        raise newException(FlightError, "You are already at that location")
    result = await client.createFlightPlan(ship.id, destination)
    ship.update(result)

proc createFlightPlan*(client: Client, ship: UserShip, destination: Location): Future[FlightPlan] {.async.} =
    ## Creates a flight plan for `ship` to go to `destination`
    result = await client.createFlightPlan(ship, destination.symbol)
    ship.update(result)

proc getFlightPlan*(client: Client, shipID: string, flightID: string): Future[FlightPlan] {.async.} =
    reqParse(client.getFlightPlanRoute(flightID), HttpGet, FlightPlan)
    client.update(result)

proc getFlightPlan*(client: Client, ship: UserShip, flightID: string): Future[FlightPlan] {.async.} =
    result = await client.getFlightPlan(ship.id, flightID)
    ship.update(result)

proc getFlightPlan*(client: Client, ship: UserShip, flight: FlightPlan): Future[FlightPlan] {.async.} =
    result = await client.getFlightPlan(ship, flight.id)
    
#
# Market Viewing
#

proc getMarket*(client: Client, location: string): Future[MarketPlace] {.async.} =
    reqParse(client.getMarketRoute(location), HttpGet, MarketPlace) 

proc getMarket*(client: Client, location: Location): Future[MarketPlace] {.async.} =
    result = await client.getMarket(location.symbol)

proc getMarket*(client: Client, ship: UserShip): Future[MarketPlace] {.async.} =
    result = await client.getMarket(ship.location)

#
# Market Selling
#

proc sellGoods*(client: Client, shipID: string, good: Goods, amount: int): Future[PurchaseOrder] {.async.} =
    let body = $ %* {
        "shipId": shipID,
        "good": $good,
        "quantity": $amount
    }
    reqParse(client.sellMarketRoute(), HttpPost, PurchaseOrder, body = body)
    client.update(result)

proc sellGoods*(client: Client, ship: UserShip, good: Goods, amount: int): Future[PurchaseOrder] {.async.} =
    result = await client.sellGoods(ship.id, good, amount)
    ship.update(result)

#
# Market Buying
#
    
proc buyGoods*(client: Client, shipID: string, good: Goods, amount: int): Future[PurchaseOrder] {.async.} =
    ## Buys a certain good from the current location of a ship
    let body = $ %* {
        "shipId": shipID,
        "good": $good,
        "quantity": amount
    }
    reqParse(client.buyMarketRoute(), HttpPost, PurchaseOrder, body)
    client.update(result)

proc buyGoods*(client: Client, ship: UserShip, good: Goods, amount: int): Future[PurchaseOrder] {.raises: [StorageError, Exception], async.} =
    ## Buys a certain good from the current location of a ship
    ## It is recommended to use this proc over the other one since this does client side verification
    let
        availableStorage = ship.spaceAvailable
        totalVolume = good.getVolume() * amount
    if availableStorage >= totalVolume:
        raise newException(StorageError, fmt"Not enough storage to handle that order: {availableStorage} < {totalVolume}")
    
    result = await client.buyGoods(ship.id, good, amount)
    ship.update(result)

