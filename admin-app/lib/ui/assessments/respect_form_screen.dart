import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class RespectFormScreen extends StatefulWidget {
  const RespectFormScreen({super.key});
  @override
  State<RespectFormScreen> createState() => _RespectFormScreenState();
}

class _RespectFormScreenState extends State<RespectFormScreen> {
  List<Map<String, dynamic>> _forms = [];
  bool _loading = true;
  String? _error;
  PlatformFile? _selectedFile;
  String? _fileName;
  String? _fileUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await Supabase.instance.client
          .from('respect_forms')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      setState(() {
        _forms = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
          _fileName = result.files.first.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null || _selectedFile!.path == null) return;

    setState(() => _uploading = true);
    try {
      final file = File(_selectedFile!.path!);
      final bytes = await file.readAsBytes();
      final fileName = 'respect_forms/${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.name}';

      // Upload to Supabase Storage
      await Supabase.instance.client.storage
          .from('documents')
          .uploadBinary(fileName, bytes);

      // Get public URL
      final publicUrl = Supabase.instance.client.storage
          .from('documents')
          .getPublicUrl(fileName);

      setState(() {
        _fileUrl = publicUrl;
        _uploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully')),
        );
      }
    } catch (e) {
      setState(() => _uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: $e')),
        );
      }
    }
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload ReSPECT Form'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedFile != null)
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(_fileName ?? 'Selected file'),
                subtitle: Text('${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB'),
              )
            else
              const Text('No file selected'),
            if (_uploading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.attach_file),
            label: const Text('Select File'),
          ),
          ElevatedButton.icon(
            onPressed: _selectedFile != null && !_uploading ? _uploadFile : null,
            icon: _uploading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_upload),
            label: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReSPECT Forms'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _forms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No ReSPECT forms found',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _forms.length,
                      itemBuilder: (_, i) {
                        final f = _forms[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF1565C0),
                              child: Icon(Icons.description, color: Colors.white),
                            ),
                            title: Text(f['service_user_name'] ?? 'Unknown'),
                            subtitle: Text(
                              'Created: ${(f['created_at'] ?? '').toString().split('T').first}',
                            ),
                            trailing: f['file_url'] != null
                                ? IconButton(
                                    icon: const Icon(Icons.download),
                                    onPressed: () {
                                      // Open or download the file
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Opening file...')),
                                      );
                                    },
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
    );
  }
}
