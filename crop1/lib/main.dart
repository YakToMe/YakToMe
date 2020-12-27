import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data.dart';
import 'learnpage.dart';
import 'package:flutter/services.dart';
import 'deck_editor.dart';


// start with a page that lets students tap on a picture of themselves, or maybe add themselves
// with the camera. Access teacher mode with pin.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIOverlays([]);
  
  // this load needs to recognize that we are skipping login & deck choice and go ahead and load
  // the defaults.
  await gData.load();
  runApp(ChangeNotifierProvider(
      create: (context) => gData,
      child: 
        MaterialApp(
          title: 'Yak to me',
          home: StartPage())));
}

class StartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // if there is more than one student or teacher account, then show the login page
    // otherwise go straight to choose deck page
    // but if there is only one deck, then go straight to the learning page.
    
    // loading the deck is async, so how can I start the game here?
    return StudentGame();
  }
}


// when the program first starts up this should be an introduction slide show.
// todo: 
class LoginPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
   final data = Provider.of<Data>(context);
   
    // should be some spash, audio announcement?
    
    // there is always a teacher mode, but students start empty.
    int i=-1;
    final students = data.profile.where((x)=>x.type=='student').map( (x) {
          i = i+1;
          return RaisedButton(child: Text(x.name),
          onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return StudentGame();
                    }));
                  });
    }).toList();   
    
    return  Center(child: Column(children: [          
          RaisedButton(child: Text("Teacher"),
          onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return TeacherHome();
                    }));
                  }),
          ...students           
        ]));
  }
}


class TeacherHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final menu = PopupMenuButton<String>(
            onSelected: (String x){},
            itemBuilder: (BuildContext context) {
              return {'Logout', 'Settings'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          );
          
    // create a student card or list tile for each deck.
    // it would be nice to group the students at the top, but probably all or most are students
    // keep a document index in the root of docs? that can also serve as our shared_preferences
    final students = gData.sortedDeck.map( (x) {
      return ListTile( title: Text(x.name), onTap: () { 
        Navigator.push(context, MaterialPageRoute( builder: (context) {
          gData.doc = x;
          return DeckEditor();
        }));
      });
    }).toList();
          
    return Scaffold(appBar: AppBar(
        title: const Text("Yak To Me"),
        actions: [
          menu
        ]),
        body: CustomScrollView(
          slivers: [
            SliverList(delegate: SliverChildListDelegate(students)

            ),
          ])
        ,floatingActionButton: FloatingActionButton(onPressed:(){},
          child: Icon(Icons.add)),
    );
  }
    
  
  
}

