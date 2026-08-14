import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/models/mar_medication.dart';
import 'package:admin_app/models/mar_suggestion.dart';
import 'package:admin_app/services/mar_service.dart';

class MarSuggestionsScreen extends StatefulWidget {
  const MarSuggestionsScreen({super.key});

  @override
  State<MarSuggestionsScreen> createState() => _MarSuggestionsScreenState();
}

class _MarSuggestionsScreenState extends State<MarSuggestionsScreen> {
  final _service = MarService(Supabase.instance.client);
  List<MarSuggestion> _suggestions = [];
  bool _isLoading = true;
  String _filterStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);
    try {
      final suggestions = await _service.getSuggestions(
        status: _filterStatus == 'all' ? null : _filterStatus,
      );
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading suggestions: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _approveSuggestion(MarSuggestion suggestion) async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Suggestion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to approve this suggestion?'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Review Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        await _service.approveSuggestion(
          suggestion.id!,
          reviewedBy: user?.id ?? '',
          reviewedByName: user?.email?.split('@').first ?? 'Admin',
          reviewNotes: notesController.text.trim().isNotEmpty
              ? notesController.text.trim()
              : null,
        );
        _loadSuggestions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Suggestion approved'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _rejectSuggestion(MarSuggestion suggestion) async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Suggestion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to reject this suggestion?'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Review Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        await _service.rejectSuggestion(
          suggestion.id!,
          reviewedBy: user?.id ?? '',
          reviewedByName: user?.email?.split('@').first ?? 'Admin',
          reviewNotes: notesController.text.trim().isNotEmpty
              ? notesController.text.trim()
              : null,
        );
        _loadSuggestions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Suggestion rejected'), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      case 'stop':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'create':
        return Icons.add_circle;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'stop':
        return Icons.stop_circle;
      default:
        return Icons.help;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'create':
        return 'New Medication';
      case 'update':
        return 'Change Medication';
      case 'delete':
        return 'Remove Medication';
      case 'stop':
        return 'Stop Medication';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Suggestions'),
        backgroundColor: const Color(0xFF1976D2),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) {
              setState(() => _filterStatus = v);
              _loadSuggestions();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'approved', child: Text('Approved')),
              const PopupMenuItem(value: 'rejected', child: Text('Rejected')),
              const PopupMenuItem(value: 'all', child: Text('All')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _suggestions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        _filterStatus == 'pending'
                            ? 'No pending suggestions'
                            : 'No suggestions found',
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSuggestions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      return _buildSuggestionCard(_suggestions[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildSuggestionCard(MarSuggestion suggestion) {
    final typeColor = _getTypeColor(suggestion.suggestionType);
    final isPending = suggestion.status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isPending ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPending
            ? BorderSide(color: typeColor.withOpacity(0.5), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: typeColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getTypeIcon(suggestion.suggestionType),
                          size: 16, color: typeColor),
                      const SizedBox(width: 4),
                      Text(
                        _getTypeLabel(suggestion.suggestionType),
                        style: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _buildStatusBadge(suggestion.status),
              ],
            ),
            const SizedBox(height: 12),

            // Service user
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(suggestion.serviceUserName ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),

            // Medication details
            if (suggestion.medicationName != null) ...[
              Row(
                children: [
                  const Icon(Icons.medication, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      suggestion.medicationName!,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            // Dosage info
            if (suggestion.dosage != null)
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text(
                  '${suggestion.dosage}${suggestion.dosageUnit != null ? ' ${suggestion.dosageUnit}' : ''}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ),

            // Frequency
            if (suggestion.frequency != null)
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text(
                  'Frequency: ${FrequencyHelper.labels[suggestion.frequency!] ?? suggestion.frequency}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ),

            // Special instructions
            if (suggestion.specialInstructions != null)
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text(
                  'Instructions: ${suggestion.specialInstructions}',
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                ),
              ),

            const SizedBox(height: 8),

            // Reason
            if (suggestion.suggestionReason != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reason:',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(suggestion.suggestionReason!,
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Suggested by
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Suggested by ${suggestion.suggestedByName}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  suggestion.suggestedAt != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(suggestion.suggestedAt!)
                      : '',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),

            // Review info (if already reviewed)
            if (!isPending && suggestion.reviewedByName != null) ...[
              const Divider(),
              Row(
                children: [
                  Icon(Icons.check_circle,
                      size: 14,
                      color: suggestion.status == 'approved'
                          ? Colors.green
                          : Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    'Reviewed by ${suggestion.reviewedByName}',
                    style: TextStyle(
                        color: suggestion.status == 'approved'
                            ? Colors.green
                            : Colors.red,
                        fontSize: 12),
                  ),
                  if (suggestion.reviewedAt != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM/yyyy').format(suggestion.reviewedAt!),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ],
              ),
              if (suggestion.reviewNotes != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Notes: ${suggestion.reviewNotes}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
            ],

            // Action buttons (only for pending)
            if (isPending) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _rejectSuggestion(suggestion),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _approveSuggestion(suggestion),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    switch (status) {
      case 'approved':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 14, color: Colors.green),
              SizedBox(width: 4),
              Text('Approved',
                  style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ],
          ),
        );
      case 'rejected':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cancel, size: 14, color: Colors.red),
              SizedBox(width: 4),
              Text('Rejected',
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ],
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_empty, size: 14, color: Colors.orange),
              SizedBox(width: 4),
              Text('Pending',
                  style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ],
          ),
        );
    }
  }
}
