import 'package:chat/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class MyPage extends StatelessWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: Text('マイページ'),
      ),
      body: Center(
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(user.photoURL!),
            ),
            Text(user.displayName!),
            Text(user.uid),
            Text(user.metadata.creationTime!.toString()),
            SizedBox(
              height: 24,
            ),
            ElevatedButton(
                onPressed: () async{
                  await GoogleSignIn().signOut();
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context){
                        return SignPage();
                      }),
                      (route) => false
                  );
                },
                child: Text('サインアウト')
            )
          ],
        ),
      ),
    );
  }
}
