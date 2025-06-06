import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:math_expressions/math_expressions.dart'; // Импорт для математических выражений

import 'firebase_options.dart'; // Импорт сгенерированного файла с конфигурацией Firebase

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Инициализация Firebase с конфигурацией
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,  // Используем конфигурацию для Web и других платформ
    );
    await FirebaseAuth.instance.signInAnonymously();
    print("Firebase успешно инициализирован");
    runApp(MyApp());
  } catch (e) {
    print("Ошибка при инициализации Firebase: $e");
  }
}

// Перечисление для выбора экрана
enum ScreenType { calculator, converter, history }

// Главный виджет приложения
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Калькулятор и Конвертер',
      home: MainPage(),  // Главная страница приложения
    );
  }
}

// Модель калькулятора
class CalculatorModel {
  String expression = '';  // Храним выражение калькулятора
  final uid = FirebaseAuth.instance.currentUser!.uid;  // ID пользователя

  // Ввод значения в калькулятор
  void input(String val) {
    if (val == '.' && expression.endsWith('.')) return;
    expression += val;
  }

  // Очистка выражения
  void clear() {
    expression = '';
  }

  // Метод для вычислений
  Future<String> calculate() async {
    try {
      // Замена символов для корректных вычислений
      final parsed = expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('−', '-')
          .replaceAll(',', '.');

      Parser p = Parser();  // Создаём экземпляр Parser
      Expression exp = p.parse(parsed);  // Парсим выражение
      ContextModel cm = ContextModel();  // Контекст для вычислений
      double result = exp.evaluate(EvaluationType.REAL, cm);  // Выполняем вычисления
      final fixed = double.parse(result.toStringAsFixed(8));  // Округляем результат

      // Сохраняем результат в Firestore
      await FirebaseFirestore.instance.collection('history').add({
        'userId': uid,
        'expression': '$expression = $fixed',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return fixed.toString();  // Возвращаем результат
    } catch (e) {
      print("Ошибка при вычислении: $e");
      return 'Ошибка';
    }
  }

  // Очистка истории вычислений
  Future<void> clearHistory() async {
    final snapshots = await FirebaseFirestore.instance
        .collection('history')
        .where('userId', isEqualTo: uid)
        .get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
    print("История очищена");
  }

  // Поток для получения истории вычислений
  Stream<QuerySnapshot> get historyStream {
    return FirebaseFirestore.instance
        .collection('history')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(50) // Ограничиваем количество записей
        .snapshots();
  }
}

// Главная страница
class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  ScreenType screen = ScreenType.calculator;  // Текущий экран
  final CalculatorModel model = CalculatorModel();  // Модель калькулятора
  final TextEditingController kmController = TextEditingController();  // Контроллер для конвертера
  String miles = '0 miles';  // Результат конвертации
  String expression = '';  // Выражение калькулятора

  // Обработчик кнопок калькулятора
  void handleButton(String value) {
    setState(() {
      if (value == 'C') {
        model.clear();
      } else if (value == '=') {
        model.calculate().then((result) {
          setState(() {
            expression = result;  // Обновляем UI с результатом вычислений
          });
        });
      } else {
        model.input(value);
      }
    });
  }

  // Построение кнопки для калькулятора
  Widget buildButton(String label, {int flex = 1, Color? color}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: () => handleButton(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(label, style: TextStyle(fontSize: 20)),
        ),
      ),
    );
  }

  // Представление экрана калькулятора
  Widget calculatorView() {
    return Column(
      children: [
        Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(color: Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(10)),
          child: Text(expression.isEmpty ? '0' : expression, style: TextStyle(fontSize: 28)),
        ),
        SizedBox(height: 10),
        ...[
          ['C', '±', '%', '÷'],
          ['7', '8', '9', '×'],
          ['4', '5', '6', '−'],
          ['1', '2', '3', '+'],
        ].map((row) => Row(
            children: row.map((e) => buildButton(e, color: ['÷','×','−','+','='].contains(e) ? Colors.orange.shade200 : null)).toList()
        )),
        Row(
            children: [
              buildButton('0', flex: 2),
              buildButton('.'),
              buildButton('=', color: Colors.orange.shade200)
            ]
        ),
        SizedBox(height: 10),
        ElevatedButton(
            onPressed: () {
              setState(() {
                screen = ScreenType.converter;  // Переход к экрану конвертера
              });
            },
            child: Text('Перейти в Конвертер')
        ),
        ElevatedButton(
            onPressed: () {
              setState(() {
                screen = ScreenType.history;  // Переход к экрану истории
              });
            },
            child: Text('Показать Историю')
        ),
      ],
    );
  }

  // Представление экрана конвертера
  Widget converterView() {
    return Column(
      children: [
        Text(miles, style: TextStyle(fontSize: 24)),
        SizedBox(height: 10),
        TextField(
          controller: kmController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: 'Введите километры'),
        ),
        ElevatedButton(
          onPressed: () {
            double? km = double.tryParse(kmController.text);
            setState(() => miles = km == null ? '0 миль' : '${(km * 0.621371).toStringAsFixed(2)} миль');
          },
          child: Text('Конвертировать'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              screen = ScreenType.calculator;  // Назад к калькулятору
            });
          },
          child: Text('Назад к Калькулятору'),
        )
      ],
    );
  }

  // Представление экрана истории
  Widget historyView() {
    return Column(
      children: [
        Text('История вычислений', style: TextStyle(fontSize: 20)),
        SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: model.historyStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Ошибка при получении данных: ${snapshot.error}"));
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Center(child: Text("История пуста"));
              }
              return ListView(
                children: docs
                    .map((doc) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(doc['expression'] ?? ''),
                ))
                    .toList(),
              );
            },
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            await model.clearHistory();  // Очистка истории
            setState(() {});
          },
          child: Text('Очистить историю'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              screen = ScreenType.calculator;  // Назад к калькулятору
            });
          },
          child: Text('Назад к Калькулятору'),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 320,
          padding: EdgeInsets.all(20),
          child: screen == ScreenType.calculator
              ? calculatorView()
              : screen == ScreenType.converter
              ? converterView()
              : historyView(),
        ),
      ),
    );
  }
}
