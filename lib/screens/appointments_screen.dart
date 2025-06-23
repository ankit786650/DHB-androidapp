import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Initialize Supabase
const supabaseUrl = 'https://lnybxilouatjribioujv.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxueWJ4aWxvdWF0anJpYmlvdWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkyMDU4MTksImV4cCI6MjA2NDc4MTgxOX0.86A7FEkUHsmphPS8LyHoOr3ZtkGlaGw1sQJrOoWI1LQ';

final supabase = Supabase.instance.client;

class Appointment {
  final String? id;
  final String patientName;
  final String patientId;
  final String doctorName;
  final String specialization;
  final String type;
  final DateTime date;
  final String time;
  final String location;
  final String duration;
  final String notes;
  final String badge;
  final String userId;

  Appointment({
    this.id,
    required this.patientName,
    required this.patientId,
    required this.doctorName,
    required this.specialization,
    required this.type,
    required this.badge,
    required this.date,
    required this.time,
    required this.location,
    required this.duration,
    required this.notes,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'patient_name': patientName,
      'patient_id': patientId,
      'doctor_name': doctorName,
      'specialization': specialization,
      'type': type,
      'badge': badge,
      'date': date.toIso8601String(),
      'time': time,
      'location': location,
      'duration': duration,
      'notes': notes,
      'user_id': userId,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      patientName: map['patient_name'] ?? '',
      patientId: map['patient_id'] ?? '',
      doctorName: map['doctor_name'] ?? '',
      specialization: map['specialization'] ?? '',
      type: map['type'] ?? '',
      badge: map['badge'] ?? '',
      date: DateTime.parse(map['date']),
      time: map['time'] ?? '',
      location: map['location'] ?? '',
      duration: map['duration'] ?? '',
      notes: map['notes'] ?? '',
      userId: map['user_id'] ?? '',
    );
  }
}

class AppointementsScreen extends StatefulWidget {
  const AppointementsScreen({super.key});

  @override
  State<AppointementsScreen> createState() => _AppointementsScreenState();
}

