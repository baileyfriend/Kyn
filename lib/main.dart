import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:kyn/picpage.dart';
import 'dart:convert';

import 'package:kyn/widgets.dart';
import 'package:kyn/hubpage.dart';
import 'package:kyn/platform_adaptive.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class User {

  String uid;
  String email;
  String displayName;


  User() {
//String uid, String email, String displayName) {
//    this.uid = uid;
//    this.email = email;
//    this.displayName = displayName;
  }

  void setUid(String uid) {
    this.uid = uid;
    print('Set uid to $uid \n\n\n');
  }

  void setEmail(String email) {
    this.email = email;
    print('Set email to $email \n\n\n');
  }

  void setDisplayName(String displayName) {
    this.displayName = displayName;
    print('Set displayName to $displayName \n\n\n');
  }


}


class Session {

  String headOfHouseholdEmail;
  String currentUid;

  Session() {
    headOfHouseholdEmail = '';

  }

  void setHeadOfHouseholdEmail(String email) {
    this.headOfHouseholdEmail = email;
    print('The head of household email was set to ' + this.headOfHouseholdEmail);
  }

  String getHeadOfHouseholdEmail() {
    return this.headOfHouseholdEmail.toLowerCase();
  }


  Future<String> getHeadOfHouseholdEmailFromFirestore() async {
    //final FirebaseUser currentUser = await _auth.currentUser();
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    print('getting hoh from firestore.. for user with email');
    print(user);
    DocumentSnapshot snapshot =
    await Firestore.instance.collection('Users')
        .document(user.email)
        .get();
    try {
      var headOfHouseholdEmail = snapshot['headOfHouseholdEmail']; // seems like error happens here. Why?
      if (headOfHouseholdEmail is String) {
        print('The head of household email is : ' + headOfHouseholdEmail);
        this.setHeadOfHouseholdEmail(headOfHouseholdEmail);
        print('success! Got hoh from firebase.');
        return headOfHouseholdEmail;
      } else {
        return '';
      }
    } catch(error) {
      print('got error while trying to get hoh email...');
      print(error);
      return '';
      }
    }
}

User me = new User();
Session session = new Session();
FirebaseUser theUser;
String headOfHouseholdEmail;


// iOS Default Theme
final ThemeData kIOSTheme = new ThemeData(
  primarySwatch: Colors.green,
  primaryColor: Colors.grey[100],
  primaryColorBrightness: Brightness.light,
);
// Android Default Theme
final ThemeData kDefaultTheme = new ThemeData(
  primarySwatch: Colors.deepPurple,
  accentColor: Colors.lightBlueAccent[100],
);

// Create Firebase & Google account objects
final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = new GoogleSignIn();


// Main
void main() => runApp(new MyApp());


// This widget is the root of your application.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'Kyn',
        theme: defaultTargetPlatform == TargetPlatform.iOS
            ? kIOSTheme
            : kDefaultTheme,
        home: new MyHomePage(title: 'Kyn Home'),
        routes: <String, WidgetBuilder>{
//        "/": (BuildContext context) => new MyHomePage(),
          "/LoggedInPage": (BuildContext context) => new LoggedInPage(),
          "/CalendarPage": (BuildContext context) => new CalendarPage(),
          "/QuestionsPage": (BuildContext context) => new QuestionsPage(),
          "/RulesPage": (BuildContext context) => new RulesPage(),
          "/PicturesPage": (BuildContext context) => new PicturesPage(),
          "/FamilyPage": (BuildContext context) => new FamilyPage(),
          "/ResourcesPage": (BuildContext context) => new ResourcesPage(),
          "/HubPage": (BuildContext context) => new HubPage(),
          "/Family/HeadOfHouseholdPage": (
              BuildContext context) => new HeadOfHouseholdPage(),
        }
    );
  }
}


class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GoogleSignInAccount _currentUser;

