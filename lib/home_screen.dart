import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:DHB/screens/dashboard_screen.dart';
import 'package:DHB/screens/nearby_facilities_screen.dart';
import 'package:DHB/screens/medications_screen.dart';
import 'package:DHB/screens/appointments_screen.dart';
import 'package:DHB/screens/upload_document.dart';
import 'package:DHB/screens/health_qr_screen.dart';
import 'package:DHB/screens/monitor_analytics_screen.dart';
import 'package:DHB/ai/ai_agent.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final AIAgent _aiAgent;
  String _agentFeedback = '';
  bool _isAgentActive = false;
  bool _isAgentInitialized = false;
  Timer? _feedbackTimer;

  // Home, Meds, Docs, Appointments, Nearby
  final List<Widget> _tabs = [
    const DashboardScreen(),
    const MedicationScreen(),
    const UploadDocumentScreen(),
    const AppointementsScreen(),
    const NearbyFacilitiesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAgent();
  }

  Future<void> _initializeAgent() async {
    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        throw Exception('Microphone permission denied');
      }

      _aiAgent = AIAgent(
        onNavigate: _handleNavigation,
        onFeedback: _handleFeedback,
        onLogout: () {},
        onShowAnalytics: _showAnalytics,
        onShowHealthQR: _showHealthQR,
      );

      await _aiAgent.initialize();

      if (mounted) {
        setState(() => _isAgentInitialized = true);

        final prefs = await SharedPreferences.getInstance();
        final isFirstLaunch = prefs.getBool('first_launch') ?? true;

        if (isFirstLaunch) {
          await prefs.setBool('first_launch', false);
          _toggleAgent();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Assistant initialization failed: $e')),
        );
      }
    }
  }

  void _handleNavigation(int index) {
    if (mounted) {
      setState(() => _selectedIndex = index);
    }
  }

  void _handleFeedback(String feedback) {
    _feedbackTimer?.cancel();
    setState(() => _agentFeedback = feedback);

    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _agentFeedback = '');
      }
    });
  }

  void _showAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MonitorAnalyticsScreen()),
    );
  }

  void _showHealthQR() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HealthQrScreen(qrData: '')),
    );
  }

  Future<void> _toggleAgent() async {
    if (!_isAgentInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assistant still initializing')));
      return;
    }

    if (!await Permission.microphone.request().isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone access is required')));
      return;
    }

    setState(() => _isAgentActive = !_isAgentActive);
    _aiAgent.setAgentActive(_isAgentActive);
  }

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  void _openHealthQRScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HealthQrScreen(qrData: '')),
    );
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _aiAgent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ----- CUSTOM HEADER -----
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(width: 1.0, color: Color(0xFFE9ECF3)),
            ),
          ),
          padding: const EdgeInsets.only(left: 16, right: 12, top: 18, bottom: 8),
          child: Row(
            children: [
              // Logo
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE9F1FF),
                ),
                padding: const EdgeInsets.all(5),
                child: const Icon(Icons.health_and_safety,
                  color: Color(0xff2261C6), size: 22),
              ),
              const SizedBox(width: 8),
              const Text(
                "MyHealth",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Color(0xff1A1D23),
                  letterSpacing: 0.1,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xff818A99)),
                onPressed: () {},
                tooltip: 'Notifications',
              ),
              IconButton(
                icon: const Icon(Icons.mic_none_rounded, color: Color(0xff818A99)),
                onPressed: _toggleAgent,
                tooltip: _isAgentActive ? 'Turn Off Assistant' : 'Turn On Assistant',
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9ECF3),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('K', // Replace with actual user initial
                      style: TextStyle(
                        color: Color(0xff5A5A5A),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
      // ----- MAIN BODY -----
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _tabs,
          ),
          if (_agentFeedback.isNotEmpty)
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _agentFeedback,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      // ----- BOTTOM NAVIGATION BAR -----
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
        selectedItemColor: const Color(0xff2261C6),
        unselectedItemColor: const Color(0xff818A99),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 28),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined, size: 26),
            label: "Meds",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined, size: 26),
            label: "Docs",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today, size: 26),
            label: "Appointments",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on, size: 26),
            label: "Nearby",
          ),
        ],
      ),
    );
  }
}

extension on AIAgent {
  void setAgentActive(bool isAgentActive) {}
}