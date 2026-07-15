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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  MemberListParams get _currentParams => MemberListParams(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        roleFilter: _roleFilter,
        isActive: true,
      );

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    ref.invalidate(memberListProvider);
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

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search members...',
                  hintStyle: GoogleFonts.inter(color: AppTheme.textHint),
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
                          const Icon(Icons.check, size: 18, color: AppTheme.primaryColor),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.memberAdd),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Member'),
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count member${count == 1 ? '' : 's'}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          if (_roleFilter != null) ...[
            const SizedBox(width: 8),
            Chip(
              label: Text(_roleFilter!.displayName),
              onDeleted: () => _setRoleFilter(null),
              deleteIcon: const Icon(Icons.close, size: 16),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
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
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                hasFilter ? Icons.search_off : Icons.people_outline,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasFilter ? 'No members found' : 'No members yet',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Try adjusting your search or filter'
                  : 'Tap the button below to add your first member',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                _buildAvatar(),
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
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildRoleBadge(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined,
                              size: 14, color: AppTheme.textHint),
                          const SizedBox(width: 4),
                          Text(
                            member.mobile,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
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
                // Quick actions
                _buildQuickActions(context),
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
        radius: 24,
        backgroundImage: NetworkImage(member.photoUrl!),
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      child: Text(
        member.initials,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
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
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppTheme.secondaryDark,
        ),
      ),
    );
  }

  Widget _buildAnniversaryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.pink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '💍 Anniversary',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.pink[700],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Call
        _QuickActionButton(
          icon: Icons.call_outlined,
          color: AppTheme.successColor,
          tooltip: 'Call',
          onTap: () => _launchAction('tel:${member.mobile}'),
        ),
        const SizedBox(height: 4),
        // WhatsApp
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
