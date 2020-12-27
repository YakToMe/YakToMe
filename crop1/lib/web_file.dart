
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui show Codec;
import 'dart:ui' show Size, Locale, TextDirection, hashValues;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';



// on the web we need our own kind of file, might as well follow convention
// we want to import 

class File {
  io.File f;
  
  File(String s):f = io.File(s);
  
  String get path => f.path;
  
  Future<Uint8List> readAsBytes() async => f.readAsBytes();
  Future<void> writeAsBytes(Uint8List b) async => f.writeAsBytes(b, flush: true);
  Future<void> writeAsString(String s) async => f.writeAsString(s);
  Future<void> writeUrlAsBytes(String url) async {
    final u = await http.get(Uri.parse(url));
    await f.writeAsBytes(u.bodyBytes);
  }
  Future<bool> exists() => f.exists();
  Future<List<String>> readAsLines() => f.readAsLines();
  Future<String> readAsString() => f.readAsString();
}

class Directory{
  io.Directory f;
  Directory(String s):f=io.Directory(s);
    Future<bool> exists() => f.exists();
}
  



@immutable
class WebFileImage extends ImageProvider<WebFileImage> {
  final File file;
  final File alternate;
  final double scale;

  const WebFileImage(this.file, this.alternate, { this.scale = 1.0 });

  @override
  Future<WebFileImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<WebFileImage>(this);
  }

  @override
  ImageStreamCompleter load(WebFileImage key, DecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: key.file.path,
      informationCollector: () sync* {
        yield ErrorDescription('Path: ${file.path}');
      },
    );
  }

  Future<ui.Codec> _loadAsync(WebFileImage key, DecoderCallback decode) async {
    assert(key == this);

    var file = this.file;
    if (!(await file.exists()))
      file = alternate;
      
    final Uint8List bytes = await file.readAsBytes();

    if (bytes.lengthInBytes == 0) {
      // The file may become available later.
      PaintingBinding.instance!.imageCache!.evict(key);
      throw StateError('$file is empty and cannot be loaded as an image.');
    }

    return await decode(bytes);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is WebFileImage
        && other.file.path == file.path
        && other.scale == scale;
  }

  @override
  int get hashCode => hashValues(file.path, scale);

  @override
  String toString() => '${objectRuntimeType(this, 'FileImage')}("${file.path}", scale: $scale)';
}