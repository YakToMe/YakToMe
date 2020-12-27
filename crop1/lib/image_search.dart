import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'data.dart';
import 'crop_photo.dart';
import 'image_search_lib.dart';

// when user clicks a photo here, it will automatically (but virtually) crop to 800x600
// then it will set this photo into the data model and return to the home page.
// I need to change this to do a media query to determine hwo many photos to show.
// potentially override with a menu.

// searchpage - >
class SearchPage extends StatefulWidget {
  final int index;
  SearchPage(this.index);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    final data = Provider.of<Data>(context);
    final word = data.doc.words[widget.index];
    return DefaultTabController(
        length: 3,
        child: Scaffold(
            appBar: AppBar(
              title: Text('Pick ' + word),
              bottom: TabBar(
                tabs: [
                  Tab(text: "Pixabay"),
                  Tab(text: "Unsplash"),
                  Tab(text: "CC"),
                ],
              ),
            ),
            body: TabBarView(children: [
              ImageList(0, word),
              ImageList(1, word),
              ImageList(2, word),
            ])));
  }
}

class ImageList extends StatefulWidget {
  final int service;
  final String word;

  ImageList(this.service, this.word);

  _ImageListState createState() => _ImageListState();
}

class _ImageListState extends State<ImageList> {
  var _image = <ImageResult>[];
  var _loaded = false;

  @override
  void initState() {
    super.initState();
  }

  _load(Data data) async {
    final lst = await searchImage(widget.service, widget.word);

    setState(() {
      _image = lst;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<Data>(context);
    if (!_loaded) {
      _load(data);
    }
    return CustomScrollView(slivers: [
      SliverGrid(
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
          delegate:
              SliverChildBuilderDelegate((BuildContext context, int index) {
                Widget eb(BuildContext context, Object exception, StackTrace? stackTrace) => Icon(Icons.error);
            return new Container(
                child: Card(
                    child: GestureDetector(
                        onTap: () async {
                          // push a photo editing route
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      CropPage(_image[index])));
                        },
                        child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: 
                              Image.network(
                               _image[index].thumbnail,
                               errorBuilder: eb
                               ),
                               
                              
                              
                              ))),
                height: 96.0);
          }, childCount: _image.length))
    ]);
  }
}



class DbFindList {
  int wordIndex;
  DbFindList(this.wordIndex);
}
class YakSearch extends SearchDelegate<DbFindList> {
  //list holds the full word list

  @override
  List<Widget> buildActions(BuildContext context) {
    return [];
  }

  @override
  Widget buildLeading(BuildContext context) {
    String _t(String k) =>
        k; //AppLocalizations.of(context)?.translate(k) ?? "";
    return IconButton(
      tooltip: _t('Back'),
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        //Take control back to previous page
        this.close(context, DbFindList(-1));
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Text("should not get here");
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final Iterable<String> suggestions =
        gData.doc.words.where((word) => word.startsWith(query));

    //calling wordsuggestion list
    return _WordSuggestionList(
        query: this.query,
        suggestions: suggestions.toList(),
        onSelected: (String suggestion) {
          this.query = suggestion;
          //showResults(context);
          int index = gData.doc.words.indexOf(suggestion);
          this.close(context, DbFindList(index));
        });
  }
}
class _WordSuggestionList extends StatelessWidget {
  final List<String> suggestions;
  final String query;
  final ValueChanged<String> onSelected;
  
  const _WordSuggestionList({required this.suggestions,required  this.query,required  this.onSelected});
  
  @override
  Widget build(BuildContext context) {

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (BuildContext context, int i) {
        final String suggestion = suggestions[i];
        return ListTile(
          leading: query.isEmpty ? Icon(Icons.history) : Icon(null),
          // Highlight the substring that matched the query.
          title: RichText(
            text: TextSpan(
              text: suggestion.substring(0, query.length),
              
              children: <TextSpan>[
                TextSpan(
                  text: suggestion.substring(query.length),
                  
                ),
              ],
            ),
          ),
          onTap: () {
            onSelected(suggestion);
          },
        );
      },
    );
  }
}