//  @override
//  void initState() {
//    super.initState();
//    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
//      setState(() {
//        _currentUser = account;
//        //session.currentUid = account.id;
//      });
//    });
//    _googleSignIn.signInSilently();
////    setUserDataOnSilent();
//  }

  @override
  @protected
  @mustCallSuper
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
      });
    });
    _googleSignIn.signInSilently()
        .then((account) {
      _currentUser = account;
//      session.currentUid = account.id;
      //print('the current user is: ' + _currentUser.toString());
    });

    session.getHeadOfHouseholdEmailFromFirestore();
    print('the head of household email is ' + session.getHeadOfHouseholdEmail());
  }

  Future<Null> _handleSignIn() async {
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication;
      final FirebaseUser user = await _auth.signInWithGoogle(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      theUser = user;
// Assures user information has been obtained
      assert(user.email != null);
      assert(user.displayName != null);
      assert(!user.isAnonymous);
      assert(await user.getIdToken() != null);

      final FirebaseUser currentUser = await _auth.currentUser();
      assert(user.uid == currentUser.uid);

      var userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName
      };


      me.setUid(user.uid);
      me.setEmail(user.email);
      me.setDisplayName(user.displayName);
      print(me.toString());

      var gotUser = await Firestore.instance.collection('Users')
          .document(user.email).get();
      print('the user info was: ');
      print(gotUser);

      try{
        var email = gotUser['email'];
        print('The user wasnt null\n\n');
        Firestore.instance.collection('Users')
            .document(email)
            .updateData(userData);
      } catch(e) {
        print('the user was null\n\n');
        Firestore.instance.collection('Users')
            .document(user.email)
            .setData(userData);
      }


      print('put data into cloud firestore');
    } catch (error) {
      print(error.toString());
    }
  }

