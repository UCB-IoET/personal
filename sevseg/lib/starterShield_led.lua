----------------------------------------------
-- Starter Shield Module
--
-- Provides a module for each resource on the starter shield
-- in a cord-based concurrency model
-- and mapping to lower level abstraction provided
-- by storm.io @ toolchains/storm_elua/src/platform/storm/libstorm.c
----------------------------------------------

require("storm") -- libraries for interfacing with the board and kernel
require("cord") -- scheduler / fiber library
----------------------------------------------
-- Shield module for starter shield
----------------------------------------------
local shield = {}

----------------------------------------------
-- LED module
-- provide basic LED functions
----------------------------------------------
local LED = {}

LED.pins = {["blue"]="D2",["green"]="D3",["red"]="D4",["red2"]="D5"}

LED.start = function()
-- configure LED pins for output
   storm.io.set_mode(storm.io.OUTPUT, storm.io.D2, 
		     storm.io.D3, 
		     storm.io.D4,
		     storm.io.D5)
end

LED.stop = function()
-- configure pins to a low power state
end

-- LED color functions
-- These should rarely be used as an active LED burns a lot of power
LED.on = function(color)
   storm.io.set(1,storm.io[LED.pins[color]])
end
LED.off = function(color)
   storm.io.set(0,storm.io[LED.pins[color]])
end

-- Flash an LED pin for a period of time
--    unspecified duration is default of 10 ms
--    this is dull for green, but bright for read and blue
--    assumes cord.enter_loop() is in effect to schedule filaments
LED.flash=function(color,duration)
   local pin = LED.pins[color] or LED.pins["red2"]
   duration = duration or 10
   storm.io.set(1,storm.io[pin])
   storm.os.invokeLater(duration*storm.os.MILLISECOND,
			function() 
			   storm.io.set(0,storm.io[pin]) 
			end)
end

----------------------------------------------
-- Buzz module
-- provide basic buzzer functions
----------------------------------------------
local Buzz = {}

Buzz.run = nil
Buzz.go = function(delay)
   delay = delay or 0
   -- configure buzzer pin for output
   storm.io.set_mode(storm.io.OUTPUT, storm.io.D6)
   Buzz.run = true
   -- create buzzer filament and run till stopped externally
   -- this demonstrates the await pattern in which
   -- the filiment is suspended until an asynchronous call 
   -- completes
   cord.new(function()
	       while Buzz.run do
		  storm.io.set(1,storm.io.D6)
		  storm.io.set(0,storm.io.D6)	       
		  if (delay == 0) then cord.yield()
		  else cord.await(storm.os.invokeLater, 
				  delay*storm.os.MILLISECOND)
		  end
	       end
	    end)
end

Buzz.stop = function()
   print ("Buzz.stop")
   Buzz.run = false		-- stop Buzz.go partner
-- configure pins to a low power state
end

----------------------------------------------
-- Button module
-- provide basic button functions
----------------------------------------------
local Button = {}

Button.pins = {"D9","D10","D11"}

Button.start = function() 
   -- set buttons as inputs
   storm.io.set_mode(storm.io.INPUT,   
		     storm.io.D9, storm.io.D10, storm.io.D11)
   -- enable internal resistor pullups (none on board)
   storm.io.set_pull(storm.io.PULL_UP, 
		     storm.io.D9, storm.io.D10, storm.io.D11)
end

-- Get the current state of the button
-- can be used when poling buttons
Button.pressed = function(button) 
   return 1-storm.io.get(storm.io[Button.pins[button]]) 
end

-------------------
-- Button events
-- each registers a call back on a particular transition of a button
-- valid transitions are:
--   FALLING - when a button is pressed
--   RISING - when it is released
--   CHANGE - either case
-- Only one transition can be in effect for a button
-- must be used with cord.enter_loop
-- none of these are debounced.
-------------------
Button.whenever = function(button, transition, action)
   -- register call back to fire when button is pressed
   local pin = Button.pins[button]
   storm.io.watch_all(storm.io[transition], storm.io[pin], action)
end

Button.when = function(button, transition, action)
   -- register call back to fire when button is pressed
   local pin = Button.pins[button]
   storm.io.watch_single(storm.io[transition], storm.io[pin], action)
end

Button.wait = function(button)
-- Wait on a button press
--   suspend execution of the filament
--   resume and return when transition occurs
-- DEC: this doesn't quite work.  Return to it
   local pin = Button.pins[button]
   cord.new(function()
	       cord.await(storm.io.watch_single,
			  storm.io.FALLING, 
			  storm.io[pin])
	    end)
