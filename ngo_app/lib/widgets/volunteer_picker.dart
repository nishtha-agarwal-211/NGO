import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../services/member_service.dart';

/// Volunteer picker widget — lets admin select members from the directory
/// or type ad-hoc volunteer names.
///
/// Usage:
/// ```dart
/// VolunteerPicker(
///   onMemberSelected: (memberId) => ...,
///   onAdHocAdded: (name) => ...,
///   excludeMemberIds: {'already-added-id-1'},
/// )
/// ```
class VolunteerPicker extends ConsumerStatefulWidget {
  /// Callback when a member is selected from the list.
  final void Function(String memberId, String memberName) onMemberSelected;

  /// Callback when an ad-hoc volunteer name is entered.
  final void Function(String name) onAdHocAdded;

  /// Member IDs to exclude from the picker (already assigned).
  final Set<String> excludeMemberIds;

  const VolunteerPicker({
    super.key,
    required this.onMemberSelected,
    required this.onAdHocAdded,
    this.excludeMemberIds = const {},
  });

  @override
  ConsumerState<VolunteerPicker> createState() => _VolunteerPickerState();
}

class _VolunteerPickerState extends ConsumerState<VolunteerPicker> {
  final _searchController = TextEditingController();
  final _adHocController = TextEditingController();
  bool _showAdHocField = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _adHocController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Header row ─────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Text(
                'Add Volunteer',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() {
                _showAdHocField = !_showAdHocField;
                if (!_showAdHocField) _adHocController.clear();
              }),
              icon: Icon(
                _showAdHocField ? Icons.person : Icons.person_add_alt_1,
                size: 18,
              ),
              label: Text(_showAdHocField ? 'From Members' : 'Type Name'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accentColor,
                textStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ─── Ad-hoc name entry ──────────────────────────────────
        if (_showAdHocField) ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _adHocController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Enter volunteer name',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  onFieldSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      widget.onAdHocAdded(value.trim());
                      _adHocController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    final name = _adHocController.text.trim();
                    if (name.isNotEmpty) {
                      widget.onAdHocAdded(name);
                      _adHocController.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Icon(Icons.add, size: 20),
                ),
              ),
            ],
          ),
        ] else ...[
          // ─── Member search + list ─────────────────────────────
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search members...',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 8),
          _buildMemberList(),
        ],
      ],
    );
  }

  Widget _buildMemberList() {
    final membersAsync = ref.watch(
      memberListProvider(
        MemberListParams(
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
          isActive: true,
        ),
      ),
    );

    return membersAsync.when(
      data: (members) {
        final available = members
            .where((m) => !widget.excludeMemberIds.contains(m.id))
            .toList();

        if (available.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: Text(
              _searchQuery.isNotEmpty
                  ? 'No matching members found'
                  : 'All members are already added',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textHint,
              ),
            ),
          );
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: available.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final member = available[index];
              return ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    member.name.isNotEmpty
                        ? member.name[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                title: Text(
                  member.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  member.role.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textHint,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: AppTheme.accentColor,
                    size: 24,
                  ),
                  onPressed: () =>
                      widget.onMemberSelected(member.id, member.name),
                ),
                onTap: () =>
                    widget.onMemberSelected(member.id, member.name),
              );
            },
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Error loading members: $e',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppTheme.errorColor,
          ),
        ),
      ),
    );
  }
}