// Google & Firebase Sign-out
  Future<Null> _handleSignOut() async {
    try {
      FirebaseAuth.instance.signOut();
      _googleSignIn.disconnect();
    } catch (error) {
      print(error);
    }
  }


  Future<Null> _switchLoggedInPage() async {
    session.getHeadOfHouseholdEmailFromFirestore();
    print('Hoh is : ' );
    print(session.getHeadOfHouseholdEmail());
    if (_currentUser != null) {
      if (session.getHeadOfHouseholdEmail() == '') { // if session doesn't have a head of household email yet
        //String headOfHouseholdEmail = await getHeadOfHousehold();
        //session.setHeadOfHouseholdEmail(headOfHouseholdEmail);
        //if (headOfHouseholdEmail == '') {
          Navigator.of(context).pushNamed("/FamilyPage");
        } else {
          Navigator.of(context).pushNamed("/LoggedInPage");
        }
      } else {
        Navigator.of(context).pushNamed("/LoggedInPage");
      }
    }


  Future<String> getHeadOfHousehold() async {
    DocumentSnapshot snapshot =
    await Firestore.instance.collection('Users')
        .document(me.email)
        .get();
    var headOfHouseholdEmail = snapshot['headOfHouseholdEmail'];
    if (headOfHouseholdEmail is String) {
      print('The head of household email is : ' + headOfHouseholdEmail);
      return headOfHouseholdEmail;
    } else {
      return '';
    }
  }

  Widget _buildBody() {
    if (_currentUser != null) {
      return new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Container(
            color: Colors.deepPurple,
            child:
            new Text(
                'Kyn.',
//                style: Theme.of(context).textTheme.display1,
                style: new TextStyle(fontFamily: "Source Serif Pro",
                    fontSize: 100.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)
            ),
          ),
          new Container(
            color: Colors.deepPurple,
            child: new Column(
              children: <Widget>[
                new Text("Welcome, " + _currentUser.displayName,
                    style: new TextStyle(fontFamily: "Source Serif Pro",
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
//                new ListTile(
//                  leading: new GoogleUserCircleAvatar(
//                    identity: _currentUser,
//                  ),
//                  title: new Text("Welcome, " +_currentUser.displayName),
//                  subtitle: new Text(_currentUser.email),
//                ),
                new IconButton(
                    icon: new Icon(Icons.vpn_key, color: Colors.white),
                    iconSize: 40.0,
                    onPressed: _switchLoggedInPage),

                new FlatButton(
                  child: new Text('Not you? Sign out.', style: new TextStyle(
                      color: Colors.white, fontSize: 12.0)),
                  onPressed: _handleSignOut,
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Container(
            color: Colors.deepPurple,
            child:
            new Text(
                'Kyn.',
//                style: Theme.of(context).textTheme.display1,
                style: new TextStyle(fontFamily: "Source Serif Pro",
                    fontSize: 100.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)
            ),
          ),
          new Container(
            child:
            new RaisedButton(
              child: new GoogleSignInWidget(),
//padding: new EdgeInsets.all(0.0),
              color: Colors.transparent,
              onPressed: _handleSignIn,
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(

      body: new Container(
        color: Colors.deepPurple,
        child: new Center(
          child: _buildBody(),
        ),
      ),
    );
  }
}

class LoggedInPage extends StatefulWidget {
  @override
  _LoggedInPageState createState() => new _LoggedInPageState();
}

class _LoggedInPageState extends State<LoggedInPage> {
  GoogleSignInAccount _currentUser;

  @override
  void initState() {
    super.initState();
    setState(() {
      _currentUser = _googleSignIn.currentUser;
    });
    _googleSignIn.signInSilently();
  }

  Future<Null> _switchQuestionsPage() async {
    if (_currentUser != null) {
      Navigator.of(context).pushNamed("/QuestionsPage");
    }
  }

  Future<Null> _switchRulesPage() async {
    if (_currentUser != null) {
      Navigator.of(context).pushNamed("/RulesPage");
    }
  }

  Future<Null> _switchPicturesPage() async {
    if (_currentUser != null) {
      Navigator.of(context).pushNamed("/PicturesPage");
    }
  }

  Future<Null> _switchResourcesPage() async {
    if (_currentUser != null) {
      Navigator.of(context).pushNamed("/ResourcesPage");
    }
  }

  Future<Null> _switchFamilyPage() async {
    if (_currentUser != null) {
      Navigator.of(context).pushNamed("/FamilyPage");
    }
  }

  Future<Null> _switchHubPage() async {
    if (_currentUser != null) {
      Navigator.of(context).pushNamed("/HubPage");
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Hi, " + _currentUser.displayName + "!"),
        backgroundColor: Colors.deepPurple,),
      body: new Container(
          color: Colors.white,
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  new Column(
                    children: <Widget>[
                      new IconButton(icon: new Icon(
                          Icons.chat_bubble, color: Colors.deepPurple),
                          iconSize: 40.0,
                          onPressed: _switchHubPage),
                      new Text("The Hub", style: new TextStyle(
                          fontFamily: "Source Serif Pro",
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple))
                    ],
                  ),
                  new Column(
                    children: <Widget>[
                      new IconButton(
                          icon: new Icon(Icons.help, color: Colors.deepPurple),
                          iconSize: 40.0,
                          onPressed: _switchQuestionsPage),
                      new Text("Questions", style: new TextStyle(
                          fontFamily: "Source Serif Pro",
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple))
                    ],
                  ),
                ],
              ),
              new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  new Column(
                    children: <Widget>[
                      new IconButton(icon: new Icon(
                          Icons.business_center, color: Colors.deepPurple),
                          iconSize: 40.0,
                          onPressed: _switchRulesPage),
                      new Text("Rules", style: new TextStyle(
                          fontFamily: "Source Serif Pro",
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple))
                    ],
                  ),
                  new Column(
                    children: <Widget>[
                      new Text(
                          'Kyn.',
//                style: Theme.of(context).textTheme.display1,
                          style: new TextStyle(fontFamily: "Source Serif Pro", fontSize: 60.0, fontWeight: FontWeight.bold, color: Colors.deepPurple)
                      ),
                    ],
                  ),
                  new Column(
                    children: <Widget>[
                      new IconButton(
                          icon: new Icon(Icons.photo, color: Colors.deepPurple),
                          iconSize: 40.0,
                          onPressed: _switchPicturesPage),
                      new Text("Pictures", style: new TextStyle(
                          fontFamily: "Source Serif Pro",
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple))
                    ],
                  ),
                ],
              ),
              new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  new Column(
                    children: <Widget>[
                      new IconButton(icon: new Icon(
                          Icons.people, color: Colors.deepPurple),
                          iconSize: 40.0,
                          onPressed: _switchFamilyPage),
                      new Text("Family", style: new TextStyle(
                          fontFamily: "Source Serif Pro",
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple))
                    ],
                  ),
                  new Column(
                    children: <Widget>[
                      new IconButton(
                          icon: new Icon(Icons.phone, color: Colors.deepPurple),
                          iconSize: 40.0,
                          onPressed: _switchResourcesPage),
                      new Text("Resources", style: new TextStyle(
                          fontFamily: "Source Serif Pro",
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple))
                    ],
                  ),
                ],
              ),
            ],
          )
      ),
    );
  }
}

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => new _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  @override
  Widget build(BuildContext context) {
// TODO: implement build
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Calendar"),
      ),
    );
  }
}

