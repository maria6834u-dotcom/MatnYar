// تست ویجت اپلیکیشن متن‌یار

import 'package:flutter_test/flutter_test.dart';
import 'package:matnyar_app/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MatnYarApp());
    
    // بررسی لود شدن اپلیکیشن
    expect(find.text('متن‌یار'), findsOneWidget);
    expect(find.text('تبدیل'), findsOneWidget);
    expect(find.text('بازسازی'), findsOneWidget);
  });
}
