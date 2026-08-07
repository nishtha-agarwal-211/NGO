import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/theme.dart';
import '../../config/router.dart';
import '../../models/enums.dart';
import '../../services/auth_service.dart';
import '../../widgets/shimmer_widgets.dart';
import '../../widgets/scale_tap_wrapper.dart';

/// Profile Dashboard Screen — displays current user details, role, member information,
/// and provides option to log out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Profile',
            onPressed: () {
              ref.invalidate(userProfileProvider);
              ref.invalidate(currentUserRoleProvider);
              ref.invalidate(isAdminProvider);
            },
          ),
        ],
      ),
      body: userProfileAsync.when(
        data: (profileData) {
          if (profileData == null) {
            return _buildNotLoggedIn(context, ref);
          }

          final user = profileData.user;
          final role = profileData.role;
          final member = profileData.member;
          final displayName = profileData.displayName;
          final initials = profileData.initials;
          final photoUrl = member?.photoUrl;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userProfileProvider);
              ref.invalidate(currentUserRoleProvider);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMD,
                vertical: AppTheme.spacingMD,
              ),
              children: [
                // ── Hero Header Card ──
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingLG),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Profile Avatar
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: Colors.white24,
                              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(photoUrl)
                                  : null,
                              child: photoUrl == null || photoUrl.isEmpty
                                  ? Text(
                                      initials,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.secondaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              role == MemberRole.admin
                                  ? Icons.security
                                  : role == MemberRole.volunteer
                                      ? Icons.volunteer_activism
                                      : Icons.verified_user,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingMD),

                      // Name & Email
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? (member?.email ?? 'No email associated'),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingMD),

                      // Role & Status Badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  role == MemberRole.admin
                                      ? Icons.admin_panel_settings
                                      : role == MemberRole.volunteer
                                          ? Icons.volunteer_activism
                                          : Icons.person_outline,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  role.displayName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Active Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: Colors.greenAccent.withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.greenAccent,
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Active Member',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingLG),

                // ── Quick Info Grid ──
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.calendar_today,
                        iconColor: AppTheme.primaryColor,
                        label: 'Member Since',
                        value: member != null
                            ? DateFormat('MMM yyyy').format(member.joinDate)
                            : DateFormat('MMM yyyy').format(DateTime.parse(user.createdAt)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.badge_outlined,
                        iconColor: AppTheme.secondaryColor,
                        label: 'Account Role',
                        value: role.displayName,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingLG),

                // ── Member Details Section ──
                if (member != null) ...[
                  _SectionHeader(title: 'Personal Information', icon: Icons.person_outline),
                  const SizedBox(height: 8),
                  Container(
                    decoration: AppTheme.adaptiveCardDecoration(
                      context,
                      radius: AppTheme.radiusLarge,
                    ),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.phone_outlined,
                          title: 'Mobile Number',
                          value: member.mobile.isNotEmpty ? member.mobile : 'Not provided',
                        ),
                        const Divider(height: 1, indent: 56),
                        _DetailRow(
                          icon: Icons.cake_outlined,
                          title: 'Date of Birth',
                          value: member.dateOfBirth != null
                              ? DateFormat('MMMM d, yyyy').format(member.dateOfBirth!)
                              : 'Not specified',
                          subtitle: member.daysUntilBirthday >= 0
                              ? (member.daysUntilBirthday == 0
                                  ? '🎉 Birthday Today!'
                                  : 'Birthday in ${member.daysUntilBirthday} days')
                              : null,
                        ),
                        if (member.weddingAnniversary != null) ...[
                          const Divider(height: 1, indent: 56),
                          _DetailRow(
                            icon: Icons.favorite_outline,
                            title: 'Wedding Anniversary',
                            value: DateFormat('MMMM d, yyyy').format(member.weddingAnniversary!),
                          ),
                        ],
                        if (member.address != null && member.address!.isNotEmpty) ...[
                          const Divider(height: 1, indent: 56),
                          _DetailRow(
                            icon: Icons.location_on_outlined,
                            title: 'Address',
                            value: member.address!,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Edit Member Profile Button
                  const SizedBox(height: AppTheme.spacingMD),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/members/${member.id}/edit'),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit Member Profile'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingLG),
                ],

                // ── Account Info Section ──
                _SectionHeader(title: 'Account Settings', icon: Icons.settings_outlined),
                const SizedBox(height: 8),
                Container(
                  decoration: AppTheme.adaptiveCardDecoration(
                    context,
                    radius: AppTheme.radiusLarge,
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.email_outlined,
                        title: 'Email Address',
                        value: user.email ?? 'No email',
                      ),
                      const Divider(height: 1, indent: 56),
                      _DetailRow(
                        icon: Icons.fingerprint,
                        title: 'User ID',
                        value: '${user.id.substring(0, 18)}...',
                      ),
                      const Divider(height: 1, indent: 56),
                      _DetailRow(
                        icon: Icons.verified_outlined,
                        title: 'Auth Provider',
                        value: user.appMetadata['provider']?.toString().toUpperCase() ?? 'SUPABASE',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingLG),

                // ── NGO App Info Card ──
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMD),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'श्री श्याम सेवा समिति',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'नर सेवा, नारायण सेवा · v1.0.0',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.dynamicTextSecondary(context),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingXL),

                // ── Logout Section ──
                ScaleTapWrapper(
                  onTap: () => _confirmSignOut(context, ref),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      border: Border.all(
                        color: AppTheme.errorColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: AppTheme.errorColor,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingXXL),
              ],
            ),
          );
        },
        loading: () => const _ProfileShimmer(),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                const SizedBox(height: 12),
                Text(
                  'Failed to load profile details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.invalidate(userProfileProvider),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Not Logged In',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please sign in to view your profile dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.login),
              icon: const Icon(Icons.login),
              label: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppTheme.errorColor),
            SizedBox(width: 10),
            Text('Log Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: AppTheme.adaptiveCardDecoration(
        context,
        radius: AppTheme.radiusLarge,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.dynamicTextSecondary(context),
                        fontSize: 11,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppTheme.dynamicTextSecondary(context)),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.dynamicTextSecondary(context),
              fontSize: 12,
            ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.secondaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileShimmer extends StatelessWidget {
  const _ProfileShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      children: const [
        ShimmerCard(height: 220),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: ShimmerCard(height: 70)),
            SizedBox(width: 10),
            Expanded(child: ShimmerCard(height: 70)),
          ],
        ),
        SizedBox(height: 16),
        ShimmerCard(height: 180),
        SizedBox(height: 16),
        ShimmerCard(height: 120),
      ],
    );
  }
}
