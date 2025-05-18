import 'package:flutter/material.dart';
import 'sos_button.dart';
import '../screens/home_screen.dart';
import '../screens/track_me_screen.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () {
                  if (currentIndex != 0) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    );
                  }
                },
              ),
              const SizedBox(width: 80), // Space for the centered SOS button
              _buildNavItem(
                context,
                icon: Icons.location_on,
                label: 'Track Me',
                isActive: currentIndex == 2,
                onTap: () {
                  if (currentIndex != 2) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const TrackMeScreen()),
                    );
                  }
                },
              ),
            ],
          ),
          Positioned(
            child: SOSButton(
              isInNavigationBar: true,
              onPressed: () {
                // Add your SOS functionality here
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFFFF69B4) : Colors.white,
            size: 28,
          ),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFFFF69B4) : Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 