import 'package:flutter/material.dart';

class ProfilePhotoViewPage extends StatelessWidget {
  final String tag;
  final String imageUrl;

  ProfilePhotoViewPage({required this.tag, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Photo'),
      ),
      body: Center(
        child: Hero(
          tag: tag,
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
