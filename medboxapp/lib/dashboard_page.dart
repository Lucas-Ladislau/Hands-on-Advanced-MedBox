import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
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
              Text(
                "Olá, tudo bem? 👋",
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              SizedBox(height: 8),
              Text(
                "Seu progresso semanal",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
              _buildProgressCard(context, "Remédios tomados", 6, 7, Icons.check_circle, Colors.green),
              SizedBox(height: 16),
              Text(
                "Calendário de hábitos",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),  
              SizedBox(height: 12),
              _buildHabitCalendar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, String title, int current, int total, IconData icon, Color color) {
    double percent = current / total;
    return Card(
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