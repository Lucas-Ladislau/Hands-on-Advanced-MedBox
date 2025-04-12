import 'package:medboxapp/main.dart';

class remedio {
  int? id;
  String nome;
  String horario;
  int numeroCompartimento;

  remedio({this.id, required this.nome, required this.horario, required this.numeroCompartimento});

  // Converter um objeto Medicina para um Map (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'horario': horario,
      'numero_compartimento': numeroCompartimento, // Adicionado ao banco
    };
  }

  factory remedio.fromMap(Map<String, dynamic> map) {
    return remedio(
      id: map['id'],
      nome: map['nome'],
      horario: map['horario'],
      numeroCompartimento: map['numero_compartimento'], // Adicionado
    );
  }
}