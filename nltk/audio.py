if False:
    import miniaudio
    import pprint
    import time
    stream = miniaudio.stream_file("c:/yaktome/assets/lang/en/animal.mp3")
    device = miniaudio.PlaybackDevice( device_id=miniaudio.Devices().get_playbacks()[3]['id'])
    #pprint.pprint(device)
    if False:
        device.start(stream)
        time.sleep(2)
        device.stop()
    #pprint.pprint (miniaudio.Devices().get_playbacks())
    #pprint.pprint(device)

    #miniaudio.wav_write_file("c:/yaktome/assets/lang/en/animal.wav")
    pprint.pprint( miniaudio.get_enabled_backends ())

if False:
    for word in ('duck', 'goose', 'buffalo', 'tomato'):
        try:
            print (arpabet[word])
        except Exception as e:
            print(e)

if False:
    playsound('c:/yaktome/assets/lang/en/duck.wav')
    import time
    time.sleep(2)