import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ------------------------------------------------------------
///  MODEL
/// ------------------------------------------------------------
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

/// ------------------------------------------------------------
///  MAIN SCREEN
/// ------------------------------------------------------------
class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  // ──────────────────────────────────────────────────────────
  //  Dummy data
  // ──────────────────────────────────────────────────────────
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
      size: "1.2 MB",
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
      size: "3.5 MB",
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
      size: "220 KB",
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
      size: "128 KB",
      initials: "DAR",
    ),
  ];

  // ──────────────────────────────────────────────────────────
  //  State for filters
  // ──────────────────────────────────────────────────────────
  final _types = [
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
  final _statuses = ['All Status', 'Verified', 'Pending'];

  String _selectedType = 'All Types';
  String _selectedStatus = 'All Status';

  // ──────────────────────────────────────────────────────────
  //  Helpers
  // ──────────────────────────────────────────────────────────
  void _openUploadDialog() {
    showDialog(
      context: context,
      builder: (_) => UploadDocumentDialog(onDocumentUploaded: (doc) {
        setState(() => documents.insert(0, doc));
      }),
    );
  }

  List<MedicalDocument> get _filteredDocs => documents.where((doc) {
        final typeOk = _selectedType == 'All Types' ||
            doc.type == _selectedType ||
            doc.tag == _selectedType;
        final statusOk =
            _selectedStatus == 'All Status' || doc.status == _selectedStatus;
        return typeOk && statusOk;
      }).toList();

  // ──────────────────────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: const Text(
          "Medical Documents",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded),
            tooltip: 'Upload',
            onPressed: _openUploadDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Subtitle
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
            child: Text(
              "Securely store and manage all your medical records in one place",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[700]),
            ),
          ),
          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: -4,
              children: [
                _buildFilterChip(
                    label: _selectedType,
                    onTap: () => _showTypeBottomSheet(context)),
                _buildFilterChip(
                    label: _selectedStatus,
                    onTap: () => _showStatusBottomSheet(context)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _filteredDocs.isEmpty
                ? Center(
                    child: Text(
                      "No documents found",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    itemCount: _filteredDocs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _DocCard(doc: _filteredDocs[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openUploadDialog,
        icon: const Icon(Icons.add),
        label: const Text("Upload"),
      ),
    );
  }

  /// modern rounded Filter chip
  Widget _buildFilterChip({required String label, required VoidCallback onTap}) {
    final isActive = !(label.startsWith('All '));

    return ActionChip(
      backgroundColor:
          isActive ? Colors.blue.shade100 : Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isActive ? Colors.blue.shade800 : Colors.grey.shade800,
        fontWeight: FontWeight.w600,
      ),
      avatar: const Icon(Icons.filter_list, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
      onPressed: onTap,
    );
  }

  void _showTypeBottomSheet(BuildContext ctx) {
    _showSelectSheet(
      ctx,
      title: "Select Document Type",
      items: _types,
      current: _selectedType,
      onSelect: (v) => setState(() => _selectedType = v),
    );
  }

  void _showStatusBottomSheet(BuildContext ctx) {
    _showSelectSheet(
      ctx,
      title: "Select Status",
      items: _statuses,
      current: _selectedStatus,
      onSelect: (v) => setState(() => _selectedStatus = v),
    );
  }

  void _showSelectSheet(
    BuildContext context, {
    required String title,
    required List<String> items,
    required String current,
    required Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Divider(),
            ...items.map(
              (item) => RadioListTile<String>(
                title: Text(item),
                value: item,
                groupValue: current,
                onChanged: (v) {
                  Navigator.pop(context);
                  onSelect(v!);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
///  DOCUMENT CARD (separated for clarity)
/// ------------------------------------------------------------
class _DocCard extends StatelessWidget {
  const _DocCard({required this.doc});

  final MedicalDocument doc;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final statusColor = switch (doc.status) {
      'Verified' => Colors.green.shade600,
      'Pending' => Colors.amber.shade700,
      _ => Colors.grey.shade600
    };

    final statusBG = statusColor.withOpacity(0.12);

    final iconData = switch (doc.type) {
      'Prescription' => Icons.receipt_long,
      _ when doc.type.contains('Imaging') => Icons.image,
      _ => Icons.insert_drive_file,
    };

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // first row
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: scheme.primary.withOpacity(0.15),
                  child: Icon(iconData, color: scheme.primary, size: 22),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBG,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    doc.status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(doc.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(doc.tag,
                style: TextStyle(
                    color: scheme.primary, fontWeight: FontWeight.w500)),
            const Divider(height: 20),
            // doctor row
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade200,
                  child: Text(doc.initials,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text("${doc.doctorName}  •  ${doc.doctorDept}",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // date & size row
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 15, color: Colors.grey),
                const SizedBox(width: 4),
                Text(DateFormat('MMM d, yyyy').format(doc.date),
                    style: const TextStyle(fontSize: 13)),
                const Spacer(),
                const Icon(Icons.storage_rounded,
                    size: 15, color: Colors.grey),
                const SizedBox(width: 4),
                Text(doc.size, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
///  UPLOAD DOCUMENT DIALOG
/// ------------------------------------------------------------
class UploadDocumentDialog extends StatefulWidget {
  const UploadDocumentDialog({super.key, required this.onDocumentUploaded});
  final void Function(MedicalDocument) onDocumentUploaded;

  @override
  State<UploadDocumentDialog> createState() => _UploadDocumentDialogState();
}

class _UploadDocumentDialogState extends State<UploadDocumentDialog> {
  final _formKey = GlobalKey<FormState>();

  // form state
  String? _fileName;
  String _docType = '';
  DateTime _docDate = DateTime.now();
  final _titleC = TextEditingController();
  final _doctorC = TextEditingController();
  String _visitReason = '';

  static const _docTypes = [
    "Lab Report",
    "Prescription",
    "Medical Imaging",
    "Consultation Notes",
    "Discharge Summary",
    "Vaccination Document",
    "Insurance Document",
    "Other"
  ];
  static const _reasonOptions = [
    "Routine Checkup",
    "Follow‑up",
    "Diagnosis",
    "Treatment",
    "Other"
  ];

  // ──────────────────────────────────────────────────────────
  //  Pickers (placeholder demo)
  // ──────────────────────────────────────────────────────────
  void _fakePickFile() {
    setState(() => _fileName = "blood_test_result.pdf");
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _docDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _docDate = picked);
  }

  // ──────────────────────────────────────────────────────────
  //  Submit
  // ──────────────────────────────────────────────────────────
  void _submit() {
    if (_formKey.currentState!.validate() &&
        _fileName != null &&
        _docType.isNotEmpty) {
      widget.onDocumentUploaded(
        MedicalDocument(
          title: _titleC.text,
          type: _docType,
          status: "Pending",
          tag: _docType,
          doctorName: _doctorC.text.isEmpty ? "Unknown" : _doctorC.text,
          doctorDept: '',
          date: _docDate,
          size: "1.1 MB",
          initials: _doctorC.text.isEmpty
              ? "UNK"
              : _doctorC.text
                  .split(" ")
                  .map((e) => e[0])
                  .take(3)
                  .join()
                  .toUpperCase(),
        ),
      );
      Navigator.pop(context);
    }
  }

  // ──────────────────────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // title row
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Upload medical document",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Accepted: JPG, PDF, PNG  •  Max 10 MB",
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
              ),
              const SizedBox(height: 24),
              // File picker
              OutlinedButton.icon(
                onPressed: _fakePickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(_fileName ?? "Choose file"),
              ),
              const SizedBox(height: 20),
              // Doc type
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: "Document type", border: OutlineInputBorder()),
                isExpanded: true,
                value: _docType.isEmpty ? null : _docType,
                items: _docTypes
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _docType = v ?? ''),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Select type' : null,
              ),
              const SizedBox(height: 18),
              // Date
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Document date",
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: DateFormat('MMMM d, yyyy').format(_docDate),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Title
              TextFormField(
                controller: _titleC,
                decoration: const InputDecoration(
                  labelText: "Title",
                  hintText: "e.g., MRI Brain, Blood Test",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 18),
              // Doctor
              TextFormField(
                controller: _doctorC,
                decoration: const InputDecoration(
                  labelText: "Doctor name (optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              // visit reason
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: "Visit reason (optional)",
                    border: OutlineInputBorder()),
                isExpanded: true,
                value: _visitReason.isEmpty ? null : _visitReason,
                items: _reasonOptions
                    .map((r) =>
                        DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _visitReason = v ?? ''),
              ),
              const SizedBox(height: 28),
              // buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text("Upload"),
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                        backgroundColor: scheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
