import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'database_helper.dart';


// 🔹 Configuração MQTT
const String mqttServer = "a75c63a4fa874ed09517714e6df8d815.s1.eu.hivemq.cloud";
const int mqttPort = 8883;
const String mqttUser = "hivemq.webclient.1740513563954";
const String mqttPassword = "Ix730QlcM2.<CrH&T,vb";
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
      home: RemedioScreen(),
    );
  }
}

class Remedio {
  int? id;
  String nome;
  String horario;
  int numeroCompartimento;

  Remedio({this.id, required this.nome, required this.horario, required this.numeroCompartimento});

  Map<String, dynamic> toMap() {
    return {'id': id, 'nome': nome, 'horario': horario, 'numero_compartimento': numeroCompartimento};
  }

  factory Remedio.fromMap(Map<String, dynamic> map) {
    return Remedio(id: map['id'], nome: map['nome'], horario: map['horario'], numeroCompartimento: map['numero_compartimento']);
  }
}

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
  final databasesPath = await getDatabasesPath();
  final path = p.join(databasesPath, 'remedios.db');

  return await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE remedios (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL,
          horario TEXT NOT NULL,
          numero_compartimento INTEGER NOT NULL
        )
      ''');
    },
  );
}


  Future<int> inserirRemedio(Remedio remedio) async {
    final db = await database;
    return await db.insert('remedios', remedio.toMap());
  }

  Future<List<Remedio>> listarRemedios() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('remedios');
    return List.generate(maps.length, (i) => Remedio.fromMap(maps[i]));
  }

  Future<void> deletarRemedio(int id) async {
    final db = await database;
    await db.delete('remedios', where: 'id = ?', whereArgs: [id]);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Medbox")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: EdgeInsets.all(16), child: Text("📡 Última Notificação:\n$mensagemRecebida")),
          Spacer(),
          Center(
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => _adicionarRemedio(context), // ✅ Agora passando o BuildContext corretamente
                  child: Text("➕ Adicionar Remédio"),
                ),
              ],
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    configurarNotificacoes();
    conectarMQTT();
    resetDatabase();
    _dbHelper = DatabaseHelper();
    //_carregarRemedios();
  }

  void configurarNotificacoes() async {
    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initSettings = InitializationSettings(android: initSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  void enviarMensagem(String nome, String horario, int compartimento) {
  final builder = MqttClientPayloadBuilder();
  builder.addString("$compartimento|$horario|$nome"); // Mensagem no formato "compartimento|horário|nome"

  client.publishMessage(mqttTopicRemedio, MqttQos.atLeastOnce, builder.payload!);
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

  Future<void> conectarMQTT() async {
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

  void _carregarRemedios() async {
    final remedio = await _dbHelper.listarRemedios();
    setState(() {
      _remedios = remedio;
    });
  }

  void _adicionarRemedio(BuildContext context) async {
  TextEditingController nomeController = TextEditingController();
  TextEditingController horarioController = TextEditingController();
  TextEditingController numerocompartimentoController = TextEditingController();

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
              controller: numerocompartimentoController,
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
                  numerocompartimentoController.text.isNotEmpty) {

                int numeroCompartimento = int.tryParse(numerocompartimentoController.text) ?? 1; // Evita erro

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

                enviarMensagem(nomeController.text, horarioController.text, numeroCompartimento);
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
    final path = p.join(databasesPath, 'medicina.db'); // Ou 'remedios.db' se tiver alterado

    await deleteDatabase(path);
  }

}