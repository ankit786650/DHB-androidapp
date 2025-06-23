import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:DHB/screens/nearby_facilities_screen.dart';
import 'package:DHB/screens/monitor_analytics_screen.dart';
import 'package:DHB/screens/health_qr_screen.dart';
import 'package:DHB/screens/medications_screen.dart';
import 'package:DHB/screens/appointments_screen.dart';

const supabaseUrl = 'https://lnybxilouatjribioujv.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxueWJ4aWxvdWF0anJpYmlvdWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkyMDU4MTksImV4cCI6MjA2NDc4MTgxOX0.86A7FEkUHsmphPS8LyHoOr3ZtkGlaGw1sQJrOoWI1LQ';

class UserMedication {
  final String id;
  final String name;
  final String dosage;
  final String dosageForm;
  final String time;
  final String frequency;

  UserMedication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.dosageForm,
    required this.time,
    required this.frequency,
  });

  factory UserMedication.fromMap(Map<String, dynamic> map) {
    return UserMedication(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      dosageForm: map['dosage_form'] ?? '',
      time: map['times'] is List && map['times'].isNotEmpty
          ? map['times'][0]
          : 'No time set',
      frequency: map['frequency'] ?? '',
    );
  }
}

class UserAppointment {
  final String id;
  final String doctorName;
  final String specialization;
  final DateTime date;
  final String time;
  final String location;
  final String type;
  final String badge;

  UserAppointment({
    required this.id,
    required this.doctorName,
    required this.specialization,
    required this.date,
    required this.time,
    required this.location,
    required this.type,
    required this.badge,
  });

