import std/tables
import std/options
import std/asyncdispatch

include exceptions

type
    LoanType* = enum
        Startup = "STARTUP"
        Enterprise = "ENTERPRISE"

    ShipClass* = enum
        AnyClass
        MK1 = "MK-I"
        MK2 = "MK-II"
        MK3 = "MK-III"

    Goods* = enum # Hopefully this doesn't get too big
        Fuel = "FUEL"
        Food = "FOOD"
        Textiles = "TEXTILES"
        Metals = "METALS"
        Workers = "WORKERS"
        Parts = "SHIP_PARTS"
        Machinery = "MACHINERY"
        Chemicals = "CHEMICALS"
        Plating = "SHIP_PLATING"
        Research = "RESEARCH"
        ConsumerGoods = "CONSUMER_GOODS"
        Electronics = "ELECTRONICS"

    LocationType* = enum
        AnyLocation
        Moon = "MOON"
        Planet = "PLANET"
        Wormhole = "WORMHOLE"
        GasGiant = "GAS_GIANT"
        Asteroid = "ASTEROID"

    FlightPlan* = object
        arrivesAt*: string
        departure*: string
        destination*: string
        distance*: int
        fuelConsumed*: int
        fuelRemaining*: int
        id*: string
        ship*: string
        terminatedAt*: Option[string]
        timeRemainingInSeconds*: int
        
    MarketItem* = object
        pricePerUnit*: int
        quantityAvailable*: int
        symbol*: Goods
        volumePerUnit*: int

    MarketPlace* = object
        marketplace*: seq[MarketItem]
        name*: string
        symbol*: string
        `type`*: LocationType
        x*: int
        y*: int
        
    PurchaseLocation* = object
        location*: string
        price*: int

    Location* = object
        name*: string
        symbol*: string
        `type`*: LocationType
        x*: int
        y*: int

    PurchaseOrderItem = object
        good: Goods
        quantity: int
        pricePerUnit: int
        total: int

    
    Ship* = object
        class*: ShipClass
        manufacturer*: string
        maxCargo*: int
        plating*: int
        purchaseLocations*: seq[PurchaseLocation]
        speed*: int
        `type`*: string
        weapons*: int 

    Cargo* = ref object
        good*: Goods
        quantity*: int
        totalVolume*: int

    UserShip* = ref object
        cargo*: seq[Cargo]
        class: ShipClass
        id*: string
        location*: string
        manufacturer: string
        maxCargo: int
        plating: int
        spaceAvailable*: int
        speed: int
        `type`: string
        weapons: int
        x*: int
        y*: int

    PurchaseOrder* = object
        credits*: int
        order*: PurchaseOrderItem
        ship*: UserShip

    Loan* = object
        amount*: int
        collateralRequired*: bool
        rate*: int
        termInDays*: int
        `type`*: LoanType # See if this can be an enum

    UserLoan* = object
        id*: string
        due*: string
        repaymentAmount*: int
        status*: string
        `type`*: LoanType

    User* = object
        username*: string
        credits*: int
        loans*: seq[UserLoan]
        ships*: seq[UserShip]

    Events* = ref object
        receivedUser*:      proc (user: User) {.async.}
        receivedLoans*:     proc (loan: seq[Loan]) {.async.}
        receivedShips*:     proc (ships: seq[Ship]) {.async.}
        receivedLocations*: proc (locations: seq[Location]) {.async.}
        receivedMarket*:    proc (location: string, market: MarketPlace) {.async.}
        
        appliedLoan*:       proc (loan: LoanType) {.async.}
        boughtShip*:        proc (location: string, class: ShipClass) {.async.}
        createdFlightPlan*: proc (shipID, destination: string, plan: FlightPlan) {.async.}
        boughtGoods*:       proc (good: Goods, amount: int, shipID: string) {.async.}
        soldGoods*:         proc (good: GOods, amount: int, shipID: string) {.async.}
        
    Client* = ref object
        username*: string
        credits*: int
        token*: string
        loans*: Table[string, UserLoan]
        ships*: Table[string, UserShip]
        events*: Events
