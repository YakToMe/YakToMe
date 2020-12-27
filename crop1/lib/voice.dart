import 'dart:typed_data';
import 'package:universal_platform/universal_platform.dart';
import 'package:ffi/ffi.dart';
import 'dart:ffi';


// MOVE THIS TO PLUGIN

const int SND_FILENAME = 0x00020000;
final _winmm = DynamicLibrary.open('winmm.dll');
int PlaySound(Pointer<Utf16> pszSound, int hmod, int fdwSound) {
  final _PlaySound = _winmm.lookupFunction<
      Int32 Function(Pointer<Utf16> pszSound, IntPtr hmod, Uint32 fdwSound),
      int Function( Pointer<Utf16> pszSound, int hmod, int fdwSound)> ('PlaySoundW');
  return _PlaySound(pszSound, hmod, fdwSound);
}

String fromUtf16(Pointer pointer, int length) {
  final buf = StringBuffer();
  final ptr = Pointer<Uint16>.fromAddress(pointer.address);

  for (var v = 0; v < length; v++) {
    final charCode = ptr.elementAt(v).value;
    if (charCode != 0) {
      buf.write(String.fromCharCode(charCode));
    } else {
      return buf.toString();
    }
  }
  return buf.toString();
}

int mciSendCommand(int IDDevice, int uMsg, int fdwCommand, int dwParam) {
  final _mciSendCommand = _winmm.lookupFunction<
      Uint32 Function(
          Uint32 IDDevice, Uint32 uMsg, IntPtr fdwCommand, IntPtr dwParam),
      int Function(int IDDevice, int uMsg, int fdwCommand,
          int dwParam)>('mciSendCommandW');
  return _mciSendCommand(IDDevice, uMsg, fdwCommand, dwParam);
}
int mciSendString(Pointer<Utf16> lpszCommand, Pointer<Utf16> lpszReturnString,
    int cchReturn, int hwndCallback) {
  final _mciSendString = _winmm.lookupFunction<
      Uint32 Function(
          Pointer<Utf16> lpszCommand,
          Pointer<Utf16> lpszReturnString,
          Uint32 cchReturn,
          IntPtr hwndCallback),
      int Function(Pointer<Utf16> lpszCommand, Pointer<Utf16> lpszReturnString,
          int cchReturn, int hwndCallback)>('mciSendStringW');
  return _mciSendString(lpszCommand, lpszReturnString, cchReturn, hwndCallback);
}
// isn't the ideal model here io uring? more than we need here though.
// cqe's return 128 bits (res + tag). Is 63 bits enough here, or should we pass pointers?
// should we pass back a vector of cqe's?

const kInit = 0; // { } -> return version.
const kListen = 1;
const kPoll = 2;   // return words recognized.

// we can fake this with a timer that just pretends that they said it.
class VoiceEngine {
  // how am I going to get this to NDK/plugin?
  // Is there any issue with plugins sharing files with the flutter program?
  int submit(int op, int tag, Uint8List json) {
    // not as efficient, but spares us memory allocation troubles in dart
    return 0;
  }
  // we could poll from a different isolate; allows long polls etc.
  int poll(int buffersize , Uint8List backbuffer) {
    return 0;
  }
  
  void mciSend(String s) {
      final sp = Utf16.toUtf16(s);
      int e0 = mciSendString(sp, Pointer<Utf16>.fromAddress(0),0,0);    
      free(sp);
  }
  int mciSendGetInt(String s) {
      final sp = Utf16.toUtf16(s);
      final buffer = allocate<Utf16>(count: 4096);   
      int e0 = mciSendString(sp, buffer,4096,0);
      String sr = fromUtf16(buffer,4096);
      int r = int.parse(sr);
      free(buffer);  
      free(sp);
      return r;
  }
  Future<void> play(String s) async {
    if ( UniversalPlatform.isWindows) {
      if (false) {
          // note: PlaySound only words with wav, not mp3
         //PlaySound(Utf16.toUtf16(s), 0, SND_FILENAME );
         mciSend("close fubar");
         mciSend("open $s type mpegvideo alias fubar");
         int length = mciSendGetInt("status fubar length");
         mciSend("play fubar");
         //await Future.delayed(Duration(milliseconds: length+1000));
         print("length: $length");
      }
      else {
        // final result = await audioPlayer.getDevices();
        // print("$result");
        // audioPlayer.setDevice(deviceIndex: 3);
        // audioPlayer.load(s);
        // audioPlayer.play();
      }
    }
  }
}
