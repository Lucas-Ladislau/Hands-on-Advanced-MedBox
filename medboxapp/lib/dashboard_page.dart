import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Desempenho', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      backgroundColor: Color(0xFFF4F6FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saudação e título
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.emoji_events, color: Colors.white, size: 30),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Olá, tudo bem? 👋",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    Text(
                      "Seu Progresso Semanal",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),
            // Card de progresso de remédios
            _buildProgressCard(context, "Remédios tomados", 6, 7, Icons.check_circle, Colors.green),
            SizedBox(height: 16),
            // Calendário de hábitos
            Text(
              "Calendário de hábitos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            _buildHabitCalendar(),
            SizedBox(height: 24),
            // Card motivacional ou espaço extra para futuras metas
            Card(
              color: Colors.deepPurple[50],
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.deepPurple, size: 32),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        "Continue assim! Cada dia cuidando da sua saúde conta. 🎉",
                        style: TextStyle(fontSize: 16, color: Colors.deepPurple[900], fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, String title, int current, int total, IconData icon, Color color) {
    double percent = current / total;
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
            SizedBox(height: 8),
            Text("$current de $total", style: TextStyle(color: Colors.grey[600]))
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCalendar() {
    List<String> days = ["S", "T", "Q", "Q", "S", "S", "D"];
    List<bool> status = [true, true, true, false, true, false, false];

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            return Column(
              children: [
                Text(days[index], style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: status[index] ? Colors.green : Colors.grey[300],
                  child: Icon(
                    status[index] ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}