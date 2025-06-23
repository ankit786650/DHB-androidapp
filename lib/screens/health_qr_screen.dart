import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HealthQrScreen extends StatefulWidget {
  const HealthQrScreen({super.key, required String qrData});

  @override
  _HealthQrScreenState createState() => _HealthQrScreenState();
}

class _HealthQrScreenState extends State<HealthQrScreen> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  String fullName = '';
  String age = '';
  String phone = '';
  String bloodGroup = 'A+';
  String sex = 'Male';
  String genderIdentity = 'Cisgender';
  String address = '';
  String emergencyName = '';
  String emergencyPhone = '';
  String? qrData;
  bool _isLoading = false;
  List<Map<String, dynamic>> _savedQRCodes = [];

  static const List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  static const List<String> sexes = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _initializeSupabase();
    _loadSavedQRCodes();
  }

  Future<void> _initializeSupabase() async {
    await Supabase.initialize(
      url: 'https://lnybxilouatjribioujv.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxueWJ4aWxvdWF0anJpYmlvdWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkyMDU4MTksImV4cCI6MjA2NDc4MTgxOX0.86A7FEkUHsmphPS8LyHoOr3ZtkGlaGw1sQJrOoWI1LQ',
    );
  }

  Future<void> _loadSavedQRCodes() async {
    try {
      setState(() => _isLoading = true);
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('health_qr_codes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _savedQRCodes = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading saved QR codes: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveQRCodeToSupabase() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final data = {
      'full_name': fullName,
      'age': age,
      'phone': phone,
      'blood_group': bloodGroup,
      'sex': sex,
      'gender_identity': genderIdentity,
      'address': address,
      'emergency_name': emergencyName,
      'emergency_phone': emergencyPhone,
      'qr_data': qrData,
      'user_id': supabase.auth.currentUser?.id,
    };

    try {
      setState(() => _isLoading = true);
      await supabase.from('health_qr_codes').insert(data);
      await _loadSavedQRCodes();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving QR code: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void generateQr() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final data = {
      'Full Name': fullName,
      'Age': age,
      'Phone': phone,
      'Blood Group': bloodGroup,
      'Sex': sex,
      'Gender Identity': genderIdentity,
      'Address': address,
      'Emergency Contact Name': emergencyName,
      'Emergency Contact Phone': emergencyPhone,
    };

    setState(() {
      qrData = data.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    });
  }

  Future<void> _deleteQRCode(String id) async {
    try {
      setState(() => _isLoading = true);
      await supabase.from('health_qr_codes').delete().eq('id', id);
      await _loadSavedQRCodes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting QR code: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health QR Generator'),
        actions: [
          if (_savedQRCodes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => _showSavedQRCodesDialog(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField('Full Name', (v) => fullName = v!),
                        _buildTextField('Age', (v) => age = v!, inputType: TextInputType.number),
                        _buildTextField('Phone Number', (v) => phone = v!, inputType: TextInputType.phone),
                        _buildDropdown('Blood Group', bloodGroup, bloodGroups, (v) => bloodGroup = v!),
                        _buildDropdown('Sex', sex, sexes, (v) => sex = v!),
                        _buildTextField('Gender Identity', (v) => genderIdentity = v!),
                        _buildTextField('Address', (v) => address = v!, maxLines: 2),
                        _buildTextField('Emergency Contact Name', (v) => emergencyName = v!),
                        _buildTextField('Emergency Contact Phone', (v) => emergencyPhone = v!, inputType: TextInputType.phone),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.qr_code),
                                label: const Text('Generate QR'),
                                onPressed: generateQr,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.save),
                                label: const Text('Save QR'),
                                onPressed: qrData != null ? _saveQRCodeToSupabase : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (qrData != null) ...[
                    const SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            QrImageView(
                              data: qrData!,
                              version: QrVersions.auto,
                              size: 180.0,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Scan this code to view details',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('QR Code Data'),
                                    content: SingleChildScrollView(
                                      child: Text(qrData!),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text('View Data'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  void _showSavedQRCodesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saved QR Codes'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _savedQRCodes.length,
            itemBuilder: (context, index) {
              final qr = _savedQRCodes[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(qr['full_name'] ?? 'No Name'),
                  subtitle: Text(
                    'Created: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(qr['created_at']))}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteQRCode(qr['id']),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      qrData = qr['qr_data'];
                      fullName = qr['full_name'] ?? '';
                      age = qr['age'] ?? '';
                      phone = qr['phone'] ?? '';
                      bloodGroup = qr['blood_group'] ?? 'A+';
                      sex = qr['sex'] ?? 'Male';
                      genderIdentity = qr['gender_identity'] ?? '';
                      address = qr['address'] ?? '';
                      emergencyName = qr['emergency_name'] ?? '';
                      emergencyPhone = qr['emergency_phone'] ?? '';
                    });
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    FormFieldSetter<String> onSaved, {
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        keyboardType: inputType,
        maxLines: maxLines,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
        ),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String current,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InputDecorator(
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: current,
            isExpanded: true,
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}  


