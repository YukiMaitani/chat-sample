import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  Post({
    required this.text,
    required this.createdAt,
    required this.posterName,
    required this.posterImageUrl,
    required this.posterId,
    required this.reference,
  });

  factory Post.fromFirestore(DocumentSnapshot<Map<String,dynamic>> documentSnapshot) {
    final data = documentSnapshot.data()!;
    return Post(
        text: data['text'],
        createdAt: data['createdAt'],
        posterName: data['posterName'],
        posterImageUrl: data['posterImageUrl'],
        posterId: data['posterId'],
        reference: documentSnapshot.reference
    );
  }

  Map<String,dynamic> toMap() {
    return <String,dynamic>{
      'text': text,
      'createdAt': createdAt,
      'posterName': posterName,
      'posterImageUrl': posterImageUrl,
      'posterId': posterId,
    };
  }

  /// 投稿文
  final String text;

  /// 投稿日時
  final Timestamp createdAt;

  /// 投稿者の名前
  final String posterName;

  /// 投稿者のアイコン画像URL
  final String posterImageUrl;

  /// 投稿者のユーザーID
  final String posterId;

  /// Firestoreのどこにデータが存在するかを表すpath情報
  final DocumentReference reference;
}