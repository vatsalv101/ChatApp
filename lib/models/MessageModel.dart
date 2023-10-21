class MessageModel {
  String? messageid;
  String? sender;
  String? text;
  String? imageUrl;
  bool? seen;
  DateTime? createdon;

  MessageModel({
    this.messageid,
    this.sender,
    this.text,
    this.imageUrl,
    this.seen,
    this.createdon,
  });

  MessageModel.fromMap(Map<String, dynamic> map) {
    messageid = map["messageid"];
    sender = map["sender"];
    text = map["text"];
    imageUrl = map["imageUrl"];
    seen = map["seen"];
    createdon = map["createdon"].toDate();
  }

  Map<String, dynamic> toMap() {
    return {
      "messageid": messageid,
      "sender": sender,
      "text": text,
      "imageUrl": imageUrl, // Include the image URL when converting to a map
      "seen": seen,
      "createdon": createdon,
    };
  }
}
