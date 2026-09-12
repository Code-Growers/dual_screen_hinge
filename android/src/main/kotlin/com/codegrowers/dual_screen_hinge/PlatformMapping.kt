package com.codegrowers.dual_screen_hinge

internal data class ResolvedPosture(val posture: String, val source: String)

internal fun resolvePosture(
    authoritativePosture: String?,
    hingeAngle: Double?,
    closedThreshold: Double = 1.0,
): ResolvedPosture = when {
    authoritativePosture != null -> ResolvedPosture(authoritativePosture, "foldingFeature")
    hingeAngle != null && hingeAngle <= closedThreshold -> ResolvedPosture("closed", "derivedAngle")
    else -> ResolvedPosture("unknown", "unavailable")
}

internal fun isValidDartEntrypoint(value: String): Boolean =
    Regex("^[A-Za-z_$][A-Za-z0-9_$]*$").matches(value)

internal class AngleFrameCoalescer(
    private val schedule: (() -> Unit) -> Unit,
    private val emit: (Double) -> Unit,
) {
    private var pending: Double? = null
    private var scheduled = false

    fun offer(value: Double) {
        pending = value
        if (scheduled) return
        scheduled = true
        schedule {
            scheduled = false
            val latest = pending
            pending = null
            if (latest != null) emit(latest)
        }
    }
}

internal class DisplaySessionLock {
    private var owner: Any? = null

    fun isHeldByAnother(candidate: Any): Boolean = owner != null && owner !== candidate

    fun acquire(candidate: Any): Boolean {
        if (isHeldByAnother(candidate)) return false
        owner = candidate
        return true
    }

    fun release(candidate: Any) {
        if (owner === candidate) owner = null
    }
}
