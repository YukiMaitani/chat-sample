import 'package:chat/my_page.dart';
import 'package:chat/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

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
    if(FirebaseAuth.instance.currentUser == null){
      return MaterialApp(
        title: 'Flutter Demo',
        home: const SignPage(),
      );
    }else {
      return MaterialApp(
          title: 'Flutter Demo',
          home: const ChatPage()
      );
    }
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
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context){
                return ChatPage();
              }),
              (route) => false,
            );
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
  final contorller = TextEditingController();

  @override
  void dispose(){
    contorller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){FocusScope.of(context).unfocus();},
      child: Scaffold(
        appBar: AppBar(
          title: const Text('チャット'),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: (){
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) {
                        return MyPage();
                      }
                  ));
                },
                child: CircleAvatar(
                  backgroundImage: NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!),
                ),
              ),
            )
          ],
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
                      return PostWidget(post: post,);
                    });
                  }
                ),
              ),
              TextFormField(
                controller: contorller,
                decoration: InputDecoration(
                  fillColor: Colors.amber[100],
                  hintText: '今何してる？',
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.amber,
                      width: 1
                    )
                  ),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.amber,
                        width: 2
                      ),
                  ),
                ),
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
                  contorller.clear();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PostWidget extends StatelessWidget {
  const PostWidget({Key? key, required this.post}) : super(key: key);
  final Post post;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(post.posterImageUrl),
          ),
          SizedBox(
            width: 4,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        post.posterName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(DateFormat('MM/dd HH:mm').format(post.createdAt.toDate()))
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      child: Text(post.text),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: FirebaseAuth.instance.currentUser!.uid == post.posterId ? Colors.amber[100] : Colors.blue[100],
                        borderRadius: BorderRadius.circular(4)
                      ),
                    ),
                    if (FirebaseAuth.instance.currentUser!.uid == post.posterId)
                      SizedBox(
                        width: 96,
                        child: Row(
                          children: [
                            IconButton(
                                onPressed: (){
                                  post.reference.delete();
                                },
                                icon: Icon(Icons.delete)
                            ),
                            IconButton(
                                onPressed: (){
                                  showDialog(context: context, builder: (context){
                                    return AlertDialog(
                                      title: Text('編集'),
                                      content: TextFormField(
                                        initialValue: post.text,
                                        autofocus: true,
                                        onFieldSubmitted: (text){
                                          post.reference.update({
                                            'text' : text
                                          });
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    );
                                  });
                                },
                                icon: Icon(Icons.edit)
                            )
                          ],
                        ),
                      )
                      else
                      SizedBox(
                        width: 96
                      )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
