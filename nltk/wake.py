
#!/usr/bin/env python3

from vosk import Model, KaldiRecognizer
import sys
import os
import wave
import json
import glob

def words():
    v = [ x.rstrip().split('\t')[1] for x in open('/yaktome/assets/1/lang/en/words.tsv', 'r').readlines()]
    v.append('[unk]')
    return  json.dumps(v)
        

def voskit():
    if not os.path.exists("model"):
        print ("Please download the model from https://alphacephei.com/vosk/models and unpack as 'model' in the current folder.")
        exit (1)
    model = Model("model")
    rec = KaldiRecognizer(model, 48000, words())    
    
    for fn in glob.iglob('c:/yaktome/assets_src/lang/en/*.wav'):
        wf = wave.open(fn, "rb")
        if wf.getnchannels() != 1 or wf.getsampwidth() != 2 or wf.getcomptype() != "NONE":
            print ("Audio file must be WAV format mono PCM.")
            exit (1)
        while True:
            data = wf.readframes(4000)
            if len(data) == 0:
                break
            if rec.AcceptWaveform(data):
                print(rec.Result())
            else:
                print(rec.PartialResult())
    print(rec.FinalResult())
    
voskit()
#print( words())