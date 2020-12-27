import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data.dart';
import 'image_search.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'learnpage.dart';
import 'web_file.dart';

// deck editor should be wrapped in a deck provider and listen to it?
class DeckEditor extends StatefulWidget {
  DeckEditorState createState() => DeckEditorState();
}

class DeckEditorState extends State<DeckEditor> {
  final _scroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    void scrollTo(int wordIndex) {
      _scroll.jumpTo(wordIndex * 150.0);
    }

    return Scaffold(
        appBar: AppBar(
            title: SearchWidget((int i) {
              scrollTo(i);
            }),
        ),
        body: WordList(controller: _scroll));
  }
}
//

class DetailScreen extends StatelessWidget {
  final int index;
  DetailScreen(this.index);
  @override
  Widget build(BuildContext context) {
    final data = Provider.of<Data>(context);

    return Scaffold(
        appBar: AppBar(title: Text(data.words[index])),
        body: Text(data.words[index]));
  }
}

class SearchWidget extends StatelessWidget {
  final void Function(int) jumpTo;
  SearchWidget(this.jumpTo);

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<Data>(context);
    return TextField(
        onTap: () async {
          YakSearch search = YakSearch();
          final w = await showSearch(context: context, delegate: search);
          jumpTo(w == null ? 0 : w.wordIndex);
        },
        decoration: InputDecoration(
          hintText: "Search ${data.doc.name}",
          prefixIcon: Icon(Icons.search),
          suffixIcon: Icon(Icons.mic),
          hintStyle: TextStyle(color: Colors.grey),
        ));
  }
}


// a Grid of cards, one for each word
// we should set the width in cards according to mediaquery
class WordList extends StatelessWidget {
  final ScrollController controller;
  const WordList({required this.controller});

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<Data>(context);

    // creates the label for the thumb scroller
    Text labelText(offset) {
      final int currentItem = controller.hasClients
          ? (controller.offset /
                  controller.position.maxScrollExtent *
                  data.words.length)
              .floor()
          : 0;
      return Text(currentItem > data.words.length
          ? data.words.last
          : data.words[currentItem]);
    }

    // creates the grid from WordCards. Why do these overflow?
    final gv = GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
      ),
      controller: controller,
      itemCount: data.words.length,
      itemBuilder: (context, index) {
        return WordCard(index);
      },
    );

    return DraggableScrollbar.semicircle(
        alwaysVisibleScrollThumb: true,
        labelTextBuilder: labelText,
        controller: controller,
        child: gv);
  }
}

class WordCard extends StatelessWidget {
  final int index;

  WordCard(this.index);

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<Data>(context);
    final w = data.doc.words[index];

    // here's where we get the image from a word.
    final imgxx = data.doc.image(w);
    return Container(
        child: Card(
            child: Column(children: [
      GestureDetector(
          onTap: () {
            bool? is_evict = imageCache?.evict(imgxx, includeLive: true);
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return SearchPage(index);
            }));
          },
          child: Image(image: imgxx, fit: BoxFit.cover)),
      WordTile(index)
    ])));
  }
}

// the caption area of the Word card.
// click the photo to replace
// menu: change translation, 
class WordTile extends StatelessWidget {
  final int index;
  WordTile(this.index);

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<Data>(context);
    
    void playGame() {

       Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return TeacherGame(data.doc.getScript(index));
                    }));
       }
    
    final w = data.words[index];
    List<Widget> tr = data.doc.lang.map((x) {
      final wt = data.doc.translate(x, w);
      return InkWell(child: Text(wt), onTap: playGame);
    }).toList();
    return ListTile(title: Wrap(spacing: 8, children: tr));
  }
}