class QuestionsPage extends StatefulWidget {
  @override
  _QuestionsPageState createState() => new _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage>{

  @override
  void initState() {
    super.initState();
    session.getHeadOfHouseholdEmail(); // make sure to get the head of household email
    print('the head of household email is ' + session.getHeadOfHouseholdEmail());
  }

  @override
  Widget build(BuildContext context) {

    final TextEditingController _questionController = new TextEditingController();

    final TextEditingController _answerController = new TextEditingController();

    var question;

    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Questions"),
        ),
        body: new StreamBuilder<QuerySnapshot>(
            stream:
            Firestore.instance.collection('Family')
                .document(session.getHeadOfHouseholdEmail())
                .getCollection("Questions").snapshots,

            builder: (context, snapshot) {
              if (!snapshot.hasData) return new Text("Loading...");
              return new ListView(
                children: snapshot.data.documents.map((document) {
                  return new ListTile(
                    onTap: () async {
                      setState(() {
                        question = document['question'];
                      });
                      await showDialog<Null>(
                          context: context,
                          builder: (BuildContext context) {
                            return new SimpleDialog(
                              title: const Text('Answer the Question'),
                              children: <Widget>[
                                new TextField(
                                    controller: _answerController,
                                    decoration: new InputDecoration(
                                        hintText: "Enter the answer"
                                    )
                                ),
                                new IconButton(icon: new Icon(
                                    Icons.done, color: Colors.deepPurple),
                                    iconSize: 60.0,
                                    onPressed: () async {
                                      try {
                                        print("Trying...");
                                        print('user entered text: ');
                                        print(_answerController.text);


                                        var data =
                                        {
                                          'answer': _answerController.text
                                        };

                                        print("email:" +session.getHeadOfHouseholdEmail());


                                        Firestore.instance.collection('Family')
                                            .document(session.getHeadOfHouseholdEmail())
                                            .getCollection("Questions")
                                            .document(question)
                                            .updateData(data);
                                      } catch (e) {
                                        print("Failed");
                                        print(e);
                                      }
                                      Navigator.pop(context);
                                    }
                                ),

                              ],
                            );
                          }

                      );
                    },
                    title: new Text(document['question']),
                    subtitle: new Text(document['answer']),
                  );
                }).toList(),

              );
            }
        ),
        floatingActionButton: new FloatingActionButton(
            backgroundColor: Colors.deepPurple,
            tooltip: 'Add', // used by assistive technologies
            child: new Icon(Icons.add),
            onPressed: () async {
              await showDialog<Null>(
                  context: context,
                  builder: (BuildContext context) {
                    return new SimpleDialog(
                      title: const Text('Add a new Question'),
                      children: <Widget>[
                        new TextField(
                            controller: _questionController,
                            decoration: new InputDecoration(
                                hintText: "Enter new question"
                            )
                        ),
                        new IconButton(icon: new Icon(
                            Icons.done, color: Colors.deepPurple),
                            iconSize: 60.0,
                            onPressed: () async {
                              try {
                                print("Trying...");
                                print('user entered text: ');
                                print(_questionController.text);

//                                var rules = new List();
//                                rules.add(await getRules());
//                                rules.add(_ruleController.text);

                                var data =
                                {
                                  'question': _questionController.text,
                                  'answer': '' // must instantiate to something
                                };

                                print("email:" +session.getHeadOfHouseholdEmail());


                                Firestore.instance.collection('Family')
                                    .document(session.getHeadOfHouseholdEmail())
                                    .getCollection("Questions")
                                    .document(_questionController.text)
                                    .setData(data);
                              } catch (e) {
                                print("Failed");
                                print(e);
                              }
                              Navigator.pop(context);
                            }
                        ),

                      ],
                    );
                  }

              );
            }
        )
    );
  }
}


