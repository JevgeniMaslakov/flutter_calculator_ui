import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.signInAnonymously();
  runApp(MyApp());
}

enum ScreenType { calculator, converter, history }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Калькулятор и Конвертер',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey[900],
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: MainPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CalculatorModel {
  String _expression = '';
  String lastResult = '';
  final uid = FirebaseAuth.instance.currentUser?.uid;

  String get expression => _expression;
  set expression(String val) => _expression = val;

  void input(String val) {
    if (val == '.' && _expression.endsWith('.')) return;
    _expression += val;
  }

  void clear() {
    _expression = '';
    lastResult = '';
  }

  Future<String> calculate() async {
    try {
      final parsed = _expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('−', '-')
          .replaceAll(',', '.');

      if (parsed.trim().isEmpty) return '';

      Parser p = Parser();
      Expression exp = p.parse(parsed);
      ContextModel cm = ContextModel();
      double result = exp.evaluate(EvaluationType.REAL, cm);
      final fixed = double.parse(result.toStringAsFixed(8));
      lastResult = fixed.toString();

      if (uid != null) {
        await FirebaseFirestore.instance.collection('history').add({
          'userId': uid,
          'expression': _expression,
          'result': fixed.toString(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      return lastResult;
    } catch (e) {
      print("Ошибка при вычислении: $e");
      return 'Ошибка';
    }
  }

  Future<void> clearHistory() async {
    final snapshots = await FirebaseFirestore.instance
        .collection('history')
        .where('userId', isEqualTo: uid)
        .get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }

  Stream<QuerySnapshot> get historyStream {
    return FirebaseFirestore.instance
        .collection('history')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}

class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  ScreenType screen = ScreenType.calculator;
  final CalculatorModel model = CalculatorModel();
  final TextEditingController kmController = TextEditingController();
  String miles = '0 миль';
  String expression = '';
  String result = '';

  void handleButton(String value) {
    setState(() {
      if (value == 'C') {
        model.clear();
        expression = '';
        result = '';
      } else if (value == '=') {
        final current = model.expression;
        model.calculate().then((res) {
          setState(() {
            result = res;
          });
        });
      } else if (value == '±') {
        if (model.expression.isNotEmpty) {
          final match = RegExp(r'(\-?\d+\.?\d*)\$').firstMatch(model.expression);
          if (match != null) {
            final number = match.group(0)!;
            final negated = number.startsWith('-') ? number.substring(1) : '-$number';
            model.expression = model.expression.substring(0, match.start) + negated;
          }
        }
        expression = model.expression;
      } else {
        model.input(value);
        expression = model.expression;
      }
    });
  }

  Widget buildButton(String label, {int flex = 1, Color? color}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: ElevatedButton(
          onPressed: () => handleButton(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.grey[850],
            foregroundColor: color != null ? Colors.black : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
          ),
          child: Text(label, style: TextStyle(fontSize: 22)),
        ),
      ),
    );
  }

  Widget calculatorView() {
    return Column(
      children: [
        Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(expression.isEmpty ? '0' : expression,
                  style: TextStyle(fontSize: 26, color: Colors.white70)),
              Text(result.isEmpty ? '' : '= $result',
                  style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(height: 20),
        ...[
          ['C', '±', '%', '÷'],
          ['7', '8', '9', '×'],
          ['4', '5', '6', '−'],
          ['1', '2', '3', '+'],
        ].map((row) => Row(
          children: row
              .map((e) => buildButton(e, color: ['÷', '×', '−', '+', '='].contains(e) ? Colors.orangeAccent : null))
              .toList(),
        )),
        Row(
          children: [
            buildButton('0', flex: 2),
            buildButton('.'),
            buildButton('=', color: Colors.orangeAccent),
          ],
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => setState(() => screen = ScreenType.converter),
              child: Text('Конвертер'),
            ),
            ElevatedButton(
              onPressed: () => setState(() => screen = ScreenType.history),
              child: Text('История'),
            ),
          ],
        ),
      ],
    );
  }

  Widget converterView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 40),
        Center(child: Text(miles, style: TextStyle(fontSize: 26, color: Colors.white))),
        SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: TextField(
            controller: kmController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Введите километры',
              hintStyle: TextStyle(color: Colors.white70),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            ),
          ),
        ),
        SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  double? km = double.tryParse(kmController.text);
                  setState(() => miles = km == null ? '0 миль' : '${(km * 0.621371).toStringAsFixed(2)} миль');
                },
                child: Text('Конвертировать'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => setState(() => screen = ScreenType.calculator),
                child: Text('Назад'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget historyView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('История вычислений', style: TextStyle(fontSize: 20, color: Colors.white)),
        SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: model.historyStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Ошибка: ${snapshot.error}'));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(child: Text('История пуста', style: TextStyle(color: Colors.white70)));
              }
              return ListView(
                children: docs.map((doc) {
                  final timestamp = doc['timestamp'] as Timestamp?;
                  final formatted = timestamp != null
                      ? DateFormat('dd.MM.yyyy HH:mm').format(timestamp.toDate())
                      : '';
                  final expression = doc['expression'] ?? '';
                  final result = doc['result'] ?? '';
                  return Card(
                    color: Colors.grey[850],
                    margin: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: ListTile(
                      title: Text('$expression = $result', style: TextStyle(color: Colors.white)),
                      subtitle: Text(formatted, style: TextStyle(color: Colors.white70)),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () async {
                  await model.clearHistory();
                  setState(() {});
                },
                child: Text('Очистить историю'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() => screen = ScreenType.calculator),
                child: Text('Назад'),
              ),
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 380),
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
