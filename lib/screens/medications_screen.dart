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
  List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 9, minute: 0)];
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
        payload: '',
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
                leading: const Icon(Icons.photo_camera),
                title: const Text('Scan Prescription (Camera)'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndProcessImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
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
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Add New Medication Reminder",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Medication Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          prefixIcon: Icon(Icons.medical_services_outlined),
                        ),
                        validator: (value) => value!.isEmpty
                            ? 'Medication name is required'
                            : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _dosageController,
                        decoration: const InputDecoration(
                          labelText: 'Dosage (e.g., 250mg, 1 tablet)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          prefixIcon: Icon(Icons.science_outlined),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Dosage is required' : null,
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _selectedDosageForm,
                        decoration: const InputDecoration(
                          labelText: 'Dosage Form',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _dosageForms.map((form) {
                          return DropdownMenuItem(
                            value: form,
                            child: Text(form),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() {
                            _selectedDosageForm = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _selectedFrequency,
                        decoration: const InputDecoration(
                          labelText: 'Frequency',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          prefixIcon: Icon(Icons.repeat),
                        ),
                        items: _frequencies.map((freq) {
                          return DropdownMenuItem(
                            value: freq,
                            child: Text(freq),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() {
                            _selectedFrequency = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Timings",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._selectedTimes.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.deepPurple[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title: Text(
                                "Time ${entry.key + 1}: ${entry.value.format(context)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.deepPurple,
                                ),
                                onPressed: () async {
                                  TimeOfDay? picked = await showTimePicker(
                                    context: context,
                                    initialTime: entry.value,
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      _selectedTimes[entry.key] = picked;
                                    });
                                  }
                                },
                              ),
                              leading: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setModalState(() {
                                    if (_selectedTimes.length > 1) {
                                      _selectedTimes.removeAt(entry.key);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Must have at least one time slot.'),
                                        ),
                                      );
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              _addTime();
                            });
                          },
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.deepPurple,
                          ),
                          label: const Text(
                            "Add Another Time",
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _startDateController,
                        readOnly: true,
                        onTap: () => _pickDate(context),
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Start date is required' : null,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _durationController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Duration',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                ),
                                prefixIcon: Icon(Icons.timer),
                              ),
                              validator: (value) {
                                if (value!.isNotEmpty && int.tryParse(value) == null) {
                                  return 'Enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value: _selectedDurationUnit,
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                ),
                              ),
                              items: _durationUnits.map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setModalState(() {
                                  _selectedDurationUnit = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      SwitchListTile(
                        title: const Text('Play Alarm Sound'),
                        value: _playAlarmSound,
                        onChanged: (bool value) {
                          setModalState(() {
                            _playAlarmSound = value;
                          });
                        },
                        secondary: Icon(
                          _playAlarmSound ? Icons.volume_up : Icons.volume_off,
                        ),
                        activeTrackColor: Colors.deepPurple,
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate() && _selectedDate != null) {
                              final reminder = MedicationReminder(
                                id: '', // Will be assigned by Supabase
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
                                  content: Text('Please fill all required fields and select a start date.'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                "Save Reminder",
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // FIX: build method must match 'Widget build(BuildContext context)' signature
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    "💊 Medication Reminder",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _nameController.clear();
                            _dosageController.clear();
                            _startDateController.clear();
                            _durationController.clear();
                            _selectedDate = null;
                            _selectedTimes = [const TimeOfDay(hour: 9, minute: 0)];
                            _selectedDosageForm = 'Tablet';
                            _selectedFrequency = 'Once a day';
                            _selectedDurationUnit = 'Days';
                            _playAlarmSound = true;
                            _openReminderForm();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          ),
                          // Removed: elevation here (not valid for ElevatedButton.styleFrom in newer Flutter)
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_alarm, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                "Add Reminder",
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _scanPrescriptionOrUpload,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          ),
                          // Removed: elevation here (not valid for ElevatedButton.styleFrom in newer Flutter)
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                "Scan/Upload Rx",
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  if (_reminders.isNotEmpty)
                    Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "📝 Saved Reminders",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        ..._reminders.map(
                          (reminder) => Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.medication,
                                        color: Colors.deepPurple,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          reminder.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(color: Colors.deepPurpleAccent),
                                  Text(
                                    "Dosage: ${reminder.dosage} (${reminder.dosageForm})",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "Frequency: ${reminder.frequency}",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "Time(s): ${reminder.times.map((t) => t.format(context)).join(', ')}\nStart Date: ${DateFormat('MMM dd, yyyy').format(reminder.startDate)}",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (reminder.durationValue != null && reminder.durationUnit != null)
                                    Text(
                                      "Duration: ${reminder.durationValue} ${reminder.durationUnit}",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "Alarm Sound: ${reminder.playSound ? 'On' : 'Off'}",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (reminder.prescriptionImageUrl != null)
                                    TextButton(
                                      onPressed: () {
                                        // Implement prescription image viewer
                                      },
                                      child: const Text('View Prescription'),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_reminders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          "No reminders set yet. Add one above! 😊",
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}