class RulesPage extends StatefulWidget {

  _RulesPageState createState() => new _RulesPageState();


}

class _RulesPageState extends State<RulesPage> {

  GoogleSignInAccount _currentUser;

  @override
  @protected
  @mustCallSuper
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
//        session.currentUid = account.id;
        print('GOT THE EMAIL: ' + _currentUser.email);
      });
    });
    _googleSignIn.signInSilently()
        .then((account) {
      _currentUser = account;
//      session.currentUid = account.id;
      print('the current user is: ' + _currentUser.toString());
    });

    session.getHeadOfHouseholdEmailFromFirestore();
    print('the head of household email is ' + session.getHeadOfHouseholdEmail());
  }

  Future<List> getRules() async {
    print('getting rules');

    session.getHeadOfHouseholdEmailFromFirestore();

    DocumentSnapshot snapshot =
    await Firestore.instance
        .collection('Family')
        .document(session.getHeadOfHouseholdEmail())
        .get();
    var rules = snapshot['rules'];
    if (rules is List) {
      print('The rules are : ' + rules.toString());
      return rules;
    } else {
      throw 'didnt work';
    }
  }


  @override
  Widget build(BuildContext context) {
    final TextEditingController _ruleController = new TextEditingController();
// TODO: implement build
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Rules"),
        ),
        body: new StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance.collection('Family').document('freund.bailey@gmail.com').getCollection("Rules").snapshots,

            builder: (context, snapshot) {
              if (!snapshot.hasData) return new Text("Loading...");
              return new ListView(
                children: snapshot.data.documents.map((document) {
                  return new ListTile(
                    onLongPress: null,
                    title: new Text("Rule: "),
                    subtitle: new Text(document['rule']),
                  );
                }).toList(),

              );
            }
        ),
        floatingActionButton: new FloatingActionButton(
            backgroundColor: Colors.deepPurple,
            tooltip: 'Add', // used by assistive technologies
            child: new Icon(Icons.add),
            onPressed: () async {
              await showDialog<Null>(
                  context: context,
                  builder: (BuildContext context) {
                    return new SimpleDialog(
                      title: const Text('Add a new Rule'),
                      children: <Widget>[
                        new TextField(
                            controller: _ruleController,
                            decoration: new InputDecoration(
                                hintText: "Enter new rule"
                            )
                        ),
                        new IconButton(icon: new Icon(
                            Icons.done, color: Colors.deepPurple),
                            iconSize: 60.0,
                            onPressed: () async {
                              try {
                                print("Trying...");

//                                var rules = new List();
//                                rules.add(await getRules());
//                                rules.add(_ruleController.text);

                                var data =
                                {
                                  'rule': _ruleController.text
                                };

                                print("email:" +session.getHeadOfHouseholdEmail());


                                Firestore.instance.collection('Family')
                                    .document(session.getHeadOfHouseholdEmail())
                                    .getCollection("Rules")
                                    .document()
                                    .setData(data);
                              } catch (e) {
                                print("Failed");
                                print(e);
                              }
                              Navigator.pop(context);
                            }
                        ),

                      ],
                    );
                  }

              );
            }
        )
    );
  }
}

