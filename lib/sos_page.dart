import 'package:flutter/material.dart';

class SOSPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SOS'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Text(
          'SOS Page',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
} 