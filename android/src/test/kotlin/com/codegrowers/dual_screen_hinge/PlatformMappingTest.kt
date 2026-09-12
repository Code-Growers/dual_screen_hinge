package com.codegrowers.dual_screen_hinge

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class PlatformMappingTest {
    @Test
    fun authoritativePostureWinsOverSensorEndpoint() {
        assertEquals(
            ResolvedPosture("flat", "foldingFeature"),
            resolvePosture(authoritativePosture = "flat", hingeAngle = 0.0),
        )
    }

    @Test
    fun nearZeroAngleIsDerivedOnlyWithoutAuthoritativePosture() {
        assertEquals(
            ResolvedPosture("closed", "derivedAngle"),
            resolvePosture(authoritativePosture = null, hingeAngle = 0.5),
        )
        assertEquals(
            ResolvedPosture("unknown", "unavailable"),
            resolvePosture(authoritativePosture = null, hingeAngle = 90.0),
        )
    }

    @Test
    fun validatesTopLevelDartEntrypointNames() {
        assertTrue(isValidDartEntrypoint("dualScreenSecondaryMain"))
        assertTrue(isValidDartEntrypoint("_privateMain"))
        assertFalse(isValidDartEntrypoint("bad entrypoint"))
        assertFalse(isValidDartEntrypoint("2bad"))
    }

    @Test
    fun angleUpdatesAreCoalescedToTheLatestValuePerFrame() {
        val scheduled = mutableListOf<() -> Unit>()
        val emitted = mutableListOf<Double>()
        val coalescer = AngleFrameCoalescer(scheduled::add, emitted::add)

        coalescer.offer(10.0)
        coalescer.offer(20.0)
        coalescer.offer(30.0)
        assertEquals(1, scheduled.size)
        scheduled.removeFirst().invoke()
        assertEquals(listOf(30.0), emitted)

        coalescer.offer(40.0)
        assertEquals(1, scheduled.size)
        scheduled.removeFirst().invoke()
        assertEquals(listOf(30.0, 40.0), emitted)
    }

    @Test
    fun displaySessionLockCoordinatesMultiplePluginEngines() {
        val lock = DisplaySessionLock()
        val primary = Any()
        val secondary = Any()

        assertTrue(lock.acquire(primary))
        assertTrue(lock.isHeldByAnother(secondary))
        assertFalse(lock.acquire(secondary))
        lock.release(secondary)
        assertTrue(lock.isHeldByAnother(secondary))
        lock.release(primary)
        assertTrue(lock.acquire(secondary))
    }
}
