import 'package:chat/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // runApp 前に何かを実行し+たいときはこれが必要です。
  await Firebase.initializeApp( // これが Firebase の初期化処理です。
    options: DefaultFirebaseOptions.android,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const ChatPage(),
    );
  }
}

class SignPage extends StatefulWidget {
  const SignPage({Key? key}) : super(key: key);

  @override
  State<SignPage> createState() => _SignPageState();
}

class _SignPageState extends State<SignPage> {
  Future<void> signInWithGoogle() async {
    // GoogleSignIn をして得られた情報を Firebase と関連づけることをやっています。
    final googleUser = await GoogleSignIn(scopes: ['profile', 'email']).signIn();

    final googleAuth = await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GoogleSignIn'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('GoogleSignIn'),
          onPressed: () async {
            await signInWithGoogle();
            Navigator.of(context).push(MaterialPageRoute(builder: (context){
              return ChatPage();
            }));
          },
        ),
      ),
    );
  }
}

final postsReference = FirebaseFirestore.instance.collection('posts').withConverter(
    fromFirestore: (documentSnapshot,_){
      return Post.fromFirestore(documentSnapshot);
    },
    toFirestore: (data,_){
      return data.toMap();
    }
);

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('チャット'),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Post>>(
                stream: postsReference.orderBy('createdAt').snapshots(),
                builder: (context,snapshot) {
                  final posts = snapshot.data?.docs ?? [];
                  return ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context,index){
                    final post = posts[index].data();
                    return Text(post.text);
                  });
                }
              ),
            ),
            TextFormField(
              onFieldSubmitted: (text){
                final user = FirebaseAuth.instance.currentUser!;
                final newDocumentReference = postsReference.doc();
                final newPost = Post(
                    text: text,
                    createdAt: Timestamp.now(),
                    posterName: user.displayName!,
                    posterImageUrl: user.photoURL!,
                    posterId: user.uid,
                    reference: newDocumentReference,
                );
                newDocumentReference.set(newPost);
              },
            ),
          ],
        ),
      ),
    );
  }
}