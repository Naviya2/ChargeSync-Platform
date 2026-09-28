import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/membership/api/member_api.dart';
import '../../../features/membership/screens/membership_screen.dart';

class RewardsCard extends StatefulWidget {
  const RewardsCard({super.key});
  @override
  State<RewardsCard> createState() => _RewardsCardState();
}

class _RewardsCardState extends State<RewardsCard> {
  Map<String, dynamic>? _balance;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final value = await MemberApi.instance.request('loyalty/me');
      if (mounted) setState(() => _balance = Map<String, dynamic>.from(value));
    } catch (_) {
      if (mounted) setState(() => _balance = null);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.surfaceContainerLow,
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: const Icon(Icons.stars_rounded, color: AppColors.primary),
      title: Text(
        _balance == null
            ? 'Membership & rewards'
            : '${_balance!['pointsBalance']} CS Points • ${_balance!['tier']}',
      ),
      subtitle: const Text('Explore plans, points history and rewards'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MembershipScreen()),
        );
        if (mounted) await _refresh();
      },
    ),
  );
}