//class PicturesPage extends StatefulWidget{
//  @override
//  State createState() => new PicturesPageState();
//}
//
//class PicturesPageState extends State<PicturesPage>{
//  GoogleSignInAccount _currentUser;
//
//  @override
//  @protected
//  @mustCallSuper
//  void initState() {
//    super.initState();
//    session.getHeadOfHouseholdEmailFromFirestore();
//    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
//      setState(() {
//        _currentUser = account;
////        session.currentUid = account.id;
//      });
//    });
//    _googleSignIn.signInSilently()
//        .then((account) {
//      _currentUser = account;
////      session.currentUid = account.id;
//      print('the current user is: ' + _currentUser.toString());
//    });
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return new Scaffold(
//      appBar: new AppBar(
//        title: new Text("Photos"),
//      ),
//      body: new Center(
//        child: buildGrid(),
//      ),
//    );  }
//}
//
//Widget buildGrid(){
////  var cnt;
////  Firestore.instance.collection('Photos').snapshots.listen((snapshot){
////    cnt = snapshot.documents.length;
////  });
//  return new GridView.extent(
//      maxCrossAxisExtent: 150.0,
//      padding: const EdgeInsets.all(4.0),
//      mainAxisSpacing: 4.0,
//      crossAxisSpacing: 4.0,
//      children: _buildGridTileList(7));
//}
////urlList.add(doc['imageUrl'])
////urlList.add( doc['imageUrl'].toString()
//
//List<Container> _buildGridTileList(int count) {
//  List<String> urlList = ['null'];
//
//  Firestore.instance.collection('Photos').snapshots.listen((snapshot){
//    snapshot.documents.forEach((doc) =>  print(doc['imageUrl']) );
//  });
//  urlList.add('https://firebasestorage.googleapis.com/v0/b/kyn-app.appspot.com/o/image_2936.jpg?alt=media&token=0a24d495-3352-47b6-bafa-cc84cad54dd1');
//  urlList.add('https://firebasestorage.googleapis.com/v0/b/kyn-app.appspot.com/o/image_4424.jpg?alt=media&token=91e8df5b-e528-4bf2-94f6-e7fa032c76bd');
//  urlList.add('https://firebasestorage.googleapis.com/v0/b/kyn-app.appspot.com/o/image_8503.jpg?alt=media&token=39b8577c-f6dc-420c-b455-a37298647953');
//  urlList.add('https://firebasestorage.googleapis.com/v0/b/kyn-app.appspot.com/o/image_4088.jpg?alt=media&token=682afbbc-67b3-42cd-a72c-eb114abf8974');
//  urlList.add('https://firebasestorage.googleapis.com/v0/b/kyn-app.appspot.com/o/image_1910.jpg?alt=media&token=f6908f1d-1b31-4da8-a87a-eebab67eba38');
//  urlList.add('https://firebasestorage.googleapis.com/v0/b/kyn-app.appspot.com/o/image_3217.jpg?alt=media&token=e4a029df-e076-4bfa-bd49-d407a4cf479c');
//  urlList.add('https://firebasestorage.googleapis.com/v0/b/kyn-app.appspot.com/o/image_2228.jpg?alt=media&token=8a89c776-ab86-427b-b73a-337beb4fb0e5');
//
////  print("Objects: " + urlList.length.toString());
////  print("stuff: " + urlList[1]);
//  List<Container> containers = new List<Container>.generate(
//      count,
//          (int index) =>
//      new Container(child: new Image.network(urlList[index + 1])));
//  return containers;
//}

class FamilyPage extends StatefulWidget {
  @override
  _FamilyPageState createState() => new _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {

  GoogleSignInAccount _currentUser;

  @override
  @protected
  @mustCallSuper
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
        //session.currentUid = account.id;
        print('GOT THE EMAIL: ' + _currentUser.email);
      });
    });
    _googleSignIn.signInSilently()
        .then((account) {
      _currentUser = account;
//      session.currentUid = account.id;
      print('the current user is: ' + _currentUser.toString());
    });
  }


  Future<Null> _switchHeadOfHouseholdPage() async {
    if (_currentUser != null) {
      Navigator.of(context).pushNamed("/Family/HeadOfHouseholdPage");
    }
  }

  Future<String> getPassword(String email) async {
    //session.getHeadOfHouseholdEmailFromFirestore();
    //var headOfHouseholdEmail = session.getHeadOfHouseholdEmail();
    print('======================================================================\nThe head of household email is ' );
    print(email);
    DocumentSnapshot snapshot =
    await Firestore.instance
        .collection('Family')
        .document(email)
        .get();
    var pw = snapshot['password'];
    if (pw is String) {
      print('The pw is : ' + pw);
      return pw;
    } else {
      throw 'didnt work';
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController _emailController = new TextEditingController();
    final TextEditingController _passwordController = new TextEditingController();
// TODO: implement build
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Family"),
        ),
// Get list of family members and put into listview
        body: new Column(
            children: <Widget>[
              new Card(
                child: new Column(
                  children: <Widget>[
                    new TextField(
                        controller: _emailController,
                        decoration: new InputDecoration(
                            hintText: "Enter email of head of household"
                        )
                    ),
                    new TextField(
                        controller: _passwordController,
                        decoration: new InputDecoration(
                            hintText: "Enter password set by head of household"
                        )
                    ),
                    new RaisedButton(
                        color: Colors.green,
                        onPressed: () async {
                          var pw = await getPassword(_emailController.text.toLowerCase());
                          print(pw);
                          var bytes = UTF8.encode(
                              _passwordController.text); // data being hashed
                          var pwGuessHash = sha256.convert(bytes).toString();

                          if (pw == pwGuessHash) {
                            var data = {
                              'familyMembers':
                              {
                                'name': _currentUser.displayName
                              }
                            };

                            headOfHouseholdEmail = _emailController.text;

                            try {
                              Firestore.instance.collection('Family').document(
                                  headOfHouseholdEmail.toLowerCase())
                                  .updateData(data)
                                  .then((val) {
                                session.setHeadOfHouseholdEmail(
                                    headOfHouseholdEmail);
// Set head of household
                                var userData = {
                                  'displayName': me.displayName,
                                  'uid': me.uid,
                                  'email': me.email,
                                  'headOfHouseholdEmail': session
                                      .getHeadOfHouseholdEmail().toLowerCase()
                                };
                                Firestore.instance.collection('Users').document(
                                    me.email).updateData(userData)
                                .then((val) {
                                  Navigator.of(context).pushNamed("/LoggedInPage");
                                })
                                .catchError((e){
                                  Firestore.instance.collection('Users').document(
                                      me.email).setData(userData)
                                      .then((val) {
                                    Navigator.of(context).pushNamed("/LoggedInPage");
                                  });
                                });
                              });
                            } catch (e) {

                              print(e);
                            }
                          }
                        },
                        child: const Text('Submit')
                    ),
                    new RaisedButton(
                      onPressed: _switchHeadOfHouseholdPage,
                      color: Colors.blue,
                      child: const Text('I am head of household'),
                    ),
//new Text(_currentUser.email)
                  ],
                ),
              )
            ]
        )
    );
  }
}