class _AppointementsScreenState extends State<AppointementsScreen> {
  List<Appointment> appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeSupabase();
    _loadAppointments();
  }

  Future<void> _initializeSupabase() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  }

  Future<void> _loadAppointments() async {
    try {
      setState(() => _isLoading = true);
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: true);

      if (response.isEmpty) {
        setState(() {
          appointments = [];
          _isLoading = false;
        });
        return;
      }

      setState(() {
        appointments = (response as List)
            .map((appt) => Appointment.fromMap(appt))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading appointments: $e')),
        );
      }
    }
  }

  // Generate the next patient id in serial order
  Future<String> _getNextPatientId() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return "1";
    // Get all patient_ids, convert to int, and get max
    final response = await supabase
        .from('appointments')
        .select('patient_id')
        .eq('user_id', userId)
        .order('patient_id', ascending: true);

    final ids = (response as List)
        .map((e) => int.tryParse(e['patient_id'] ?? "") ?? 0)
        .where((id) => id > 0)
        .toList();

    if (ids.isEmpty) return "1";
    final nextId = (ids.reduce((a, b) => a > b ? a : b)) + 1;
    return nextId.toString();
  }

  Future<bool> _patientIdExists(String patientId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;
    final response = await supabase
        .from('appointments')
        .select('id')
        .eq('user_id', userId)
        .eq('patient_id', patientId);
    return (response as List).isNotEmpty;
  }

  Future<void> _saveAppointment(Appointment appointment) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      if (appointment.id == null) {
        // Create new appointment
        await supabase.from('appointments').insert(appointment.toMap());
      } else {
        // Update existing appointment
        await supabase
            .from('appointments')
            .update(appointment.toMap())
            .eq('id', appointment.id!);
      }
      await _loadAppointments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving appointment: $e')),
        );
      }
    }
  }

  Future<void> _deleteAppointment(String id) async {
    try {
      await supabase.from('appointments').delete().eq('id', id);
      await _loadAppointments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting appointment: $e')),
        );
      }
    }
  }

  void _showScheduleDialog({Appointment? editAppointment}) async {
    // If editing, pass the patientId as-is.
    // If new, generate a patient id and check uniqueness.
    final userId = supabase.auth.currentUser?.id ?? '';
    String? autoPatientId;
    if (editAppointment == null) {
      autoPatientId = await _getNextPatientId();
    }

    final result = await showDialog<Appointment>(
      context: context,
      builder: (_) => ScheduleAppointmentDialog(
        appointment: editAppointment,
        autoPatientId: autoPatientId,
        checkPatientIdExists: _patientIdExists,
      ),
    );

    if (result != null && mounted) {
      await _saveAppointment(result);
    }
  }

  void _confirmDelete(int index) {
    final appointment = appointments[index];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Appointment"),
        content: const Text("Are you sure you want to delete this appointment?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (appointment.id != null) {
                await _deleteAppointment(appointment.id!);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appt, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient info row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green[100],
                  radius: 19,
                  child: Text(
                    appt.patientName.isNotEmpty
                        ? appt.patientName.split(" ").map((e) => e[0]).take(2).join()
                        : "PT",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    appt.patientName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Text(
                  appt.patientId,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),
            // Doctor and badge
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  radius: 19,
                  child: Text(
                    appt.doctorName.split(" ").map((e) => e[0]).take(2).join(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appt.doctorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(appt.specialization, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    appt.badge,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Date, time, location, duration
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(DateFormat('MMMM d, yyyy').format(appt.date), style: const TextStyle(fontSize: 13)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(appt.time, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(appt.duration, style: const TextStyle(fontSize: 13)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(appt.location, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Notes
            Text("Notes:", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
            Text(appt.notes, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            // Edit/Delete row
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  onPressed: () {
                    _showScheduleDialog(
                      editAppointment: appt,
                    );
                  },
                  tooltip: "Edit",
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () {
                    _confirmDelete(index);
                  },
                  tooltip: "Delete",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).padding;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: Appointments + Schedule Button
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Appointments",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () => _showScheduleDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text("Schedule New Appointment"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            // Your Appointments
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    "Your Appointments",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    "${appointments.length} appointments total",
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            // List of appointments (scrollable)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: insets.bottom + 12,
                          ),
                          child: Column(
                            children: [
                              ...appointments.asMap().entries.map(
                                    (entry) => _buildAppointmentCard(entry.value, entry.key),
                                  ),
                              if (appointments.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 40),
                                  child: Text(
                                    "No appointments yet.",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScheduleAppointmentDialog extends StatefulWidget {
  final Appointment? appointment;
  final String? autoPatientId;
  final Future<bool> Function(String patientId)? checkPatientIdExists;
  const ScheduleAppointmentDialog({super.key, this.appointment, this.autoPatientId, this.checkPatientIdExists});

  @override
  State<ScheduleAppointmentDialog> createState() => _ScheduleAppointmentDialogState();
}

class _ScheduleAppointmentDialogState extends State<ScheduleAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _patientIdController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  String _type = '';
  DateTime? _date;
  TimeOfDay? _time;
  String _duration = '';
  String? _patientIdError;
  bool _checkingPatientId = false;

  static const types = [
    "Follow-up",
    "Routine Checkup",
    "Initial Consultation",
    "Emergency",
  ];
  static const durations = [
    "30 min",
    "45 min",
    "1 hour",
    "2 hours",
  ];

  @override
  void initState() {
    super.initState();
    if (widget.appointment != null) {
      final appt = widget.appointment!;
      _patientNameController.text = appt.patientName;
      _patientIdController.text = appt.patientId;
      _doctorNameController.text = appt.doctorName;
      _specializationController.text = appt.specialization;
      _type = appt.type;
      _date = appt.date;
      _time = _parseTime(appt.time);
      _locationController.text = appt.location;
      _duration = appt.duration;
      _notesController.text = appt.notes;
    } else if (widget.autoPatientId != null) {
      _patientIdController.text = widget.autoPatientId!;
      // Check if new patientId exists
      _checkPatientIdUnique(widget.autoPatientId!);
    }
  }

  TimeOfDay? _parseTime(String time) {
    try {
      final parts = time.split(":");
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  Future<void> _checkPatientIdUnique(String id) async {
    if (widget.appointment != null || widget.checkPatientIdExists == null) {
      setState(() => _patientIdError = null);
      return;
    }
    setState(() {
      _checkingPatientId = true;
      _patientIdError = null;
    });
    final exists = await widget.checkPatientIdExists!(id);
    setState(() {
      _patientIdError = exists ? "This Patient ID is already taken." : null;
      _checkingPatientId = false;
    });
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientIdController.dispose();
    _doctorNameController.dispose();
    _specializationController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    DateTime now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 2),
    );
    setState(() {
      _date = picked;
    });
  }

  void _pickTime() async {
    TimeOfDay now = TimeOfDay.now();
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _time ?? now,
    );
    if (picked != null) {
      setState(() {
        _time = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.appointment == null ? "Schedule New Appointment" : "Edit Appointment",
                        style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),
                // Patient Info
                const Text(
                  "Patient Information",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                isWide
                    ? Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _patientNameController,
                              decoration: const InputDecoration(
                                labelText: "Patient Name",
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? "Enter patient name" : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _patientIdController,
                              enabled: false, // Patient ID is always auto-generated and cannot be edited
                              decoration: InputDecoration(
                                labelText: "Patient ID",
                                border: const OutlineInputBorder(),
                                suffixIcon: _checkingPatientId
                                    ? const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2)),
                                      )
                                    : _patientIdError != null
                                        ? const Icon(Icons.error, color: Colors.red)
                                        : null,
                                errorText: _patientIdError,
                              ),
                              onChanged: (v) {
                                if (v.isNotEmpty) {
                                  _checkPatientIdUnique(v);
                                }
                              },
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          TextFormField(
                            controller: _patientNameController,
                            decoration: const InputDecoration(
                              labelText: "Patient Name",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? "Enter patient name" : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _patientIdController,
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: "Patient ID",
                              border: const OutlineInputBorder(),
                              suffixIcon: _checkingPatientId
                                  ? const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2)),
                                    )
                                  : _patientIdError != null
                                      ? const Icon(Icons.error, color: Colors.red)
                                      : null,
                              errorText: _patientIdError,
                            ),
                            onChanged: (v) {
                              if (v.isNotEmpty) {
                                _checkPatientIdUnique(v);
                              }
                            },
                          ),
                        ],
                      ),
                const SizedBox(height: 18),

                // Doctor Info
                const Text(
                  "Doctor Information",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                isWide
                    ? Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _doctorNameController,
                              decoration: const InputDecoration(
                                labelText: "Doctor Name",
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? "Enter doctor name" : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _specializationController,
                              decoration: const InputDecoration(
                                labelText: "Specialization",
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? "Enter specialization" : null,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          TextFormField(
                            controller: _doctorNameController,
                            decoration: const InputDecoration(
                              labelText: "Doctor Name",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? "Enter doctor name" : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _specializationController,
                            decoration: const InputDecoration(
                              labelText: "Specialization",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? "Enter specialization" : null,
                          ),
                        ],
                      ),
                const SizedBox(height: 12),
                isWide
                    ? Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                labelText: "Location",
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? "Enter location" : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: "Duration",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              value: _duration.isEmpty ? null : _duration,
                              items: durations
                                  .map((d) => DropdownMenuItem(
                                        value: d,
                                        child: Text(d),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                setState(() {
                                  _duration = v ?? '';
                                });
                              },
                              validator: (v) =>
                                  v == null || v.isEmpty ? "Select duration" : null,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              labelText: "Location",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? "Enter location" : null,
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: "Duration",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            value: _duration.isEmpty ? null : _duration,
                            items: durations
                                .map((d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _duration = v ?? '';
                              });
                            },
                            validator: (v) =>
                                v == null || v.isEmpty ? "Select duration" : null,
                          ),
                        ],
                      ),
                const SizedBox(height: 18),

                // Appointment Info
                const Text(
                  "Appointment Information",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                isWide
                    ? Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: "Appointment Type",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              value: _type.isEmpty ? null : _type,
                              items: types
                                  .map((type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                setState(() {
                                  _type = v ?? '';
                                });
                              },
                              validator: (v) =>
                                  v == null || v.isEmpty ? "Select type" : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickDate,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: "Appointment Date",
                                    hintText: "dd/mm/yyyy",
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.calendar_today),
                                    isDense: true,
                                  ),
                                  controller: TextEditingController(
                                    text: _date == null
                                        ? ""
                                        : DateFormat('dd/MM/yyyy').format(_date!),
                                  ),
                                  validator: (v) =>
                                      _date == null ? "Select date" : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: "Appointment Type",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            value: _type.isEmpty ? null : _type,
                            items: types
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _type = v ?? '';
                              });
                            },
                            validator: (v) =>
                                v == null || v.isEmpty ? "Select type" : null,
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _pickDate,
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: "Appointment Date",
                                  hintText: "dd/mm/yyyy",
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                  isDense: true,
                                ),
                                controller: TextEditingController(
                                  text: _date == null
                                      ? ""
                                      : DateFormat('dd/MM/yyyy').format(_date!),
                                ),
                                validator: (v) =>
                                    _date == null ? "Select date" : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickTime,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Appointment Time",
                        hintText: "--:--",
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                        isDense: true,
                      ),
                      controller: TextEditingController(
                        text: _time == null
                            ? ""
                            : _time!.format(context),
                      ),
                      validator: (v) =>
                          _time == null ? "Select time" : null,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Notes
                const Text(
                  "Notes",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Notes",
                    hintText: "Enter any relevant notes about the visit...",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate() &&
                            _date != null &&
                            _time != null &&
                            _type.isNotEmpty &&
                            _duration.isNotEmpty &&
                            _patientIdError == null) {
                          final userId = supabase.auth.currentUser?.id ?? '';
                          Navigator.pop(
                            context,
                            Appointment(
                              id: widget.appointment?.id,
                              patientName: _patientNameController.text,
                              patientId: _patientIdController.text,
                              doctorName: _doctorNameController.text,
                              specialization: _specializationController.text,
                              type: _type,
                              badge: _type,
                              date: _date!,
                              time: _time!.format(context),
                              location: _locationController.text,
                              duration: _duration,
                              notes: _notesController.text,
                              userId: userId,
                            ),
                          );
                        }
                      },
                      child: Text(widget.appointment == null ? "Schedule Visit" : "Save Changes"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}