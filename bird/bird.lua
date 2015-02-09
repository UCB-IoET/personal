require("storm")
require("cord")
require("math")
require("table")
shield = require("starter")

print("Tweet tweet I'm a bird with node ID ", storm.os.nodeid())

sport = 55555

songs = {60, 300, 1000} -- TODO change this to freq, duration pairs
cur_song = math.random(3)

-- Listening window
min1 = 100*storm.os.MILLISECOND
max1 = storm.os.SECOND
min2 = 100*storm.os.MILLISECOND
max2 = 2*storm.os.SECOND

csock = storm.net.udpsocket(math.random(55556, 65535), function() end)

function play_song(song)
    print("I'm playing song ", cur_song)
    shield.Buzz.go(1/song)
    storm.os.invokeLater(500*storm.os.MILLISECOND, listen)
end

function maxkey(t)
    max = 0
    index = 0
    for i = 1, table.getn(t) do
        if t[i] >= max then
            max = t[i]
            index = i
        end
    end
    return index
end

function listen()
    print("started listening")
    shield.Buzz.stop()
    song_table = {0, 0, 0}
    song_table[cur_song] = song_table[cur_song] + 1
    wait1 = math.random(min1, max1)
    wait2 = math.random(min2, max2)

    ssock = storm.net.udpsocket(sport, function(song_id, srcip, srcport)
        song_table[song_id] = song_table[song_id] + 1
        print (string.format("Message from %s port %d: Song %s",from,port,payload))
    end)

    storm.os.invokeLater(wait1, function() print("announcing song") storm.net.sendto(csock, cur_song, "ff02::1", sport) end)
    storm.os.invokeLater(wait1 + wait2, function()
        storm.net.close(ssock)
        cur_song = maxkey(song_table)
        print("my song is now ", cur_song)
        play_song(songs[cur_song])
    end)
end

play_song(cur_song)
cord.enter_loop()
