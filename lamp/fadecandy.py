def chase(color, gap=3, iterations=3, delay=0.05, brightness=1):
    for _ in xrange(iterations):
        for i in xrange(-2, numLEDs - 3):
    pixels = [bright(hex_to_RGB(color), brightness)] * numLEDs
            for g in xrange(0, gap):
                pixels[i + g] = (0, 0, 0)
            client.put_pixels(pixels)
            time.sleep(delay)
    fade_out()
