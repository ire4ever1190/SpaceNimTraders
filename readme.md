I was going to call it space nimvaders but that doesn't make much sense seeing has it is a trading game


## Tutorial
### What's The Game?

SpaceTraders is a typical fleet management / trading / strategy game. Right now we've built the basic game features such as purchasing ships, navigating them around the universe, and trading goods at a profit. Later we plan to expand into construction, combat, exploration, factions, officers, ship modules and more.

### How To Play Guide

To follow this guide you first need to install the library

`nimble install spacenimtraders`

You can then follow along by running it all in a nim file or by using `inim`

This tutorial uses the sync api but you can use it in an async context with `newAsyncClient` instead of `newClient`

### Generate An Access Token

The API is only accessible if you have an access token. You can claim a username and generate a token by using this method. Make sure you save this token and don't share it with anyone. You can only generate a single token once per username.

```nim
import spacenimtraders
let token = claimUsername("foobar") # Username is foobar # Save this token to a file or something so that you can read it back in later
echo token

let client = newClient("foobar", token)
```

### View Your User Account

Congratulations on taking your first steps toward the complete and total domination of galactic trade! Let's take a quick look at your account.

```nim
echo client
```

Looks like you don't have much in the way of credits or assets. Let's see how we can fix that.
### View Available Loans

Let's kick off our trade empire by taking out a small low-risk loan. We can use these funds to purchase our first ship and fill our cargo with something valuable.

```nim
for loan in client.getLoans:
    echo client.getLoans()
```

### Take Out A Loan

Let's take out a small loan to kick off our new venture.

```nim
discard client.applyLoan(Startup)
```

### View Ships To Purchase

Now our credits are looking much healthier! But remember, you will have to pay it back by the due date. Let's buy a small ship to start shipping goods around and hopefully make enough to pay back our loan.

```nim
for ship in client.getShips(MK1):
    echo ship
```

Choose one of the available ships and send a request to purchase it. The Jackshaw looks like a good cheap option.
### Purchase A Ship

```nim
discard client.buyShip("OE-PM-TR", "JW-MK-I")
echo client
```

Save your ship to a variable so we can resuse it in a moment.
```nim
let ship = client.ships[`your_ship_id`]
```

Now let's load it up with fuel and metals and see if we can make a profitable trade.
### Purchase Ship Fuel

```nim
discard client.buyGoods(ship, Fuel, 20)
```

### View Marketplace

Each location has a marketplace of goods. Let's see what's available to us.

```nim
echo client.getMarket(ship.location)
```

Metals look like a solid trade good. Let's fill our cargo full.

```nim
discard client.buyGoods(ship, Metal, 80)
```

### Find Nearby Planet

Now we need to find a nearby planet to unload our cargo.

```nim
for planet in client.getLocations(ship.getSystem(), Planet):
    echo planet
```

Looks like Prime is right next to us. Let's create a flight plan to send our ship to the planet.
### Create Flight Plan

```nim
let flightPlan = client.createFlightPlan(ship, "OE-PM")
```

You can monitor your ship's flight plan until it arrives. We will save the flight plan so that we can check on it in a moment.

### View Flight Plan

```nim
echo client.getFlightPlan(flightPlan)
```

### Sell Trade Goods

Let's place a sell order for our metals.

```nim
discard client.sellGoods(ship, Metal, 80)
echo client
```

### Next Steps

Congratulations! You made your first profitable trade. You will likely want to trade in higher margin goods, but metals are a sure-fire way to make some credits. Try buying another ship, exploring each market, and maybe automate your way to wealth and glory! When you're ready to pay back your loan, you can call the final method in this guide:s

```nim
discard client.payLoan()
```
