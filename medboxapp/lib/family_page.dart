import 'package:flutter/material.dart';

class FamilyPage extends StatelessWidget {
  final List<Map<String, dynamic>> familiares = [
    {
      'nome': 'João (Pai)',
      'status': 'Tomou todos os remédios e sinais vitais estão normais ✅',
      'vitals': {'pressao': '120/80', 'batimentos': 76, 'spo2': 98},
      'remedios': [
        {'nome': 'Enalapril', 'horario': '08:00', 'tomado': true},
        {'nome': 'AAS', 'horario': '12:00', 'tomado': true},
        {'nome': 'Metformina', 'horario': '18:00', 'tomado': true},
      ],
      'agendados': 3,
      'tomados': 3,
    },
    {
      'nome': 'Maria (Avó)',
      'status': 'Esqueceu 1 remédio. Pressão ligeiramente alta ⚠️',
      'vitals': {'pressao': '144/95', 'batimentos': 82, 'spo2': 95},
      'remedios': [
        {'nome': 'Losartana', 'horario': '09:00', 'tomado': true},
        {'nome': 'Glifage', 'horario': '13:00', 'tomado': false},
      ],
      'agendados': 2,
      'tomados': 1,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Acompanhamento Familiar', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      backgroundColor: Color(0xFFF4F6FA),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: familiares.length,
        itemBuilder: (context, index) {
          final pessoa = familiares[index];
          return Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Icon(Icons.person, color: Colors.deepPurple, size: 32),
              title: Text(pessoa['nome'], style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(pessoa['status']),
              trailing: Icon(Icons.chevron_right, color: Colors.deepPurple),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
                  builder: (_) => _buildDetalhes(context, pessoa),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetalhes(BuildContext context, Map<String, dynamic> pessoa) {
    final vitals = pessoa['vitals'];
    final remedios = pessoa['remedios'] as List;
    int agendados = pessoa['agendados'];
    int tomados = pessoa['tomados'];
    bool tudoOk = tomados == agendados;

    return SingleChildScrollView(
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300], borderRadius: BorderRadius.circular(3)),
            ),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.person, color: Colors.deepPurple, size: 34),
              SizedBox(width: 12),
              Text(pessoa['nome'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            ],
          ),
          SizedBox(height: 14),
          Text("Sinais Vitais", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          SizedBox(height: 8),
          Row(
            children: [
              _buildVital('Pressão', vitals['pressao'], Icons.monitor_heart, Colors.red),
              SizedBox(width: 14),
              _buildVital('Batimentos', '${vitals['batimentos']} bpm', Icons.favorite, Colors.pink),
              SizedBox(width: 14),
              _buildVital('SpO₂', '${vitals['spo2']}%', Icons.air, Colors.blue),
            ],
          ),
          SizedBox(height: 18),
          Text("Medicamentos do dia", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          ...remedios.map<Widget>((remedio) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              remedio['tomado'] ? Icons.check_circle : Icons.radio_button_unchecked,
              color: remedio['tomado'] ? Colors.green : Colors.orange,
            ),
            title: Text(remedio['nome'], style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text("Horário: ${remedio['horario']}"),
            trailing: remedio['tomado']
                ? Text("Tomado", style: TextStyle(color: Colors.green))
                : Text("Pendente", style: TextStyle(color: Colors.orange)),
          )),
          SizedBox(height: 8),
          Card(
            color: tudoOk ? Colors.green[50] : Colors.orange[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(tudoOk ? Icons.check_circle : Icons.error, color: tudoOk ? Colors.green : Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tudoOk
                        ? "Todos os medicamentos foram tomados corretamente hoje. Excelente!"
                        : "Atenção: Existem medicamentos pendentes. Verifique com ${pessoa['nome'].split(' ')[0]}.",
                      style: TextStyle(fontWeight: FontWeight.bold, color: tudoOk ? Colors.green[900] : Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
        ],
      ),
      ),
    );
  }

  Widget _buildVital(String label, String valor, IconData icon, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            children: [
              Icon(icon, color: color),
              SizedBox(height: 5),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              Text(valor, style: TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}