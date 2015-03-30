require "cord" -- scheduler / fiber library
require "storm"

n = 17
offish = storm.array.create(3 * n, storm.array.UINT8)

function on(color, delay)
    black = storm.array.create(3*n, storm.array.UINT8)
    for c = 1,3 do
        for i = 0, n - 3 do
            black:set(i*3 + c, 0xff)
            storm.n.neopixel(black)
            for i = 1, 30000 do end
            --cord.await(storm.os.invokeLater, 50*storm.os.MILLISECOND)
            --for g = 1,3 do
            --  black:set((i + g)*3, 0x00)
            --end
        end
    end
end

function off(color, delay)
    white = storm.array.create(3*n, storm.array.UINT8)
    for i = 1,3*n do
        white:set(i, 0xff)
    end
    for c = 1,3 do
        for i = n-3, 0, -1 do
            white:set(i*3 + c, 0x00)
            storm.n.neopixel(white)
            for i = 1, 30000 do end
        end
    end
end

storm.io.set_mode(storm.io.INPUT, storm.io.D3)
storm.io.set_pull(storm.io.PULL_UP, storm.io.D3)

function listen_rising()
   storm.io.watch_single(storm.io.RISING, storm.io.D3, function()
							on()
							listen_falling()
													   end)
end

function listen_falling()
   storm.io.watch_single(storm.io.FALLING, storm.io.D3, function()
							off()
							listen_rising()
														end)
end

listen_rising()

-- enable a shell
sh = require "stormsh"
sh.start()
cord.enter_loop() -- start event/sleep loop
