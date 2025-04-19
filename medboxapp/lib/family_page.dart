import 'package:flutter/material.dart';

class FamilyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Visão Familiar')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.person),
              title: Text('João (Pai)'),
              subtitle: Text('Tomou todos os remédios e sinais vitais estão normais ✅'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.person),
              title: Text('Maria (Avó)'),
              subtitle: Text('Esqueceu 1 remédio. Pressão ligeiramente alta ⚠️'),
            ),
          ),
        ],
      ),
    );
  }
}