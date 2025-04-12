#include <WiFi.h>
#include <PubSubClient.h>
#include <WiFiClientSecure.h>
#include <DHT.h>

// Configurações de rede Wi-Fi
const char* ssid = "Starlink_CIT";
const char* password = "Ufrr@2024Cit";

// Configurações do HiveMQ Broker
const char* mqtt_server = "a75c63a4fa874ed09517714e6df8d815.s1.eu.hivemq.cloud";
const char* mqtt_topic1 = "Umidade";
const char* mqtt_topic2 = "Remedios";
const char* mqtt_username = "hivemq.webclient.1740513563954";
const char* mqtt_password = "Ix730QlcM2.<CrH&T,vb";
const int mqtt_port = 8883;

WiFiClientSecure espClient;
PubSubClient client(espClient);

// Definição dos pinos
#define led_remedio1 32
#define led_remedio2 22
#define buzzer 21
#define trigPin 18        // Pino de Trigger do HC-SR04
#define echoPin 19        // Pino de Echo do HC-SR04
#define dhtPin 33         // Pino de dados do DHT11

DHT dht(dhtPin, DHT11);

// Função de callback para receber mensagens MQTT
void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("Mensagem recebida: ");
  String message;
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  Serial.println(message);

  // Aciona os LEDs e o buzzer com base no tópico recebido
  if (message == "Remedio registrado: Remedio 1\") {
    acionaLedEBuzzer(led_remedio1, "Remédio 1");
  } else if (message == "Remedio registrado: Remedio 2") {
    acionaLedEBuzzer(led_remedio2, "Remédio 2");
  }
} 

// Função para conectar ao Wi-Fi
void setup_wifi() {
  delay(10);
  Serial.println("Conectando ao Wi-Fi...");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWi-Fi conectado.");
}

// Função para reconectar ao broker MQTT
void reconnect() {
  while (!client.connected()) {
    Serial.print("Tentando se reconectar ao MQTT...");
    if (client.connect("ESP32Client", mqtt_username, mqtt_password)) {
      Serial.println("Conectado.");
      client.subscribe(mqtt_topic1);  // Inscreve-se no tópico
    } else {
      Serial.print("Falha, rc=");
      Serial.print(client.state());
      Serial.println(" tentando novamente em 5 segundos.");
      delay(5000);
    }
  }
}

// Função para acionar o LED e o buzzer, desligando-os quando a pessoa se aproxima
void acionaLedEBuzzer(int ledPin, const char* nomeRemedio) {
  Serial.println("Entrou");
  digitalWrite(ledPin, HIGH);  // Liga o LED
  tone(buzzer, 5000);          // Aciona o buzzer (5000Hz)
  Serial.println(nomeRemedio);

  // Aguarda a pessoa se aproximar (distância ≤ 5 cm) para desligar LED e buzzer
  while (medirDistancia() > 5) {
    delay(100);
  }

  digitalWrite(ledPin, LOW);
  noTone(buzzer);
  Serial.println("Distância atingida, desligando LED e buzzer.");
}

// Função para medir a distância com o HC-SR04
long medirDistancia() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  
  long duracao = pulseIn(echoPin, HIGH);
  long distancia = (duracao / 2) * 0.0343;
  return distancia;
}

// Função para ler dados do DHT11 e enviar alerta se necessário
void lerTemperaturaEUmidade() {
  float temperatura = dht.readTemperature();
  float umidade = dht.readHumidity();
  
  if (isnan(temperatura) || isnan(umidade)) {
    Serial.println("Falha ao ler do DHT11");
  } else {
    Serial.print("Temperatura: ");
    Serial.print(temperatura);
    Serial.print("°C  Umidade: ");
    Serial.print(umidade);
    Serial.println("%");

    if (umidade > 80) {
      Serial.println("🚨 Alerta: Umidade acima de 80%");
      tone(buzzer, 1000);
      client.publish(mqtt_topic2, "Umidade acima de 80%");

      // Aguarda a pessoa se aproximar (≤ 5 cm) para desligar o buzzer
      while (medirDistancia() > 5) {
        delay(100);
      }
      noTone(buzzer);
      Serial.println("Pessoa se aproximou, buzzer desligado.");
    } else {
      noTone(buzzer);
    }
  }
}

void setup() {
  Serial.begin(115200);

  pinMode(led_remedio1, OUTPUT);
  pinMode(led_remedio2, OUTPUT);
  pinMode(buzzer, OUTPUT);
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);

  dht.begin();

  setup_wifi();
  espClient.setInsecure();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  Serial.print("Distância: ");
  Serial.print(medirDistancia());
  Serial.println(" cm");
  
  lerTemperaturaEUmidade();
  
  delay(5000);
}
