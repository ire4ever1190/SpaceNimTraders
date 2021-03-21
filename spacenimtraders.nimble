# Package

version       = "0.2.0"
author        = "Jake Leahy"
description   = "API wrapper for the game spacetraders (https://spacetraders.io)"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.2.0"

task ex, "Runs the example":
    # exec "nim c -d:ssl -d:traderDebug -r example"
    exec "nim c -d:ssl -r example"
