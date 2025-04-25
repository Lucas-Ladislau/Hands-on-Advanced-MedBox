import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:fl_chart/fl_chart.dart';

class VitalsPage extends StatefulWidget {
  @override
  _VitalsPageState createState() => _VitalsPageState();
}

class _VitalsPageState extends State<VitalsPage> {
  int batimentos = 141;
  String pressao = '141/90';
  int spo2 = 90;
  int passos = 3133;

  late MqttServerClient client;

  @override
  void initState() {
    super.initState();
    configurarMQTT();
  }

  void configurarMQTT() async {
    client = MqttServerClient('6b855318cbf249028a44d6a8610f73e9.s1.eu.hivemq.cloud', 'vitals_client');
    client.port = 8883;
    client.secure = true;
    client.setProtocolV311();
    client.logging(on: false);

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('vitals_client')
        .authenticateAs('hivemq.webclient.1744490960100', '2fk,1c30<%TPREj&AZdy')
        .startClean();

    client.connectionMessage = connMessage;

    try {
      await client.connect();
      client.subscribe('smartwatch/vitals', MqttQos.atLeastOnce);

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? event) {
        final recMess = event![0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        print("Mensagem recebida no vitals: $payload");
      });
    } catch (e) {
      print('Erro na conexão MQTT do VitalsPage: $e');
      client.disconnect();
    }
  }

  Widget buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Icon(icon, color: color),
              ],
            ),
            SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
final List<double> batimentosRecentes = [76, 80, 78, 83, 75, 77, 79, 78, 81, 77];

Widget buildBatimentosChart() {
  return Card(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: Colors.pink, size: 28),
              SizedBox(width: 10),
              Text("Evolução dos Batimentos", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    spots: List.generate(
                      batimentosRecentes.length,
                      (i) => FlSpot(i.toDouble(), batimentosRecentes[i]),
                    ),
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    color: Colors.pink,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Sinais Vitais', style: TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
    ),
    backgroundColor: Color(0xFFF4F6FA),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sinais Vitais
          Text(
            "Últimos dados registrados",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          // Pressão
          Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: Icon(Icons.monitor_heart, color: Colors.red, size: 32),
              title: Text("Pressão Arterial", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("$pressao mmHg\nMedido há 7 min", style: TextStyle(fontSize: 15)),
            ),
          ),
          SizedBox(height: 10),
          // Saturação
          Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: Icon(Icons.air, color: Colors.blue, size: 32),
              title: Text("Oxigenação (SpO₂)", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("$spo2%\nMedido há 7 min", style: TextStyle(fontSize: 15)),
            ),
          ),
          SizedBox(height: 10),
          // Batimentos
          Card(
  color: Colors.white,
  elevation: 2,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  child: ExpansionTile(
    leading: Icon(Icons.favorite, color: Colors.pink, size: 32),
    title: Text("Batimentos Cardíacos", style: TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text("$batimentos bpm\nMedido há 7 min", style: TextStyle(fontSize: 15)),
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: buildBatimentosChart(),
      ),
    ],
  ),
),
          SizedBox(height: 10),
          // Passos
          Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: Icon(Icons.directions_walk, color: Colors.green, size: 32),
              title: Text("Contagem de Passos", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("$passos passos\nÚltimos 7 dias", style: TextStyle(fontSize: 15)),
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: Text(
              "Lembre-se de cuidar bem da sua saúde! 💙",
              style: TextStyle(fontSize: 16, color: Colors.deepPurple, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );
}

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }
}
