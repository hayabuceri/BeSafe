import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';
import 'track_me_screen.dart';
import 'shared_locations_screen.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/sos_button.dart';
import 'self_defense_screen.dart';
import 'safety_tips_screen.dart';
import 'emergency_procedure_screen.dart';
import 'health_tips_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import '../models/emergency_contact.dart';
import 'emergency_contacts_screen.dart';
import '../widgets/app_menu.dart';

class HomeScreen extends StatefulWidget {
  final String? displayName;
  
  const HomeScreen({Key? key, this.displayName}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _tipsController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  @override
  void initState() {
    super.initState();
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
    String name = widget.displayName ?? user?.displayName ?? 'User';
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(
        actions: [
          AppMenu(
            onNameUpdate: (newName) {
              setState(() {
                name = newName;
              });
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
                    _buildTipCard('Emergency Procedures', 'assets/emergency_procedures.jpg'),
                    _buildTipCard('Health Tips', 'assets/health_tips.jpg'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFF69B4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF69B4).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning_rounded,
                            color: Color(0xFFFF69B4),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'SOS Emergency Feature',
                          style: TextStyle(
                            color: Color(0xFFFF69B4),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'How to use:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInstructionStep(
                      '1',
                      'Press the SOS button',
                    ),
                    _buildInstructionStep(
                      '2',
                      'Reconfirm the alert by pressing the Yes button',
                    ),
                    _buildInstructionStep(
                      '3',
                      'Your emergency contacts will be received your shared location',
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF69B4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFFFF69B4),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You can cancel the alert by select "No" option if triggered by mistake.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
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
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .collection('home_emergency_contacts')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final contactCount = snapshot.data?.docs.length ?? 0;
                          if (contactCount < 5) {
                            return IconButton(
                              icon: const Icon(Icons.add_circle, color: Color(0xFFFF69B4)),
                              onPressed: () => _showAddContactDialog(context),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .collection('home_emergency_contacts')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final contactCount = snapshot.data?.docs.length ?? 0;
                      return Text(
                        '$contactCount/5',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              SizedBox(
                height: 120,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .collection('home_emergency_contacts')
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
                        final contactData = contacts[index].data() as Map<String, dynamic>;
                        final contact = EmergencyContact.fromMap(contactData);
                        return _buildContactCard(contact);
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Essential Services',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 16),
              
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
  
  Widget _buildTipCard(String title, String imagePath) {
    return GestureDetector(
      onTap: () {
        if (title == 'Self Defense Tips') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SelfDefenseScreen()),
          );
        } else if (title == 'Safety Tips') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SafetyTipsScreen()),
          );
        } else if (title == 'Emergency Procedures') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EmergencyProcedureScreen()),
          );
        } else if (title == 'Health Tips') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HealthTipsScreen()),
          );
        }
      },
      child: Card(
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
      final status = await Permission.location.request();
      if (status.isDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required')),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finding nearby police stations...')),
      );

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final url = Uri.parse(
        'https://www.google.com/maps/search/police+station/@${position.latitude},${position.longitude},14z',
      );

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
      final status = await Permission.location.request();
      if (status.isDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required')),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finding nearby hospitals...')),
      );

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final url = Uri.parse(
        'https://www.google.com/maps/search/hospital/@${position.latitude},${position.longitude},14z',
      );

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
      final status = await Permission.location.request();
      if (status.isDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required')),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finding nearby petrol pumps...')),
      );

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final url = Uri.parse(
        'https://www.google.com/maps/search/petrol+pump/@${position.latitude},${position.longitude},14z',
      );

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
  
  void _showAddContactDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('home_emergency_contacts')
        .get()
        .then((snapshot) {
          if (snapshot.docs.length >= 5) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Maximum 5 emergency contacts allowed')),
            );
            return;
          }
          
          if (!context.mounted) return;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.black,
              title: const Text(
                'Add Emergency Contact',
                style: TextStyle(color: Color(0xFFFF69B4)),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
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
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
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
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        final contact = EmergencyContact(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text.trim(),
                          phone: phoneController.text.trim(),
                        );

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('home_emergency_contacts')
                            .doc(contact.id)
                            .set(contact.toMap());

                        if (!context.mounted) return;
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Color(0xFFFF69B4)),
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget _buildContactCard(EmergencyContact contact) {
    return Container(
      width: 160,
      height: 150,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFF69B4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.person_outline,
            color: Color(0xFFFF69B4),
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            contact.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            contact.phone,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () async {
                  final phoneNumber = contact.phone;
                  final url = Uri.parse('tel:$phoneNumber');
                  
                  try {
                    await launchUrl(url);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open phone dialer')),
                    );
                  }
                },
                child: const Icon(
                  Icons.phone,
                  color: Color(0xFFFF69B4),
                  size: 24,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.black,
                      title: const Text(
                        'Delete Contact',
                        style: TextStyle(color: Color(0xFFFF69B4)),
                      ),
                      content: Text(
                        'Are you sure you want to delete ${contact.name}?',
                        style: const TextStyle(color: Colors.white),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text(
                            'No',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Yes',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (shouldDelete == true) {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('home_emergency_contacts')
                          .doc(contact.id)
                          .delete();
                    }
                  }
                },
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF69B4).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFFFF69B4),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 