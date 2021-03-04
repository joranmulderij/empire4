import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget{
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  bool darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Empire 4 Web',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        primaryColor: Colors.deepPurple
      ),
      darkTheme: ThemeData(
        /*primarySwatch: Colors.deepPurple,
        primaryColor: Colors.black,
        brightness: Brightness.dark,
        accentColor: Colors.deepPurple,*/
        brightness: Brightness.dark,
        accentColor: Colors.deepPurple,
      ),
      themeMode: darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      home: MainScreen(toggleDarkMode: toggleDarkMode,),
    );
  }

  void toggleDarkMode(){
    setState(() {
      FirebaseAnalytics().logEvent(name: 'toggle_dark_mode');
      darkModeEnabled = !darkModeEnabled;
    });
  }
}

class MainScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController gameCodeController = TextEditingController();
  final toggleDarkMode;

  MainScreen({this.toggleDarkMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Image.asset('web/faviconwhite.png'), onPressed: (){
          showAboutDialog(
            context: context,
            applicationIcon: Image.asset(MediaQuery.of(context).platformBrightness == Brightness.dark ? 'web/favicon.png' : 'web/faviconwhite.png', height: 48, width: 48,),
            applicationName: 'Empire 4 Web',
            applicationVersion: '1.2.1',
            applicationLegalese: 'Play the group game Empire online.',
          );
        },),
        title: Text('Empire 4 Web'),
        actions: [
          /*IconButton(
            icon: Icon(Icons.settings_brightness),
            onPressed: toggleDarkMode,
          ),*/
          Container(
            padding: EdgeInsets.all(10),
            child: OutlineButton(
              child: Text('Host a Game'),
              textColor: Colors.white,
              onPressed: (){
                FirebaseAnalytics().logEvent(name: 'clicked_host');
                Navigator.push(context, MaterialPageRoute(
                    builder: (BuildContext context) => HostScreen()
                ));
              },
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (BuildContext context) => Row(
          children: [
            Spacer(),
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Name',
                    ),
                    controller: nameController,
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Nickname',
                    ),
                    controller: nicknameController,
                  ),
                  TextField(
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    decoration: InputDecoration(
                      labelText: 'Game Pin',
                    ),
                    controller: gameCodeController,
                  ),
                  Container(height: 6,),
                  RaisedButton(
                    child: Text('Add'),
                    color: Colors.deepPurple,
                    textColor: Colors.white,
                    onPressed: (){
                      FirebaseAnalytics().logEvent(name: 'clicked_add');
                      if(nameController.text.length < 3){
                        FirebaseAnalytics().logEvent(name: 'name_short');
                        Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text('Field "Name" is too short!'),
                          backgroundColor: Colors.deepPurple,
                          margin: EdgeInsets.fromLTRB(20, 20, 20, 20),
                          behavior: SnackBarBehavior.floating,
                        ));
                        return;
                      } else if(nicknameController.text.length < 3){
                        FirebaseAnalytics().logEvent(name: 'Nickname_short');
                        Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text('Field "Nickname" is too short!'),
                          backgroundColor: Colors.deepPurple,
                          margin: EdgeInsets.fromLTRB(20, 20, 20, 20),
                          behavior: SnackBarBehavior.floating,
                        ));
                        return;
                      } else if(gameCodeController.text.length < 5){
                        FirebaseAnalytics().logEvent(name: 'game_pin_short');
                        Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text('Field "Game Pin" is too short!'),
                          backgroundColor: Colors.deepPurple,
                          margin: EdgeInsets.fromLTRB(20, 20, 20, 20),
                          behavior: SnackBarBehavior.floating,
                        ));
                        return;
                      } else if(!gameCodeController.text.contains(RegExp('^[0-9]+\$'))){
                        FirebaseAnalytics().logEvent(name: 'game_pin_only_numbers');
                        Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text('Your Game Pin can include only numbers.'),
                          backgroundColor: Colors.deepPurple,
                          margin: EdgeInsets.fromLTRB(20, 20, 20, 20),
                          behavior: SnackBarBehavior.floating,
                        ));
                        return;
                      }
                      print(nameController.text);
                      print(nicknameController.text);
                      print(gameCodeController.text);

                      FirebaseFirestore.instance.doc('games/${gameCodeController.text}').update({
                        nameController.text : nicknameController.text
                      }).then((value){
                        nameController.clear();
                        nicknameController.clear();
                        FirebaseAnalytics().logEvent(name: 'add_success');
                        Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text('Your name has been successfully added.'),
                          backgroundColor: Colors.deepPurple,
                          margin: EdgeInsets.fromLTRB(20, 20, 20, 20),
                          behavior: SnackBarBehavior.floating,
                        ));
                      }).catchError((error){
                        print(error.runtimeType);
                        FirebaseAnalytics().logEvent(name: 'add_error', parameters: {'error': error.toString(), 'type': error.runtimeType.toString()});
                        Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text('We could not find a game with this pin!'),
                          backgroundColor: Colors.deepPurple,
                          margin: EdgeInsets.fromLTRB(20, 20, 20, 20),
                          behavior: SnackBarBehavior.floating,
                        ));
                      }).timeout(Duration(seconds: 5), onTimeout: (){
                        FirebaseAnalytics().logEvent(name: 'timeout_error');
                        Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text('An unexpected error occurred. Please try again later.'),
                          backgroundColor: Colors.deepPurple,
                          margin: EdgeInsets.fromLTRB(20, 20, 20, 20),
                          behavior: SnackBarBehavior.floating,
                        ));
                      });
                    },
                  ),
                ],
              ),
            ),
            Spacer(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: toggleDarkMode,
        child: Icon(Icons.settings_brightness),
      ),
    );
  }
}

