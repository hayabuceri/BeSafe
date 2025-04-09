import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About BeSafe'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'About BeSafe',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              Text(
                "BeSafe Is A Mobile App Designed To Enhance Women's Safety At UNITEN. "
                "With Features Like Real-Time Location Sharing, Guardian Tracking, And "
                "Safety Tips, BeSafe Ensures You're Never Alone. Our Mission Is To "
                "Empower Users With Tools To Stay Secure And Connected, Promoting A "
                "Safer Community For Everyone.",
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 