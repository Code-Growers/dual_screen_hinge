package com.codegrowers.dual_screen_hinge

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.window.area.WindowAreaCapability.Operation.Companion.OPERATION_PRESENT_ON_AREA
import androidx.window.area.WindowAreaCapability.Operation.Companion.OPERATION_TRANSFER_ACTIVITY_TO_AREA
import androidx.window.area.WindowAreaCapability.Status.Companion.WINDOW_AREA_STATUS_ACTIVE
import androidx.window.area.WindowAreaCapability.Status.Companion.WINDOW_AREA_STATUS_AVAILABLE
import androidx.window.area.WindowAreaCapability.Status.Companion.WINDOW_AREA_STATUS_UNAVAILABLE
import androidx.window.area.WindowAreaController
import androidx.window.area.WindowAreaInfo
import androidx.window.area.WindowAreaPresentationSessionCallback
import androidx.window.area.WindowAreaSession
import androidx.window.area.WindowAreaSessionCallback
import androidx.window.area.WindowAreaSessionPresenter
import androidx.window.core.ExperimentalWindowApi
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor

@OptIn(ExperimentalWindowApi::class)
class DualScreenHingePlugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    DefaultLifecycleObserver {

    private lateinit var applicationContext: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var angleSensor: HingeAngleSensorController
    private val mainHandler = Handler(Looper.getMainLooper())
    private val mainExecutor = Executor { command -> mainHandler.post(command) }

    private var activity: Activity? = null
    private var lifecycle: Lifecycle? = null
    private var windowStateObserver: WindowStateObserver? = null
    private var eventSink: EventChannel.EventSink? = null
    private var hingeAngle: Double? = null
    private var displayFeatures = emptyList<Map<String, Any>>()
    private var supportedPostures = emptyList<String>()
    private var rearWindowArea: WindowAreaInfo? = null
    private var rearMode = ModeSnapshot("unsupported")
    private var dualMode = ModeSnapshot("unsupported")
    private var currentMode: String? = null
    private var activeScreen = "unknown"
    private var lastEvent: Map<String, Any?>? = null

