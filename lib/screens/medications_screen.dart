import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'notification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

// Initialize Supabase
Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: 'https://lnybxilouatjribioujv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxueWJ4aWxvdWF0anJpYmlvdWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkyMDU4MTksImV4cCI6MjA2NDc4MTgxOX0.86A7FEkUHsmphPS8LyHoOr3ZtkGlaGw1sQJrOoWI1LQ',
  );
}

class MedicationReminder {
  final String id;
  final String name;
  final String dosage;
  final String dosageForm;
  final String frequency;
  final List<TimeOfDay> times;
  final DateTime startDate;
  final int? durationValue;
  final String? durationUnit;
  final bool playSound;
  final String? prescriptionImageUrl;

  MedicationReminder({
    required this.id,
    required this.name,
    required this.dosage,
    required this.dosageForm,
    required this.frequency,
    required this.times,
    required this.startDate,
    this.durationValue,
    this.durationUnit,
    this.playSound = true,
    this.prescriptionImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'dosage_form': dosageForm,
      'frequency': frequency,
      'times': times.map((t) => '${t.hour}:${t.minute}').toList(),
      'start_date': startDate.toIso8601String(),
      'duration_value': durationValue,
      'duration_unit': durationUnit,
      'play_sound': playSound,
      'prescription_image_url': prescriptionImageUrl,
    };
  }

