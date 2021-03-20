type
    TraderError* = CatchableError ## Base Error
    ApiError* = TraderError       ## Thrown when issue with api
    StorageError* = TraderError   ## Thrown when issue with a ships storage
    CreditError* = TraderError    ## Thrown when client does not have enough credits to cover a cost
    FlightError* = TraderError    ## Thrown when an issue happens when planning a flight or in flight    
