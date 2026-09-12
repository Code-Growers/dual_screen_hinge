package com.codegrowers.dual_screen_hinge

import android.app.Activity
import androidx.window.area.WindowAreaController
import androidx.window.area.WindowAreaInfo
import androidx.window.area.WindowAreaInfo.Type.Companion.TYPE_REAR_FACING
import androidx.window.core.ExperimentalWindowApi
import androidx.window.layout.FoldingFeature
import androidx.window.layout.SupportedPosture
import androidx.window.layout.WindowInfoTracker
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch

@OptIn(ExperimentalWindowApi::class)
internal class WindowStateObserver(
    private val activity: Activity,
    private val onLayoutChanged: (List<Map<String, Any>>, List<String>) -> Unit,
    private val onWindowAreaChanged: (WindowAreaInfo?) -> Unit,
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    fun start() {
        scope.launch {
            val tracker = WindowInfoTracker.getOrCreate(activity)
            val supportedPostures = runCatching {
                tracker.supportedPostures.mapNotNull {
                    if (it == SupportedPosture.TABLETOP) "tabletop" else null
                }
            }.getOrDefault(emptyList())

            try {
                tracker.windowLayoutInfo(activity).collectLatest { info ->
                    onLayoutChanged(
                        mapFeatures(info.displayFeatures.filterIsInstance<FoldingFeature>()),
                        supportedPostures,
                    )
                }
            } catch (_: Throwable) {
                onLayoutChanged(emptyList(), supportedPostures)
            }
        }

        scope.launch {
            try {
                WindowAreaController.getOrCreate().windowAreaInfos.collectLatest { infos ->
                    onWindowAreaChanged(infos.firstOrNull { it.type == TYPE_REAR_FACING })
                }
            } catch (_: Throwable) {
                onWindowAreaChanged(null)
            }
        }
    }

    fun stop() = scope.cancel()

    private fun mapFeatures(features: List<FoldingFeature>): List<Map<String, Any>> {
        val density = activity.resources.displayMetrics.density
        return features.map { feature ->
            val bounds = feature.bounds
            mapOf(
                "bounds" to mapOf(
                    "left" to bounds.left / density,
                    "top" to bounds.top / density,
                    "right" to bounds.right / density,
                    "bottom" to bounds.bottom / density,
                ),
                "type" to if (feature.occlusionType == FoldingFeature.OcclusionType.FULL) {
                    "hinge"
                } else {
                    "fold"
                },
                "orientation" to if (feature.orientation == FoldingFeature.Orientation.VERTICAL) {
                    "vertical"
                } else {
                    "horizontal"
                },
                "occlusion" to if (feature.occlusionType == FoldingFeature.OcclusionType.FULL) {
                    "full"
                } else {
                    "none"
                },
                "isSeparating" to feature.isSeparating,
                "nativeState" to if (feature.state == FoldingFeature.State.FLAT) "flat" else "halfOpened",
            )
        }
    }
}