class HeadOfHouseholdPage extends StatefulWidget {
  _HeadOfHouseholdPageState createState() => new _HeadOfHouseholdPageState();
}

class _HeadOfHouseholdPageState extends State<HeadOfHouseholdPage> {
  final TextEditingController _passwordController = new TextEditingController();
  final TextEditingController _password2Controller = new TextEditingController();
  GoogleSignInAccount _currentUser;

  @override
  @protected
  @mustCallSuper
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
//        session.currentUid = account.id;
      });
    });
    _googleSignIn.signInSilently()
        .then((account) {
      _currentUser = account;
//      session.currentUid = account.id;
      print('the current user is: ' + _currentUser.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Head of Household"),
        ),
        body: new Column(
            children: <Widget>[
              new Card(
                child: new Column(
                  children: <Widget>[
                    new TextField(
                        autocorrect: false,
                        controller: _passwordController,
                        decoration: new InputDecoration(
                            hintText: "Set Password"
                        )
                    ),
                    new TextField(
                        autocorrect: false,
                        controller: _password2Controller,
                        decoration: new InputDecoration(
                            hintText: "Confirm Password"
                        ),
//                      onSubmitted: ( newValue ) {
//                          if (_passwordController.text != _password2Controller.text){
//
//                          }
//                      },
                    ),
                    new RaisedButton(
                      color: Colors.green,
                        onPressed: () async {
                          if(_passwordController.text == _password2Controller.text) {
                            var bytes = UTF8.encode(
                                _passwordController.text); // data being hashed
                            var digest = sha256.convert(bytes);
                            var familyData = {
                              'password': digest.toString(),
//                              'familyMembers': {
//                                'name': '',
//                                'email': '',
//                                'rules': []
//                              },
//
//                              'resources': {
//                                'name': '',
//                                'phoneNumber': '',
//                                'address': '',
//                                'email': ''
//                              },
//
//                              'questions': {
//                                'asker': '',
//                                'question': '',
//                                'answer': ''
//                              },
//
//                              'rules': []
                            };

                            Firestore.instance
                                .collection('Family')
                                .document(_currentUser.email)
                                .setData(familyData)
                                .then((val) {
                                  session.setHeadOfHouseholdEmail(_currentUser.email);

                              var userData = {
                                'headOfHouseholdEmail': session
                                    .getHeadOfHouseholdEmail()
                              };

                              Firestore.instance.collection('Users').document(
                                  _currentUser.email).updateData(userData);
                            })
                            .then((result){
//                              showDialog(
//                                context: context,
//                                builder: (_) => new AlertDialog(
//                                  title: new Text('Successfully set password'),
//                                ),
//                              );
                            print('successfully set head of household to self');
                            Navigator.of(context).pushNamed("/LoggedInPage");
                            })
                            .catchError((error){

                            });

                          } else {
////                         showDialog(
//                            context: context,
//                            builder: (_) => new AlertDialog(
//                            title: new Text('Successfully set password'),
//                            ),

                          }

                        },
                        child: const Text('Submit')
                    )
                  ],
                ),
              )
            ]
        )
    );
  }
}

