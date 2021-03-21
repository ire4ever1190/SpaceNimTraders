import src/spacenimtraders
import src/spacenimtraders/utils
import std/tables
import asyncdispatch
import options
import os
import terminal
import math
import times

#
# This example file is what I used to pay off my loan
# It goes between Prime and Tritus and finds the best good to buy at one and sell at the other
# It is pretty bad code and I don't recommend using this
#

let client = newClient(
    "Viceroy-Nute-Gunray",
    readFile("token")
)


const prime = "OE-PM"
const tritus = "OE-PM-TR"


template refuel() = 
    let neededFuel = 4 - ship.getFuel()
    if neededFuel > 0:
        discard client.buyGoods(ship, Fuel, neededFuel)

template goTo(planet: string) {.dirty.}=
    block:
        var plan: FlightPlan
        refuel()
        if ship.location.get() != planet:
            echo "Heading to ", planet
            plan = client.createFlightPlan(ship, planet)
        let tot = plan.timeRemainingInSeconds
        echo ""
        for i in 0..tot:
            cursorUp()
            eraseLine()
            echo $round((i/tot) * 100, 2) & "%"
            sleep(1000)
        echo ""
        sleep(1000)

template buyMetal() =
    if ship.spaceAvailable >= 96:
       discard client.buyGoods(ship, Metals, 96)
    

var ship = client.ships["ckmelvjmj11371241bs6istrtj9t"]

var goneOnce = false
var lastCredits = client.credits
var lastTime = now()

template creditRate() =
    let diff = now() - lastTime
    let credDiff = user.credits - lastCredits
    echo "Credits"
    
template sellInventory() =
    var items: seq[tuple[good: Goods, amount: int]]
    for cargo in ship.cargo:
        if cargo.good != Fuel:
            items &= (cargo.good, cargo.quantity)
    for item in items:
        discard client.sellGoods(ship, item.good, item.amount)
    echo "Credits, ", client.credits

template buyBestItem(x, y: MarketPlace) =
    let bestItem = x.bestPriceDiff(y)
    let size = bestItem.getVolume()
    let canBuy = if size != 0:
            96.floorDiv(size)
        else:
            (client.credits - 30000).floorDiv(x.price(bestItem))
    let canAfford = (client.credits - 100).floorDiv(x.price(bestItem))
    let toBuy = min(x.get(bestItem).quantityAvailable, canBuy).min(canAfford)
    echo "Buying, ", $toBuy, " x ", $bestItem
    discard client.buyGoods(ship, bestItem, toBuy)

template allShips(body: untyped) {.dirty.} =
    for ship in client.ships.values:
        body

goTo(tritus)
discard client.getMarket(tritus)

while true:
    sellInventory()
    if goneOnce:
        buyBestItem(client.getMarket(tritus), client.getMarket(prime))
    else:
        buyMetal()
    goTo(prime)

    sellInventory
    refuel()
        
    buyBestItem(client.getMarket(prime), client.getMarket(tritus))
        
    goneOnce = true
    goTo(tritus)
        


