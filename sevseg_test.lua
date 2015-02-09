require("storm")
require("cord")
shield = require("starter")

print("Seven Segment Display Test")

display = shield.Display.new()
display.display(2, 7)

cord.enter_loop()