    private var rearSession: WindowAreaSession? = null
    private var presentationSession: WindowAreaSessionPresenter? = null
    private var secondaryEngine: FlutterEngine? = null
    private var secondaryEngineGroup: FlutterEngineGroup? = null
    private var secondaryView: FlutterView? = null
    private var pendingOperationResult: MethodChannel.Result? = null
    private var stopRequestedWhileStarting = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        angleSensor = HingeAngleSensorController(applicationContext, mainHandler) { angle ->
            hingeAngle = angle
            emitState()
        }
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        eventSink = null
        unregisterSensor()
        detachActivity(permanent = true)
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) = attachActivity(binding)

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        attachActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = detachActivity(permanent = false)

    override fun onDetachedFromActivity() = detachActivity(permanent = true)

    private fun attachActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding).also {
            it.addObserver(this)
        }
        startActivityCollectors(binding.activity)
        updateSensorRegistration()
    }

    private fun detachActivity(permanent: Boolean) {
        lifecycle?.removeObserver(this)
        lifecycle = null
        windowStateObserver?.stop()
        windowStateObserver = null
        unregisterSensor()
        activity = null
        if (permanent) closeSessions()
    }

    private fun startActivityCollectors(currentActivity: Activity) {
        windowStateObserver?.stop()
        windowStateObserver = WindowStateObserver(
            activity = currentActivity,
            onLayoutChanged = { features, postures ->
                displayFeatures = features
                supportedPostures = postures
                emitState()
            },
            onWindowAreaChanged = { info ->
                rearWindowArea = info
                updateAreaAvailability()
            },
        ).also { it.start() }
    }

    private fun updateAreaAvailability() {
        val info = rearWindowArea
        if (currentMode != REAR_MODE) {
            rearMode = ModeSnapshot(capabilityState(info, OPERATION_TRANSFER_ACTIVITY_TO_AREA))
        }
        if (currentMode != DUAL_MODE) {
            dualMode = ModeSnapshot(capabilityState(info, OPERATION_PRESENT_ON_AREA))
        }
        emitState()
    }

    private fun capabilityState(
        info: WindowAreaInfo?,
        operation: androidx.window.area.WindowAreaCapability.Operation,
    ): String {
        val status = info?.getCapability(operation)?.status ?: return "unsupported"
        return when (status) {
            WINDOW_AREA_STATUS_AVAILABLE -> "available"
            WINDOW_AREA_STATUS_ACTIVE -> "active"
            WINDOW_AREA_STATUS_UNAVAILABLE -> "unavailable"
            else -> "unsupported"
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
        updateSensorRegistration()
        emitState(force = true)
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        unregisterSensor()
        lastEvent = null
    }

    override fun onStart(owner: LifecycleOwner) = updateSensorRegistration()

    override fun onStop(owner: LifecycleOwner) = unregisterSensor()

    private fun updateSensorRegistration() {
        angleSensor.setEnabled(
            eventSink != null &&
                lifecycle?.currentState?.isAtLeast(Lifecycle.State.STARTED) == true,
        )
    }

    private fun unregisterSensor() = angleSensor.setEnabled(false)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "currentState" -> result.success(buildState())
            "capabilities" -> result.success(buildCapabilities())
            "startRearDisplay" -> startRearDisplay(result)
            "stopRearDisplay" -> stopRearDisplay(result)
            "startDualScreen" -> startDualScreen(call, result)
            "stopDualScreen" -> stopDualScreen(result)
            else -> result.notImplemented()
        }
    }

    private fun startRearDisplay(result: MethodChannel.Result) {
        val currentActivity = requireAvailableSession(REAR_MODE, rearMode.state, result) ?: return
        val info = rearWindowArea
        if (info == null) {
            unavailable(result)
            return
        }
        currentMode = REAR_MODE
        processSessionLock.acquire(this)
        stopRequestedWhileStarting = false
        pendingOperationResult = result
        rearMode = ModeSnapshot("starting")
        emitState()
        try {
            WindowAreaController.getOrCreate().transferActivityToWindowArea(
                info.token,
                currentActivity,
                mainExecutor,
                object : WindowAreaSessionCallback {
                    override fun onSessionStarted(session: WindowAreaSession) {
                        rearSession = session
                        if (stopRequestedWhileStarting || currentMode != REAR_MODE) {
                            session.close()
                            return
                        }
                        activeScreen = "outer"
                        rearMode = ModeSnapshot("active")
                        completePendingSuccess()
                        emitState()
                    }

                    override fun onSessionEnded(t: Throwable?) {
                        rearSession = null
                        activeScreen = "unknown"
                        currentMode = null
                        stopRequestedWhileStarting = false
                        releaseProcessSession()
                        rearMode = ModeSnapshot(
                            if (t == null) "available" else "error",
                            errorCode = if (t == null) null else "sessionEnded",
                        )
                        completePendingError(t)
                        updateAreaAvailability()
                    }
                },
            )
        } catch (error: Throwable) {
            failStart(REAR_MODE, error, result)
        }
    }

    private fun stopRearDisplay(result: MethodChannel.Result) {
        if (currentMode != REAR_MODE) return result.success(null)
        rearMode = ModeSnapshot("stopping")
        emitState()
        if (rearSession == null) cancelPendingStart()
        stopRequestedWhileStarting = rearSession == null
        rearSession?.close()
        result.success(null)
    }

    private fun startDualScreen(call: MethodCall, result: MethodChannel.Result) {
        val entrypoint = call.argument<String>("entrypoint")
        if (entrypoint == null || !isValidDartEntrypoint(entrypoint)) {
            result.error("invalidEntrypoint", "Invalid top-level Dart entrypoint.", null)
            return
        }
        val arguments = call.argument<List<String>>("arguments") ?: emptyList()
        val currentActivity = requireAvailableSession(DUAL_MODE, dualMode.state, result) ?: return
        val info = rearWindowArea
        if (info == null) {
            unavailable(result)
            return
        }
        currentMode = DUAL_MODE
        processSessionLock.acquire(this)
        stopRequestedWhileStarting = false
        pendingOperationResult = result
        dualMode = ModeSnapshot("starting")
        emitState()
        try {
            WindowAreaController.getOrCreate().presentContentOnWindowArea(
                info.token,
                currentActivity,
                mainExecutor,
                object : WindowAreaPresentationSessionCallback {
                    override fun onSessionStarted(session: WindowAreaSessionPresenter) {
                        if (stopRequestedWhileStarting || currentMode != DUAL_MODE) {
                            session.close()
                            return
                        }
                        try {
                            attachSecondaryFlutter(session, entrypoint, arguments)
                            presentationSession = session
                            activeScreen = "inner"
                            dualMode = ModeSnapshot("active", isContentVisible = true)
                            completePendingSuccess()
                            emitState()
                        } catch (error: Throwable) {
                            session.close()
                            onSessionEnded(error)
                        }
                    }

                    override fun onSessionEnded(t: Throwable?) {
                        disposeSecondaryFlutter()
                        presentationSession = null
                        activeScreen = "unknown"
                        currentMode = null
                        stopRequestedWhileStarting = false
                        releaseProcessSession()
                        dualMode = ModeSnapshot(
                            if (t == null) "available" else "error",
                            errorCode = if (t == null) null else "sessionEnded",
                        )
                        completePendingError(t)
                        updateAreaAvailability()
                    }

                    override fun onContainerVisibilityChanged(isVisible: Boolean) {
                        dualMode = dualMode.copy(isContentVisible = isVisible)
                        emitState()
                    }
                },
            )
        } catch (error: Throwable) {
            failStart(DUAL_MODE, error, result)
        }
    }

    private fun stopDualScreen(result: MethodChannel.Result) {
        if (currentMode != DUAL_MODE) return result.success(null)
        dualMode = ModeSnapshot("stopping")
        emitState()
        if (presentationSession == null) cancelPendingStart()
        stopRequestedWhileStarting = presentationSession == null
        presentationSession?.close()
        disposeSecondaryFlutter()
        result.success(null)
    }

    private fun attachSecondaryFlutter(
        presenter: WindowAreaSessionPresenter,
        entrypoint: String,
        arguments: List<String>,
    ) {
        val loader = FlutterInjector.instance().flutterLoader()
        loader.ensureInitializationComplete(applicationContext, null)
        val dartEntrypoint = DartExecutor.DartEntrypoint(loader.findAppBundlePath(), entrypoint)
        val options = FlutterEngineGroup.Options(presenter.context)
            .setDartEntrypoint(dartEntrypoint)
            .setDartEntrypointArgs(arguments)
            .setAutomaticallyRegisterPlugins(true)
        val group = FlutterEngineGroup(applicationContext)
        val engine = group.createAndRunEngine(options)
        val view = FlutterView(presenter.context)
        view.attachToFlutterEngine(engine)
        presenter.setContentView(view)
        secondaryEngine = engine
        secondaryEngineGroup = group
        secondaryView = view
    }

    private fun disposeSecondaryFlutter() {
        secondaryView?.detachFromFlutterEngine()
        secondaryView = null
        secondaryEngine?.destroy()
        secondaryEngine = null
        secondaryEngineGroup = null
    }

    private fun requireAvailableSession(
        mode: String,
        state: String,
        result: MethodChannel.Result,
    ): Activity? {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("noActivity", "A foreground Flutter activity is required.", null)
            return null
        }
        if (currentMode != null || processSessionLock.isHeldByAnother(this)) {
            result.error(
                "operationInProgress",
                "Another display session is active.",
                currentMode,
            )
            return null
        }
        if (state == "unsupported") {
            result.error("unsupported", "$mode is not supported on this device.", null)
            return null
        }
        if (state != "available") {
            result.error("unavailable", "$mode is not currently available.", state)
            return null
        }
        return currentActivity
    }

    private fun unavailable(result: MethodChannel.Result): Nothing? {
        result.error("unavailable", "No rear-facing window area is available.", null)
        return null
    }

    private fun failStart(mode: String, error: Throwable, result: MethodChannel.Result) {
        currentMode = null
        releaseProcessSession()
        pendingOperationResult = null
        if (mode == REAR_MODE) {
            rearMode = ModeSnapshot("error", errorCode = "sessionEnded")
        } else {
            dualMode = ModeSnapshot("error", errorCode = "sessionEnded")
        }
        emitState()
        result.error("sessionEnded", error.message ?: "Display session ended.", null)
    }

    private fun completePendingSuccess() {
        pendingOperationResult?.success(null)
        pendingOperationResult = null
    }

    private fun completePendingError(error: Throwable?) {
        if (error != null) {
            pendingOperationResult?.error(
                "sessionEnded",
                error.message ?: "The display session ended before it started.",
                null,
            )
        }
        pendingOperationResult = null
    }

    private fun cancelPendingStart() {
        pendingOperationResult?.error(
            "sessionEnded",
            "The display session was stopped before it became active.",
            null,
        )
        pendingOperationResult = null
    }

    private fun closeSessions() {
        pendingOperationResult?.error(
            "sessionEnded",
            "The owning Flutter engine was detached.",
            null,
        )
        pendingOperationResult = null
        rearSession?.close()
        presentationSession?.close()
        rearSession = null
        presentationSession = null
        disposeSecondaryFlutter()
        currentMode = null
        activeScreen = "unknown"
        stopRequestedWhileStarting = false
        releaseProcessSession()
    }

    private fun releaseProcessSession() {
        processSessionLock.release(this)
    }

    private fun buildCapabilities(): Map<String, Any> {
        val info = rearWindowArea
        val rear = capabilityState(info, OPERATION_TRANSFER_ACTIVITY_TO_AREA) != "unsupported"
        val dual = capabilityState(info, OPERATION_PRESENT_ON_AREA) != "unsupported"
        val layout = displayFeatures.isNotEmpty() || supportedPostures.isNotEmpty()
        return mapOf(
            "platformSupported" to (angleSensor.isSupported || layout || rear || dual),
            "hingeAngleSensor" to angleSensor.isSupported,
            "layoutFeatures" to layout,
            "rearDisplay" to rear,
            "dualScreenPresentation" to dual,
        )
    }

    private fun buildState(): Map<String, Any?> {
        val authoritativePosture = displayFeatures.firstOrNull()?.get("nativeState") as? String
        val resolvedPosture = resolvePosture(authoritativePosture, hingeAngle)
        return mapOf(
            "schemaVersion" to 1,
            "activeScreen" to activeScreen,
            "isInnerScreen" to null,
            "hingeAngle" to hingeAngle,
            "posture" to resolvedPosture.posture,
            "postureSource" to resolvedPosture.source,
            "displayFeatures" to displayFeatures,
            "supportedPostures" to supportedPostures,
            "displayModes" to mapOf(
                "rearDisplay" to rearMode.toMap(),
                "dualScreen" to dualMode.toMap(),
            ),
        )
    }

    private fun emitState(force: Boolean = false) {
        val sink = eventSink ?: return
        val event = buildState()
        if (!force && event == lastEvent) return
        lastEvent = event
        if (Looper.myLooper() == Looper.getMainLooper()) {
            sink.success(event)
        } else {
            mainHandler.post { eventSink?.success(event) }
        }
    }

    private data class ModeSnapshot(
        val state: String,
        val isContentVisible: Boolean = false,
        val errorCode: String? = null,
    ) {
        fun copy(isContentVisible: Boolean) = ModeSnapshot(state, isContentVisible, errorCode)

        fun toMap(): Map<String, Any?> = mapOf(
            "state" to state,
            "isContentVisible" to isContentVisible,
            "errorCode" to errorCode,
        )
    }

    private companion object {
        val processSessionLock = DisplaySessionLock()
        const val METHOD_CHANNEL = "com.example.iphone_duo_hinge/methods"
        const val EVENT_CHANNEL = "com.example.iphone_duo_hinge/events"
        const val REAR_MODE = "rearDisplay"
        const val DUAL_MODE = "dualScreen"
    }
}
