import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'database_helper.dart';
import 'remedio_model.dart';
import 'huffman.dart';
import 'dart:async';
// import 'package:flutter/material.dart';


// 🔹 Configuração MQTT
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
    Padding(
      padding: EdgeInsets.all(16),
      child: Text("📡 Última Notificação:\n$mensagemRecebida"),
    ),
    Expanded(
      child: ListView.builder(
        itemCount: _remedios.length,
        itemBuilder: (context, index) {
          final remedio = _remedios[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(Icons.medication),
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
        padding: const EdgeInsets.only(bottom: 20),
        child: ElevatedButton(
          onPressed: () => _adicionarRemedio(context),
          child: Text("➕ Adicionar Remédio"),
        ),
      ),
    ),
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

    _carregarRemedios();
    
    // Roda a verificação a cada 30 segundos
    Timer.periodic(Duration(seconds: 15), (timer) {
      verificarHorarios();
    });
  }

  void verificarHorarios() async {
    final now = TimeOfDay.now();
    var horaAtual = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    print("Hora atual: $horaAtual");  


    final remedios = await _dbHelper.listarRemedios();
    print("ENTROUUUU");
    for (var remedio in remedios) {
      if (remedio.horario == horaAtual) {
        // Evita envio repetido: só envia 1x por minuto
        print("hora do remedio !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        // enviarMensagem(remedio.nome, remedio.horario, remedio.numeroCompartimento);
        // exibirNotificacao("💊 Hora do Remédio!", "${remedio.nome} no compartimento ${remedio.numeroCompartimento}");
      }
    }
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
            print("Umidade detectada");
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
    final path = p.join(databasesPath, 'remedios.db'); // Ou 'remedios.db' se tiver alterado

    await deleteDatabase(path);
  }

}