import types
import api

import std/asyncdispatch
import std/strformat
import std/strutils
import std/tables
import std/httpclient
import std/json

#
# Constructors
#


proc newClient*(username, token: string): Client =
    ## Creates a new client instance
    ## Note: This does not create the account for you
    result = Client(
        username: username,
        token: token,
        events: Events(),
        cache: Cache()
    )
    discard result.getUser()

proc newAsyncClient*(username, token: string): AsyncClient =
    ## Creates a new async client instance
    ## Note; This does not create the account for you
    result = AsyncClient(
        username: username,
        token: token,
        events: Events(),
        cache: Cache()
    )
    discard waitFor result.getUser()

proc claimUsername*(username: string): string =
    ## Claims a username and returns the token
    let httpclient = newHttpClient()
    let response = httpclient.postContent(fmt"https://api.spacetraders.io/users/{username}/token")
    result = response.parseJson()["token"].getStr()
        
#
# toString functions
#

proc `$`*(cargo: Cargo): string =
    result = fmt"{cargo.good} x {cargo.quantity} || {cargo.totalVolume}L"

proc `$`*(ship: UserShip): string =
    result &= fmt"ID: {ship.id}" & "\n"
    result &= fmt"Cargo: {ship.spaceAvailable}" & "\n"
    for cargo in ship.cargo:
        result &= $cargo & "\n"

proc `$`*(client: Client): string =
    result &= "Username: " & client.username & "\n"
    result &= "Credits: " & $client.credits & "\n"
    for ship in client.ships.values:
        result &= $ship
    

proc `$`*(location: PurchaseLocation): string =
    result &= fmt"Name: {location.location}" & "\n"
    result &= fmt"Price: {location.price}" & "\n"
    
proc `$`*(ship: Ship): string =
    result &= fmt"{ship.type} is a {ship.class} ship produced by {ship.manufacturer}" & "\n"
    result &= "Info: \n"
    let indent = "    "
    result &= fmt"{indent} Speed: {ship.speed}" & "\n"
    result &= fmt"{indent} Max Cargo: {ship.maxCargo}" & "\n"
    result &= fmt"{indent} Weapons: {ship.weapons}" & "\n"
    result &= fmt"{indent} Plating: {ship.plating}" & "\n"
    result &= "Purchase Locations:\n"
    for location in ship.purchaseLocations:
        result &= $location & "\n"

proc `$`*(loan: Loan): string =
    result = fmt"{loan.type}: {loan.amount}"

proc `$`*(item: MarketItem): string =
    result = fmt"{item.symbol}: ".alignLeft(17)
    result &= fmt"{item.quantityAvailable} @ {item.pricePerUnit}€".alignLeft(13) &  fmt" || {item.volumePerUnit}L"

proc `$`*(market: MarketPlace): string =
    result = fmt"Market: {market.symbol}" & "\n"
    result = fmt"Location: {market.type} at {market.x} {market.y}" & "\n"
    for item in market.marketplace:
        result &= $item & "\n"

proc `$`*(location: Location): string =
    result = fmt"{location.name} ({location.symbol}) {location.x} {location.y}"

proc `$`*(flightPlan: FlightPlan): string =
    result = fmt"Destination: {flightPlan.destination}" & "\n"
    result = fmt"Consumed {flightPlan.fuelConsumed} fuel. {flightPlan.fuelRemaining} remaining" & "\n"
    result = fmt"Time Left: {flightPlan.timeRemainingInSeconds}" 
