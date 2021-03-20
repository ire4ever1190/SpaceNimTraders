# Package

version       = "0.1.0"
author        = "Jake Leahy"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.4.0"

task ex, "Runs the example":
    # exec "nim c -d:ssl -d:traderDebug -r example"
    exec "nim c -d:ssl -r example"
