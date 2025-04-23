import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Good Morning", style: TextStyle(fontSize: 18, color: Colors.grey)),
                      Text("Lucas", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage('assets/avatar.png'),
                  )
                ],
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: "Search",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Measurements", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("All Signs", style: TextStyle(color: Colors.blue))
                ],
              ),
              SizedBox(height: 12),
              buildMetricCard(
                title: "Blood Pressure (bpm)",
                value: pressao,
                subtitle: "7 min ago",
                color: Colors.red,
                icon: Icons.monitor_heart,
              ),
              buildMetricCard(
                title: "Blood Oxygen (SpO₂)",
                value: "$spo2%",
                subtitle: "7 min ago",
                color: Colors.orange,
                icon: Icons.air,
              ),
              buildMetricCard(
                title: "Steps Count",
                value: "$passos Steps",
                subtitle: "Last 7 days",
                color: Colors.blue,
                icon: Icons.directions_walk,
              ),
            ],
          ),
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
