package com.mentoria.healthdataapp

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.TextView
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import com.mentoria.healthdataapp.presentation.HealthDataService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity() {
    private lateinit var textStatus: TextView
    private lateinit var healthService: HealthDataService

    private val permissions = arrayOf(
        Manifest.permission.BODY_SENSORS,
        Manifest.permission.ACTIVITY_RECOGNITION,
        Manifest.permission.INTERNET
    )

    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissionsResult ->
        if (permissionsResult.values.all { it }) {
            startCollection()
        } else {
            textStatus.text = "Permissões negadas. Não é possível coletar dados."
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        textStatus = findViewById(R.id.textStatus)

        if (permissions.all {
                ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
            }) {
            startCollection()
        } else {
            requestPermissionLauncher.launch(permissions)
        }
    }

    private fun startCollection() {
        textStatus.text = "Coletando dados..."
        healthService = HealthDataService(this) { heartRateString ->
            runOnUiThread {
                textStatus.text = "Batimentos: $heartRateString bpm"
            }
        }
        healthService.start()
    }

    override fun onStop() {
        super.onStop()
        if (::healthService.isInitialized) {
            // Rode o stop() em uma coroutine, pois ele é suspend
            CoroutineScope(Dispatchers.Main).launch {
                healthService.stop()
            }
        }
    }
}