
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

// these two are used, but are flagged as "legacy"
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as dimg;

import 'web_file.dart';
import 'data.dart';

/// Functions used by search_page to gather search results from various stock services.

class ImageResult {
  String word;
  String thumbnail;
  String url;
  String jsonCredits;
  ImageResult({required this.word, required this.thumbnail, required this.url,required this.jsonCredits});
}


  Future<List<ImageResult>> searchImage(int service, String word) async {
    switch (service) {
      case 1:
        return getUnsplash(word);
      case 2:
        return getCc(word);
      case 0:
      default:
        return getPixabayList(word);
    }
  }


Future<void> autoCropFile(File f) async {
  final b = await f.readAsBytes();
  final og = dimg.decodeImage(b);
  double x = 0;
  double y = 0;

  double width, height;
  if (og.width / og.height > 4 / 3) {
    height = og.height + 0.0;
    width = 4.0 * height / 3.0;
    x = (og.width - width) / 2.0;
  } else {
    width = og.width + 0.0;
    height = 3.0 * width / 4.0;
    y = (og.height - height) / 2.0;
  }

  var croppedImage =
      dimg.copyCrop(og, x.toInt(), y.toInt(), width.toInt(), height.toInt());
  if (width > 1024.0) {
    croppedImage = dimg.copyResize(croppedImage, width: 1024, height: 768);
  }
  final rbytes = dimg.encodeJpg(croppedImage, quality: 50); // can this be webp?
  await f.writeAsBytes(Uint8List.fromList(rbytes));
}

  
  // fetch url, crop to 1024x768, save it to a file
  Future<void> getCropped(String url, File fileSave) async {
    final u = await http.get(Uri.parse(url));
    await fileSave.writeAsBytes(u.bodyBytes);
    await autoCropFile(fileSave);
  }

  
  
  
Future<Map> getPixabay(String q) async {
  final String url =
      'https://pixabay.com/api/?key=19200042-de3d94b67d65264e46dd4d317&q=$q&image_type=photo&safesearch=true&per_page=100&lang=en&page=1&min_width=1024&min_height=768';
  http.Response response = await http.get(url);
  return json.decode(response.body);
}

Future<List<ImageResult>> getPixabayList(String word) async {
  final r = <ImageResult>[];
  final m = await getPixabay(word);
  final h = m['hits'];
  for (var hx in h) {
    r.add(ImageResult(
        word: word,
        thumbnail: hx['previewURL'],
        url: hx['largeImageURL'], // imageUrl with full access?
        jsonCredits: json.encode(hx)));
  }
  return r;
}

Future<List<ImageResult>> getCc(String word) async {
  final String url =
      'https://api.creativecommons.engineering/v1/images?q=$word&mature=false&license=cc0,by';
  http.Response response = await http.get(url);
  final mx = await json.decode(response.body);
  final r = <ImageResult>[];
  final h = mx['results'];
  for (var hx in h) {
    r.add(ImageResult(
        word: word,
        thumbnail: hx['thumbnail'],
        url: hx['url'], // imageUrl with full access?
        jsonCredits: json.encode(hx)));
  }
  return r;
}

Future<List<ImageResult>> getUnsplash(String word) async {
  final accessKey = 'K5ldpQf_sARSmzoc9poK2qxFt5fX9SeuzQs2meTIEPU';
  //final secretKey = 'wlOlB24NjX2xNfCdFviZ80vBhjAqGoVETL71kkvXXto';
  final String url =
      'https://api.unsplash.com/search/photos?client_id=$accessKey&query=$word';
  http.Response response = await http.get(url);
  final r = <ImageResult>[];
  final mx = await json.decode(response.body);
  // some how m is already just a list
  // it has urls in it. raw, full, regular, small, thumb
  final m = mx["results"];
  for (var hx in m) {
    final urls = hx['urls'];
    r.add(ImageResult(
        word: word,
        thumbnail: urls['thumb'],
        url: urls['full'], // imageUrl with full access?
        jsonCredits: json.encode(hx)));
  }
  return r;
}

