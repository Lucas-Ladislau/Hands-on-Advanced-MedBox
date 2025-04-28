package com.mentoria.healthdataapp.presentation

import android.util.Log
import com.hivemq.client.mqtt.MqttClient
import com.hivemq.client.mqtt.mqtt3.Mqtt3AsyncClient
import java.nio.charset.StandardCharsets
import java.util.*

class MqttHelper(
    serverUri: String = "6b855318cbf249028a44d6a8610f73e9.s1.eu.hivemq.cloud",
    port: Int = 8883,
    username: String = "hivemq.webclient.1744490960100",
    password: String = "2fk,1c30<%TPREj&AZdy",
    private val topic: String = "Batimentos"
) {
    private val mqttClient: Mqtt3AsyncClient = MqttClient.builder()
        .useMqttVersion3()
        .identifier("wearos_" + UUID.randomUUID().toString())
        .serverHost(serverUri)
        .serverPort(port)
        .sslWithDefaultConfig() // SSL/TLS obrigatório para porta 8883 (HiveMQ Cloud)
        .buildAsync()

    init {
        connect(username, password)
    }

    private fun connect(username: String, password: String) {
        mqttClient.connectWith()
            .simpleAuth()
            .username(username)
            .password(password.toByteArray(StandardCharsets.UTF_8))
            .applySimpleAuth()
            .send()
            .whenComplete { _, throwable ->
                if (throwable != null) {
                    Log.e("MqttHelper", "Falha ao conectar MQTT: ${throwable.message}")
                } else {
                    Log.d("MqttHelper", "Conectado ao MQTT broker!")
                }
            }
    }

    fun publish(message: String) {
        mqttClient.publishWith()
            .topic(topic)
            .payload(message.toByteArray(StandardCharsets.UTF_8))
            .send()
            .whenComplete { _, throwable ->
                if (throwable != null) {
                    Log.e("MqttHelper", "Erro ao publicar MQTT: ${throwable.message}")
                }
            }
    }

    fun disconnect() {
        mqttClient.disconnect()
    }
}