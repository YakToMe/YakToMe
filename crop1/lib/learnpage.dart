import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import 'data.dart';
import 'deck_editor.dart';
import 'fish.dart';

// add the rive puppet.
// add the voice engine

// a material route from the teach mode for testing
// takes a single word, generates 3 distractors and creates a gamescript for the game widget.
// provides a variety of ux affordances for testing (for now just a back button.)
class TeacherGame extends StatelessWidget {
  final GameScript script;
  TeacherGame(this.script);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SpeechScreen(script));
  }
}

// the student game doesn't take any arguments; it follows the algorithm to pick
// where it left off and produce the next challenge.
class StudentGame extends StatelessWidget {
  final GameScript script;

  StudentGame() : script = gData.doc.getNextScript();

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SpeechScreen(script));
  }
}

class SpeechScreen extends StatefulWidget {
  final GameScript script;
  SpeechScreen(this.script);

  @override
  _SpeechScreenState createState() => _SpeechScreenState(script);
}

// every few seconds turn off, speak a prompt, then turn back on.
class _SpeechScreenState extends State<SpeechScreen>
    with TickerProviderStateMixin {
  GameScript _script;
  //bool _loaded = true;
  bool _successState = false;
  final status = [false, false, false, false];
  int language = 0;
  final _controller = <AnimationController>[];

  List<String> speechFile = <String>[];

  _SpeechScreenState(this._script);

  String get langId => _script.deck.lang[language];

  @override
  void initState() {
    super.initState();
    _controller.add(AnimationController(vsync: this));
    _controller[0].addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextLanguage();
      }
    });

    // I should cache everything here, and not start until we can go without skips.
    // most of this defers to the voice plugin. build a json description of what
    // we will be doing, then we can wait until it's ready.
    _nextLanguage();
  }

  @override
  void dispose() {
    _controller.forEach((x) => x.dispose());
    _stopListen();
    super.dispose();
  }

  // this is already called within setState
  void _nextLanguage() {
    // we should pause a little here so we can display the last check animation.
    _successState = false;
    for (int i = 0; i != 4; i++) status[i] = false;
    _nextLanguageAsync();
  }

  // we need to async get the file (eventually bytes, but even just the name)
  Future<void> _nextLanguageAsync() async {
    final d = _script.deck;
    final wordmp3 = <String>[];
    for (var x in _script.word) {
      wordmp3.add(await d.speechFile(langId, d.words[x]));
    }

    final f = [await d.speechFile(langId, "_the_password_is"), ...wordmp3];
    setState( () { speechFile = f;});
  }

  void _tapWord(int n) async {
    //playWord(_script.deck.words[_script.word[n]]);
    final d = _script.deck;
    final f = await d.speechFile(langId, d.words[n]);
    setState(() {
      speechFile = [f];
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    double puppetHeight = (mq.size.height / 4);
    double puppetWidth = 4 / 3 * puppetHeight;
    double puppetTop = mq.size.height - puppetHeight;
    double puppetLeft = 0;  
    double puppetRight = mq.size.width - puppetWidth;

    return Stack(children: [
      ...(_successState
          ? []
          : [
              WordChoice(
                  deck: _script.deck,
                  lang: langId,
                  status: status,
                  onTap: _tapWord,
                  word: _script.word)
            ]),
      ...(_successState
          ? [
              Lottie.asset('assets/balloons.zip',
                  controller: _controller[0],
                  height: mq.size.height,
                  width: mq.size.width, onLoaded: (composition) {
                _controller[0]
                  ..duration = composition.duration
                  ..forward();
              }),
            ]
          : []),
      Positioned(
          left: puppetLeft,
          top: puppetTop,
          width: puppetWidth,
          height: puppetHeight,
          child: GestureDetector(
              onDoubleTap: () {
                for (int i = 0; i != 4; i++) {
                  _sayWord(i);
                }
              },
              onLongPress: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return DeckEditor();
                }));
              },
              child: FishPuppet(speechFile))),
        Positioned(
          left: puppetRight,
          top: puppetTop,
          width: puppetWidth,
          height: puppetHeight,
          child: GestureDetector(
              onDoubleTap: () {
                for (int i = 0; i != 4; i++) {
                  _sayWord(i);
                }
              },
              onLongPress: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return DeckEditor();
                }));
              },
              child: FishPuppet([]))),
    ]);
  }

  // this records the fact that we said deck.word[word] in language langId.
  void _sayWord(int word) {
    for (int i = 0; i != 4; i++) {
      if (!status[i] && _script.word[i] == word) {
        setState(() {
          status[i] = true;
        });
        break;
      }
    }
    if (status.reduce((a, b) => a && b) == true) {
      // we want finish the animation for wordchoice before
      Future.delayed(const Duration(seconds: 2), () {
        _success();
      });
    }
  }

  Future<void> _nextQuestion() async {
    gData.doc.logScript(_script);
    _script = _script.deck.getNextScript();
    language = 0;
    _nextLanguage();
  }

  Future<void> _success() async {
    // for each word/status update the score
    for (int i = 0; i != status.length; i++) {
      _script.score[_script.word[i] * _script.deck.lang.length + language] =
          1.0;
    }

    if (language + 1 == _script.deck.lang.length) {
      // maybe this should go to a victory materialroute, then pop that
      // when they tap or it completes? where do we getnextscript?
      setState(() {
        // we need to wait here until the lottie animations are done.
        _successState = true;
        _nextQuestion();
      });
    } else {
      setState(() {
        language++;
        _nextLanguage();
      });
    }
  }

  // try grpc voice recognition
  void _stopListen() {}
  void _listen() {}
}


