import std/hashes
import types

#
# Hash functions for types
#

proc hash(market: MarketPlace): Hash =
    result = market.name.hash !& market.symbol.hash !& market.`type`.hash 
    result = !$result

