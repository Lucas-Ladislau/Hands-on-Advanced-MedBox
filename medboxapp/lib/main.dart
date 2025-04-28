import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:medboxapp/huffman.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';

import 'database_helper.dart';
import 'remedio_model.dart';
import 'vitals_page.dart';
import 'dashboard_page.dart';
import 'family_page.dart';

import 'dart:async';

const String mqttServer = "HIVE_SERVER";
const int mqttPort = 8883;
const String mqttUser = "HIVE_CLIENT";
const String mqttPassword = "HIVE_PASSWORD";
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
          backgroundColor: const Color.fromARGB(255, 47, 163, 47),
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
    
    Timer.periodic(Duration(seconds: 45), (timer) {
      verificarHorarios();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saudação e ícone
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Bem-vindo(a)!", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                    Text("Sua Rotina de Remédios", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            // Última Notificação
            Card(
              color: Colors.amber[50],
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.notifications_active, color: Colors.amber),
                title: Text("Última Notificação", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(mensagemRecebida, style: TextStyle(fontSize: 16)),
              ),
            ),
            SizedBox(height: 16),
            // Lista de Remédios
            Text(
              "Seus Remédios",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            _remedios.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text("Nenhum remédio cadastrado.", style: TextStyle(fontSize: 16))),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _remedios.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final remedio = _remedios[index];
                      return Card(
                        color: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          leading: Icon(Icons.medication, color: Colors.deepPurple, size: 32),
                          title: Text(remedio.nome, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("⏰ ${remedio.horario}", style: TextStyle(fontSize: 15)),
                              Text("Compartimento: ${remedio.numeroCompartimento}", style: TextStyle(fontSize: 14)),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deletarRemedio(remedio.id!),
                          ),
                        ),
                      );
                    },
                  ),
            SizedBox(height: 28),
            // Botão Adicionar Remédio
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: StadiumBorder(),
                  backgroundColor: Colors.deepPurple,
                  elevation: 4,
                ),
                onPressed: () => _adicionarRemedio(context),
                icon: Icon(Icons.add, color: Colors.white, size: 26),
                label: Text(
                  "Adicionar Remédio",
                  style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 12),
          ],
        ),
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

    client.onDisconnected = () {
      print('MQTT DESCONECTADO. Tentando reconectar em 5 segundos...');
      Future.delayed(Duration(seconds: 5), () {
        conectarMQTT();
      });
    };

    try {
      await client.connect();
      if (client.connectionStatus?.state == MqttConnectionState.connected) {
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
      }else{
        print('Erro ao conectar MQTT: ${client.connectionStatus}');
      }
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
    // final mensagemOriginal = "$compartimento|$horario|$nome";
    final mensagemOriginal = "Remedio $compartimento";

    // Gera compressão
    final huffman = HuffmanCoding();
    final mensagemComprimida = huffman.compress(mensagemOriginal);

    // Serializa o mapa de códigos como string JSON-like
    final codigos = jsonEncode(huffman.codes);

    // Cria payload no formato: códigos ||| mensagem_comprimida
    final payload = "$codigos|||$mensagemComprimida";
    builder.addString(payload);

    // Publica no MQTT
    client.publishMessage(mqttTopicRemedio, MqttQos.atLeastOnce, builder.payload!);

    // Medir os tamanhos
    // final tamanhoOriginalChars = mensagemOriginal.length;
    // final tamanhoOriginalBytes = utf8.encode(mensagemOriginal).length;
    // final tamanhoComprimidoBits = mensagemComprimida.length;
    // final tamanhoComprimidoBytes = (tamanhoComprimidoBits / 8).ceil(); 

    // Mostrar resultados
    // print("Mensagem original: $mensagemOriginal");
    // print("Tamanho original: $tamanhoOriginalChars caracteres / $tamanhoOriginalBytes bytes");
    // print("Mensagem comprimida (bits): $mensagemComprimida");
    // print("Tamanho comprimido: $tamanhoComprimidoBits bits ≈ $tamanhoComprimidoBytes bytes");
    // print("Tabela de códigos: ${huffman.codes}");
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
  TextEditingController frequenciaController = TextEditingController();
  TextEditingController duracaoController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Adicionar Remédio"),
        content: SingleChildScrollView(
          child: Column(
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
              TextField(
                controller: frequenciaController,
                decoration: InputDecoration(labelText: "Frequência(em horas)"),
              ),
              TextField(
                controller: duracaoController,
                decoration: InputDecoration(labelText: "Duração(em dias)"),
              ),
            ],
          ),
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
