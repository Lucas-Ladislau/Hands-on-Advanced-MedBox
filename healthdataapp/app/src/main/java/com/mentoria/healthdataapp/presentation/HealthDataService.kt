package com.mentoria.healthdataapp.presentation

import android.content.Context
import android.util.Log
import androidx.health.services.client.HealthServices
import androidx.health.services.client.MeasureCallback
import androidx.health.services.client.data.DataType
import androidx.health.services.client.data.Availability
import androidx.health.services.client.data.DataPointContainer
import androidx.health.services.client.data.DataTypeAvailability
import androidx.health.services.client.unregisterMeasureCallback
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

class HealthDataService(
    private val context: Context,
    private val onUpdate: (String) -> Unit
) {
    private val mqttHelper = MqttHelper(
        serverUri = "6b855318cbf249028a44d6a8610f73e9.s1.eu.hivemq.cloud",
        port = 8883,
        username = "hivemq.webclient.1744490960100",
        password = "2fk,1c30<%TPREj&AZdy",
        topic = "Batimentos"
    )
    private var job: Job? = null
    private val healthClient = HealthServices.getClient(context)
    private val measureClient = healthClient.measureClient

    private val heartRateCallback = object : MeasureCallback {
        override fun onAvailabilityChanged(dataType: androidx.health.services.client.data.DeltaDataType<*, *>, availability: Availability) {
            if (availability is DataTypeAvailability) {
                Log.d("HealthDataService", "Heart rate sensor availability: $availability")
            }
        }

        override fun onDataReceived(data: DataPointContainer) {
            val heartRateDataPoints = data.getData(DataType.HEART_RATE_BPM)
            print("CHEGOUU A FUNÇAO")
            if (heartRateDataPoints.isNotEmpty()) {
                print("ENTROUU")
                print(heartRateDataPoints.last().value)
                val heartRate = heartRateDataPoints.last().value.toFloat()
                // Não precisa montar JSON aqui se só for mostrar na tela
                mqttHelper.publish("{\"heartRate\": $heartRate}")
                onUpdate(heartRate.toString()) // <<-- Passa apenas o valor
            }
        }
//        override fun onDataReceived(data: DataPointContainer) {
//            val heartRateDataPoints = data.getData(DataType.HEART_RATE_BPM)
//            Log.d("HealthDataService", "Received points: $heartRateDataPoints")
//            if (heartRateDataPoints.isNotEmpty()) {
//                val heartRate = heartRateDataPoints.last().value.toFloat()
//                Log.d("HealthDataService", "HeartRate value: $heartRate")
//                onUpdate(heartRate.toString())
//            } else {
//                Log.d("HealthDataService", "No heart rate points")
//            }
//        }
    }

    fun start() {
        job = CoroutineScope(Dispatchers.Main).launch {
            try {
                measureClient.registerMeasureCallback(DataType.HEART_RATE_BPM, heartRateCallback)
            } catch (e: Exception) {
                Log.e("HealthDataService", "Erro ao iniciar coleta", e)
                onUpdate("Erro ao iniciar coleta: ${e.message}")
            }
        }
    }

    suspend fun stop() {
        job?.cancel()
        try {
            measureClient.unregisterMeasureCallback(DataType.HEART_RATE_BPM, heartRateCallback)
        } catch (e: Exception) {
            Log.e("HealthDataService", "Erro ao parar coleta", e)
        }
        mqttHelper.disconnect()
    }
}