  factory MedicationReminder.fromMap(Map<String, dynamic> map) {
    return MedicationReminder(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      dosageForm: map['dosage_form'] ?? '',
      frequency: map['frequency'] ?? '',
      times: (map['times'] as List).map((t) {
        final parts = t.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).toList().cast<TimeOfDay>(),
      startDate: DateTime.parse(map['start_date']),
      durationValue: map['duration_value'],
      durationUnit: map['duration_unit'],
      playSound: map['play_sound'] ?? true,
      prescriptionImageUrl: map['prescription_image_url'],
    );
  }
}

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  List<MedicationReminder> _reminders = [];
  late final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  DateTime? _selectedDate;
  final List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 9, minute: 0)];
  String _selectedDosageForm = 'Tablet';
  String _selectedFrequency = 'Once a day';
  String _selectedDurationUnit = 'Days';
  bool _playAlarmSound = true;
  bool _isLoading = false;

  final List<String> _dosageForms = [
    'Tablet',
    'Capsule',
    'Liquid',
    'Injection',
    'Cream',
    'Syrup',
    'Other',
  ];
  final List<String> _frequencies = [
    'Once a day',
    'Twice a day',
    'Thrice a day',
    'Every 4 hours',
    'Every 6 hours',
    'Every 8 hours',
    'Every 12 hours',
    'As needed',
  ];
  final List<String> _durationUnits = ['Days', 'Weeks', 'Months', 'Years'];

  XFile? _pickedFile;

  static const String geminiApiKey = 'AIzaSyCGUPuCxjiiojit9xryCYMcR7bswO0A8eU';

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _startDateController.dispose();
    _durationController.dispose();
    _pickedFile = null;
    super.dispose();
  }

  Future<void> _loadMedications() async {
    try {
      setState(() => _isLoading = true);
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('medications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (!mounted) return;
      
      setState(() {
        _reminders = (response as List).map<MedicationReminder>((med) => MedicationReminder.fromMap(med)).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading medications: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _addTime() => setState(() => _selectedTimes.add(TimeOfDay.now()));

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _startDateController.text = DateFormat('MMM dd, yyyy').format(date);
      });
    }
  }

  Future<void> _setAlarms(MedicationReminder reminder) async {
    for (int i = 0; i < reminder.times.length; i++) {
      final time = reminder.times[i];
      DateTime alarmTime = DateTime(
        reminder.startDate.year,
        reminder.startDate.month,
        reminder.startDate.day,
        time.hour,
        time.minute,
      );
      if (alarmTime.isBefore(DateTime.now())) {
        alarmTime = alarmTime.add(const Duration(days: 1));
      }
      await NotificationService().scheduleNotification(
        id: _reminders.length * 100 + i,
        title: 'Time to take ${reminder.name}!',
        body: 'Dosage: ${reminder.dosage} of ${reminder.dosageForm}',
        scheduledDate: alarmTime,
        playSound: reminder.playSound,
        payload: '', UILocalNotificationDateInterpretation: null,
      );
    }
  }

  Future<void> _saveMedicationToSupabase(MedicationReminder reminder) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('medications')
          .insert(reminder.toMap())
          .select()
          .single();

      final savedMedication = MedicationReminder.fromMap(response);
      
      if (!mounted) return;
      
      setState(() {
        _reminders.insert(0, savedMedication);
      });
      
      await _setAlarms(savedMedication);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medication saved successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving medication: $e')),
      );
      rethrow;
    }
  }

  Future<String?> _uploadPrescriptionImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      final filePath = 'prescriptions/$fileName';

      await _supabase.storage
          .from('prescriptions')
          .uploadBinary(filePath, bytes);

      return _supabase.storage
          .from('prescriptions')
          .getPublicUrl(filePath);
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading prescription: $e')),
      );
      return null;
    }
  }

  Future<void> _extractPrescriptionDetails(XFile pickedImage) async {
    try {
      setState(() => _isLoading = true);
      String? imageUrl;
      try {
        imageUrl = await _uploadPrescriptionImage(pickedImage);
      } catch (e) {
        debugPrint('Error uploading image: $e');
      }

      final bytes = await pickedImage.readAsBytes();
      final base64Image = base64Encode(bytes);

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$geminiApiKey',
      );

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "inlineData": {"mimeType": "image/jpeg", "data": base64Image},
              },
              {
                "text":
                    "You are given a photo of a doctor's prescription. Extract all prescribed medicines with their complete details as structured JSON. For each medicine, extract: name, dosage/strength (e.g. 16mg, 1 tab, 1 cap), form (e.g. Tab, Cap, Syrup, Inj), frequency (e.g. TDS, BD, OD, QID, etc), duration (if present). Return a JSON array, each item like: {\"name\": \"\", \"dosage\": \"\", \"form\": \"\", \"frequency\": \"\", \"duration\": \"\"}. If a field is not present, output an empty string for that field. Only output the JSON.",
              },
            ],
          },
        ],
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        String? content = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        
        if (content != null) {
          final jsonPattern = RegExp(r'\[.*\]', dotAll: true);
          final match = jsonPattern.firstMatch(content);
          
          if (match != null) {
            final jsonExtract = match.group(0)!;
            final List meds = jsonDecode(jsonExtract);
            bool anyMedicinesAdded = false;
            
            for (var med in meds) {
              try {
                final String name = med['name']?.toString() ?? '';
                final String dosage = med['dosage']?.toString() ?? '';
                final String form = med['form']?.toString() ?? 'Tablet';
                final String frequency = med['frequency']?.toString() ?? 'Once a day';
                final String duration = med['duration']?.toString() ?? '';
                
                if (name.isEmpty || dosage.isEmpty) continue;

                List<TimeOfDay> times = _getTimesFromFrequency(frequency);

                MedicationReminder reminder = MedicationReminder(
                  id: '', // Will be assigned by Supabase
                  name: name,
                  dosage: dosage,
                  dosageForm: form,
                  frequency: frequency,
                  times: times,
                  startDate: DateTime.now(),
                  durationValue: duration.isNotEmpty ? int.tryParse(duration) : null,
                  durationUnit: duration.isNotEmpty ? 'Days' : null,
                  playSound: true,
                  prescriptionImageUrl: imageUrl,
                );
                
                await _saveMedicationToSupabase(reminder);
                anyMedicinesAdded = true;
              } catch (e) {
                debugPrint('Error processing medicine: $e');
              }
            }
            
            if (!mounted) return;
            
            if (anyMedicinesAdded) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Prescription processed successfully!')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No valid medicines found in the prescription.')),
              );
            }
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing prescription: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<TimeOfDay> _getTimesFromFrequency(String freq) {
    switch (freq.toUpperCase()) {
      case 'TDS': return [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 14, minute: 0), TimeOfDay(hour: 20, minute: 0)];
      case 'BD': return [TimeOfDay(hour: 9, minute: 0), TimeOfDay(hour: 21, minute: 0)];
      case 'OD': return [TimeOfDay(hour: 9, minute: 0)];
      case 'QID': return [TimeOfDay(hour: 7, minute: 0), TimeOfDay(hour: 12, minute: 0), TimeOfDay(hour: 17, minute: 0), TimeOfDay(hour: 21, minute: 0)];
      default: return [TimeOfDay(hour: 9, minute: 0)];
    }
  }

  Future<void> _scanPrescriptionOrUpload() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.deepPurple),
                title: const Text('Scan Prescription (Camera)'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndProcessImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file, color: Colors.deepPurple),
                title: const Text('Upload Document (Gallery)'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndProcessImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked == null) return;
    
    setState(() => _pickedFile = picked);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Processing prescription...')),
    );
    await _extractPrescriptionDetails(picked);
  }

  void _openReminderForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 5,
                blurRadius: 10,
              ),
            ],
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 20),
                  width: 60,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text(
                          "New Medication",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildFormField(
                          controller: _nameController,
                          label: 'Medication Name',
                          icon: Icons.medical_services_outlined,
                          validator: (value) => value!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 15),
                        _buildFormField(
                          controller: _dosageController,
                          label: 'Dosage',
                          icon: Icons.science_outlined,
                          validator: (value) => value!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 15),
                        _buildDropdown(
                          value: _selectedDosageForm,
                          items: _dosageForms,
                          label: 'Dosage Form',
                          icon: Icons.category,
                          onChanged: (value) => setState(() => _selectedDosageForm = value!),
                        ),
                        const SizedBox(height: 15),
                        _buildDropdown(
                          value: _selectedFrequency,
                          items: _frequencies,
                          label: 'Frequency',
                          icon: Icons.repeat,
                          onChanged: (value) => setState(() => _selectedFrequency = value!),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Reminder Times",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._selectedTimes.asMap().entries.map(
                          (entry) => _buildTimeInput(entry.key, entry.value),
                        ),
                        TextButton.icon(
                          onPressed: _addTime,
                          icon: const Icon(Icons.add_circle, color: Colors.deepPurple),
                          label: const Text(
                            "Add Another Time",
                            style: TextStyle(color: Colors.deepPurple),
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildFormField(
                          controller: _startDateController,
                          label: 'Start Date',
                          icon: Icons.calendar_today,
                          readOnly: true,
                          onTap: () => _pickDate(context),
                          validator: (value) => value!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildFormField(
                                controller: _durationController,
                                label: 'Duration',
                                icon: Icons.timer,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value!.isNotEmpty && int.tryParse(value) == null) {
                                    return 'Invalid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 1,
                              child: _buildDropdown(
                                value: _selectedDurationUnit,
                                items: _durationUnits,
                                label: 'Unit',
                                onChanged: (value) => setState(() => _selectedDurationUnit = value!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        SwitchListTile(
                          title: const Text('Play Alarm Sound'),
                          value: _playAlarmSound,
                          onChanged: (value) => setState(() => _playAlarmSound = value),
                          secondary: Icon(
                            _playAlarmSound ? Icons.volume_up : Icons.volume_off,
                            color: Colors.deepPurple,
                          ),
                          activeColor: Colors.deepPurple,
                        ),
                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate() && _selectedDate != null) {
                                final reminder = MedicationReminder(
                                  id: '',
                                  name: _nameController.text,
                                  dosage: _dosageController.text,
                                  dosageForm: _selectedDosageForm,
                                  frequency: _selectedFrequency,
                                  times: List.from(_selectedTimes),
                                  startDate: _selectedDate!,
                                  durationValue: int.tryParse(_durationController.text),
                                  durationUnit: _durationController.text.isNotEmpty
                                      ? _selectedDurationUnit
                                      : null,
                                  playSound: _playAlarmSound,
                                );
                                
                                await _saveMedicationToSupabase(reminder);
                                if (!mounted) return;
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please fill all required fields'),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              "Save Medication",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String label,
    IconData? icon,
    required void Function(String?)? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.deepPurple) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTimeInput(int index, TimeOfDay time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.access_time, color: Colors.deepPurple),
        title: Text(
          "Time ${index + 1}: ${time.format(context)}",
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.deepPurple),
              onPressed: () async {
                TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: time,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Colors.deepPurple,
                          onPrimary: Colors.white,
                          onSurface: Colors.black,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _selectedTimes[index] = picked;
                  });
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  if (_selectedTimes.length > 1) {
                    _selectedTimes.removeAt(index);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Must have at least one time slot'),
                      ),
                    );
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 180.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text('Medication Reminder',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.deepPurple[700]!,
                            Colors.deepPurple[400]!,
                          ],
                        ),
                      ),
                    ),
                  ),
                  backgroundColor: Colors.deepPurple,
                  shape: const ContinuousRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _buildActionButtons(),
                        const SizedBox(height: 30),
                        if (_reminders.isNotEmpty) 
                          _buildRemindersHeader(),
                      ],
                    ),
                  ),
                ),
                if (_reminders.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/no_meds.png', height: 150),
                          const SizedBox(height: 20),
                          Text(
                            "No reminders yet!",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Add your first medication reminder",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final reminder = _reminders[index];
                        return _buildReminderCard(reminder);
                      },
                      childCount: _reminders.length,
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openReminderForm,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add),
        label: const Text("Add Reminder"),
        elevation: 4,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _scanPrescriptionOrUpload,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Scan Rx",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: InkWell(
            onTap: () {
              _scanPrescriptionOrUpload();
            },
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.upload, color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Upload Rx",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemindersHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.medication, color: Colors.deepPurple),
        ),
        const SizedBox(width: 10),
        const Text(
          "Your Medications",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const Spacer(),
        Text(
          "${_reminders.length} ${_reminders.length == 1 ? 'item' : 'items'}",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildReminderCard(MedicationReminder reminder) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          // Implement edit functionality
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getMedicationColor(reminder.name),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.medication, color: Colors.white),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${reminder.dosage} ${reminder.dosageForm}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showReminderOptions(reminder);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildDetailRow(Icons.schedule, "Frequency", reminder.frequency),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.access_time,
                "Times",
                reminder.times.map((t) => t.format(context)).join(', '),
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.calendar_today,
                "Start Date",
                DateFormat('MMM dd, yyyy').format(reminder.startDate),
              ),
              if (reminder.durationValue != null && reminder.durationUnit != null)
                Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.timer,
                      "Duration",
                      "${reminder.durationValue} ${reminder.durationUnit}",
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: reminder.playSound
                          ? Colors.green[50]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          reminder.playSound ? Icons.volume_up : Icons.volume_off,
                          size: 16,
                          color: reminder.playSound
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          reminder.playSound ? "Sound On" : "Sound Off",
                          style: TextStyle(
                            fontSize: 12,
                            color: reminder.playSound
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (reminder.prescriptionImageUrl != null)
                    TextButton.icon(
                      onPressed: () {
                        // Show prescription image
                      },
                      icon: const Icon(Icons.image, size: 16),
                      label: const Text("View Rx"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.deepPurple),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getMedicationColor(String name) {
    // Generate a consistent color based on medication name
    final colors = [
      Colors.deepPurple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.teal,
    ];
    return colors[name.hashCode % colors.length];
  }

  void _showReminderOptions(MedicationReminder reminder) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  reminder.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Reminder'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement edit functionality
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Reminder'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteReminder(reminder);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_off, color: Colors.orange),
                title: const Text('Disable Alarms'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement disable alarms
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text('Share Details'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement share functionality
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteReminder(MedicationReminder reminder) async {
    try {
      setState(() => _isLoading = true);
      await _supabase
          .from('medications')
          .delete()
          .eq('id', reminder.id);

      if (!mounted) return;
      
      setState(() {
        _reminders.removeWhere((r) => r.id == reminder.id);
      });
      
      // Cancel all related notifications
      for (int i = 0; i < reminder.times.length; i++) {
        await NotificationService().cancelNotification(
          _reminders.length * 100 + i);
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medication reminder deleted'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting reminder: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }
}

extension on NotificationService {
  Future<void> cancelNotification(int i) async {}
}