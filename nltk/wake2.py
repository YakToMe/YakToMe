from pocketsphinx import AudioFile

audio = AudioFile(audio_file='/mypython/nltk/en-US.wav',lm=False, keyphrase='zap', kws_threshold=1e-20)
for phrase in audio:
    print(phrase.segments(detailed=True)) # => "[('forward', -617, 63, 121)]"
