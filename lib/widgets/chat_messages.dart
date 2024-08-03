import 'package:chat_app/widgets/message_bubbles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser!;
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chat')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, chatSnapShots) {
        if (chatSnapShots.connectionState == ConnectionState.waiting) {
          CircularProgressIndicator();
        }

        if (!chatSnapShots.hasData || chatSnapShots.data!.docs.isEmpty) {
          return Center(
            child: Text("no messages found"),
          );
        }
        if (chatSnapShots.hasError) {
          return Center(
            child: Text("something went wrong bro.."),
          );
        }

        final loadedMessage = chatSnapShots.data!.docs;
        return ListView.builder(
            padding: EdgeInsets.only(
              bottom: 40,
              left: 13,
              right: 13,
            ),
            reverse: true,
            itemCount: loadedMessage.length,
            itemBuilder: (ctx, index) {
              // return Text(loadedMessage[index].data()['text']);
              final chatMessage = loadedMessage[index].data();
              final nextChatMessage = index + 1 < loadedMessage.length
                  ? loadedMessage[index + 1].data()
                  : null;
              final currentMessageUserId = chatMessage['userId'];
              final nextMessageUserId =
                  nextChatMessage != null ? nextChatMessage['userId'] : null;
              final nextUserIsSame = nextMessageUserId == currentMessageUserId;

              if (nextUserIsSame) {
                return MessageBubble.next(
                    message: chatMessage['text'],
                    isMe: authenticatedUser.uid == currentMessageUserId);
              } else {
                return MessageBubble.first(
                    userImage: chatMessage['userImage'],
                    username: chatMessage['username'],
                    message: chatMessage['text'],
                    isMe: authenticatedUser.uid == currentMessageUserId);
              }
            });
      },
    );
  }
}
