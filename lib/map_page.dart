import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapPage extends StatelessWidget {
  final String query;

  MapPage({required this.query});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(query),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _launchMap(query),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
          ),
          child: Text('Open Google Maps'),
        ),
      ),
    );
  }

  void _launchMap(String query) async {
    final Uri url = Uri.parse("https://maps.google.com/?q=$query");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch maps');
    }
  }
} 