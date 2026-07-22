import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Shared error message utilities.
///
/// Converts raw exception text into friendly, user-facing messages
/// so that internal details never leak to the UI.
class ErrorUtils {
  ErrorUtils._();

  /// Convert a raw exception into a friendly user-facing message.
  static String friendlyMessage(dynamic error) {
    final msg = error.toString().toLowerCase();

    // Auth errors
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials')) {
      return 'Invalid email or password. Please try again.';
    }

    // Network errors
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }

    // Postgres unique-violation (code 23505)
    if (msg.contains('23505') || msg.contains('unique') || msg.contains('duplicate key')) {
      return 'This record already exists. Please check for duplicates.';
    }

    // Permission / RLS errors
    if (msg.contains('permission') || msg.contains('rls') || msg.contains('policy')) {
      return 'You don\'t have permission to perform this action.';
    }

    // Storage errors
    if (msg.contains('storage') && msg.contains('bucket')) {
      return 'File upload failed. Please try again.';
    }

    // Generic fallbacks by action keyword
    if (msg.contains('delete')) {
      return 'Failed to delete. Please try again.';
    }
    if (msg.contains('upload')) {
      return 'Upload failed. Please try again.';
    }
    if (msg.contains('update')) {
      return 'Update failed. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  /// Show a friendly error SnackBar.
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(friendlyMessage(error)),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }
}
