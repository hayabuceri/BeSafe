import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class HealthTipsScreen extends StatelessWidget {
  const HealthTipsScreen({Key? key}) : super(key: key);

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
                'Health Tips',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF69B4),
                ),
              ),
              const SizedBox(height: 20),
              
              _buildTipSection(
                'General Health Tips',
                [
                  'Stay hydrated - drink at least 8 glasses of water daily',
                  'Get 7-9 hours of quality sleep each night',
                  'Exercise regularly - aim for 30 minutes daily',
                  'Maintain a balanced diet with fruits and vegetables',
                  'Practice good hygiene and wash hands frequently',
                ],
              ),
              _buildTipSection(
                'Mental Health Care',
                [
                  'Practice stress management through meditation or deep breathing',
                  'Take regular breaks during work or study',
                  'Stay connected with friends and family',
                  'Seek professional help when feeling overwhelmed',
                  'Maintain a healthy work-life balance',
                ],
              ),
              _buildTipSection(
                'Preventive Care',
                [
                  'Schedule regular health check-ups',
                  'Keep vaccinations up to date',
                  'Practice good posture while working',
                  'Limit screen time and take eye breaks',
                  'Maintain good oral hygiene',
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
                      'Your health is your wealth. These tips are general guidelines. For specific health concerns, always consult with a healthcare professional.',
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