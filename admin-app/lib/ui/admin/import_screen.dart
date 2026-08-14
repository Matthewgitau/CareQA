import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/services/supabase_auth_service.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final List<_ImportFile> _selectedFiles = [];
  bool _isMixed = false;
  bool _isImporting = false;
  String? _jobId;
  List<Map<String, dynamic>> _assets = [];
  bool _isLoadingAssets = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding Import'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Import your existing data',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload staff, service user, and daily note files. Data is parsed and reviewed before being saved.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Category selector
            const Text('Import Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'staff', child: Text('Staff Files')),
                DropdownMenuItem(value: 'service_users', child: Text('Service Users')),
                DropdownMenuItem(value: 'daily_notes', child: Text('Daily Notes')),
              ],
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),

            // Mixed files toggle
            SwitchListTile(
              title: const Text('My files are all mixed together'),
              subtitle: const Text('Enable if you have multiple document types in one folder'),
              value: _isMixed,
              onChanged: (v) => setState(() => _isMixed = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),

            // File upload zone
            _buildUploadZone(),
            const SizedBox(height: 16),

            // Selected files list
            if (_selectedFiles.isNotEmpty) ...[
              const Text('Files to upload', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._selectedFiles.map((f) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description),
                title: Text(f.name),
                subtitle: Text(f.category),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedFiles.remove(f)),
                ),
              )),
              const SizedBox(height: 16),
            ],

            // Upload button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedFiles.isEmpty || _isImporting ? null : _startImport,
                icon: _isImporting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload),
                label: Text(_isImporting ? 'Importing...' : 'Import ${_selectedFiles.length} Files'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            if (_jobId != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Import Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Job ID: $_jobId'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadAssets,
                child: const Text('Refresh Status'),
              ),
            ],

            if (_assets.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Review & Confirm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._assets.map((asset) => Card(
                child: ListTile(
                  title: Text(asset['original_filename']?.toString() ?? 'Unknown file'),
                  subtitle: Text('Status: ${asset['status']}'),
                  trailing: asset['status'] == 'pending'
                      ? ElevatedButton(
                          onPressed: () => _importAsset(asset),
                          child: const Text('Import'),
                        )
                      : null,
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  String _category = 'staff';

  Widget _buildUploadZone() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: InkWell(
        onTap: _pickFiles,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 8),
            Text('Drag & drop files here or tap to browse',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text('PDF, DOCX, CSV, XLSX supported',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    // Placeholder for file picker - in production use file_picker package
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Files'),
        content: const Text('File picker placeholder. In production, this opens the file browser.'),
        actions: [
          TextButton(
            onPressed: () {
              // Simulate adding a file
              setState(() {
                _selectedFiles.add(_ImportFile(
                  name: 'sample_${_selectedFiles.length + 1}.pdf',
                  category: _category,
                ));
              });
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _startImport() async {
    setState(() => _isImporting = true);
    try {
      final auth = Provider.of<SupabaseAuthService>(context, listen: false);
      final user = Supabase.instance.client.auth.currentUser;

      final response = await Supabase.instance.client
          .from('imports')
          .insert({
            'category': _category,
            'status': 'in_progress',
            'total_files': _selectedFiles.length,
            'organisation_id': auth.organisationId ?? '',
            'user_id': user?.id,
          })
          .select()
          .single();

      setState(() {
        _jobId = response['id'] as String;
        _isImporting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import job started!')),
      );
    } catch (e) {
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadAssets() async {
    final jobId = _jobId;
    if (jobId == null) return;
    setState(() => _isLoadingAssets = true);
    try {
      final response = await Supabase.instance.client
          .from('imported_assets')
          .select()
          .eq('import_id', jobId);
      setState(() {
        _assets = List<Map<String, dynamic>>.from(response);
        _isLoadingAssets = false;
      });
    } catch (e) {
      setState(() => _isLoadingAssets = false);
    }
  }

  Future<void> _importAsset(Map<String, dynamic> asset) async {
    try {
      final auth = Provider.of<SupabaseAuthService>(context, listen: false);
      final parsedData = asset['parsed_data'] as Map<String, dynamic>? ?? {};

      // Generate UUID and insert into target table
      // This is a placeholder - production would map fields to the correct table
      await Supabase.instance.client
          .from(asset['target_table']?.toString() ?? 'carers')
          .insert({
            ...parsedData,
            'organisation_id': auth.organisationId ?? '',
          });

      await Supabase.instance.client
          .from('imported_assets')
          .update({'status': 'imported'})
          .eq('id', asset['id']);

      setState(() => _loadAssets());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record imported successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

class _ImportFile {
  final String name;
  final String category;
  const _ImportFile({required this.name, required this.category});
}