import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import 'database_helper.dart';
import 'remedio_model.dart';
import 'vitals_page.dart';
import 'dashboard_page.dart';
import 'family_page.dart';

import 'dart:async';

const String mqttServer = "6b855318cbf249028a44d6a8610f73e9.s1.eu.hivemq.cloud";
const int mqttPort = 8883;
const String mqttUser = "hivemq.webclient.1744490960100";
const String mqttPassword = "2fk,1c30<%TPREj&AZdy";
const String mqttTopicUmidade = "Umidade";
const String mqttTopicRemedio = "Remedios";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medbox',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Color(0xFFF4F0FA),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
          selectedIconTheme: IconThemeData(size: 28),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
      home: HomeController(),
    );
  }
}

class HomeController extends StatefulWidget {
  @override
  _HomeControllerState createState() => _HomeControllerState();
}

class _HomeControllerState extends State<HomeController> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    RemedioScreen(),
    VitalsPage(),
    DashboardPage(),
    FamilyPage(),
  ];

  final List<PreferredSizeWidget?> _appBars = [
    AppBar(
      title: Text('MedBox', style: TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
    ),
    null,
    null,
    null,
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBars[_selectedIndex],
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Vitais'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Desempenho'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Familiar'),
        ],
      ),
    );
  }
}

class RemedioScreen extends StatefulWidget {
  @override
  _RemedioScreenState createState() => _RemedioScreenState();
}

class _RemedioScreenState extends State<RemedioScreen> {
  late MqttServerClient client;
  String mensagemRecebida = "Aguardando notificações...";
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  late DatabaseHelper _dbHelper;
  List<Remedio> _remedios = [];

  @override
  void initState() {
    super.initState();
    configurarNotificacoes();
    conectarMQTT();
    _dbHelper = DatabaseHelper();
    // resetDatabase();
    _carregarRemedios();

    Timer.periodic(Duration(seconds: 15), (timer) {
      verificarHorarios();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "📡 Última Notificação:\n$mensagemRecebida",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: _remedios.isEmpty
                ? Center(
                    child: Text("Nenhum remédio cadastrado.", style: TextStyle(fontSize: 16)),
                  )
                : ListView.builder(
                    itemCount: _remedios.length,
                    itemBuilder: (context, index) {
                      final remedio = _remedios[index];
                      return Card(
                        color: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: Icon(Icons.medication, color: Colors.deepPurple),
                          title: Text(remedio.nome),
                          subtitle: Text("⏰ ${remedio.horario} • Compartimento: ${remedio.numeroCompartimento}"),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deletarRemedio(remedio.id!),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: StadiumBorder(),
                  backgroundColor: Colors.deepPurple,
                ),
                onPressed: () => _adicionarRemedio(context),
                icon: Icon(Icons.add, color: Colors.white),
                label: Text(
                  "Adicionar Remédio",
                  style: TextStyle(color: Colors.amber), // 👈 Cor personalizada aqui
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void configurarNotificacoes() async {
    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initSettings = InitializationSettings(android: initSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  void conectarMQTT() async {
    client = MqttServerClient(mqttServer, 'flutter_client');
    client.port = mqttPort;
    client.secure = true;
    client.setProtocolV311();
    client.logging(on: false);

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .authenticateAs(mqttUser, mqttPassword)
        .startClean();

    client.connectionMessage = connMessage;

    try {
      await client.connect();
      client.subscribe(mqttTopicUmidade, MqttQos.atLeastOnce);
      client.subscribe(mqttTopicRemedio, MqttQos.atLeastOnce);

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? event) {
        if (event != null && event.isNotEmpty) {
          final recMessage = event[0].payload as MqttPublishMessage;
          final payload =
              MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);
          setState(() {
            mensagemRecebida = payload;
          });

          if (event[0].topic == mqttTopicUmidade && payload.contains("alta")) {
            exibirNotificacao("🚨 Alerta!", "Umidade elevada na caixa!");
          }
          if (event[0].topic == mqttTopicRemedio && payload.contains("apagado")) {
            exibirNotificacao("✅ Confirmação", "Remédio tomado!");
          }
        }
      });
    } catch (e) {
      client.disconnect();
    }
  }

  void verificarHorarios() async {
  final now = TimeOfDay.now();
  var horaAtual = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

  final remedios = await _dbHelper.listarRemedios();
  for (var remedio in remedios) {
    if (remedio.horario == horaAtual) {
      enviarMensagem(remedio.nome, remedio.horario, remedio.numeroCompartimento);
      exibirNotificacao(
        "💊 Hora do Remédio!",
        "${remedio.nome} no compartimento ${remedio.numeroCompartimento}",
      );
    }
  }
}

  

  Future<void> exibirNotificacao(String titulo, String mensagem) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'canal_alertas', 'Alertas de Sensor',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(0, titulo, mensagem, platformDetails);
  }

  void enviarMensagem(String nome, String horario, int compartimento) {
    final builder = MqttClientPayloadBuilder();
    builder.addString("$compartimento|$horario|$nome"); // Mensagem no formato "compartimento|horário|nome"

    client.publishMessage(mqttTopicRemedio, MqttQos.atLeastOnce, builder.payload!);
  }

  void _carregarRemedios() async {
    final remedio = await _dbHelper.listarRemedios();
    setState(() {
      _remedios = remedio;
    });
  }

  void _adicionarRemedio(BuildContext context) async {
    TextEditingController nomeController = TextEditingController();
    TextEditingController horarioController = TextEditingController();
    TextEditingController compartimentoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Adicionar Remédio"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: InputDecoration(labelText: "Nome"),
              ),
              TextField(
                controller: horarioController,
                decoration: InputDecoration(labelText: "Horário (HH:MM)"),
              ),
              TextField(
                controller: compartimentoController,
                decoration: InputDecoration(labelText: "Número do Compartimento"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nomeController.text.isNotEmpty &&
                    horarioController.text.isNotEmpty &&
                    compartimentoController.text.isNotEmpty) {

                  int numeroCompartimento = int.tryParse(compartimentoController.text) ?? 1;

                  await _dbHelper.inserirRemedio(
                    Remedio(
                      nome: nomeController.text,
                      horario: horarioController.text,
                      numeroCompartimento: numeroCompartimento,
                    ),
                  );

                  setState(() {
                    _carregarRemedios();
                  });

                  Navigator.pop(context);
                }
              },
              child: Text("Salvar"),
            ),
          ],
        );
      },
    );
  }

  void _deletarRemedio(int id) async {
    await _dbHelper.deletarRemedio(id);
    _carregarRemedios();
  }

  void resetDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'remedios.db');
    await deleteDatabase(path);
  }
}
