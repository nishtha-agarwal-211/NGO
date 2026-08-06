import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/member.dart';
import '../models/donor.dart';

/// CSV Export and Share utilities for Member and Donor records.
class ExportUtils {
  ExportUtils._();

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  /// Escape string fields for CSV safety.
  static String _csvEscape(String? field) {
    if (field == null) return '""';
    final escaped = field.replaceAll('"', '""');
    return '"$escaped"';
  }

  /// Export list of members to CSV and share file.
  static Future<void> exportMembersToCsv(List<Member> members) async {
    if (kIsWeb) return; // dart:io is unavailable on web
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('ID,Name,Mobile,Email,Role,Active,Join Date,DOB,Anniversary,Address,Notes,Tags');

    for (final member in members) {
      final dobStr = member.dateOfBirth != null ? _dateFormat.format(member.dateOfBirth!) : '';
      final annivStr = member.weddingAnniversary != null ? _dateFormat.format(member.weddingAnniversary!) : '';
      final joinStr = _dateFormat.format(member.joinDate);
      final tagsStr = member.tags.join('; ');

      buffer.writeln([
        _csvEscape(member.id),
        _csvEscape(member.name),
        _csvEscape(member.mobile),
        _csvEscape(member.email),
        _csvEscape(member.role.name),
        _csvEscape(member.isActive ? 'Yes' : 'No'),
        _csvEscape(joinStr),
        _csvEscape(dobStr),
        _csvEscape(annivStr),
        _csvEscape(member.address),
        _csvEscape(member.notes),
        _csvEscape(tagsStr),
      ].join(','));
    }

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${tempDir.path}/members_export_$timestamp.csv';
    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'Members Export - Shree Shyam Seva Samiti',
      text: 'Exported ${members.length} member records.',
    );
  }

  /// Export list of donors to CSV and share file.
  static Future<void> exportDonorsToCsv(List<Donor> donors) async {
    if (kIsWeb) return; // dart:io is unavailable on web
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('ID,Name,Mobile,Email,Donor Type,Total Donations,Total Amount,Created Date,Address,Notes');

    for (final donor in donors) {
      final createdStr = _dateFormat.format(donor.createdAt);

      buffer.writeln([
        _csvEscape(donor.id),
        _csvEscape(donor.name),
        _csvEscape(donor.mobile),
        _csvEscape(donor.email),
        _csvEscape(donor.donorType.name),
        donor.donationCount ?? 0,
        donor.totalDonated ?? 0.0,
        _csvEscape(createdStr),
        _csvEscape(donor.address),
        _csvEscape(donor.notes),
      ].join(','));
    }

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${tempDir.path}/donors_export_$timestamp.csv';
    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'Donors Export - Shree Shyam Seva Samiti',
      text: 'Exported ${donors.length} donor records.',
    );
  }
}
