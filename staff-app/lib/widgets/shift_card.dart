import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:staff_app/models/shift.dart';

class ShiftCard extends StatelessWidget {
  final Shift shift;
  final VoidCallback? onTap;

  const ShiftCard({
    super.key,
    required this.shift,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Time
                  Text(
                    '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(shift.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(shift.status)),
                    ),
                    child: Text(
                      shift.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(shift.status),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Source badge: distinguish admin-created ROUTE calls from
              // client-booked shifts (they read from different tables).
              if (shift.source == 'route') ...[
                Row(
                  children: [
                    Icon(
                      Icons.route,
                      size: 14,
                      color: Colors.teal.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      shift.routeName ?? 'Route call',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              // Service User
              if (shift.serviceUserName != null) ...[
                Text(
                  shift.serviceUserName!,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
              // Address with copy + map actions
              if (shift.serviceUserAddress != null &&
                  shift.serviceUserAddress!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _AddressRow(address: shift.serviceUserAddress!),
              ],
              // Location (fallback if service_user address not available)
              if ((shift.serviceUserAddress == null ||
                      shift.serviceUserAddress!.isEmpty) &&
                  shift.location != null &&
                  shift.location!.isNotEmpty) ...[
                const SizedBox(height: 4),
                _AddressRow(address: shift.location!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String time) {
    if (time.isEmpty) return '--:--';
    final parts = time.split(':');
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// Displays an address with a copy-to-clipboard button and a map-launcher
/// button (Google Maps / Apple Maps / Waze picker).
class _AddressRow extends StatelessWidget {
  final String address;

  const _AddressRow({required this.address});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Expanded(
          child: GestureDetector(
            onLongPress: () => _copyAddress(context),
            child: Text(
              address,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ),
        // Copy button
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _copyAddress(context),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Icon(
                Icons.copy,
                size: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ),
        // Map button
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openMapPicker(context),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Icon(
                Icons.map,
                size: 16,
                color: Colors.blue.shade400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _copyAddress(BuildContext context) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        width: 250,
      ),
    );
  }

  void _openMapPicker(BuildContext context) {
    final encoded = Uri.encodeComponent(address);
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Open in Maps',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Icon(Icons.map, color: Colors.green.shade700),
              ),
              title: const Text('Google Maps'),
              subtitle: const Text('Open in browser or app'),
              onTap: () {
                Navigator.pop(context);
                launchUrl(
                  Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            if (Theme.of(context).platform == TargetPlatform.iOS)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.map, color: Colors.blue.shade700),
                ),
                title: const Text('Apple Maps'),
                onTap: () {
                  Navigator.pop(context);
                  launchUrl(
                    Uri.parse('https://maps.apple.com/?q=$encoded'),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.navigation, color: Colors.blue.shade700),
              ),
              title: const Text('Waze'),
              subtitle: const Text('Open in Waze app'),
              onTap: () {
                Navigator.pop(context);
                launchUrl(
                  Uri.parse('https://waze.com/ul?q=$encoded&navigate=yes'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}