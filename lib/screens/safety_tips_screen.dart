import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class SafetyTipsScreen extends StatelessWidget {
  const SafetyTipsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Safety Tips',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF69B4),
                ),
              ),
              const SizedBox(height: 20),
              _buildTipSection(
                'Basic Safety Rules',
                [
                  'Stay aware of your surroundings at all times',
                  'Trust your instincts - if something feels wrong, it probably is',
                  'Keep your phone charged and easily accessible',
                  'Walk confidently and stay in well-lit areas',
                  'Have your keys ready before reaching your destination',
                ],
              ),
              _buildTipSection(
                'If You Feel Threatened',
                [
                  'Stay calm and assess the situation',
                  'Keep distance between yourself and potential threats',
                  'Use your voice - yell "FIRE" to attract attention',
                  'Look for escape routes and move toward populated areas',
                  'Call emergency services if possible',
                ],
              ),

              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFF69B4)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remember',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF69B4),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your safety is the top priority. These tips are for general awareness. In case of immediate danger, always try to escape first and call for help.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipSection(String title, List<String> tips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...tips.map((tip) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '• ',
                style: TextStyle(
                  color: Color(0xFFFF69B4),
                  fontSize: 16,
                ),
              ),
              Expanded(
                child: Text(
                  tip,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }
} 