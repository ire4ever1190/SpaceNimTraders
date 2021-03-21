import std/hashes
import types

#
# Hash functions for types
#

proc hash*(item: MarketItem): Hash =
    result = item.symbol.hash !& item.quantityAvailable.hash !& item.pricePerUnit
    result = !$result

proc hash*(market: MarketPlace): Hash =
    result = market.name.hash !& market.symbol.hash !& market.`type`.hash 
    for item in market.marketplace:
        result = result !& item.hash
    result = !$result

