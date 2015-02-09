require("storm")
require("cord")
shield = require("starter")

print("Seven Segment Display Test")

d = shield.Display.new()
d.display(2, 7)

cord.enter_loop()
