import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/reward_catalogue.dart';
import '../../services/incentive_service.dart';

class RewardCatalogueScreen extends StatefulWidget {
  const RewardCatalogueScreen({super.key});

  @override
  State<RewardCatalogueScreen> createState() => _RewardCatalogueScreenState();
}

class _RewardCatalogueScreenState extends State<RewardCatalogueScreen> {
  final _service = IncentiveService(Supabase.instance.client);
  List<RewardCatalogue> _rewards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    setState(() => _isLoading = true);
    try {
      final rewards = await _service.getRewardCatalogue();
      if (mounted) {
        setState(() {
          _rewards = rewards;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading rewards: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reward Catalogue'),
        actions: [
          IconButton(
            onPressed: _loadRewards,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rewards.isEmpty
              ? const Center(child: Text('No rewards available'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _rewards.length,
                  itemBuilder: (context, index) {
                    final reward = _rewards[index];
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Reward Icon
                            Container(
                              width: double.infinity,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getRewardIcon(reward.rewardType),
                                size: 40,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Reward Name
                            Text(
                              reward.rewardName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),

                            // Reward Type
                            Text(
                              reward.getRewardTypeDisplay(),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),

                            // Points Required
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${reward.pointsRequired} pts',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Stock Status
                            Row(
                              children: [
                                Icon(
                                  reward.isInStock ? Icons.check_circle : Icons.cancel,
                                  size: 14,
                                  color: reward.isInStock ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  reward.isInStock ? 'In Stock' : 'Out of Stock',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  IconData _getRewardIcon(String rewardType) {
    switch (rewardType) {
      case 'gift_card':
        return Icons.card_giftcard;
      case 'voucher':
        return Icons.confirmation_number;
      case 'merchandise':
        return Icons.shopping_bag;
      case 'experience':
        return Icons.star;
      case 'donation':
        return Icons.favorite;
      case 'training_course':
        return Icons.school;
      case 'extra_holiday':
        return Icons.beach_access;
      case 'flexible_hours':
        return Icons.access_time;
      case 'parking_spot':
        return Icons.local_parking;
      default:
        return Icons.card_giftcard;
    }
  }
}