class HostScreen extends StatelessWidget {
  final TextEditingController gameController = TextEditingController();

  final Random random = Random();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Empire 4 Host'),
      ),
      body: Center(
        child: Row(
          children: [
            Spacer(),
            Expanded(
              flex: 5,
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Game Name',
                ),
                onSubmitted: (String name) async {
                  FirebaseAnalytics().logEvent(name: 'started_game', parameters: {'name': name});
                  int id = random.nextInt(90000) + 10000;
                  await FirebaseFirestore.instance.collection('games').firestore.doc('games/$id').set({'name' : name});
                  Navigator.pushReplacement(context, MaterialPageRoute(
                      builder: (BuildContext context) => ParticipantsScreen(id: id, name: name,)
                  ));
                },
                controller: gameController,
              ),
            ),
            Spacer(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text('Start Game'),
        onPressed: () async {
          FirebaseAnalytics().logEvent(name: 'start_game_clicked', parameters: {'name': gameController.text});
          FirebaseAnalytics().logEvent(name: 'started_game', parameters: {'name': gameController.text});
          int id = random.nextInt(99999);
          await FirebaseFirestore.instance.collection('games').firestore.doc('games/$id').set({'name' : gameController.text});
          Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (BuildContext context) => ParticipantsScreen(id: id, name: gameController.text,)
          ));
        }
      ),
    );
  }
}


class ParticipantsScreen extends StatelessWidget {
  final int id;
  final String name;

  ParticipantsScreen({this.id, this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Pin: $id'),
      ),
      body: WillPopScope(
        onWillPop: () async {
          FirebaseAnalytics().logEvent(name: 'exit_back');
          FirebaseFirestore.instance.collection('games').doc(id.toString()).delete();
          return true;
        },
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('games').doc('$id').snapshots(),
          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot){
            if(!snapshot.hasData){
              return Center(child: CircularProgressIndicator(),);
            }
            return ListView(
              children: (snapshot.data.data() != null) ? (snapshot.data.data().keys.where((element) => element != 'name').map((name) => ListTile(
                leading: CircleAvatar(child: Text(name.substring(0, 1).toUpperCase(), style: TextStyle(fontSize: 24),),),
                title: Text(name),
              )).toList()..insert(0, ListTile(title: MaterialBanner(
                content: Text('People can now join with game pin $id. When everyone has joined, click "Continue".'),
                actions: [Container()],
              ),))) : [],
            );
          },
        ),
      ),
        floatingActionButton: FloatingActionButton.extended(
          label: Text('Continue'),
          onPressed: () async {
            FirebaseAnalytics().logEvent(name: 'clicked_continue');
            DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance.doc('games/$id').get();
            Map data = documentSnapshot.data();
            FirebaseFirestore.instance.doc('games/$id').delete();
            Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (BuildContext context) => NicknameScreen(data: data,)
            ));
          },
        )
    );
  }
}

class NicknameScreen extends StatefulWidget {
  final Map data;
  NicknameScreen({this.data});

  @override
  NicknameScreenState createState() => NicknameScreenState(data: data);
}

class NicknameScreenState extends State<NicknameScreen> {
  final Map data;
  final FlutterTts flutterTts = FlutterTts();
  String currentName = '';
  double opacity = 0;
  String name;
  int playRepeat = 0;

  NicknameScreenState({this.data}){
    name = data['name'];
    data.remove('name');
    nicknames = shuffle(data.values.toList());
    nicknames.add('');
  }
  List nicknames;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Click "Read Out". "$name"'),
        actions: [
          FlatButton(
            child: Text('Set Language'),
            textColor: Colors.white,
            onPressed: () async {
              FirebaseAnalytics().logEvent(name: 'set_language_button');
              List languages = await flutterTts.getLanguages;
              showDialog(context: context, builder: (context) => SimpleDialog(
                children: languages.map((e) => ListTile(
                  title: Text(e),
                  onTap: (){
                    FirebaseAnalytics().logEvent(name: 'set_language', parameters: {'lan': e});
                    flutterTts.setLanguage(e);
                    Navigator.pop(context);
                  },
                )).toList(),
              ));
            },
          ),
        ],
      ),
      body: Center(
        child: AnimatedOpacity(
          duration: Duration(milliseconds: 500),
          opacity: opacity,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 500),
            width: currentName.length.toDouble() * 20 + 30,
            child: FloatingActionButton.extended(
              label: Text(currentName, style: TextStyle(fontSize: 24),),
              onPressed: null,
              heroTag: null,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text('Read Out'),
        onPressed: (){
          playRepeat++;
          FirebaseAnalytics().logEvent(name: 'play', parameters: {'repeat': playRepeat});
          setState(() {
            currentName = nicknames[0];
            opacity = 1;
          });
          flutterTts.speak(nicknames[0]);
          Stream.periodic(const Duration(seconds: 5), (v) => v).take(nicknames.length-1).listen((count){
            setState(() {
              currentName = nicknames[count+1];
            });
            flutterTts.speak(nicknames[count+1]).then((value) => print(value));
          }).asFuture().then((value) => opacity = 0);
        },
      ),
    );
  }
}

List shuffle(List items) {
  var random = new Random();
  for (var i = items.length - 1; i > 0; i--) {
    var n = random.nextInt(i + 1);
    var temp = items[i];
    items[i] = items[n];
    items[n] = temp;
  }
  return items;
}