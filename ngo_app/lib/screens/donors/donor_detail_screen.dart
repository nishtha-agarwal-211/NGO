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
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 64, color: AppTheme.textHint),
          const SizedBox(height: 16),
          Text('Donor not found', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                _buildQuickActions(),
                const SizedBox(height: 24),

                // Stats row
                _buildStatsRow(),
                const SizedBox(height: 24),

                // Contact info
                _buildSectionHeader('Contact Information'),
                const SizedBox(height: 12),
                _buildInfoCard(context),
                const SizedBox(height: 24),

                // Notes
                if (donor.notes != null && donor.notes!.isNotEmpty) ...[
                  _buildSectionHeader('Notes'),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Text(
                      donor.notes!,
                      style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Donation history
                _buildSectionHeader('Donation History'),
                const SizedBox(height: 12),
                _buildDonationHistory(),
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
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    donor.donorType.displayName,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.call, label: 'Call', color: AppTheme.successColor,
            onTap: () => _launch('tel:${donor.mobile}'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.chat, label: 'WhatsApp', color: const Color(0xFF25D366),
            onTap: () => _launch('https://wa.me/${donor.mobile.replaceAll(RegExp(r'[^0-9]'), '')}'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.sms_outlined, label: 'SMS', color: AppTheme.primaryColor,
            onTap: () => _launch('sms:${donor.mobile}'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.accentColor, Color(0xFF26A69A)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
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
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
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
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.phone_outlined, 'Mobile', donor.mobile),
          if (donor.email != null)
            _buildInfoRow(Icons.email_outlined, 'Email', donor.email!),
          if (donor.address != null)
            _buildInfoRow(Icons.location_on_outlined, 'Address', donor.address!),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            'Added',
            DateFormat('MMM d, yyyy').format(donor.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textHint, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
    );
  }

  Widget _buildDonationHistory() {
    return donationsAsync.when(
      data: (donations) {
        if (donations.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 40, color: AppTheme.textHint),
                const SizedBox(height: 12),
                Text('No donations recorded yet',
                    style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
              ],
            ),
          );
        }
        return Column(
          children: donations.map((d) => _DonationTile(donation: d)).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Text('Error loading donations: $e'),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
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
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d, yyyy').format(donation.donationDate),
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  if (donation.projectName != null)
                    Text(
                      donation.projectName!,
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.accentColor),
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
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
