import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chatapp/models/ChatRoomModel.dart';
import 'package:chatapp/models/FirebaseHelper.dart';
import 'package:chatapp/models/UserModel.dart';
import 'package:chatapp/pages/ChatRoomPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'LoginPage.dart';
import 'ProfileViewPage.dart';
import 'SearchPage.dart';

class HomePage extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const HomePage({Key? key, required this.userModel, required this.firebaseUser}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Chat App"),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return LoginPage();
                  },
                ),
              );
            },
            icon: Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("chatrooms")
                .where("participants.${widget.userModel.uid}", isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                if (snapshot.hasData) {
                  QuerySnapshot chatRoomSnapshot = snapshot.data as QuerySnapshot;

                  return ListView.builder(
                    itemCount: chatRoomSnapshot.docs.length,
                    itemBuilder: (context, index) {
                      ChatRoomModel chatRoomModel =
                      ChatRoomModel.fromMap(chatRoomSnapshot.docs[index].data() as Map<String, dynamic>);

                      Map<String, dynamic> participants = chatRoomModel.participants!;

                      List<String> participantKeys = participants.keys.toList();
                      participantKeys.remove(widget.userModel.uid);

                      return FutureBuilder(
                        future: FirebaseHelper.getUserModelById(participantKeys[0]),
                        builder: (context, userData) {
                          if (userData.connectionState == ConnectionState.done) {
                            if (userData.data != null) {
                              UserModel targetUser = userData.data as UserModel;

                              // Get the last message time
                              DateTime? lastMessageTime = chatRoomModel.lastMessageTime;
                              DateTime currentDate = DateTime.now();

                              // Format the last message time to display it
                              String formattedLastMessageTime = "";
                              if (lastMessageTime != null) {
                                if (lastMessageTime.year == currentDate.year &&
                                    lastMessageTime.month == currentDate.month &&
                                    lastMessageTime.day == currentDate.day) {
                                  // The last message was sent today, so display the time
                                  formattedLastMessageTime = DateFormat.jm().format(lastMessageTime);
                                } else {
                                  // The last message was sent on a different day, so display the date
                                  formattedLastMessageTime = DateFormat.yMd().format(lastMessageTime);
                                }
                              }

                              // Get the last message and handle long messages
                              String lastMessage = chatRoomModel.lastMessage.toString();
                              if (lastMessage.length > 32) {
                                lastMessage = lastMessage.substring(0, 32) + '...';
                              }

                              return ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return ChatRoomPage(
                                          chatroom: chatRoomModel,
                                          firebaseUser: widget.firebaseUser,
                                          userModel: widget.userModel,
                                          targetUser: targetUser,
                                        );
                                      },
                                    ),
                                  );
                                },
                                leading: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => ProfilePhotoViewPage(
                                        tag: 'profile_photo_${targetUser.uid}',
                                        imageUrl: targetUser.profilepic.toString(),
                                      ),
                                    ));
                                  },
                                  child: Hero(
                                    tag: 'profile_photo_${targetUser.uid}',
                                    child: CircleAvatar(
                                      backgroundImage: NetworkImage(targetUser.profilepic.toString()),
                                    ),
                                  ),
                                ),
                                title: Text(targetUser.fullname.toString()),
                                subtitle: Row(
                                  children: [
                                    Expanded(
                                      child: (chatRoomModel.lastMessage.toString() != "")
                                          ? Text(
                                        lastMessage,
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: Theme.of(context).textTheme.bodyText1?.fontSize,
                                        ),
                                      )
                                          : Text(
                                        "Say hi to your new friend!",
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        formattedLastMessageTime,
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return Container();
                            }
                          } else {
                            // Display a loading indicator while waiting for the data
                            return Center(
                              child: SpinKitFadingCircle(
                                color: Theme.of(context).primaryColor, // Customize the color
                                size: 30.0, // Customize the size
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error.toString()),
                  );
                } else {
                  return Center(
                    child: Text("No Chats"),
                  );
                }
              } else {
                // Display a loading indicator while waiting for the data
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) {
              return SearchPage(userModel: widget.userModel, firebaseUser: widget.firebaseUser);
            },
          ));
        },
        child: Icon(Icons.search),
      ),
    );
  }
}