end

----------------------------------------------
shield.LED = LED
shield.Buzz = Buzz
shield.Button = Button
return shield


----------------------------------------------
----------------------------------------------
-- Seven Segment Display Library
require("bit")
local Display{}

-- Constants

Display.ADDR_AUTO = 0x40
Display.ADDR_FIXED = 0x44
Display.STARTADDR = 0xc0
Display.POINT_ON = 1
Display.POINT_OFF = 0
Display.BRIGHT_DARKEST = 0
Display.BRIGHT_TYPICAL = 2
Display.BRIGHTEST = 7

-- 0-9, A, b, C, d, E, F, '-', ' '
Display.TubeTab = { 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f, 
                    0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 
                    0x40, 0x00};

Display.Clkpin = storm.io.D7 -- ??  Check the schematic...
Display.Datapin = storm.io.D8

-- Public methods

function Display:new()
storm.io.set_mode(storm.io.OUTPUT, storm.io.D7, storm.io.D8)
--storm.io.set_pull(storm.io.PULLUP, storm.io.D7, storm.io.D8) --maybe??

	for i = 1, 4 do
		self.dtaDisplay[i] = 0x00
	end
	self.set()
    local newObj = {}
    self.__index = self
    return setmetatable(newObj, self)
end

--[[
    loca - location 3-2-1-0
    num - number to display
--]]
function Display:display(loca, dta)
	if loca > 4 or loca < 1
    then return
    end
	self.dtaDisplay[loca] = dta
	loca = 5 - loca
	local segData = self.coding(dta)
	self.start()
	self.writeByte(Display.ADDR_FIXED)
	self.stop()
	self.start()
	self.writeByte(bit.bor(loca, 0xc0)
	self.writeByte(segData)
	self.stop()
	self.start()
	self.writeByte(self.Cmd_Dispdisplay)
	stop()
end

function Display:clear()
    self.display(0x00,0x7f)
    self.display(0x01,0x7f)
    self.display(0x02,0x7f)
    self.display(0x03,0x7f)
end

-- Private methods

function Display:writeByte(wr_data)
	local i
	local count1
	for i = 1, 8 do
		storm.io.set(0, Display.Clkpin)
		if bit.band(wr_data, 0x01) then
			storm.io.set(1, Display.Datapin)
		else
			storm.io.set(0, Display.Datapin)
		end
		wr_data = bit.brshift(wr_data, 1)
		storm.io.set(1, Display.Clkpin)
	end
	
	storm.io.set(0, Display.Clkpin)
	storm.io.set(1, Display.Datapin)
	storm.io.set(1, Display.Clkpin)
	storm.io.set_mode(storm.io.INPUT, Display.Datapin)
	while storm.io.get(Display.Datapin) == 1 do
		count1 = count1 + 1
		if count1 == 200 then
			storm.io.set_mode(storm.io.OUTPUT, Display.Datapin)
			storm.io.set(0, Display.Datapin)
			count1 = 0
			storm.io.set_mode(storm.io.INPUT, Display.Datapin)
        end
    end
	storm.io.set_mode(storm.io.OUTPUT, Display.Datapin)
end

function Display:start()
	storm.io.set(1, Display.Clkpin)
	storm.io.set(1, Display.Datapin)
	storm.io.set(0, Display.Datapin)
	storm.io.set(0, Display.Clkpin)
end

function Display:stop()
	storm.io.set(0, Display.Clkpin)
	storm.io.set(0, Display.Datapin)
	storm.io.set(1, Display.Clkpin)
	storm.io.set(1, Display.Datapin)
end

function Display:set(brightness, SetData, SetAddr)
	self.brightness = brightness
	self.Cmd_SetData = SetData
	self.Cmd_SetAddr = SetAddr
	self.Cmd_Dispdisplay = 0x88 = brightness
end

function Display:pointOn()
	self.PointFlag = 1
	for i = 1, 4 do
		display(i, self.dtaDisplay[i])
	end
end

function Display:pointOff()
	self.PointFlag = 0
	for i = 1, 4 do
		display(i, self.dtaDisplay[i])
	end
end

function Display:coding(DispData)
	local PointData = (self.PointFlag and 0x80 or 0x00)
	if DispData == 0x7f then
		DispData = PointData
	else
		DispData = Display.TubeTab[DispData] + PointData
	end
	return DispData
end
