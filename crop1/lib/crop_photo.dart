import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'data.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as dimg;
import 'dart:io'; // problem for web :(
import 'image_search_lib.dart';

class CropPage extends StatefulWidget {
  final ImageResult image;
  CropPage(this.image);

  @override
  CropPageState createState() => CropPageState();
}

class CropPageState extends State<CropPage> {
  //File _image;      //File file = File('c:\\yaktome\\assets\\image\\alligator.jpg');'
  final TransformationController controller = TransformationController();
  Uint8List bytes = Uint8List(0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _load() async {
    final u = await http.get(Uri.parse(widget.image.url));
    setState(() {
      bytes = u.bodyBytes;
    });
  }

  Future<void> finalCrop(Data data) async {
    final og = dimg.decodeImage(bytes);
    Matrix4 matrix = controller.value;
    double scale = 1 / matrix.entry(0, 0);
    final x = (-matrix.entry(0, 3) * scale).toInt();
    final y = (-matrix.entry(1, 3) * scale).toInt();
    print("$x,$y,$scale,${og.width},${og.height}");

    double width, height;
    if (og.width / og.height > 4 / 3) {
      height = og.height + 0.0;
      width = 4.0 * height / 3.0;
    } else {
      width = og.width + 0.0;
      height = 3.0 * width / 4.0;
    }

    width = width * scale;
    height = height * scale;

    // not right? if the picture is 4K, then we scale it up, 1/scale

    var croppedImage = dimg.copyCrop(og, x, y, width.toInt(), height.toInt());
    if (width > 1024.0) {
      croppedImage = dimg.copyResize(croppedImage, width: 1024, height: 768);
    }

    final rbytes =
        dimg.encodeJpg(croppedImage, quality: 50); // can this be webp?
    await data.doc.writePicture(widget.image.word,  Uint8List.fromList(rbytes));
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<Data>(context);
    if (bytes.isEmpty) return Scaffold(); 

    // I could use a media query here to pick a clip rect that fits on the screen?
    // is there an easier way to do it?
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: () {
              Navigator.pop(context);
            }),
        title: Text("Crop the picture then tap save"),
        actions: [
          IconButton(
              icon: const Icon(Icons.send),
              onPressed: () async {
                await finalCrop(data);
                Navigator.pop(context);
              })
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Container(
            child: bytes == null
                ? null
                : Center(
                    child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.red),
                      child: ClipRect(
                        child: Center(
                            child: InteractiveViewer(
                          transformationController: controller,
                          panEnabled: true,
                          constrained: false,
                          child: Image.memory(bytes),
                        )),
                      ),
                    ),
                  )),
          ),
        ],
      ),
    );
  }
}
