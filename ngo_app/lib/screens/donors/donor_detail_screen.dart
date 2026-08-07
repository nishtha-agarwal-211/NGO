import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/donor.dart';
import '../../models/donation.dart';
import '../../models/enums.dart';
import '../../services/donor_service.dart';
import '../../services/auth_service.dart';
import '../../utils/error_utils.dart';
import '../../utils/communication_utils.dart';
import '../../widgets/scale_tap_wrapper.dart';

/// Donor profile screen with contact info, donation history, and totals.
class DonorDetailScreen extends ConsumerWidget {
  final String donorId;

  const DonorDetailScreen({super.key, required this.donorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donorAsync = ref.watch(donorDetailProvider(donorId));
    final donationsAsync = ref.watch(donorDonationsProvider(donorId));
    final totalAsync = ref.watch(donorTotalDonatedProvider(donorId));
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;

    return Scaffold(
      body: donorAsync.when(
        data: (donor) {
          if (donor == null) return _buildNotFound(context);
          return _DonorDetailBody(
            donor: donor,
            donationsAsync: donationsAsync,
            totalDonated: totalAsync.valueOrNull ?? 0,
            isAdmin: isAdmin,
            onDelete: () => _deleteDonor(context, ref, donor),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(ErrorUtils.friendlyMessage(e))),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 64, color: AppTheme.dynamicTextHint(context)),
          const SizedBox(height: 16),
          Text('Donor not found', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDonor(BuildContext context, WidgetRef ref, Donor donor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: const Text('Delete Donor?'),
        content: Text('Are you sure you want to delete ${donor.name}? This will also remove all their donation records.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(donorServiceProvider).deleteDonor(donor.id);
        ref.invalidate(donorListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${donor.name} has been deleted')),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ErrorUtils.showErrorSnackBar(context, e);
        }
      }
    }
  }
}

class _DonorDetailBody extends StatelessWidget {
  final Donor donor;
  final AsyncValue<List<Donation>> donationsAsync;
  final double totalDonated;
  final bool isAdmin;
  final VoidCallback onDelete;

  const _DonorDetailBody({
    required this.donor,
    required this.donationsAsync,
    required this.totalDonated,
    required this.isAdmin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Quick actions
                _buildQuickActions(context),
                const SizedBox(height: 24),

                // Stats row
                _buildStatsRow(context),
                const SizedBox(height: 24),

                // Contact info
                _buildSectionHeader(context, 'Contact Information'),
                const SizedBox(height: 12),
                _buildInfoCard(context),
                const SizedBox(height: 24),

                // Notes
                if (donor.notes != null && donor.notes!.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Notes'),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.adaptiveCardDecoration(
                      context,
                      radius: AppTheme.radiusLarge,
                    ),
                    child: Text(
                      donor.notes!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Donation history
                _buildSectionHeader(context, 'Donation History'),
                const SizedBox(height: 12),
                _buildDonationHistory(context),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppTheme.accentColor,
      foregroundColor: Colors.white,
      actions: [
        if (isAdmin) ...[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/donors/${donor.id}/edit'),
          ),
          PopupMenuButton<String>(
            onSelected: (v) { if (v == 'delete') onDelete(); },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 20),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.accentColor, Color(0xFF004D40)],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  child: Text(
                    donor.initials,
                    style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  donor.name,
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Text(
                    donor.donorType.displayName,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.call, label: 'Call', color: AppTheme.successColor,
            onTap: () => _launch('tel:${donor.mobile}'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.chat, label: 'WhatsApp', color: const Color(0xFF25D366),
            onTap: () => _launch('https://wa.me/${donor.mobile.replaceAll(RegExp(r'[^0-9]'), '')}'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.receipt_long_outlined, label: 'Receipt', color: AppTheme.secondaryDark,
            onTap: () => CommunicationUtils.sendDonationReceipt(
              donorName: donor.name,
              phone: donor.mobile,
              amountOrItem: '₹${_formatAmount(totalDonated)}',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.sms_outlined, label: 'SMS', color: primary,
            onTap: () => _launch('sms:${donor.mobile}'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.adaptiveCardShadow(context),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  '₹${_formatAmount(totalDonated)}',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total Donated',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
          Expanded(
            child: Column(
              children: [
                Text(
                  donor.donorType.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Donor Type',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      decoration: AppTheme.adaptiveCardDecoration(
        context,
        radius: AppTheme.radiusLarge,
      ),
      child: Column(
        children: [
          _buildInfoRow(context, Icons.phone_outlined, 'Mobile', donor.mobile),
          if (donor.email != null)
            _buildInfoRow(context, Icons.email_outlined, 'Email', donor.email!),
          if (donor.address != null)
            _buildInfoRow(context, Icons.location_on_outlined, 'Address', donor.address!),
          _buildInfoRow(
            context,
            Icons.calendar_today_outlined,
            'Added',
            DateFormat('MMM d, yyyy').format(donor.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(icon, size: 18, color: AppTheme.accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  Widget _buildDonationHistory(BuildContext context) {
    return donationsAsync.when(
      data: (donations) {
        if (donations.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: AppTheme.adaptiveCardDecoration(
              context,
              radius: AppTheme.radiusLarge,
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 40, color: AppTheme.dynamicTextHint(context)),
                const SizedBox(height: 12),
                Text(
                  'No donations recorded yet',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }
        return Column(
          children: donations.map((d) => _DonationTile(donation: d)).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Text(
        'Error loading donations: $e',
        style: TextStyle(color: AppTheme.errorColor),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2);
  }

  Future<void> _launch(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _DonationTile extends StatelessWidget {
  final Donation donation;

  const _DonationTile({required this.donation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.adaptiveCardDecoration(
          context,
          radius: AppTheme.radiusMedium,
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _typeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(_typeIcon, size: 20, color: _typeColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donation.donationType.displayName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d, yyyy').format(donation.donationDate),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (donation.projectName != null)
                    Text(
                      donation.projectName!,
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.accentColor, fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ),
            Text(
              donation.displayValue,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _typeIcon {
    switch (donation.donationType) {
      case DonationType.cash: return Icons.currency_rupee;
      case DonationType.kind: return Icons.inventory_2_outlined;
      case DonationType.service: return Icons.handshake_outlined;
    }
  }

  Color get _typeColor {
    switch (donation.donationType) {
      case DonationType.cash: return AppTheme.successColor;
      case DonationType.kind: return AppTheme.secondaryColor;
      case DonationType.service: return AppTheme.primaryColor;
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon, required this.label, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTapWrapper(
      onTap: onTap,
      pressedScale: 0.94,
      enableHaptics: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

