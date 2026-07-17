import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../config/router.dart';
import '../../models/donor.dart';
import '../../models/enums.dart';
import '../../services/donor_service.dart';
import '../../services/auth_service.dart';

/// Donor list screen with search, filter by type, and rich donor cards.
class DonorListScreen extends ConsumerStatefulWidget {
  const DonorListScreen({super.key});

  @override
  ConsumerState<DonorListScreen> createState() => _DonorListScreenState();
}

class _DonorListScreenState extends ConsumerState<DonorListScreen> {
  final _searchController = TextEditingController();
  DonorType? _typeFilter;
  bool _showSearch = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DonorListParams get _currentParams => DonorListParams(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        typeFilter: _typeFilter,
      );

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    ref.invalidate(donorListProvider);
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _searchQuery = '';
        ref.invalidate(donorListProvider);
      }
    });
  }

  void _setTypeFilter(DonorType? type) {
    setState(() => _typeFilter = type);
    ref.invalidate(donorListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final donorListAsync = ref.watch(donorListProvider(_currentParams));
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search donors...',
                  hintStyle: GoogleFonts.inter(color: AppTheme.textHint),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: true,
                ),
              )
            : const Text('Donors'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
            tooltip: _showSearch ? 'Close search' : 'Search',
          ),
          PopupMenuButton<DonorType?>(
            icon: Icon(
              Icons.filter_list,
              color: _typeFilter != null ? AppTheme.secondaryColor : null,
            ),
            tooltip: 'Filter by type',
            onSelected: _setTypeFilter,
            itemBuilder: (context) => [
              const PopupMenuItem<DonorType?>(
                value: null,
                child: Text('All Types'),
              ),
              ...DonorType.values.map((type) => PopupMenuItem<DonorType?>(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          type == DonorType.recurring
                              ? Icons.repeat
                              : Icons.looks_one_outlined,
                          size: 18,
                          color: AppTheme.accentColor,
                        ),
                        const SizedBox(width: 8),
                        Text(type.displayName),
                        if (_typeFilter == type) ...[
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
      body: donorListAsync.when(
        data: (donors) => _buildDonorList(donors),
        loading: () => _buildLoadingState(),
        error: (error, _) => _buildErrorState(error),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.donorAdd),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Donor'),
            )
          : null,
    );
  }

  Widget _buildDonorList(List<Donor> donors) {
    if (donors.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(donorListProvider),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 88),
        itemCount: donors.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _buildCountHeader(donors.length);
          final donor = donors[index - 1];
          return _DonorCard(
            donor: donor,
            onTap: () => context.push('/donors/${donor.id}'),
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
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count donor${count == 1 ? '' : 's'}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentColor,
              ),
            ),
          ),
          if (_typeFilter != null) ...[
            const SizedBox(width: 8),
            Chip(
              label: Text(_typeFilter!.displayName),
              onDeleted: () => _setTypeFilter(null),
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
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
            const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text('Something went wrong',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(error.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(donorListProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilter = _searchQuery.isNotEmpty || _typeFilter != null;
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
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                hasFilter ? Icons.search_off : Icons.volunteer_activism_outlined,
                size: 40,
                color: AppTheme.accentColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasFilter ? 'No donors found' : 'No donors yet',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Try adjusting your search or filter'
                  : 'Tap the button below to add your first donor',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Donor Card Widget ──────────────────────────────────────────

class _DonorCard extends StatelessWidget {
  final Donor donor;
  final VoidCallback onTap;

  const _DonorCard({required this.donor, required this.onTap});

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
              border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.accentColor.withValues(alpha: 0.1),
                  child: Text(
                    donor.initials,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ),
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
                              donor.name,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildTypeBadge(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 14, color: AppTheme.textHint),
                          const SizedBox(width: 4),
                          Text(
                            donor.mobile,
                            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Quick actions
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQuickAction(
                      icon: Icons.call_outlined,
                      color: AppTheme.successColor,
                      onTap: () => _launch('tel:${donor.mobile}'),
                    ),
                    const SizedBox(height: 4),
                    _buildQuickAction(
                      icon: Icons.chat_outlined,
                      color: const Color(0xFF25D366),
                      onTap: () => _launch(
                        'https://wa.me/${donor.mobile.replaceAll(RegExp(r'[^0-9]'), '')}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    final isRecurring = donor.donorType == DonorType.recurring;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isRecurring ? AppTheme.accentColor : AppTheme.textSecondary).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRecurring ? Icons.repeat : Icons.looks_one_outlined,
            size: 12,
            color: isRecurring ? AppTheme.accentColor : AppTheme.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            donor.donorType.displayName,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isRecurring ? AppTheme.accentColor : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
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
    );
  }

  Future<void> _launch(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