  factory UserAppointment.fromMap(Map<String, dynamic> map) {
    return UserAppointment(
      id: map['id'] ?? '',
      doctorName: map['doctor_name'] ?? '',
      specialization: map['specialization'] ?? '',
      date: DateTime.parse(map['date']),
      time: map['time'] ?? '',
      location: map['location'] ?? '',
      type: map['type'] ?? '',
      badge: map['badge'] ?? '',
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final supabase = Supabase.instance.client;
  String userName = "Kishan";
  int medicationCount = 0;
  int appointmentCount = 0;
  bool isLoading = true;
  bool isLoadingMedications = false;
  bool isLoadingAppointments = false;
  List<UserMedication> userMedications = [];
  List<UserAppointment> userAppointments = [];

  // Mock documents
  final List<Map<String, String>> documents = [
    {"title": "Lab Results", "date": "07/15/2024"},
    {"title": "Insurance Card", "date": "06/20/2024"},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchUserMedications();
    _fetchUserAppointments();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => isLoading = true);
      final userId = supabase.auth.currentUser?.id;

      if (userId != null) {
        final profile = await supabase
            .from('profiles')
            .select('username')
            .eq('id', userId)
            .single();

        setState(() => userName = profile['username'] ?? 'Kishan');

        final apps = await supabase
            .from('appointments')
            .select('*')
            .eq('user_id', userId);

        setState(() => appointmentCount = apps.length);
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchUserMedications() async {
    try {
      setState(() => isLoadingMedications = true);
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('medications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        userMedications =
            response.map<UserMedication>((med) => UserMedication.fromMap(med)).toList();
        medicationCount = userMedications.length;
      });
    } catch (e) {
      debugPrint('Error fetching medications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load medications: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoadingMedications = false);
    }
  }

  Future<void> _fetchUserAppointments() async {
    try {
      setState(() => isLoadingAppointments = true);
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: true)
          .limit(2);

      setState(() {
        userAppointments = response
            .map<UserAppointment>((appt) => UserAppointment.fromMap(appt))
            .toList();
      });
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load appointments: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoadingAppointments = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7fc),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  const SizedBox(height: 12),
                  Text(
                    "Welcome back, $userName",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1a1a1a),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Your personal assistant for managing health.",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Features Section
                  _buildFeaturesSection(),
                  const SizedBox(height: 28),

                  // Upcoming Medications Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Upcoming Medications",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff1a1a1a),
                        ),
                      ),
                      InkWell(
                        onTap: () => _navigateToMedicationsScreen(context),
                        child: Text(
                          "View All",
                          style: TextStyle(
                            color: Color(0xff2d5bff),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  isLoadingMedications
                      ? const Center(child: CircularProgressIndicator())
                      : userMedications.isEmpty
                          ? _buildEmptyState('No medications added', Icons.medication)
                          : Column(
                              children: userMedications
                                  .take(3)
                                  .map(
                                    (med) => _buildMedicationItem(
                                      name: med.name,
                                      dosage: '${med.dosage}${med.dosageForm}',
                                      time: med.time,
                                      color: getMedColor(med.name),
                                    ),
                                  )
                                  .toList(),
                            ),
                  const SizedBox(height: 28),

                  // Appointments Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Appointments",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff1a1a1a),
                        ),
                      ),
                      InkWell(
                        onTap: () => _navigateToAppointmentsScreen(context),
                        child: Text(
                          "View All",
                          style: TextStyle(
                            color: Color(0xff2d5bff),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  isLoadingAppointments
                      ? const Center(child: CircularProgressIndicator())
                      : userAppointments.isEmpty
                          ? _buildEmptyState('No appointments scheduled', Icons.calendar_today)
                          : Column(
                              children: userAppointments
                                  .map((appt) => _buildAppointmentItem(appt: appt))
                                  .toList(),
                            ),
                  const SizedBox(height: 28),

                  // Documents Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Documents",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff1a1a1a),
                        ),
                      ),
                      InkWell(
                        onTap: () {},
                        child: Text(
                          "View All",
                          style: TextStyle(
                            color: Color(0xff2d5bff),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildDocumentsSection(documents),
                  const SizedBox(height: 28),

                  // Health Program Alerts Section
                  const Text(
                    "Health Program Alerts",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1a1a1a),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildHealthAlerts(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // Features grid based on the image
  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        crossAxisSpacing: 16,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _featureCard(
            icon: Icons.dashboard_customize,
            label: 'Dashboard',
            onTap: () {},
            color: const Color(0xff2d5bff),
          ),
          _featureCard(
            icon: Icons.calendar_month,
            label: 'Appointments',
            onTap: () => _navigateToAppointmentsScreen(context),
            color: const Color(0xff4f8fff),
          ),
          _featureCard(
            icon: Icons.monitor_heart,
            label: 'Monitor',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MonitorAnalyticsScreen())),
            color: const Color(0xff67c6e7),
          ),
          _featureCard(
            icon: Icons.qr_code_2,
            label: 'QR Code',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HealthQrScreen(qrData: '',))),
            color: const Color(0xffa37be7),
          ),
          _featureCard(
            icon: Icons.account_circle,
            label: 'Profile',
            onTap: () {},
            color: const Color(0xff7bda9b),
          ),
          _featureCard(
            icon: Icons.more_horiz,
            label: 'More',
            onTap: () {},
            color: const Color(0xfff7b731),
          ),
        ],
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xfff5f7fb),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xfff1f1f1)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xff212121),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationItem({
    required String name,
    required String dosage,
    required String time,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.19),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.medical_services_outlined,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xff1a1a1a),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dosage,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xff2d5bff),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem({required UserAppointment appt}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Calendar icon
          Container(
            decoration: BoxDecoration(
              color: const Color(0xfff5e9ff),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.event_note,
              color: Color(0xffa37be7),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appt.type.isNotEmpty ? appt.type : "Appointment",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xff1a1a1a),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  appt.doctorName.isNotEmpty ? "Dr. ${appt.doctorName}" : "",
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, yyyy').format(appt.date),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (appt.badge.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xfff6f7fb),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                appt.badge,
                style: const TextStyle(
                  color: Color(0xfff7b731),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xfff6f7fb),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                "Upcoming",
                style: TextStyle(
                  color: Color(0xfff7b731),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(List<Map<String, String>> docs) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: docs
            .map((doc) => _documentCard(
                  title: doc['title']!,
                  date: doc['date']!,
                  icon: doc['title'] == "Lab Results"
                      ? Icons.description_outlined
                      : Icons.credit_card_outlined,
                ))
            .toList(),
      ),
    );
  }

  Widget _documentCard({
    required String title,
    required String date,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xfff5f7fb),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: const Color(0xff4f8fff),
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xff1a1a1a),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          date,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthAlerts() {
    return Column(
      children: [
        _healthAlertCard(
          icon: Icons.campaign_outlined,
          iconColor: const Color(0xff34c759),
          bgColor: const Color(0xffeafaf1),
          title: "Local Health Camp: Free Diabetes Screening",
          description: "Main Street Community Hall, July 25th, 9 AM - 3 PM.",
          actionText: "Learn More & Register",
          actionColor: const Color(0xff34c759),
        ),
        const SizedBox(height: 14),
        _healthAlertCard(
          icon: Icons.new_releases_outlined,
          iconColor: const Color(0xfff7b731),
          bgColor: const Color(0xfffffae5),
          title: "New Subsidy for Mental Wellness Programs",
          description: "Eligible individuals can now apply for reduced-cost therapy sessions.",
          actionText: "Check Eligibility",
          actionColor: const Color(0xfff7b731),
        ),
      ],
    );
  }

  Widget _healthAlertCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String description,
    required String actionText,
    required Color actionColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  actionText,
                  style: TextStyle(
                    color: actionColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 12),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _navigateToMedicationsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MedicationScreen()),
    ).then((_) {
      _fetchUserMedications();
      _loadUserData();
    });
  }

  void _navigateToAppointmentsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AppointementsScreen()),
    ).then((_) {
      _loadUserData();
      _fetchUserAppointments();
    });
  }

  Color getMedColor(String medName) {
    if (medName.toLowerCase().contains('amox')) return const Color(0xff4f8fff);
    if (medName.toLowerCase().contains('ibu')) return const Color(0xffa37be7);
    if (medName.toLowerCase().contains('vitamin')) return const Color(0xff7bda9b);
    return const Color(0xff2d5bff);
  }
}