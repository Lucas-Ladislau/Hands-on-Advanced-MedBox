// vitals_page.dart
import 'package:flutter/material.dart';

class VitalsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sinais Vitais')),
      body: Center(
        child: Text(
          '❤️ Batimento Cardíaco: 75 bpm\n🩸 Pressão: 120/80\n🫁 Saturação: 98%',
          style: TextStyle(fontSize: 22),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}