class WordChoice extends StatelessWidget {
  final Deck deck;
  final String lang;
  final List<int> word;
  final List<bool> status;
  final void Function(int) onTap;
  final bool showCaption;
  WordChoice(
      {required this.deck,
      required this.lang,
      required this.status,
      required this.onTap,
      required this.word,
      this.showCaption = true});

  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final data = gData; // Provider.of<Data>(context);

    double widthChoice = (mq.size.width - 48) / 2;
    double heightChoice = (mq.size.height - 48) / 2;
    double wspace = k16;
    double hspace = k16;
    // we want 4:3 pictures with even spacing and a minimum border of 16px.
    if (widthChoice > 4 / 3 * heightChoice) {
      // shrink the width to keep aspect ration
      widthChoice = 4 / 3 * heightChoice;
      wspace = (mq.size.width - 2 * widthChoice + k16) / 2;
    } else {
      heightChoice = 3 / 4 * widthChoice;
      hspace = (mq.size.height - 2 * heightChoice + k16) / 2;
    }

    // where should the image caching occur?
    // i here is always 0 to 4.
    Widget makeChoice(int i) {
      final w = deck.words[word[i]];
      final fb = deck.image(w);
      return Duck(
          value: status[i],
          onTap: () {
            onTap(i);
          },
          image: fb,
          caption: deck.translate(lang, w),
          checkLottie: 'assets/checkmark.zip');
    }

    return Container(
        color: Colors.black,
        child: Stack(children: [
          Positioned(
              left: wspace,
              top: hspace,
              child: makeChoice(0),
              width: widthChoice,
              height: heightChoice),
          Positioned(
              left: wspace + k16 + widthChoice,
              top: hspace,
              child: makeChoice(1),
              width: widthChoice,
              height: heightChoice),
          Positioned(
              left: wspace,
              top: hspace + k16 + heightChoice,
              child: makeChoice(2),
              width: widthChoice,
              height: heightChoice),
          Positioned(
              left: wspace + k16 + widthChoice,
              top: hspace + k16 + heightChoice,
              child: makeChoice(3),
              width: widthChoice,
              height: heightChoice),
        ]));
  }
}

// duck provices a widget that animates from an active state to a success state
// It's like a checkbox that can't be unchecked. It provides onTap event
class Duck extends StatefulWidget {
  final bool value;
  final void Function() onTap;
  final ImageProvider image;
  final String checkLottie;
  final String caption;

  Duck(
      {required this.value,
      required this.onTap,
      required this.image,
      required this.checkLottie,
      required this.caption});

  @override
  DuckState createState() => DuckState();
}

// do we need this ticker provider? can't we share one at a higher level?
class DuckState extends State<Duck> with TickerProviderStateMixin {
  AnimationController? _controller;
  bool _check = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_check != widget.value) {
      if (widget.value) {
        _controller?.forward();
        _check = true;
      } else {
        _controller?.animateBack(0.0);
        _check = false;
      }
    }
    return GestureDetector(
        onTap: () {
          widget.onTap();
        },
        child: Stack(children: [
          // image here might not be an asset; should we use an image provider?
          // the animate opacity here allows the challenge image to be dimmed while overlaying the
          // success image. might want a success sound? that's going to reduce recognition though.
          AnimatedOpacity(
              opacity: _check ? 0.5 : 1.0,
              duration: Duration(milliseconds: 300),
              child: Image(image: widget.image)),
          Center(
              child: Lottie.asset(widget.checkLottie, controller: _controller,
                  onLoaded: (composition) {
            // Configure the AnimationController with the duration of the
            // Lottie file and start the animation.
            _controller?..duration = composition.duration;
          }, width: 96 * 2.0, height: 96 * 2.0))
        ]));
  }
}

const k16 = 16.0;
