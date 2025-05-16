import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class SelfDefenseScreen extends StatelessWidget {
  const SelfDefenseScreen({Key? key}) : super(key: key);

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
                'Self Defense Tips',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF69B4),
                ),
              ),
              const SizedBox(height: 20),
              
              _buildTipSection(
                'Basic Self-Defense Moves',
                [
                  'Palm Strike: Push the heel of your palm upward into an attacker\'s nose or chin',
                  'Knee Strike: Use your knee to strike the groin or thigh',
                  'Elbow Strike: Use your elbow to strike the face or ribs',
                  'Stomp: Stomp on the attacker\'s foot with your heel',
                  'Break Free from Grabs: Turn toward the thumb side, it\'s the weakest point',
                ],
              ),
              _buildTipSection(
                'Prevention Tips',
                [
                  'Share your location with trusted contacts',
                  'Avoid walking alone at night when possible',
                  'Keep emergency numbers on speed dial',
                  'Take a self-defense class if possible',
                  'Always have a backup plan',
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