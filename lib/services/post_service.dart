import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/screens/view_image.dart';
import 'package:social_media_app/services/services.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:uuid/uuid.dart';

class PostService extends Service {
  String postId = Uuid().v4();

//uploads profile picture to the users collection
  uploadProfilePicture(File image, User user) async {
    String link = await uploadImage(profilePic, image);
    var ref = usersRef.doc(user.uid);
    ref.update({
      "photoUrl": link,
    });
  }

//uploads post to the post collection
  uploadPost(File image, String location, String description) async {
    String link = await uploadImage(posts, image);
    print("Upload post");
    DocumentSnapshot doc =
        await usersRef.doc(firebaseAuth.currentUser!.uid).get();
    user = UserModel.fromJson(
      doc.data() as Map<String, dynamic>,
    );
    print(link);
    var ref = postRef.doc();
    ref.set({
      "id": ref.id,
      "postId": ref.id,
      "username": user!.username,
      "ownerId": firebaseAuth.currentUser!.uid,
      "mediaUrl": link,
      "description": description ?? "",
      "location": location ?? "Green Horizon",
      "timestamp": Timestamp.now(),
    }).catchError((e) {
      print(e);
    });
  }

//uploads post to the post collection
  deletePost(String uid) async {
    DocumentSnapshot doc =
        await usersRef.doc(firebaseAuth.currentUser!.uid).get();
    var ref = postRef.doc(uid);
    ref.delete();
  }

//uploads post to the post collection
  updatePost(String uid,
      {File? image, String? location, String? description}) async {
    Map<String, Object> data = {};
    if (image != null) {
      String link = await uploadImage(posts, image);
      data["mediaUrl"] = link;
    }

    if (location != null) {
      data["location"] = location;
    }
    if (description != null) {
      data["description"] = description;
    }

    DocumentSnapshot doc =
        await usersRef.doc(firebaseAuth.currentUser!.uid).get();
    user = UserModel.fromJson(
      doc.data() as Map<String, dynamic>,
    );
    var ref = postRef.doc(uid);
    ref.update(data).catchError((e) {
      print(e);
    });
  }

//upload a comment
  uploadComment(String currentUserId, String comment, String postId,
      String ownerId, String mediaUrl) async {
    DocumentSnapshot doc = await usersRef.doc(currentUserId).get();
    user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
    await commentRef.doc(postId).collection("comments").add({
      "username": user!.username,
      "comment": comment,
      "timestamp": Timestamp.now(),
      "userDp": user!.photoUrl,
      "userId": user!.id,
    });
    bool isNotMe = ownerId != currentUserId;
    if (isNotMe) {
      addCommentToNotification("comment", comment, user!.username!, user!.id!,
          postId, mediaUrl, ownerId, user!.photoUrl!);
    }
  }

  deleteComment(String? postId, String commentId) async {
    var ref = commentRef.doc(postId).collection("comments").doc(commentId);
    ref.delete();
  }

  updateComment(String commentId, String? postId, String newComment) async {
    commentRef.doc(postId).collection("comments").doc(commentId).update({
      "comment": newComment,
      "timestamp": Timestamp.now(),
    });
  }
//add the comment to notification collection
  addCommentToNotification(
      String type,
      String commentData,
      String username,
      String userId,
      String postId,
      String mediaUrl,
      String ownerId,
      String userDp) async {
    await notificationRef.doc(ownerId).collection('notifications').add({
      "type": type,
      "commentData": commentData,
      "username": username,
      "userId": userId,
      "userDp": userDp,
      "postId": postId,
      "mediaUrl": mediaUrl,
      "timestamp": Timestamp.now(),
    });
  }

//add the likes to the notfication collection
  addLikesToNotification(String type, String username, String userId,
      String postId, String mediaUrl, String ownerId, String userDp) async {
    await notificationRef
        .doc(ownerId)
        .collection('notifications')
        .doc(postId)
        .set({
      "type": type,
      "username": username,
      "userId": firebaseAuth.currentUser!.uid,
      "userDp": userDp,
      "postId": postId,
      "mediaUrl": mediaUrl,
      "timestamp": Timestamp.now(),
    });
  }

  //remove likes from notification
  removeLikeFromNotification(
      String ownerId, String postId, String currentUser) async {
    bool isNotMe = currentUser != ownerId;

    if (isNotMe) {
      DocumentSnapshot doc = await usersRef.doc(currentUser).get();
      user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
      notificationRef
          .doc(ownerId)
          .collection('notifications')
          .doc(postId)
          .get()
          .then((doc) => {
                if (doc.exists) {doc.reference.delete()}
              });
    }
  }
}
