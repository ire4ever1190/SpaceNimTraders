import types

## Defines all the routes for the api

{.push inline.}

proc getUserRoute*(client: Client): string =
    result = "/users/" & client.username

proc getLoansRoute*(client: Client): string = 
    result = "/game/loans"

proc applyLoanRoute*(client: Client): string = 
    result = client.getUserRoute() & "/loans"

proc payLoanRoute*(client: Client, loanID: string): string =
    result = client.applyLoanRoute() & "/" & loanID

proc getShipsRoute*(client: Client): string =
    result = "/game/ships"

proc buyShipRoute*(client: Client): string =
    result = client.getUserRoute() & "/ships"

proc getMarketRoute*(client: Client, location: string): string =
    result = "/game/locations/" & location & "/marketplace"

proc buyMarketRoute*(client: Client): string =
    result = client.getUserRoute() & "/purchase-orders"

proc getLocationsRoute*(client: Client, system: string): string =
    result = "/game/systems/" & system & "/locations"

proc createFlightPlanRoute*(client: Client): string =
    result = client.getUserRoute() & "/flight-plans"

proc getFlightPlanRoute*(client: Client, flightID: string): string =
    result = client.createFlightPlanRoute() & "/" & flightID

proc sellMarketRoute*(client: Client): string =
    result = client.getUserRoute() & "/sell-orders"

{.pop.}
