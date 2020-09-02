import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        primaryColor: Colors.deepPurple
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController iconController = TextEditingController();
  final TextEditingController gameCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Empire 4'),
        actions: [
          FlatButton(
            child: Text('Host a Game'),
            textColor: Colors.white,
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(
                builder: (BuildContext context) => HostScreen()
              ));
            },
          ),
        ],
      ),
      body: Builder(
        builder: (BuildContext context) => Center(
          child: Container(
            height: 250,
            width: 400,
            child: Column(
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
                    labelText: 'Icon',
                  ),
                  controller: iconController,
                ),
                TextField(
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  decoration: InputDecoration(
                    labelText: 'Game Code',
                  ),
                  controller: gameCodeController,
                ),
                Container(height: 6,),
                RaisedButton(
                  child: Text('Add'),
                  color: Colors.deepPurple,
                  textColor: Colors.white,
                  onPressed: (){
                    if(nameController.text.length < 3){
                      Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text('Your Name is too short!'),
                        backgroundColor: Colors.deepPurple,
                      ));
                      return;
                    } else if(iconController.text.length < 3){
                      Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text('Your Icon is too short!'),
                        backgroundColor: Colors.deepPurple,
                      ));
                      return;
                    } else if(gameCodeController.text.length < 5){
                      Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text('Your Game Code is too short!'),
                        backgroundColor: Colors.deepPurple,
                      ));
                      return;
                    } else if('^[0-9]+\$'.contains(gameCodeController.text)){
                      Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text('Your Game Code can only include numbers.'),
                        backgroundColor: Colors.deepPurple,
                      ));
                      return;
                    }
                    print(nameController.text);
                    print(iconController.text);
                    print(gameCodeController.text);

                    FirebaseFirestore.instance.doc('games/${gameCodeController.text}').update({
                      nameController.text : iconController.text
                    });

                    nameController.clear();
                    iconController.clear();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HostScreen extends StatelessWidget {
  final TextEditingController gameController = TextEditingController();

  final FlutterTts flutterTts = FlutterTts();


  Random random = Random();

  String language = 'en-US';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Empire 4 Host'),
        actions: [
          FlatButton(
            child: Text('Language'),
            textColor: Colors.white,
            onPressed: () async {
              List languages = await flutterTts.getLanguages;
              showDialog(context: context, child: SimpleDialog(
                children: languages.map((e) => ListTile(
                  title: Text(e),
                  onTap: (){
                    language = e;
                    Navigator.pop(context);
                  },
                )).toList(),
              ));
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          height: 150,
          width: 400,
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Game Name',
            ),
            controller: gameController,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text('Start Game'),
        onPressed: () async {
          int id = random.nextInt(99999);
          await FirebaseFirestore.instance.collection('games').firestore.doc('games/$id').set({'name' : gameController.text});
          Navigator.push(context, MaterialPageRoute(
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
        title: Text('Wait for everyone to join game "$name":'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('games').doc('$id').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot){
          if(!snapshot.hasData){
            return Center(child: CircularProgressIndicator(),);
          }
          print(snapshot.data.id);
          return ListView(
            children: snapshot.data.data().keys.where((element) => element != 'name').map((name) => ListTile(
              leading: CircleAvatar(child: Text(name.substring(0, 1).toUpperCase(), style: TextStyle(fontSize: 24),),),
              title: Text(name),
            )).toList(),
            //children: [],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text('Continue'),
        onPressed: () async {
          DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance.doc('games/$id').get();
          Map data = documentSnapshot.data();
          FirebaseFirestore.instance.doc('games/$id').delete();
          Navigator.push(context, MaterialPageRoute(
            builder: (BuildContext context) => IconScreen(data: data,)
          ));
        },
      ),
    );
  }
}

class IconScreen extends StatefulWidget {
  final Map data;
  IconScreen({this.data});

  @override
  IconScreenState createState() => IconScreenState(data: data);
}

class IconScreenState extends State<IconScreen> {
  final Map data;
  final FlutterTts flutterTts = FlutterTts();
  String currentName = '';

  IconScreenState({this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
      ),
      body: Center(
        child: AnimatedOpacity(
          duration: Duration(seconds: 1),
          opacity: 1,
          child: FloatingActionButton.extended(
            label: Text(currentName, style: TextStyle(fontSize: 24),),
            onPressed: null,
            heroTag: null,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text('Read Out'),
        onPressed: (){
          setState(() {
            currentName = data.remove('name').values.toList()[0];
          });
        },
      ),
    );
  }
}

