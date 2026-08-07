import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../config/router.dart';
import '../../models/member.dart';
import '../../models/enums.dart';
import '../../services/member_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/shimmer_widgets.dart';
import '../../utils/export_utils.dart';
import '../../widgets/scale_tap_wrapper.dart';
import '../../utils/error_utils.dart';

/// Member list screen with search, filter, and rich member cards.
class MemberListScreen extends ConsumerStatefulWidget {
  const MemberListScreen({super.key});

  @override
  ConsumerState<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends ConsumerState<MemberListScreen> {
  final _searchController = TextEditingController();
  MemberRole? _roleFilter;
  bool _showSearch = false;
  String _searchQuery = '';

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  MemberListParams get _currentParams => MemberListParams(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        roleFilter: _roleFilter,
        isActive: true,
      );

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = value);
      ref.invalidate(memberListProvider);
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _searchQuery = '';
        ref.invalidate(memberListProvider);
      }
    });
  }

  void _setRoleFilter(MemberRole? role) {
    setState(() => _roleFilter = role);
    ref.invalidate(memberListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final memberListAsync = ref.watch(memberListProvider(_currentParams));
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppTheme.dynamicTextPrimary(context),
                ),
                decoration: InputDecoration(
                  hintText: 'Search members...',
                  hintStyle: GoogleFonts.inter(color: AppTheme.dynamicTextHint(context)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: true,
                ),
              )
            : const Text('Members'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
            tooltip: _showSearch ? 'Close search' : 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export CSV',
            onPressed: () {
              final members = memberListAsync.valueOrNull ?? [];
              if (members.isNotEmpty) {
                ExportUtils.exportMembersToCsv(members);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No members available to export')),
                );
              }
            },
          ),
          PopupMenuButton<MemberRole?>(
            icon: Icon(
              Icons.filter_list,
              color: _roleFilter != null ? AppTheme.secondaryColor : null,
            ),
            tooltip: 'Filter by role',
            onSelected: _setRoleFilter,
            itemBuilder: (context) => [
              const PopupMenuItem<MemberRole?>(
                value: null,
                child: Text('All Roles'),
              ),
              ...MemberRole.values.map((role) => PopupMenuItem<MemberRole?>(
                    value: role,
                    child: Row(
                      children: [
                        Icon(
                          _roleIcon(role),
                          size: 18,
                          color: _roleColor(role),
                        ),
                        const SizedBox(width: 8),
                        Text(role.displayName),
                        if (_roleFilter == role) ...[
                          const Spacer(),
                          Icon(Icons.check, size: 18, color: Theme.of(context).colorScheme.primary),
                        ],
                      ],
                    ),
                  )),
            ],
          ),
        ],
      ),
      body: memberListAsync.when(
        data: (members) => _buildMemberList(members),
        loading: () => _buildLoadingState(),
        error: (error, _) => _buildErrorState(error),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.memberAdd),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Member'),
            )
          : null,
    );
  }

  Widget _buildMemberList(List<Member> members) {
    if (members.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(memberListProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: 8,
          bottom: 88, // Space for FAB
        ),
        itemCount: members.length + 1, // +1 for the count header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCountHeader(members.length);
          }
          return _MemberCard(
            member: members[index - 1],
            onTap: () => context.push('/members/${members[index - 1].id}'),
          );
        },
      ),
    );
  }

  Widget _buildCountHeader(int count) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Text(
              '$count member${count == 1 ? '' : 's'}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
          ),
          if (_roleFilter != null) ...[
            const SizedBox(width: 8),
            Chip(
              label: Text(_roleFilter!.displayName),
              onDeleted: () => _setRoleFilter(null),
              deleteIcon: const Icon(Icons.close, size: 14),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const ShimmerLoadingList();
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              ErrorUtils.friendlyMessage(error),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(memberListProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilter = _searchQuery.isNotEmpty || _roleFilter != null;
    final primary = Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              ),
              child: Icon(
                hasFilter ? Icons.search_off : Icons.people_outline,
                size: 40,
                color: primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasFilter ? 'No members found' : 'No members yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Try adjusting your search or filter'
                  : 'Tap the button below to add your first member',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  IconData _roleIcon(MemberRole role) {
    switch (role) {
      case MemberRole.admin:
        return Icons.admin_panel_settings;
      case MemberRole.volunteer:
        return Icons.volunteer_activism;
      case MemberRole.member:
        return Icons.person;
    }
  }

  Color _roleColor(MemberRole role) {
    switch (role) {
      case MemberRole.admin:
        return AppTheme.primaryColor;
      case MemberRole.volunteer:
        return AppTheme.accentColor;
      case MemberRole.member:
        return AppTheme.textSecondary;
    }
  }
}

// ─── Member Card Widget ─────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  final Member member;
  final VoidCallback onTap;

  const _MemberCard({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ScaleTapWrapper(
      onTap: onTap,
      pressedScale: 0.98,
      enableHaptics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.adaptiveCardDecoration(
            context,
            radius: AppTheme.radiusLarge,
          ),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(context),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildRoleBadge(context),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: AppTheme.dynamicTextHint(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          member.mobile,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                              ),
                        ),
                      ],
                    ),
                    if (_hasBirthdayBadge || _hasAnniversaryBadge) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (_hasBirthdayBadge) _buildBirthdayBadge(),
                          if (_hasBirthdayBadge && _hasAnniversaryBadge)
                            const SizedBox(width: 6),
                          if (_hasAnniversaryBadge) _buildAnniversaryBadge(),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Quick actions (haptic safe)
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    if (member.photoUrl != null) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(member.photoUrl!),
        backgroundColor: primary.withValues(alpha: 0.12),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: primary.withValues(alpha: 0.12),
      child: Text(
        member.initials,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context) {
    Color bgColor;
    Color textColor;
    final primary = Theme.of(context).colorScheme.primary;

    switch (member.role) {
      case MemberRole.admin:
        bgColor = primary.withValues(alpha: 0.12);
        textColor = primary;
        break;
      case MemberRole.volunteer:
        bgColor = AppTheme.accentColor.withValues(alpha: 0.12);
        textColor = AppTheme.accentColor;
        break;
      case MemberRole.member:
        bgColor = AppTheme.dynamicBorder(context);
        textColor = AppTheme.dynamicTextSecondary(context);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        member.role.displayName,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  bool get _hasBirthdayBadge => member.isBirthdayWithin(7);
  bool get _hasAnniversaryBadge => member.isAnniversaryWithin(7);

  Widget _buildBirthdayBadge() {
    final days = member.daysUntilBirthday;
    final label = days == 0 ? '🎂 Today!' : '🎂 In $days day${days == 1 ? '' : 's'}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.secondaryDark,
        ),
      ),
    );
  }

  Widget _buildAnniversaryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.pink.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        '💍 Anniversary',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.pink[700],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Call action (disable haptics to prevent haptic spam when tapping rapidly)
        _QuickActionButton(
          icon: Icons.call_outlined,
          color: AppTheme.successColor,
          tooltip: 'Call',
          onTap: () => _launchAction('tel:${member.mobile}'),
        ),
        const SizedBox(height: 6),
        // WhatsApp action
        _QuickActionButton(
          icon: Icons.chat_outlined,
          color: const Color(0xFF25D366),
          tooltip: 'WhatsApp',
          onTap: () => _launchAction('https://wa.me/${member.mobile.replaceAll(RegExp(r'[^0-9]'), '')}'),
        ),
      ],
    );
  }

  void _launchAction(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ScaleTapWrapper(
        onTap: onTap,
        pressedScale: 0.92,
        enableHaptics: false, // Prevents haptic spam when tapping back to back
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

