import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'package:rive/rive.dart';
import 'package:rive/src/rive_core/node.dart';
import 'dart:collection';
import 'dart:math';

import 'data.dart';
import 'voice.dart';
import 'web_file.dart';
import 'deck_editor.dart';

class FishPuppet extends StatefulWidget {
  final List<String> speechFile; // lips change .txt
  FishPuppet(this.speechFile);
  _FishState createState() => _FishState();
}

//  List<String> mouthSequence = <String>[];
//   List<int> mouthDelay = <int>[];
// reads a rhubarb file, translates to adobe puppet keys.
class Lips {
  final List<double> time;
  final List<String> mouth;
  Lips(this.mouth, this.time);

  static String mapMouth(String rhubarb) {
    switch (rhubarb) {
      case 'A':
        return "M";
      case 'B':
        return "D";
      case 'C':
        return "Ee";
      case 'D':
        return "Ah";
      case 'E':
        return "Uh";
      case 'F':
        return "W-Oo";
      case 'G':
        return "F";
      case 'H':
        return "L";
      case 'X':
      default:
        return "Neutral";
    }
  }

  static Future<Lips> fromFile(String p) async {
    assert(await File(p).exists(), "$p does not exist");
    final words = await File(p).readAsLines();
    final r1 = <double>[];
    final r0 = <String>[];
    for (var x in words) {
      final w = x.split('\t');
      if (w.length >= 2) {
        r0.add(mapMouth(w[1]));
        r1.add(double.parse(w[0]));
      }
    }
    return Lips(r0, r1);
  }
}

class SpeechController extends RiveAnimationController<RuntimeArtboard> {
  HashMap<String, Node> _mouthMap = HashMap<String, Node>();
  Node? _mouth;

  Lips lips = Lips([], []);
  int mouthIndex = 0;
  double talkTime = 0;

  set mouth(String s) {
    if (_mouth != null) _mouth?.opacity = 0;
    _mouth = _mouthMap[s];
    _mouth?.opacity = 1;
    isActive = true;
  }

  @override
  bool init(RuntimeArtboard artboard) {
    artboard.forEachComponent((component) {
      if (component.parent.name == "Mouth") {
        _mouthMap[component.name] = component as Node;
      }
    });
    this.mouth = "Smile";
    return true;
  }

  void say(Lips x) {
    lips = x;
    mouthIndex = 0;
    isActive = true;
  }

  @override
  void apply(RuntimeArtboard core, double elapsedSeconds) {
    if (mouthIndex < lips.mouth.length) {
      if (mouthIndex == 0) 
        talkTime =0;
      else
        talkTime += elapsedSeconds;
      if (talkTime >= lips.time.last) {
        mouth = "Smile";
        mouthIndex = 0;
        lips = Lips([], []);
      } else {
        while (talkTime >= lips.time[mouthIndex] &&
            mouthIndex < lips.mouth.length) mouthIndex++;
        this.mouth = lips.mouth[mouthIndex-1];
        //print("$mouthIndex, ${lips.mouth[mouthIndex]}, $talkTime, ${lips.time[mouthIndex]}");
      }
    }
  }
}

class BlinkController extends RiveAnimationController<RuntimeArtboard> {
  SimpleAnimation trigger;
  double blinkTime = 0;
  double nextBlinkTime = 0;
  BlinkController(String s) : trigger = SimpleAnimation(s);
  final rnd = Random();
  @override
  bool init(RuntimeArtboard artboard) {
    artboard.addController(trigger);
    isActive = true;
    return true;
  }

  @override
  bool apply(RuntimeArtboard core, double elapsedSeconds) {
    blinkTime += elapsedSeconds;
    if (blinkTime > nextBlinkTime) {
      nextBlinkTime += rnd.nextInt(2) + 2;
      trigger.instance.time = 0;
      trigger.isActive = true;
    }
    return true; // always going.
  }
}

class _FishState extends State<FishPuppet> with SingleTickerProviderStateMixin {
  SpeechController speech = SpeechController();
  RiveAnimationController? _bubbles;
  Artboard? _artboard;

  @override
  void initState() {
    _loadRiveFile();
    addSpeech(widget.speechFile);
    super.initState();
  }

  @override
  void didUpdateWidget(FishPuppet old) {
    addSpeech(widget.speechFile);
    super.didUpdateWidget(old);
  }

  Future<void> addSpeech(List<String> speechFile) async {
    if (speechFile.isNotEmpty) {
      final lips = await Lips.fromFile(speechFile[0]+'.txt');
      speech.say(lips);
    }
  }

  /// continue init async
  void _loadRiveFile() async {
    final bytes = await rootBundle.load('assets/fish.riv');
    final file = RiveFile();
    if (file.import(bytes)) {
      setState(() {
        final tail = SimpleAnimation('tail');

        _artboard = file.mainArtboard
          ..addController(tail)
          ..addController(BlinkController('blink'))
          ..addController(speech)
          ;
        tail.instance.animation.fps = 60;
      });
    }
  }

  void _toBubble() {
    if (_bubbles != null) _artboard?.removeController(_bubbles);
    _artboard?.addController(_bubbles = SimpleAnimation('bubbles'));
  }

  @override
  Widget build(BuildContext context) {
    return _artboard != null
        ? Rive(
            artboard: _artboard,
            //fit: BoxFit.cover,
          )
        : Container();
  }
}