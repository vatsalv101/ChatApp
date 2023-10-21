import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/MessageModel.dart';

class MessageBubble extends StatefulWidget {
  final MessageModel message;
  final String currentUserId;
  final bool isImageLoading;
  final Function onTapImage;

  MessageBubble({
    required this.message,
    required this.currentUserId,
    required this.isImageLoading,
    required this.onTapImage,
  });

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool showTimestamp = false;

  @override
  Widget build(BuildContext context) {
    final isImageMessage = widget.message.imageUrl != null;

    return GestureDetector(
      onTap: () {
        if (isImageMessage) {
          widget.onTapImage();
        } else {
          setState(() {
            showTimestamp = !showTimestamp;
          });
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Column(
          crossAxisAlignment: widget.message.sender == widget.currentUserId
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (isImageMessage)
              Stack(
                alignment: Alignment.center,
                children: [
                  // Add a loading indicator while the image is loading
                  if (widget.isImageLoading)
                    const CircularProgressIndicator()

                  else
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: widget.message.sender == widget.currentUserId
                              ? Colors.blueAccent
                              : Colors.deepPurple,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                          bottomLeft: Radius.circular(
                              widget.message.sender == widget.currentUserId ? 8 : 0),
                          bottomRight: Radius.circular(
                              widget.message.sender != widget.currentUserId ? 8 : 0),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          widget.message.imageUrl!,
                          fit: BoxFit.cover,
                          width: 200,
                          height: 200,
                          errorBuilder: (context, error, stackTrace) {
                            // Display a grey area when there is an error loading the image
                            return Container(
                              color: Colors.grey, // You can customize the color
                              width: 200,
                              height: 200,
                            );
                          },
                        ),
                      ),
                    ),
                  if (widget.isImageLoading)
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.message.sender == widget.currentUserId
                            ? Colors.blueAccent
                            : Colors.deepPurple,
                      ),
                    ),
                ],
              )
            else
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.message.sender == widget.currentUserId
                      ? Colors.blueAccent
                      : Colors.deepPurple,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(
                        widget.message.sender == widget.currentUserId ? 20 : 0),
                    bottomRight: Radius.circular(
                        widget.message.sender != widget.currentUserId ? 20 : 0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.message.text.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: Row(
                mainAxisAlignment: widget.message.sender == widget.currentUserId
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  if (showTimestamp)
                    Container(
                      margin: EdgeInsets.only(right: 4),
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        formatTime(widget.message.createdon),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
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
}
