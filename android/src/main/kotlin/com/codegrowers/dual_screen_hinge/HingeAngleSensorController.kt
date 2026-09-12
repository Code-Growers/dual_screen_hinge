package com.codegrowers.dual_screen_hinge

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler

internal class HingeAngleSensorController(
    context: Context,
    handler: Handler,
    onAngle: (Double) -> Unit,
) : SensorEventListener {
    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val sensor = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
        sensorManager.getDefaultSensor(Sensor.TYPE_HINGE_ANGLE)
    } else {
        null
    }
    private val coalescer = AngleFrameCoalescer(
        schedule = { task -> handler.postDelayed(task, FRAME_MILLIS) },
        emit = onAngle,
    )
    private var registered = false

    val isSupported: Boolean get() = sensor != null

    fun setEnabled(enabled: Boolean) {
        if (enabled && !registered && sensor != null) {
            registered = sensorManager.registerListener(
                this,
                sensor,
                SensorManager.SENSOR_DELAY_GAME,
            )
        } else if (!enabled && registered) {
            sensorManager.unregisterListener(this)
            registered = false
        }
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type != Sensor.TYPE_HINGE_ANGLE || event.values.isEmpty()) return
        coalescer.offer(event.values[0].toDouble().coerceIn(0.0, 360.0))
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    private companion object {
        const val FRAME_MILLIS = 16L
    }
}
