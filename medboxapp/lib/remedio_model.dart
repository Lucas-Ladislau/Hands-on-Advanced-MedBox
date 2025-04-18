import 'package:medboxapp/main.dart';

class Remedio {
  int? id;
  String nome;
  String horario;
  int numeroCompartimento;

  Remedio({this.id, required this.nome, required this.horario, required this.numeroCompartimento});

  // Converter um objeto Medicina para um Map (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'horario': horario,
      'numero_compartimento': numeroCompartimento, // Adicionado ao banco
    };
  }

  factory Remedio.fromMap(Map<String, dynamic> map) {
    return Remedio(
      id: map['id'],
      nome: map['nome'],
      horario: map['horario'],
      numeroCompartimento: map['numero_compartimento'], // Adicionado
    );
  }
}