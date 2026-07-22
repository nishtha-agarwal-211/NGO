import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/event.dart';
import '../../models/event_volunteer.dart';
import '../../models/donation.dart';
import '../../models/enums.dart';
import '../../services/event_service.dart';
import '../../services/auth_service.dart';
import '../../services/member_service.dart';
import '../../services/donor_service.dart';
import '../../models/member.dart';
import '../../models/donor.dart';

/// Full event detail screen — shows event info, volunteers, donations,
/// expenses, and photo gallery link.
class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final isAdminAsync = ref.watch(isAdminProvider);

    return eventAsync.when(
      data: (event) {
        if (event == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Event not found')),
          );
        }
        return _EventDetailBody(
          event: event,
          isAdmin: isAdminAsync.valueOrNull ?? false,
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text('Error: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(eventDetailProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDetailBody extends ConsumerStatefulWidget {
  final Event event;
  final bool isAdmin;

  const _EventDetailBody({required this.event, required this.isAdmin});

  @override
  ConsumerState<_EventDetailBody> createState() => _EventDetailBodyState();
}

class _EventDetailBodyState extends ConsumerState<_EventDetailBody> {
  final _dateFormat = DateFormat('EEEE, MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final volunteersAsync = ref.watch(eventVolunteersProvider(widget.event.id));
    final donationsAsync = ref.watch(eventDonationsProvider(widget.event.id));
    final expensesAsync = ref.watch(eventExpensesProvider(widget.event.id));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── App Bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.event.displayTitle,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.8),
                      AppTheme.accentColor,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Icon(
                        _statusIcon(widget.event.effectiveStatus),
                        size: 40,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(widget.event.effectiveStatus).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          widget.event.effectiveStatus.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: widget.isAdmin
                ? [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) => _handleMenuAction(value),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit Event'), dense: true)),
                        if (widget.event.isUpcoming)
                          const PopupMenuItem(value: 'complete', child: ListTile(leading: Icon(Icons.check_circle), title: Text('Mark Completed'), dense: true)),
                        const PopupMenuDivider(),
                        const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: AppTheme.errorColor), title: Text('Delete', style: TextStyle(color: AppTheme.errorColor)), dense: true)),
                      ],
                    ),
                  ]
                : null,
          ),

          // ─── Content ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Info Card
                  _buildInfoCard(),
                  const SizedBox(height: 20),

                  // Stats Row
                  _buildStatsRow(volunteersAsync, donationsAsync, expensesAsync),
                  const SizedBox(height: 24),

                  // Photos button
                  _buildSectionButton(
                    icon: Icons.photo_library_outlined,
                    label: 'View Photos',
                    color: AppTheme.secondaryColor,
                    onTap: () => context.push('/events/${widget.event.id}/photos'),
                  ),
                  const SizedBox(height: 24),

                  // Volunteers Section
                  _buildSectionHeader('Volunteers', Icons.people_outline),
                  const SizedBox(height: 12),
                  volunteersAsync.when(
                    data: (volunteers) => _buildVolunteersList(volunteers),
                    loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (e, _) => Text('Error loading volunteers: $e'),
                  ),
                  const SizedBox(height: 24),

                  // Donations Section
                  if (widget.isAdmin) ...[
                    _buildSectionHeader('Donations', Icons.volunteer_activism_outlined),
                    const SizedBox(height: 12),
                    donationsAsync.when(
                      data: (donations) => _buildDonationsList(donations),
                      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (e, _) => Text('Error loading donations: $e'),
                    ),
                    const SizedBox(height: 24),

                    // Expenses Section
                    _buildSectionHeader('Expenses', Icons.receipt_long_outlined),
                    const SizedBox(height: 12),
                    expensesAsync.when(
                      data: (expenses) => _buildExpensesList(expenses),
                      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (e, _) => Text('Error loading expenses: $e'),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Notes
                  if (widget.event.notes != null && widget.event.notes!.isNotEmpty) ...[
                    _buildSectionHeader('Notes', Icons.notes_outlined),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: Text(
                        widget.event.notes!,
                        style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary, height: 1.5),
                      ),
                    ),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Info Card ────────────────────────────────────────────────

  Widget _buildInfoCard() {
    final timeDisplay = widget.event.formattedTimeRange.isNotEmpty
        ? widget.event.formattedTimeRange
        : widget.event.eventTime;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          _infoRow(Icons.calendar_today_outlined, 'Date', _dateFormat.format(widget.event.eventDate)),
          if (timeDisplay != null && timeDisplay.isNotEmpty) ...[
            const Divider(height: 20),
            _infoRow(Icons.access_time_outlined, 'Time', timeDisplay),
          ],
          if (widget.event.location != null) ...[
            const Divider(height: 20),
            _infoRow(Icons.location_on_outlined, 'Location', widget.event.location!),
          ],
          if (widget.event.projectName != null) ...[
            const Divider(height: 20),
            _infoRow(Icons.folder_outlined, 'Project', widget.event.projectName!),
          ],
          const Divider(height: 20),
          _infoRow(Icons.group_outlined, 'Beneficiaries', '${widget.event.beneficiaryCount}'),
          if (widget.event.beneficiaryDetails != null && widget.event.beneficiaryDetails!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(
                widget.event.beneficiaryDetails!,
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        SizedBox(
          width: 90,
          child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
        ),
        Expanded(
          child: Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  // ─── Stats Row ────────────────────────────────────────────────

  Widget _buildStatsRow(
    AsyncValue<List<EventVolunteer>> volunteersAsync,
    AsyncValue<List<Donation>> donationsAsync,
    AsyncValue<List<EventExpense>> expensesAsync,
  ) {
    return Row(
      children: [
        _statChip(
          Icons.people,
          volunteersAsync.valueOrNull?.length.toString() ?? '—',
          'Volunteers',
          AppTheme.primaryColor,
        ),
        const SizedBox(width: 10),
        _statChip(
          Icons.volunteer_activism,
          donationsAsync.valueOrNull?.length.toString() ?? '—',
          'Donations',
          AppTheme.accentColor,
        ),
        const SizedBox(width: 10),
        _statChip(
          Icons.receipt_long,
          expensesAsync.valueOrNull?.length.toString() ?? '—',
          'Expenses',
          AppTheme.secondaryColor,
        ),
      ],
    );
  }

  Widget _statChip(IconData icon, String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 6),
            Text(count, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ─── Section Helpers ──────────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _buildSectionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Volunteers List ──────────────────────────────────────────

  Widget _buildVolunteersList(List<EventVolunteer> volunteers) {
    return Column(
      children: [
        if (volunteers.isEmpty)
          _emptyCard('No volunteers assigned yet'),
        ...volunteers.map((v) => _volunteerTile(v)),
        if (widget.isAdmin) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddMemberVolunteerDialog(),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Add Member'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddAdHocVolunteerDialog(),
                  icon: const Icon(Icons.person_add_alt, size: 18),
                  label: const Text('Add Name'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _volunteerTile(EventVolunteer v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: (v.isAdHoc ? AppTheme.textHint : AppTheme.primaryColor).withValues(alpha: 0.1),
            child: Icon(
              v.isAdHoc ? Icons.person_outline : Icons.person,
              size: 16,
              color: v.isAdHoc ? AppTheme.textHint : AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(v.displayName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          if (v.isAdHoc)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.textHint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Ad-hoc', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textHint)),
            ),
          if (widget.isAdmin) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _removeVolunteer(v),
              child: Icon(Icons.close, size: 16, color: AppTheme.textHint),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Donations List ───────────────────────────────────────────

  Widget _buildDonationsList(List<Donation> donations) {
    final totalCash = donations
        .where((d) => d.donationType == DonationType.cash && d.amount != null)
        .fold<double>(0, (sum, d) => sum + d.amount!);

    return Column(
      children: [
        if (totalCash > 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              children: [
                Icon(Icons.currency_rupee, size: 18, color: AppTheme.successColor),
                const SizedBox(width: 6),
                Text(
                  'Total: ₹${totalCash.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.successColor),
                ),
              ],
            ),
          ),
        if (donations.isEmpty)
          _emptyCard('No donations logged'),
        ...donations.map((d) => _donationTile(d)),
        if (widget.isAdmin) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogDonationDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Log Donation'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _donationTile(Donation d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(_donationTypeIcon(d.donationType), size: 18, color: AppTheme.accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.donorName ?? 'Unknown Donor', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(d.displayValue, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(d.donationType.displayName, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.accentColor, fontWeight: FontWeight.w500)),
          ),
          if (widget.isAdmin) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _deleteDonation(d),
              child: Icon(Icons.close, size: 16, color: AppTheme.textHint),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Expenses List ────────────────────────────────────────────

  Widget _buildExpensesList(List<EventExpense> expenses) {
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    return Column(
      children: [
        if (total > 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              children: [
                Icon(Icons.currency_rupee, size: 18, color: AppTheme.secondaryDark),
                const SizedBox(width: 6),
                Text(
                  'Total: ₹${total.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.secondaryDark),
                ),
              ],
            ),
          ),
        if (expenses.isEmpty)
          _emptyCard('No expenses recorded'),
        ...expenses.map((e) => _expenseTile(e)),
        if (widget.isAdmin) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddExpenseDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Expense'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _expenseTile(EventExpense e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_outlined, size: 18, color: AppTheme.secondaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(e.description, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Text(e.displayAmount, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.secondaryDark)),
          if (widget.isAdmin) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _deleteExpense(e),
              child: Icon(Icons.close, size: 16, color: AppTheme.textHint),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppTheme.textHint)),
    );
  }

  // ─── Action Handlers ──────────────────────────────────────────

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'edit':
        context.push('/events/${widget.event.id}/edit');
        break;
      case 'complete':
        await ref.read(eventServiceProvider).completeEvent(widget.event.id);
        ref.invalidate(eventDetailProvider);
        ref.invalidate(upcomingEventsProvider);
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Event?'),
            content: const Text('This will permanently delete this event and all associated data.'),
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
        if (confirmed == true && mounted) {
          await ref.read(eventServiceProvider).deleteEvent(widget.event.id);
          if (mounted) context.pop();
        }
        break;
    }
  }

  void _removeVolunteer(EventVolunteer v) async {
    await ref.read(eventServiceProvider).removeVolunteer(v.id);
    ref.invalidate(eventVolunteersProvider);
  }

  void _deleteDonation(Donation d) async {
    await ref.read(eventServiceProvider).deleteDonation(d.id);
    ref.invalidate(eventDonationsProvider);
  }

  void _deleteExpense(EventExpense e) async {
    await ref.read(eventServiceProvider).deleteExpense(e.id);
    ref.invalidate(eventExpensesProvider);
  }

  // ─── Dialogs ──────────────────────────────────────────────────

  void _showAddMemberVolunteerDialog() async {
    final membersAsync = await ref.read(memberServiceProvider).getMembers(isActive: true);
    if (!mounted) return;

    final selected = await showDialog<Member>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Member'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: membersAsync.length,
            itemBuilder: (_, i) {
              final m = membersAsync[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(m.initials, style: const TextStyle(color: AppTheme.primaryColor, fontSize: 13)),
                ),
                title: Text(m.name),
                subtitle: Text(m.mobile, style: const TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(ctx, m),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      await ref.read(eventServiceProvider).addMemberVolunteer(widget.event.id, selected.id);
      ref.invalidate(eventVolunteersProvider);
    }
  }

  void _showAddAdHocVolunteerDialog() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Volunteer'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Volunteer Name', prefixIcon: Icon(Icons.person_outline)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await ref.read(eventServiceProvider).addAdHocVolunteer(widget.event.id, name);
      ref.invalidate(eventVolunteersProvider);
    }
  }

  void _showLogDonationDialog() async {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DonationType donationType = DonationType.cash;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Log Donation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Donor Name', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mobileCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone_outlined)),
                ),
                const SizedBox(height: 16),
                SegmentedButton<DonationType>(
                  segments: DonationType.values.map((t) => ButtonSegment(value: t, label: Text(t.displayName))).toList(),
                  selected: {donationType},
                  onSelectionChanged: (s) => setDialogState(() => donationType = s.first),
                ),
                const SizedBox(height: 12),
                if (donationType == DonationType.cash)
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount (₹)', prefixIcon: Icon(Icons.currency_rupee)),
                  )
                else
                  TextField(
                    controller: descCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || mobileCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, {
                  'name': nameCtrl.text.trim(),
                  'mobile': mobileCtrl.text.trim(),
                  'type': donationType,
                  'amount': double.tryParse(amountCtrl.text.trim()),
                  'description': descCtrl.text.trim(),
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final donorService = ref.read(donorServiceProvider);

      // Auto-create donor if doesn't exist
      var donor = await donorService.findByMobile(result['mobile'] as String);
      donor ??= await donorService.createDonor(Donor(
        id: '',
        name: result['name'] as String,
        mobile: result['mobile'] as String,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final donation = Donation(
        id: '',
        donorId: donor.id,
        projectId: widget.event.projectId,
        eventId: widget.event.id,
        donationType: result['type'] as DonationType,
        amount: result['amount'] as double?,
        itemDescription: (result['description'] as String?)?.isEmpty == true ? null : result['description'] as String?,
        donationDate: widget.event.eventDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(eventServiceProvider).logEventDonation(donation);
      ref.invalidate(eventDonationsProvider);
      ref.invalidate(donorListProvider);
    }
  }

  void _showAddExpenseDialog() async {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Description', hintText: 'e.g., Rice - 50kg'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (₹)', prefixIcon: Icon(Icons.currency_rupee)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text.trim());
              if (descCtrl.text.trim().isEmpty || amount == null) return;
              Navigator.pop(ctx, {'description': descCtrl.text.trim(), 'amount': amount});
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      final expense = EventExpense(
        id: '',
        eventId: widget.event.id,
        description: result['description'] as String,
        amount: result['amount'] as double,
        createdAt: DateTime.now(),
      );
      await ref.read(eventServiceProvider).addExpense(expense);
      ref.invalidate(eventExpensesProvider);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────

  IconData _statusIcon(EventStatus status) {
    switch (status) {
      case EventStatus.upcoming:
        return Icons.schedule;
      case EventStatus.completed:
        return Icons.check_circle_outline;
      case EventStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Color _statusColor(EventStatus status) {
    switch (status) {
      case EventStatus.upcoming:
        return AppTheme.primaryColor;
      case EventStatus.completed:
        return AppTheme.successColor;
      case EventStatus.cancelled:
        return AppTheme.errorColor;
    }
  }

  IconData _donationTypeIcon(DonationType type) {
    switch (type) {
      case DonationType.cash:
        return Icons.currency_rupee;
      case DonationType.kind:
        return Icons.inventory_2_outlined;
      case DonationType.service:
        return Icons.handshake_outlined;
    }
  }
}
