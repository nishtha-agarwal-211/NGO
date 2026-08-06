import 'package:flutter_test/flutter_test.dart';
import 'package:ngo_app/utils/communication_utils.dart';

void main() {
  group('CommunicationUtils Unit Tests', () {
    test('formatPhoneForWhatsApp formats 10-digit Indian numbers correctly', () {
      final formatted = CommunicationUtils.formatPhoneForWhatsApp('9876543210');
      expect(formatted, equals('919876543210'));
    });

    test('formatPhoneForWhatsApp strips non-digit characters', () {
      final formatted = CommunicationUtils.formatPhoneForWhatsApp('+91 98765 43210');
      expect(formatted, equals('919876543210'));
    });

    test('formatPhoneForWhatsApp leaves pre-formatted international numbers unchanged', () {
      final formatted = CommunicationUtils.formatPhoneForWhatsApp('919876543210');
      expect(formatted, equals('919876543210'));
    });
  });
}
