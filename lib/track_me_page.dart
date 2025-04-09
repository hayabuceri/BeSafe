import 'package:flutter/material.dart';

class TrackMePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Me'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Text(
          'Track Me Page',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
} 