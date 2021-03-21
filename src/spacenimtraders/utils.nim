import types

import std/math
import std/asyncdispatch
import std/tables
import std/options

## `Utils` contains helper functions that implement common tasks to make your life easier
## 
## While I highly recommend you try and write your algorithm (and share it with me plz), I did include `bestPriceDiff`
## which is what I use myself to figure out what to buy and sell

when defined(traderDebug):
    proc debug*(inputs: varargs[string]) =
        ## Used internally
        ## Outputs a block of statements to the console
        echo ""
        echo "====== Space Trader Debug ======"
        for input in inputs:
            echo input
        echo "================================"
        echo ""

proc canAfford*(ships: seq[Ship], client: Client | AsyncClient): seq[Ship] =
    ## Returns a list of ships that the user can afford
    for ship in ships:
        block outer:
            for location in ship.purchaseLocations:
                if location.price <= client.credits:
                    result &= ship
                    break outer

proc getVolume*(good: Goods): int =
    ## Returns the volume/unit for a good
    case good:
        of Metals:
            1
        of Machinery:
            4
        of Chemicals:
            1
        of Fuel:
            1
        of Plating:
            2
        of Workers:
            2
        of Parts:
            5
        of Research:
            0
        of Food:
            1
        of Textiles:
            1
        of ConsumerGoods:
            1
        of Electronics:
            1

proc getSystem*(ship: UserShip): string =
    ## Gets the current system that a ship is in
    result = ship.location.get()[0..1]

proc getDistance*(ship: UserShip, location: Location): float64 =
    ## Gets the distance between a ship and a location
    let
        deltaX = abs(ship.x.get() - location.x).float64
        deltaY = abs(ship.x.get() - location.x).float64
    result = sqrt(
        deltaX.pow(2.0) + deltaY.pow(2.0)
    )

proc getClosest*(locations: seq[Location], ship: UserShip): Location =
    ## Returns the closest location to the ship
    var minDistance = float64.high
    for location in locations:
        if location.symbol != ship.location.get():
            let distance = ship.getDistance(location)
            if distance < minDistance:
                result = location
                minDistance = distance        

proc contains*(market: MarketPlace, goodSymbol: Goods): bool =
    ## Returns true if a market contains a good
    for good in market.marketplace:
        if good.symbol == goodSymbol:
            return true

proc get*(market: MarketPlace, goodSymbol: Goods): MarketItem =
    ## Gets a market item in a market
    for good in market.marketplace:
        if good.symbol == goodSymbol:
            return good

proc price*(market: MarketPlace, goodSymbol: Goods): int =
    ## Returns the cost of a good in a market
    result = market.get(goodSymbol).pricePerUnit

proc volPrice*(market: MarketPlace, goodSymbol: Goods): float64 =
    ## Calculates the cost / volume ratio of a good in a market
    let price = market.price(goodSymbol)
    result = price / goodSymbol.getVolume()

proc shipInLocation*(client: Client | AsyncClient, location: string): bool =
    ## Returns true if the client has a ship at `location`
    for ship in client.ships.values():
        if ship.location.get() == location:
            return true

proc bestPriceDiff*(x, y: MarketPlace): Goods =
    ## Gets item that you can buy in x that gets best price in Y
    ## Bases the algorithm on price/volume
    var max = 0.float
    for item in x.marketplace:
        let diff = y.volPrice(item.symbol) -  x.volPrice(item.symbol)
        if diff > max:
            result = item.symbol
            max = diff

proc getFuel*(ship: UserShip): int =
    ## Returns how much fuel a ship has
    for cargo in ship.cargo:
        if cargo.good == FUEL:
            return cargo.quantity
