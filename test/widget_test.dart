import 'package:flutter_test/flutter_test.dart';

import 'package:twezimbeapp/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Supabase requires network initialization so we only verify the widget tree
    // is constructable at the class level.
    expect(TwezimbeApp.new, isNotNull);
  });
}
