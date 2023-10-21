import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:chatapp/models/ChatRoomModel.dart';
import 'package:chatapp/models/MessageModel.dart';
import 'package:chatapp/models/UserModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

import 'MessageBubble.dart';

class ChatRoomPage extends StatefulWidget {
  final UserModel targetUser;
  final ChatRoomModel chatroom;
  final UserModel userModel;
  final User firebaseUser;

  const ChatRoomPage({
    Key? key,
    required this.targetUser,
    required this.chatroom,
    required this.userModel,
    required this.firebaseUser,
  }) : super(key: key);

  @override
  _ChatRoomPageState createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  TextEditingController messageController = TextEditingController();
  bool isImageLoading = false;
  bool isSendingImage = false;

  void sendMessage({String? imageUrl}) async {
    String msg = messageController.text.trim();
    messageController.clear();

    if (msg != "" || imageUrl != null) {
      setState(() {
        isSendingImage = true;
      });

      MessageModel newMessage = MessageModel(
        messageid: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: widget.userModel.uid,
        createdon: DateTime.now(),
        text: msg,
        imageUrl: imageUrl,
        seen: false,
      );

      FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(widget.chatroom.chatroomid)
          .collection("messages")
          .doc(newMessage.messageid)
          .set(newMessage.toMap())
          .then((_) {
        setState(() {
          isSendingImage = false;
        });
      });

      widget.chatroom.lastMessage = imageUrl != null ? "Image" : msg;
      widget.chatroom.lastMessageTime = DateTime.now();
      FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(widget.chatroom.chatroomid)
          .set(widget.chatroom.toMap());
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageUrl = await uploadImage(pickedFile.path);
      sendMessage(imageUrl: imageUrl);
    }
  }

  Future<String> uploadImage(String imagePath) async {
    Reference reference = FirebaseStorage.instance.ref().child(DateTime.now().millisecondsSinceEpoch.toString());
    UploadTask uploadTask = reference.putFile(File(imagePath));
    TaskSnapshot taskSnapshot = await uploadTask;

    final originalBytes = await File(imagePath).readAsBytes();
    final compressedBytes = await FlutterImageCompress.compressWithList(
      originalBytes,
      minHeight: 800,
      minWidth: 800,
      quality: 20,
    );

    await reference.putData(compressedBytes);

    String downloadURL = await taskSnapshot.ref.getDownloadURL();
    return downloadURL;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              backgroundImage:
                  NetworkImage(widget.targetUser.profilepic.toString()),
            ),
            SizedBox(width: 10),
            Text(widget.targetUser.fullname.toString()),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection("chatrooms")
                      .doc(widget.chatroom.chatroomid)
                      .collection("messages")
                      .orderBy("createdon", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.active) {
                      if (snapshot.hasData) {
                        QuerySnapshot dataSnapshot =
                            snapshot.data as QuerySnapshot;

                        return ListView.builder(
                          reverse: true,
                          itemCount: dataSnapshot.docs.length,
                          itemBuilder: (context, index) {
                            MessageModel currentMessage = MessageModel.fromMap(
                              dataSnapshot.docs[index].data()
                                  as Map<String, dynamic>,
                            );

                            bool isNewDate = false;
                            if (index < dataSnapshot.docs.length - 1) {
                              final MessageModel nextMessage =
                                  MessageModel.fromMap(
                                dataSnapshot.docs[index + 1].data()
                                    as Map<String, dynamic>,
                              );
                              if (!isSameDay(currentMessage.createdon,
                                  nextMessage.createdon)) {
                                isNewDate = true;
                              }
                            }

                            return Column(
                              crossAxisAlignment:
                                  currentMessage.sender == widget.userModel.uid
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                              children: [
                                if (isNewDate)
                                  DateHeader(currentMessage.createdon),
                                MessageBubble(
                                  message: currentMessage,
                                  currentUserId:
                                      widget.userModel.uid.toString(),
                                  isImageLoading: isImageLoading,
                                  onTapImage: () {
                                    _openImageInViewer(currentMessage.imageUrl);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                              "An error occurred! Please check your internet connection."),
                        );
                      } else {
                        return Center(
                          child: Text("Say hi to your new friend"),
                        );
                      }
                    } else {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  },
                ),
              ),
            ),
            Container(
              color: Colors.grey[200],
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Row(
                children: [
                  Flexible(
                    child: TextField(
                      controller: messageController,
                      maxLines: null,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter message",
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      pickImage();
                    },
                    icon: Icon(Icons.photo,
                        color: Theme.of(context).colorScheme.secondary),
                  ),
                  IconButton(
                    onPressed: () {
                      sendMessage();
                    },
                    icon: Icon(Icons.send,
                        color: Theme.of(context).colorScheme.secondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatTime(DateTime? time) {
    if (time != null) {
      return DateFormat.jm().format(time);
    } else {
      return '';
    }
  }

  bool isSameDay(DateTime? dateA, DateTime? dateB) {
    return dateA!.year == dateB!.year &&
        dateA.month == dateB!.month &&
        dateA.day == dateB.day;
  }

  void _openImageInViewer(String? imageUrl) {
    if (imageUrl != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return PhotoView(
              imageProvider: NetworkImage(imageUrl),
            );
          },
        ),
      );
    }
  }
}

class DateHeader extends StatelessWidget {
  final DateTime? date;

  DateHeader(this.date);

  @override
  Widget build(BuildContext context) {
    if (date != null) {
      final now = DateTime.now();
      if (date!.year == now.year &&
          date!.month == now.month &&
          date!.day == now.day) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Text(
            'Today',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text(
            DateFormat.yMMMMd().format(date!),
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
    } else {
      return Container();
    }
  }
}
