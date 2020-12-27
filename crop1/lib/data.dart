import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'dart:collection';
import 'image_search_lib.dart';
import 'voice.dart';
import 'web_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';


final Data gData = Data();
final audio = VoiceEngine();
// for now only one deck open at a time; potentially a tab interface though.

class Profile {
  int id = 0;
  String name = "unknown";
  String type = "student";  
  List<String> lang = <String>['en'];
  bool loaded = false;  
  final deck = <Deck>[];
}


// this is an argument to the the learnpage; sets up the game
// the game script is the state that is stored for each student*deck 
// so they can pick up where they left off.
// we can also create arbitrary game states for testing.
class GameScript {
  //void Function(int) onComplete;  // game is over.
  Deck deck;
  List<int> word;    
  
  // there is a different score for each language*word
  // 
  List<double> score = <double>[];
  
  

  // set the card to a future state for testing.
  // setting card to a future state 
  GameScript(this.deck,this.word){
    for (int i=0; i!=word.length*deck.lang.length; i++)
      score.add(0);
  }

}


// should deck be 
class Deck extends ChangeNotifier  {
  int id = 1;
  String name;
  List<String> lang = <String>['en', 'es'];  
  
  // words is more like "concepts"; they uniquely identify meaning among homographs
  List<String> words = [];  
  List<double> score = <double>[0];  // leng.leng * word.length.
  bool loaded = false;
  String path="";
  final _translate = HashMap<String, String>(); 
      
  Deck({this.id=1, this.name=""});
  
  Future<void> updateImage(ImageResult r) async {
    File(imagePath(r.word)).writeUrlAsBytes(r.url);
    await File(imagePath(r.word)+'.json').writeAsString(r.jsonCredits);
    notifyListeners();
  }
  
  GameScript getScript(int i) {
    return GameScript(this, [ i,i,i,i]);
  }
  
  // the minimum score over languages; 0 if any are 0 (so don't go on).
  double get lastScore {
    double sc = score.last;
    for (int i=1; i!=lang.length; i++){
      sc = min(sc,score[score.length-i-1]);
    }
    return sc;
  }
  
  GameScript getNextScript() {
    assert(score.length <= lang.length*words.length);
    assert(words.isNotEmpty);
    assert(score.isNotEmpty);
    assert(lang.isNotEmpty);

    // move to the next word unless last score was 0.
    if (score.length!=lang.length*words.length &&  lastScore != 0){
      for (int i=0; i!=lang.length; i++) score.add(0);
    }
    int w = (score.length ~/ lang.length) -1;    
    
    // pick 3 previous words, unless they don't exist, then use word 0.
    final r = <int>[];
    for (int i =w-3; i<=w; i++){
      r.add( i<0?0:i);
    }
    return GameScript(this,r);
  }
 
  Future<void> loadState() async {
    final m =  jsonDecode( await File(path+'/state.json').readAsString());
    lang = List<String>.from(m['lang']);
    score = List<double>.from(m['score']);
  }
  
  Future<void> saveState() async {
    final s = jsonEncode( {
        lang: lang,
        score: score
    });
    File(path+'/state.json').writeAsString(s);
  }
  // how should I generalize this?
  // only log student games, not test games
  Future<void> logScript(GameScript s) async {
    for (int i=0; i!=s.word.length; i++ ) {
      for (int j=0; j!=lang.length; j++){
        score[s.word[i]*lang.length+j] = max(score[s.word[i]*lang.length+j], s.score[i*lang.length+j]);
      }
    }
    await saveState();
  }
  
  // this sets the prototype of the root as itself, which could cause loops
  // but avoids nulls :(
  Deck get prototype {
    assert (this != gData.prototype);
    return gData.prototype;
  }
  bool get isRoot => gData.prototype == this;

  String getValidFilename(String s) => s.replaceAll(' ', '_');

  // this is the path for the deck, doesn't look farther
  String imagePath(String word) => imagePath2(path,word);
  String protoPath(String word) => imagePath2(prototype.path,word);
        
  String imagePath2(String root, String word) =>
      absolute('$root/image/' + getValidFilename(word) + '.jpg');      
      
  Future<void> writePicture(String word, Uint8List bytes) async {
    await File(imagePath(word)).writeAsBytes(bytes);
    notifyListeners();
    gData.notifyListeners();
  }
  
  // look in the prototype if necessary
  WebFileImage image(word)  {
    return WebFileImage(File(imagePath(word)),File(protoPath(word)));
  }

  Future<String> credits(word) async {
     final f = File(imagePath(word) + '.json');
     return (await f.exists())? f.readAsString() :  File(protoPath(word) + '.json').readAsString();
  }

  String multiLabel(String word) =>
      lang.map((x) => _translate['$x:$word'] ?? word).join(', ');
      

  
  String translate(String lang, String word) {
    return _translate['$lang:$word'] ?? gData.prototype._translate['$lang:$word'] ??word;
  }  



   Future<String> speechFile(String lang, String word) async {
     final p = '$path/lang/$lang/$word';
     if (await File(p).exists())
        return p;
     else
        return '${prototype.path}/lang/$lang/$word';
   }
 
  
  
  
  Future<bool> loadLanguage(String langx) async {
    final fn = '$path/lang/$langx/words.tsv';
    if (await File(fn).exists()) {
      final words = await File(fn).readAsLines();
      for (var x in words) {
        final w = x.split('\t');
        if (w.length >= 2) {
          _translate['$langx:${w[0]}'] = w[1];
        }
      }
      return true;
    } else {
      // should automatically download here?
      return false;
    }
  }
  Future<void> load(String pathx,{bool prototype=false}) async {
    loaded = true;
    path = '$pathx/$id';
    final fn = '$path/words.txt';
    words = await File(fn).readAsLines();

    for (var x in lang) {
      await loadLanguage(x);
    }    
    if (!prototype)
      await loadState();
  }  
 }

// Etc is the raw data that Data wraps around.


class Data extends ChangeNotifier {
  //final String dir;
  String docsDir = "/yaktome/docs";
  String assetDir = "/yaktome/assets"; // when should we use this vs application documents?
  String tempDir = "/yaktome/temp";
  List<Profile> profile = [];
  List<Deck> sortedDeck = []; 
  bool devInstall = false;

  // the name here should be localized, so we need some id that doesn't depend on the name.
  final prototype = Deck(name: "Starter");
  Deck doc = Deck();  // easier than fighting null safety
  List<String> get words => doc.words;
  
  Data();

  Future<void> load() async {
    devInstall = await Directory(docsDir).exists();
    if (!devInstall) {
      docsDir = (await getApplicationDocumentsDirectory()).path;
      assetDir = (await getApplicationSupportDirectory()).path;
    }
    tempDir = (await getTemporaryDirectory()).path;
      
    // todo! load the json configuration
    // load the (for now single) prototype, It should be in 
    await prototype.load('$assetDir',prototype: true);
    
    // intiate storedDeck with the all the decks
    // sort by the active student decks first.
    final Map<String,dynamic> m = jsonDecode(await File('$docsDir/index.json').readAsString());
    final deck = m["profile"] as List<dynamic>;
    for (var dx in deck) {
      final d = dx as Map<String,dynamic>;
      final r = Profile();
      r.id = d['id'];
      r.name = d['name'];
      r.type = d['type'];
      r.lang = List<String>.from(d['lang']);
      profile.add(r);
    }
    
    // for now we have one student, one teacher, one deck, so go ahead and load it.
    await doc.load("$docsDir/10001");
 }


}
