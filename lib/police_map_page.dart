import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PoliceMapPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Police Stations'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _launchPoliceStations,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
          ),
          child: Text('Open Google Maps'),
        ),
      ),
    );
  }

  void _launchPoliceStations() async {
    final Uri url = Uri.parse("https://maps.google.com/?q=police stations near me");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      print('Could not launch maps');
    }
  }
} 