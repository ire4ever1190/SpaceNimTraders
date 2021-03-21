import types

## Defines all the routes for the api

{.push inline.}

proc getUserRoute*(client: Client | AsyncClient): string =
    result = "/users/" & client.username

proc getLoansRoute*(client: Client | AsyncClient): string = 
    result = "/game/loans"

proc applyLoanRoute*(client: Client | AsyncClient): string = 
    result = client.getUserRoute() & "/loans"

proc payLoanRoute*(client: Client | AsyncClient, loanID: string): string =
    result = client.applyLoanRoute() & "/" & loanID

proc getShipsRoute*(client: Client | AsyncClient): string =
    result = "/game/ships"

proc buyShipRoute*(client: Client | AsyncClient): string =
    result = client.getUserRoute() & "/ships"

proc getMarketRoute*(client: Client | AsyncClient, location: string): string =
    result = "/game/locations/" & location & "/marketplace"

proc buyMarketRoute*(client: Client | AsyncClient): string =
    result = client.getUserRoute() & "/purchase-orders"

proc getLocationsRoute*(client: Client | AsyncClient, system: string): string =
    result = "/game/systems/" & system & "/locations"

proc createFlightPlanRoute*(client: Client | AsyncClient): string =
    result = client.getUserRoute() & "/flight-plans"

proc getFlightPlanRoute*(client: Client | AsyncClient, flightID: string): string =
    result = client.createFlightPlanRoute() & "/" & flightID

proc sellMarketRoute*(client: Client | AsyncClient): string =
    result = client.getUserRoute() & "/sell-orders"

{.pop.}
