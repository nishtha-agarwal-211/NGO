import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/member.dart';
import '../../models/enums.dart';
import '../../services/member_service.dart';
import '../../services/auth_service.dart';

/// Full member profile screen — shows all fields, quick actions, badges.
class MemberDetailScreen extends ConsumerWidget {
  final String memberId;

  const MemberDetailScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(memberDetailProvider(memberId));
    final isAdminAsync = ref.watch(isAdminProvider);

    return Scaffold(
      body: memberAsync.when(
        data: (member) {
          if (member == null) {
            return _buildNotFound(context);
          }
          return _MemberDetailBody(
            member: member,
            isAdmin: isAdminAsync.valueOrNull ?? false,
            onDelete: () => _deleteMember(context, ref, member),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError(context, ref, error),
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
          Text(
            'Member not found',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
          ),
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

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              'Failed to load member',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(memberDetailProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMember(BuildContext context, WidgetRef ref, Member member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Deactivate Member?'),
        content: Text('Are you sure you want to deactivate ${member.name}? They will no longer appear in the active members list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(memberServiceProvider).deactivateMember(member.id);
        ref.invalidate(memberListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${member.name} has been deactivated')),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to deactivate: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }
}

// ─── Detail Body ────────────────────────────────────────────────

class _MemberDetailBody extends StatelessWidget {
  final Member member;
  final bool isAdmin;
  final VoidCallback onDelete;

  const _MemberDetailBody({
    required this.member,
    required this.isAdmin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Collapsing app bar with gradient + avatar
        _buildSliverAppBar(context),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Quick action buttons (Call, WhatsApp, SMS)
                _buildQuickActions(context),
                const SizedBox(height: 24),

                // Badges (birthday / anniversary)
                if (_hasBadges) ...[
                  _buildBadgesSection(),
                  const SizedBox(height: 24),
                ],

                // Contact Info
                _buildSectionHeader('Contact Information'),
                const SizedBox(height: 12),
                _buildInfoCard([
                  _InfoRow(icon: Icons.phone_outlined, label: 'Mobile', value: member.mobile),
                  if (member.email != null)
                    _InfoRow(icon: Icons.email_outlined, label: 'Email', value: member.email!),
                  if (member.address != null)
                    _InfoRow(icon: Icons.location_on_outlined, label: 'Address', value: member.address!),
                ]),
                const SizedBox(height: 24),

                // Personal Info
                _buildSectionHeader('Personal Details'),
                const SizedBox(height: 12),
                _buildInfoCard([
                  _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Role',
                    value: member.role.displayName,
                    trailing: _buildRoleBadge(),
                  ),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Joined',
                    value: DateFormat('MMMM yyyy').format(member.joinDate),
                  ),
                  if (member.dateOfBirth != null)
                    _InfoRow(
                      icon: Icons.cake_outlined,
                      label: 'Birthday',
                      value: _formatDate(member.dateOfBirth!),
                    ),
                  if (member.weddingAnniversary != null)
                    _InfoRow(
                      icon: Icons.favorite_outline,
                      label: 'Anniversary',
                      value: _formatDate(member.weddingAnniversary!),
                    ),
                ]),
                const SizedBox(height: 24),

                // Tags
                if (member.tags.isNotEmpty) ...[
                  _buildSectionHeader('Tags'),
                  const SizedBox(height: 12),
                  _buildTagsSection(),
                  const SizedBox(height: 24),
                ],

                // Notes
                if (member.notes != null && member.notes!.isNotEmpty) ...[
                  _buildSectionHeader('Notes'),
                  const SizedBox(height: 12),
                  _buildNotesCard(),
                  const SizedBox(height: 24),
                ],

                // Status
                _buildStatusCard(),
                const SizedBox(height: 100), // Bottom padding for FAB
              ],
            ),
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      actions: [
        if (isAdmin) ...[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => context.push('/members/${member.id}/edit'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'deactivate') onDelete();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'deactivate',
                child: Row(
                  children: [
                    Icon(Icons.person_off_outlined, color: AppTheme.errorColor, size: 20),
                    SizedBox(width: 8),
                    Text('Deactivate', style: TextStyle(color: AppTheme.errorColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40), // space for app bar
                // Avatar
                Hero(
                  tag: 'member_avatar_${member.id}',
                  child: _buildAvatar(),
                ),
                const SizedBox(height: 14),
                // Name
                Text(
                  member.name,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                // Role
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    member.role.displayName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (member.photoUrl != null) {
      return CircleAvatar(
        radius: 44,
        backgroundImage: NetworkImage(member.photoUrl!),
        backgroundColor: Colors.white.withValues(alpha: 0.2),
      );
    }
    return CircleAvatar(
      radius: 44,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      child: Text(
        member.initials,
        style: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.call,
            label: 'Call',
            color: AppTheme.successColor,
            onTap: () => _launch('tel:${member.mobile}'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.chat,
            label: 'WhatsApp',
            color: const Color(0xFF25D366),
            onTap: () => _launch(
              'https://wa.me/${member.mobile.replaceAll(RegExp(r'[^0-9]'), '')}',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.sms_outlined,
            label: 'SMS',
            color: AppTheme.primaryColor,
            onTap: () => _launch('sms:${member.mobile}'),
          ),
        ),
        if (member.email != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.email_outlined,
              label: 'Email',
              color: AppTheme.secondaryDark,
              onTap: () => _launch('mailto:${member.email}'),
            ),
          ),
        ],
      ],
    );
  }

  bool get _hasBadges =>
      member.isBirthdayWithin(7) || member.isAnniversaryWithin(7);

  Widget _buildBadgesSection() {
    return Column(
      children: [
        if (member.isBirthdayWithin(7)) _buildCelebrationBanner(
          emoji: '🎂',
          label: member.daysUntilBirthday == 0
              ? 'Birthday Today!'
              : 'Birthday in ${member.daysUntilBirthday} day${member.daysUntilBirthday == 1 ? '' : 's'}',
          color: AppTheme.warningColor,
        ),
        if (member.isBirthdayWithin(7) && member.isAnniversaryWithin(7))
          const SizedBox(height: 8),
        if (member.isAnniversaryWithin(7)) _buildCelebrationBanner(
          emoji: '💍',
          label: 'Wedding Anniversary Coming Up!',
          color: Colors.pink,
        ),
      ],
    );
  }

  Widget _buildCelebrationBanner({
    required String emoji,
    required String label,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildInfoCard(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              Divider(
                height: 1,
                indent: 52,
                color: Colors.grey.withValues(alpha: 0.1),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleBadge() {
    Color bgColor;
    Color textColor;

    switch (member.role) {
      case MemberRole.admin:
        bgColor = AppTheme.primaryColor.withValues(alpha: 0.12);
        textColor = AppTheme.primaryColor;
        break;
      case MemberRole.volunteer:
        bgColor = AppTheme.accentColor.withValues(alpha: 0.12);
        textColor = AppTheme.accentColor;
        break;
      case MemberRole.member:
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = AppTheme.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        member.role.displayName,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: member.tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            tag,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Text(
        member.notes!,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppTheme.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: member.isActive
            ? AppTheme.successColor.withValues(alpha: 0.08)
            : AppTheme.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(
            member.isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: member.isActive ? AppTheme.successColor : AppTheme.errorColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            member.isActive ? 'Active Member' : 'Inactive Member',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: member.isActive ? AppTheme.successColor : AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  Future<void> _launch(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─── Info Row Widget ────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── Quick Action Card ──────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
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
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
