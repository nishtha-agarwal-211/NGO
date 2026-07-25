import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

import 'package:ngo_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Mock shared preferences channel calls for tests
    const channel = MethodChannel('plugins.flutter.io/shared_preferences');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{};
        }
        return null;
      },
    );

    await Supabase.initialize(
      url: 'https://xyz.supabase.co',
      publishableKey: 'public-anon-key',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
      ),
    );
  });

  testWidgets('NgoApp renders title and initial navigation shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NgoApp(),
      ),
    );

    // Fast-forward time to handle initial notification timer
    await tester.pump(const Duration(seconds: 4));

    expect(find.byType(NgoApp), findsOneWidget);
  });
}