class ResourcesPage extends StatefulWidget {
  @override
  _ResourcesPageState createState() => new _ResourcesPageState();
}

class _ResourcesPageState extends State<ResourcesPage> {
  final TextEditingController _nameController = new TextEditingController();
  final TextEditingController _phoneController = new TextEditingController();
  GoogleSignInAccount _currentUser;

  @override
  @protected
  @mustCallSuper
  void initState() {
    super.initState();
    session.getHeadOfHouseholdEmailFromFirestore();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
//        session.currentUid = account.id;
      });
    });
    _googleSignIn.signInSilently()
        .then((account) {
      _currentUser = account;
//      session.currentUid = account.id;
      print('the current user is: ' + _currentUser.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Resources"),
        ),
        body: new StreamBuilder<QuerySnapshot>(
            stream:
            Firestore.instance.collection('Family')
                .document(session.getHeadOfHouseholdEmail())
                .getCollection("Resources").snapshots,

            builder: (context, snapshot) {
              if (!snapshot.hasData) return new Text("Loading...");
              return new ListView(
                children: snapshot.data.documents.map((document) {
                  return new ListTile(
                    onLongPress: null,
                    title: new Text(document['name']),
                    subtitle: new Text(document['phone']),
                  );
                }).toList(),

              );
            }
        ),
        floatingActionButton: new FloatingActionButton(
            backgroundColor: Colors.deepPurple,
            tooltip: 'Add', // used by assistive technologies
            child: new Icon(Icons.add),
            onPressed: () async {
              await showDialog<Null>(
                  context: context,
                  builder: (BuildContext context) {
                    return new SimpleDialog(
                      title: const Text('Add a new Resource'),
                      children: <Widget>[
                        new TextField(
                            controller: _nameController,
                            decoration: new InputDecoration(
                                hintText: "Enter name"
                            )
                        ),
                        new TextField(
                            controller: _phoneController,
                            decoration: new InputDecoration(
                                hintText: "Enter phone number"
                            )
                        ),
                        new IconButton(icon: new Icon(
                            Icons.done, color: Colors.deepPurple),
                            iconSize: 60.0,
                            onPressed: () async {
                              try {
                                print("Trying...");
                                print('user entered text: ');
                                print(_nameController.text);

//                                var rules = new List();
//                                rules.add(await getRules());
//                                rules.add(_ruleController.text);

                                var data =
                                {
                                  'name': _nameController.text,
                                  'phone': _phoneController.text
                                };
                                session.getHeadOfHouseholdEmailFromFirestore();
                                print("email:" +session.getHeadOfHouseholdEmail());


                                Firestore.instance.collection('Family')
                                    .document(session.getHeadOfHouseholdEmail())
                                    .getCollection("Resources")
                                    .document()
                                    .setData(data);
                              } catch (e) {
                                print("Failed");
                                print(e);
                              }
                              Navigator.pop(context);
                            }
                        ),

                      ],
                    );
                  }

              );
            }
        )
    );
  }
}


//class HubPage extends StatefulWidget{
//  _HubPageState createState() => new _HubPageState();
//}
//
//class _HubPageState extends State<HubPage>{
//  @override
//  Widget build(BuildContext context) {
//    return new Scaffold(
//      appBar: new AppBar(
//        title: new Text("The Hub"),
//      ),
//      body: new ChatScreen(),
//    );
//  }
//}```