import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  String? chatroomid;
  Map<String, dynamic>? participants;
  String? lastMessage;
  DateTime? lastMessageTime;
  List<dynamic>? users;

  ChatRoomModel({this.chatroomid, this.participants, this.lastMessage, this.lastMessageTime, this.users});

  ChatRoomModel.fromMap(Map<String, dynamic> map) {
    chatroomid = map["chatroomid"];
    participants = map["participants"];
    lastMessage = map["lastmessage"];
    users = map["users"];
    // Parse the last message time as a DateTime
    if (map["lastmessagetime"] != null) {
      lastMessageTime = DateTime.fromMillisecondsSinceEpoch(map["lastmessagetime"].millisecondsSinceEpoch);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      "chatroomid": chatroomid,
      "participants": participants,
      "lastmessage": lastMessage,
      "users" : users,

      // Store the last message time as a timestamp in Firestore
      "lastmessagetime": lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
    };
  }
}
