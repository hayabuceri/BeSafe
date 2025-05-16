import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class EmergencyProcedureScreen extends StatelessWidget {
  const EmergencyProcedureScreen({Key? key}) : super(key: key);

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
                'Emergency Procedures',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF69B4),
                ),
              ),
              const SizedBox(height: 20),
              
              _buildTipSection(
                'In Case of Emergency',
                [
                  'Stay calm and assess the situation quickly',
                  'Call emergency services immediately (911 or local emergency number)',
                  'Move to a safe location if possible',
                  'Alert nearby people who can help',
                  'Use the SOS feature in the app to notify emergency contacts',
                ],
              ),
              _buildTipSection(
                'Medical Emergency Steps',
                [
                  'Check for responsiveness and breathing',
                  'If trained, perform basic first aid or CPR if needed',
                  'Keep the person still and comfortable',
                  'Gather information about medications or medical conditions',
                  'Stay with the person until help arrives',
                ],
              ),
              _buildTipSection(
                'Natural Disaster Response',
                [
                  'Follow local authority instructions',
                  'Have an emergency kit ready',
                  'Know your evacuation routes',
                  'Stay informed through official channels',
                  'Help others if it\'s safe to do so',
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
                      'Important',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF69B4),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'In life-threatening situations, always call emergency services first. These procedures are guidelines to help you stay safe while waiting for professional help.',
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