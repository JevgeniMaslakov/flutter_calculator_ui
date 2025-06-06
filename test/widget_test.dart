import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_calculator/main.dart';  // Используйте правильное имя пакета

void main() {
  testWidgets('Calculator UI responds to input', (WidgetTester tester) async {
    // Размещение приложения для тестирования
    await tester.pumpWidget(MaterialApp(home: MyApp()));

    // Убедитесь, что экран начинается с 0
    expect(find.text('0'), findsOneWidget);

    // Нажимаем на кнопку '1'
    await tester.tap(find.text('1'));  // находим кнопку с текстом '1'
    await tester.pump();

    // Проверяем, что на экране теперь отображается '1'
    expect(find.text('1'), findsOneWidget);
  });
}
