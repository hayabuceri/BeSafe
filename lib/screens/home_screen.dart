import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';
import 'emergency_contacts_screen.dart';
import 'track_me_screen.dart';
import 'shared_locations_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? displayName;
  
  const HomeScreen({Key? key, this.displayName}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _tipsController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;

  @override
  void initState() {
    super.initState();
    // Auto-scroll the tips carousel
    Future.delayed(const Duration(seconds: 3), () {
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _tipsController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_tipsController.hasClients) {
        if (_currentPage < _totalPages - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        
        _tipsController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        
        _startAutoScroll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();
    final user = _authService.getCurrentUser();
    
    // Use the passed display name if available, otherwise try to get it from Firebase
    String name = widget.displayName ?? user?.displayName ?? 'User';
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $name',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Be',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  WidgetSpan(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF69B4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Safe',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              // Show menu options
              showMenu(
                context: context,
                position: const RelativeRect.fromLTRB(100, 80, 0, 0),
                items: [
                  PopupMenuItem(
                    child: const Text(
                      'Profile',
                      style: TextStyle(color: Colors.black),
                    ),
                    onTap: () async {
                      // We need to add a delay because the menu is closing
                      await Future.delayed(Duration.zero);
                      if (!context.mounted) return;
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                      );
                      // If profile was updated successfully, refresh the display name
                      if (result == true) {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          final userData = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .get();
                          if (userData.exists && mounted) {
                            setState(() {
                              // Update the name variable to reflect changes
                              name = userData['name'] ?? 'User';
                            });
                          }
                        }
                      }
                    },
                  ),
                  PopupMenuItem(
                    child: const Text(
                      'Emergency Contacts',
                      style: TextStyle(color: Colors.black),
                    ),
                    onTap: () async {
                      await Future.delayed(Duration.zero);
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmergencyContactsScreen(),
                        ),
                      );
                    },
                  ),
                  PopupMenuItem(
                    child: const Text(
                      'About',
                      style: TextStyle(color: Colors.black),
                    ),
                    onTap: () async {
                      await Future.delayed(Duration.zero);
                      if (!context.mounted) return;
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.black,
                            title: const Text(
                              'About BeSafe',
                              style: TextStyle(
                                color: Color(0xFFFF69B4),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: const Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BeSafe is your personal safety companion, designed to provide quick access to emergency services and safety features.',
                                  style: TextStyle(color: Colors.white),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Version: 1.0.0',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Close',
                                  style: TextStyle(color: Color(0xFFFF69B4)),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  PopupMenuItem(
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.black),
                    ),
                    onTap: () async {
                      await _authService.signOut();
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tips Carousel
              SizedBox(
                height: 200,
                child: PageView(
                  controller: _tipsController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildTipCard('Self Defense Tips', 'assets/self_defense.jpg'),
                    _buildTipCard('Safety Tips', 'assets/safety_tips.jpg'),
                    _buildTipCard('Emergency Procedures', 'assets/emergency.jpg'),
                    _buildTipCard('Health Tips', 'assets/health.jpg'),
                    _buildTipCard('Security Tips', 'assets/security.jpg'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Page indicator and counter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Emergency Contacts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFFFF69B4)),
                        onPressed: () => _showAddContactDialog(context),
                      ),
                    ],
                  ),
                  Text(
                    '${_currentPage + 1}/$_totalPages',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Emergency Contacts
              SizedBox(
                height: 120,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .collection('emergency_contacts')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFFFF69B4)),
                      );
                    }

                    final contacts = snapshot.data!.docs;
                    if (contacts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'No emergency contacts added',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => _showAddContactDialog(context),
                              child: const Text(
                                'Add Contact',
                                style: TextStyle(color: Color(0xFFFF69B4)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index].data() as Map<String, dynamic>;
                        final name = contact['name'] ?? '';
                        final phone = contact['phone'] ?? '';
                        
                        return GestureDetector(
                          onTap: () async {
                            if (phone.isNotEmpty) {
                              final url = Uri.parse('tel:$phone');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              } else {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not make phone call')),
                                );
                              }
                            }
                          },
                          onLongPress: () => _showDeleteContactDialog(context, contacts[index].id),
                          child: Container(
                            width: 150,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF69B4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  phone,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Essential Services
              const Text(
                'Essential Services',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Services Icons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildServiceIcon(
                      Icons.location_on,
                      'Police Stations',
                      const Color(0xFFFF69B4),
                    ),
                    _buildServiceIcon(
                      Icons.local_hospital,
                      'Hospitals',
                      Colors.red,
                    ),
                    _buildServiceIcon(
                      Icons.local_gas_station,
                      'Petrol Pump',
                      Colors.orange,
                    ),
                    _buildServiceIcon(
                      Icons.people,
                      'Shared Locations',
                      Colors.blue,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Bottom Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavButton(Icons.home, 'Home', true),
                  _buildSOSButton(),
                  _buildNavButton(Icons.location_on, 'Track Me', false),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTipCard(String title, String imagePath) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.white, size: 40),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildServiceIcon(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () async {
        if (label == 'Police Stations') {
          await _openNearbyPoliceStations();
        } else if (label == 'Hospitals') {
          await _openNearbyHospitals();
        } else if (label == 'Petrol Pump') {
          await _openNearbyPetrolPumps();
        } else if (label == 'Shared Locations') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SharedLocationsScreen(),
            ),
          );
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _openNearbyPoliceStations() async {
    try {
      // Request location permission
      final status = await Permission.location.request();
      if (status.isDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required')),
        );
        return;
      }

      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finding nearby police stations...')),
      );

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Create Google Maps URL for nearby police stations
      final url = Uri.parse(
        'https://www.google.com/maps/search/police+station/@${position.latitude},${position.longitude},14z',
      );

      // Open Google Maps
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error accessing location')),
      );
    }
  }

  Future<void> _openNearbyHospitals() async {
    try {
      // Request location permission
      final status = await Permission.location.request();
      if (status.isDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required')),
        );
        return;
      }

      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finding nearby hospitals...')),
      );

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Create Google Maps URL for nearby hospitals
      final url = Uri.parse(
        'https://www.google.com/maps/search/hospital/@${position.latitude},${position.longitude},14z',
      );

      // Open Google Maps
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error accessing location')),
      );
    }
  }

  Future<void> _openNearbyPetrolPumps() async {
    try {
      // Request location permission
      final status = await Permission.location.request();
      if (status.isDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required')),
        );
        return;
      }

      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finding nearby petrol pumps...')),
      );

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Create Google Maps URL for nearby petrol pumps
      final url = Uri.parse(
        'https://www.google.com/maps/search/petrol+pump/@${position.latitude},${position.longitude},14z',
      );

      // Open Google Maps
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error accessing location')),
      );
    }
  }
  
  Widget _buildNavButton(IconData icon, String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (label == 'Track Me') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TrackMeScreen()),
          );
        }
      },
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
  
  Widget _buildSOSButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFF69B4), width: 2),
        borderRadius: BorderRadius.circular(50),
      ),
      child: const Text(
        'SOS',
        style: TextStyle(
          color: Color(0xFFFF69B4),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAddContactDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String phone = '';

    // Check if user has reached the limit
    final contacts = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('emergency_contacts')
        .get();

    if (contacts.docs.length >= 5) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 emergency contacts allowed')),
      );
      return;
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            'Add Emergency Contact',
            style: TextStyle(
              color: Color(0xFFFF69B4),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFF69B4)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    name = value ?? '';
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFF69B4)),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    phone = value ?? '';
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .collection('emergency_contacts')
                        .add({
                          'name': name,
                          'phone': phone,
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                    
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Emergency contact added successfully')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error adding emergency contact')),
                    );
                  }
                }
              },
              child: const Text(
                'Add',
                style: TextStyle(color: Color(0xFFFF69B4)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteContactDialog(BuildContext context, String contactId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            'Delete Contact',
            style: TextStyle(
              color: Color(0xFFFF69B4),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to remove this contact from emergency contacts?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .collection('emergency_contacts')
                      .doc(contactId)
                      .delete();
                  
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact removed successfully')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error removing contact')),
                  );
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
} 