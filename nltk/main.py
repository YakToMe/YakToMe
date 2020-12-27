import nltk
import nltk.tokenize
import pycurl
from io import BytesIO
from google.cloud import texttospeech
#from google.clound import texttospeech_v1beta1 as texttospeech
import requests
import re
import os
import json
import subprocess
from pathlib import Path
from playsound import playsound


os.environ["GOOGLE_APPLICATION_CREDENTIALS"]='c:\csharp\google.json'

arpabet = nltk.corpus.cmudict.dict()

def count_phoneme(w):
    x = 0
    for t in w.split():
        x += len(arpabet[t][0])
    return x

def get_valid_filename(s):
    """
    Return the given string converted to a string that can be used for a clean
    filename. Remove leading and trailing spaces; convert other spaces to
    underscores; and remove anything that is not an alphanumeric, dash,
    underscore, or dot.
    >>> get_valid_filename("john's portrait in 2004.jpg")
    'johns_portrait_in_2004.jpg'
    """
    s = str(s).strip().replace(' ', '_')
    return re.sub(r'(?u)[^-\w.]', '', s)
    
def download(url, file):
    res = requests.get(url)
    with open(file, 'wb') as fd:
        for chunk in res.iter_content(chunk_size=128):
            fd.write(chunk)
            
def write_file(string, file):
    with open(file, 'w') as fd:
        fd.write(string)
    
def get_image(w,count,dir):
    res = requests.get("https://api.creativecommons.engineering/v1/images?q={}&mature=false&license=cc0,by".format(w))
    ix = 0
    js = res.json()
    ri = js["results"]
    fn = get_valid_filename(w)
    Path("{}/{}".format(dir,fn)).mkdir(parents=True, exist_ok=True)
    while ix < count:
        #print(ri[ix]["url"])
        download(ri[ix]["url"],"{}/{}/{}.jpg".format(dir,fn,ix))
        #write the result to a credits file
        write_file( json.dumps(ri[ix]),"{}/{}/{}.json".format(dir,fn,ix))
        ix += 1
            
def speech_part(line):
    a = nltk.pos_tag(nltk.word_tokenize(line))
    for (w,p) in a:
        if p[0:2]=='NN':
            return 'N'
    for (w,p) in a:
        if p[0:2]=='JJ':
            return 'A' #adjective
    for (w,p) in a:
        if p[0:2]=='PR':
            return 'P' #pronoun
    for (w,p) in a:
        if p[0:2]=='IN':
            return 'Z' #preposition
    for (w,p) in a:
        if p[0:1]=='V':
            return 'V' #verb
    for (w,p) in a:
        if p[0:2]=='RB':
            return 'B' #adverb            
    return ''
            
def extract_nouns():
    nouns = open('/yaktome/data/nouns.txt', 'w')
    not_nouns = open('/yaktome/data/not_nouns.txt', 'w')
    preposition = open('/yaktome/data/preposition.txt', 'w')
    adverb = open('/yaktome/data/adverb.txt', 'w')
    pronoun = open('/yaktome/data/pronoun.txt', 'w')    
    verb = open('/yaktome/data/verb.txt', 'w')    
    adjective = open('/yaktome/data/adjective.txt', 'w')   
        
    Lines = open('/yaktome/data/words.txt', 'r').readlines()
    for line in Lines:
        #print(line, nltk.pos_tag(nltk.word_tokenize(line)))
        x = speech_part(line)
        if x=='N':
            nouns.write(line)
        elif x=='A': 
            adjective.write(line)
        elif x=='P':
            pronoun.write(line)
        elif x=='Z':
            preposition.write(line)
        elif x=='V':
            verb.write(line)
        elif x=='B':
            adverb.write(line)
        else:
            not_nouns.write(line)

def text_to_wav(filename,voice="",  text="", ssml=""):
    language_code = "-".join(voice.split("-")[:2])
    if ssml=="":
        text_input = texttospeech.SynthesisInput(text=text)
    else:
        text_input = texttospeech.SynthesisInput(ssml=ssml)
    voice_params = texttospeech.VoiceSelectionParams(
        language_code=language_code, name=voice
    )
    audio_config = texttospeech.AudioConfig(
        audio_encoding=texttospeech.AudioEncoding.LINEAR16
    )

    client = texttospeech.TextToSpeechClient()
    response = client.synthesize_speech(
        input=text_input, voice=voice_params, audio_config=audio_config
    )
    with open(filename, "wb") as out:
        out.write(response.audio_content)
        #print(f'Audio content written to "{filename}"')
        
    
def play_voice(text="",outputfile="",ssml="",voice="en-US-Wavenet-H"):
    if outputfile=="":
        outputfile = '/yaktome/assets/'+get_valid_filename(text)+'.wav'
    else:
        outputfile = '/yaktome/assets/'+outputfile+'.wav'
    if not os.path.exists(outputfile):
        text_to_wav(outputfile, voice=voice,text=text,ssml=ssml)
    print(outputfile)
    #playsound(file)
    
