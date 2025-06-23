import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MedicalDocument {
  final String title;
  final String type;
  final String status;
  final String tag;
  final String doctorName;
  final String doctorDept;
  final DateTime date;
  final String size;
  final String initials;

  MedicalDocument({
    required this.title,
    required this.type,
    required this.status,
    required this.tag,
    required this.doctorName,
    required this.doctorDept,
    required this.date,
    required this.size,
    required this.initials,
  });
}

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  List<MedicalDocument> documents = [
    MedicalDocument(
      title: "Comprehensive Blood Test",
      type: "Lab Report",
      status: "Verified",
      tag: "Lab Report",
      doctorName: "Dr. Priya Sharma",
      doctorDept: "Cardiology",
      date: DateTime(2025, 5, 15),
      size: "245 KB",
      initials: "DPS",
    ),
    MedicalDocument(
      title: "Medication List",
      type: "Prescription",
      status: "Verified",
      tag: "Prescription",
      doctorName: "Dr. Priya Sharma",
      doctorDept: "Cardiology",
      date: DateTime(2025, 5, 15),
      size: "128 KB",
      initials: "DPS",
    ),
    MedicalDocument(
      title: "Chest X-Ray Scan",
      type: "Imaging",
      status: "Pending",
      tag: "Imaging",
      doctorName: "Dr. Priya Sharma",
      doctorDept: "Cardiology",
      date: DateTime(2025, 5, 15),
      size: "1.2 MB",
      initials: "DPS",
    ),
    MedicalDocument(
      title: "MRI Scan Results",
      type: "Imaging Report",
      status: "Verified",
      tag: "Imaging Report",
      doctorName: "Dr. Rohan Mehra",
      doctorDept: "Neurology",
      date: DateTime(2025, 4, 20),
      size: "3.5 MB",
      initials: "DRM",
    ),
    MedicalDocument(
      title: "Diabetes Management",
      type: "Treatment Plan",
      status: "Verified",
      tag: "Treatment Plan",
      doctorName: "Dr. Ananya Reddy",
      doctorDept: "Endocrinology",
      date: DateTime(2025, 5, 5),
      size: "220 KB",
      initials: "DAR",
    ),
    MedicalDocument(
      title: "Blood Sugar Log",
      type: "Patient Record",
      status: "Pending",
      tag: "Patient Record",
      doctorName: "Dr. Ananya Reddy",
      doctorDept: "Endocrinology",
      date: DateTime(2025, 5, 5),
      size: "128 KB",
      initials: "DAR",
    ),
  ];

  String selectedType = 'All Types';
  String selectedStatus = 'All Status';

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (_) => UploadDocumentDialog(
        onDocumentUploaded: (MedicalDocument doc) {
          setState(() {
            documents.insert(0, doc);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final types = [
      'All Types',
      'Lab Report',
      'Prescription',
      'Medical Imaging',
      'Consultation Notes',
      'Discharge Summary',
      'Vaccination Document',
      'Insurance Document',
      'Other',
    ];
    final statuses = [
      'All Status',
      'Verified',
      'Pending',
    ];

    List<MedicalDocument> filtered = documents.where((doc) {
      final matchType = selectedType == 'All Types' || doc.type == selectedType || doc.tag == selectedType;
      final matchStatus = selectedStatus == 'All Status' || doc.status == selectedStatus;
      return matchType && matchStatus;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Text(
                "Medical Documents",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[900]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
              child: Text(
                "Securely store and manage all your medical records in one place",
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ),
            // Combined Filters + Upload Button Row
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // All Types Dropdown
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedType,
                        isDense: true,
                        style: const TextStyle(fontSize: 15, color: Colors.black87),
                        items: types.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => selectedType = v ?? 'All Types'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // All Status Dropdown
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        isDense: true,
                        style: const TextStyle(fontSize: 15, color: Colors.black87),
                        items: statuses.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(s, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => selectedStatus = v ?? 'All Status'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Upload Button
                    SizedBox(
                      height: 42,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.upload_file, size: 19),
                        label: const Text("Upload"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        onPressed: _showUploadDialog,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(thickness: 1),
            // Vertical, scrollable cards list
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) => _buildDocCard(filtered[idx]),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDocCard(MedicalDocument doc) {
    Color statusColor = doc.status == 'Verified'
        ? Colors.green[100]!
        : doc.status == 'Pending'
            ? Colors.amber[100]!
            : Colors.grey[200]!;

    Color statusTextColor = doc.status == 'Verified'
        ? Colors.green[700]!
        : doc.status == 'Pending'
            ? Colors.orange[700]!
            : Colors.grey[700]!;

    IconData icon = doc.type == 'Prescription'
        ? Icons.receipt_long
        : doc.type.contains('Imaging')
            ? Icons.image
            : Icons.insert_drive_file;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon & status
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[50],
                  radius: 22,
                  child: Icon(icon, color: Colors.blue[800]),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    doc.status,
                    style: TextStyle(
                      color: statusTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              doc.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              doc.tag,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blueGrey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const Divider(height: 18),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[200],
                  child: Text(
                    doc.initials,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.doctorName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(doc.doctorDept, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 15, color: Colors.grey[400]),
                const SizedBox(width: 3),
                Text(DateFormat('MMM d, yyyy').format(doc.date), style: const TextStyle(fontSize: 13)),
                const Spacer(),
                Icon(Icons.insert_drive_file, size: 15, color: Colors.grey[400]),
                const SizedBox(width: 3),
                Text(doc.size, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Upload Document Dialog
class UploadDocumentDialog extends StatefulWidget {
  final void Function(MedicalDocument) onDocumentUploaded;
  const UploadDocumentDialog({super.key, required this.onDocumentUploaded});

  @override
  State<UploadDocumentDialog> createState() => _UploadDocumentDialogState();
}

class _UploadDocumentDialogState extends State<UploadDocumentDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _fileName;
  String _docType = '';
  DateTime _docDate = DateTime.now();
  final _titleController = TextEditingController();
  final _doctorController = TextEditingController();
  String _visitReason = '';
  static const docTypes = [
    "Lab Report",
    "Prescription",
    "Medical Imaging",
    "Consultation Notes",
    "Discharge Summary",
    "Vaccination Document",
    "Insurance Document",
    "Other"
  ];
  static const reasonOptions = [
    "Routine Checkup",
    "Follow-up",
    "Diagnosis",
    "Treatment",
    "Other"
  ];

  void _fakePickFile() async {
    setState(() {
      _fileName = "blood_test_result.pdf";
    });
  }

  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _docDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    setState(() {
      _docDate = picked!;
    });
    }

  void _submit() {
    if (_formKey.currentState!.validate() && _fileName != null && _docType.isNotEmpty) {
      widget.onDocumentUploaded(
        MedicalDocument(
          title: _titleController.text,
          type: _docType,
          status: "Pending",
          tag: _docType,
          doctorName: _doctorController.text.isEmpty ? "Unknown" : _doctorController.text,
          doctorDept: "",
          date: _docDate,
          size: "1.1 MB",
          initials: _doctorController.text.isEmpty
              ? "UNK"
              : _doctorController.text.split(" ").map((e) => e[0]).take(3).join().toUpperCase(),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    const Expanded(
                      child: Text(
                        "Hi Kishan, please fill it",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  "Provide details for the document you are uploading. Accepted formats: JPG, PDF, PNG (max 10MB).",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 18),
                // File Picker
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Document File", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _fakePickFile,
                          child: const Text("Choose File"),
                        ),
                        Expanded(
                          child: Text(
                            _fileName == null ? "No file chosen" : _fileName!,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Document Type",
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  value: _docType.isEmpty ? null : _docType,
                  items: docTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _docType = v ?? ''),
                  validator: (v) => v == null || v.isEmpty ? "Select document type" : null,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Document Date",
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      controller: TextEditingController(
                        text: DateFormat('MMMM d, yyyy').format(_docDate),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: "Document Title",
                    hintText: "e.g., Blood Test Report, X-Ray Left Knee",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? "Enter document title" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _doctorController,
                  decoration: const InputDecoration(
                    labelText: "Doctor Name (Optional)",
                    hintText: "e.g., Dr. Priya Sharma",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Visit Reason (Optional)",
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  value: _visitReason.isEmpty ? null : _visitReason,
                  items: reasonOptions
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _visitReason = v ?? ''),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_upload),
                      onPressed: _submit,
                      label: const Text("Upload & Save"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
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