def play_voice_file(path,voice):
    for line in  open(path, 'r').readlines():
        play_voice(text=line,voice=voice)
         
def play_translated(lang, voice):
    for line in open(f"c:/yaktome/assets/lang/{lang}/words.txt", "r").readlines():
        v = line.split("\t")
        text_to_wav(f"c:/yaktome/assets/lang/{lang}/{get_valid_filename(v[0])}.wav",voice=voice, text=v[1])

    
def test():      
    #text_to_wav("en-US-Wavenet-H", "What is the temperature in Sydney?")
    #get_image('water buffalo',3,'/yaktome/ccby')
    #print(get_valid_filename('water buffalo'))
    play_voice(ssml='''<speak>Say the password 
    <prosody rate='-20%'>duck 
    <break strength="weak"/> duck 
    <break strength="weak"/> goose</prosody>
    </speak>''', file='duck_duck_goose')
    play_voice(text="Good Job! That's it!")
    play_voice(text="Try again!")
    #input("wait for it")

def sorted_nouns():
    extract_nouns()
    nouns = open('/yaktome/data/sorted_nouns.txt', 'w')
    Lines = open('/yaktome/data/nouns.txt', 'r').readlines()
    sorted = []
    for line in Lines:
        tup = (count_phoneme(line.rstrip()),line.rstrip())
        sorted.append(tup)
    sorted.sort()
    for (n,w) in sorted:
        nouns.write("{}\n".format(w))
        
#sorted_nouns()

#play_voice(file="the_password_is", ssml="<speak><prosody rate='-20%'>the password is </prosody></speak>")
# play_voice(file="thats_it", ssml="<speak><prosody >That's it! You did it! </prosody></speak>")

# play all the voices for some language
#play_voice_file('/yaktome/assets/words.txt')

#play_voice_file('/yaktome/assets/words.txt',voice='es-ES-Wavenet-B')
#play_voice( text="the password is?", voice='es-ES-Wavenet-B')

# translate the phrases into the target language
# text to speech the phrases that we need into wav files into assets_src
# use rhubarb to do lip syncing
# use ffmpg to encode mp3
# copy the mp3 and lipsync files into asset directory.
prompts = [ 
    "_the_password_is", "The password is",  "<speak><prosody rate='-20%'></prosody></speak>",
]
languages = [
    "es-ES-Wavenet-B",
]

#play_voice(voice="es-ES-Wavenet-B", outputfile="_the_password_is", ssml="<speak><prosody rate='-20%'>la contraseña es</prosody></speak>")

def replace_ext(fname,ext):
    return os.path.splitext(fname)[0] + ext

def mp3_encode(wav):
    subprocess.call(f"ffmpeg -i {wav} {replace_ext(wav,'.mp3')}")
    
def lipsync(wav,english=False):
    ph = '' if english else '-r phonetic '
    subprocess.call(f"rhubarb {ph} -o  {replace_ext(wav,'.txt')} {wav}")    
    
#mp3_encode('c:/yaktome/assets/1/lang/es/_the_password_is.wav')
#lipsync('c:/yaktome/assets/1/lang/es/_the_password_is.wav')

#text_to_wav('C:/yaktome/assets/lang/es/hello.mp3', 'es-ES-Wavenet-B', text="hola, mundo")

#this creates audio from a translation file
#play_translated("es", 'es-ES-Wavenet-B')

def translate_ex():
    from googletrans import Translator
    translator = Translator()
    for x in translator.translate(['The quick brown fox', 'jumps over', 'the lazy dog'], dest='es') :
        print(x.text)


# translate words to valid file name and the engish translation in a separate file.
# replace ' ' with _

def to_valid():
    en = open('/yaktome/assets/1/lang/en/words.tsv', 'w')
    Lines = [x.rstrip() for x in open('/yaktome/assets/1/words.txt', 'r').readlines()]
    for x in Lines:
        v = x.replace('_', ' ')
        en.write(f"{x}\t{v}\n")

def to_valid3():
    en = open('/yaktome/assets/1/lang/en/words.tsv', 'w')
    en2 = open('/yaktome/assets/1/valid.txt', 'w')
    Lines = [x.rstrip() for x in open('/yaktome/assets/1/words.txt', 'r').readlines()]
    for x in Lines:
        v = x.replace(' ','_')
        en.write(f"{v}\t{x}")
        en2.write(f"{v}")
        
                
def to_valid2():
    es = open('/yaktome/assets/1/lang/es/words.tsv','r').readlines()
    es2 = open('/yaktome/assets/1/lang/es/words2.tsv','w')
    for x in es:
        w = x.split('\t')
        es2.write(f"{w[0].replace(' ','_')}\t{w[1]}")
        
    
to_valid()

        
        
        


