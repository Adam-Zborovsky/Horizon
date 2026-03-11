package com.example.horizon.tiles

import android.content.Context
import androidx.wear.protolayout.*
import androidx.wear.protolayout.DimensionBuilders.*
import androidx.wear.protolayout.LayoutElementBuilders.*
import androidx.wear.protolayout.ColorBuilders
import androidx.wear.protolayout.ModifiersBuilders.*
import androidx.wear.protolayout.ResourceBuilders.*
import androidx.wear.protolayout.TimelineBuilders.*
import androidx.wear.protolayout.material.Text
import androidx.wear.protolayout.material.Typography
import androidx.wear.tiles.TileService
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

/**
 * Wear OS Tile showing alpha opportunity signals.
 * Shows ticker, direction (LONG/SHORT), and brief analysis.
 */
class AlphaTileService : TileService() {

    companion object {
        private const val OBSIDIAN = 0xFF0F0F0F.toInt()
        private const val GOLD_AMBER = 0xFFFFB800.toInt()
        private const val SOFT_CRIMSON = 0xFFFF4B5C.toInt()
        private const val WHITE = 0xFFFFFFFF.toInt()
        private const val WHITE_70 = 0xB3FFFFFF.toInt()
        private const val WHITE_30 = 0x4DFFFFFF.toInt()

        private const val FRESHNESS_INTERVAL_MS = 15L * 60 * 1000

        fun requestUpdate(context: Context) {
            getUpdater(context).requestUpdate(AlphaTileService::class.java)
        }
    }

    override fun onTileRequest(requestParams: RequestBuilders.TileRequest): ListenableFuture<TileBuilders.Tile> {
        TileDataWorker.schedule(this)

        val opportunities = TileDataCache.getOpportunities(this)
        val layout = buildLayout(opportunities)

        val tile = TileBuilders.Tile.Builder()
            .setResourcesVersion("1")
            .setFreshnessIntervalMillis(FRESHNESS_INTERVAL_MS)
            .setTileTimeline(
                Timeline.Builder()
                    .addTimelineEntry(
                        TimelineEntry.Builder()
                            .setLayout(Layout.Builder().setRoot(layout).build())
                            .build()
                    )
                    .build()
            )
            .build()

        return Futures.immediateFuture(tile)
    }

    override fun onTileResourcesRequest(requestParams: RequestBuilders.ResourcesRequest): ListenableFuture<Resources> {
        return Futures.immediateFuture(
            Resources.Builder().setVersion("1").build()
        )
    }

    private fun buildLayout(opportunities: List<OpportunityTileData>): LayoutElement {
        val column = Column.Builder()
            .setWidth(expand())
            .setHorizontalAlignment(HORIZONTAL_ALIGN_CENTER)

        // Title: ALPHA
        column.addContent(
            Text.Builder(this, "ALPHA SIGNALS")
                .setTypography(Typography.TYPOGRAPHY_CAPTION1)
                .setColor(ColorBuilders.argb(GOLD_AMBER))
                .setModifiers(
                    Modifiers.Builder()
                        .setPadding(Padding.Builder().setBottom(dp(6f)).build())
                        .build()
                )
                .build()
        )

        if (opportunities.isEmpty()) {
            column.addContent(
                Text.Builder(this, "No signals")
                    .setTypography(Typography.TYPOGRAPHY_CAPTION2)
                    .setColor(ColorBuilders.argb(WHITE_30))
                    .build()
            )
        } else {
            for ((i, opp) in opportunities.take(2).withIndex()) {
                column.addContent(buildOpportunityRow(opp))
                if (i < 1 && i < opportunities.size - 1) {
                    column.addContent(Spacer.Builder().setHeight(dp(6f)).build())
                }
            }
        }

        return Box.Builder()
            .setWidth(expand())
            .setHeight(expand())
            .setHorizontalAlignment(HORIZONTAL_ALIGN_CENTER)
            .setVerticalAlignment(VERTICAL_ALIGN_CENTER)
            .setModifiers(
                Modifiers.Builder()
                    .setBackground(
                        Background.Builder()
                            .setColor(ColorBuilders.argb(OBSIDIAN))
                            .build()
                    )
                    .setPadding(Padding.Builder().setAll(dp(14f)).build())
                    .build()
            )
            .addContent(column.build())
            .build()
    }

    private fun buildOpportunityRow(opp: OpportunityTileData): LayoutElement {
        val isLong = opp.direction.lowercase() == "long"
        val dirColor = if (isLong) GOLD_AMBER else SOFT_CRIMSON
        val dirBg = if (isLong) 0x22FFB800 else 0x22FF4B5C
        val dirLabel = opp.direction.uppercase().ifEmpty { "ALPHA" }

        // Row wrapped in a "Glass" card
        return Box.Builder()
            .setWidth(expand())
            .setModifiers(
                Modifiers.Builder()
                    .setBackground(
                        Background.Builder()
                            .setColor(ColorBuilders.argb(0x1AFFFFFF))
                            .setCorner(Corner.Builder().setRadius(dp(10f)).build())
                            .build()
                    )
                    .setPadding(Padding.Builder().setAll(dp(8f)).build())
                    .build()
            )
            .addContent(
                Column.Builder()
                    .setWidth(expand())
                    .addContent(
                        Row.Builder()
                            .setWidth(expand())
                            .setVerticalAlignment(VERTICAL_ALIGN_CENTER)
                            .addContent(
                                Text.Builder(this, opp.ticker)
                                    .setTypography(Typography.TYPOGRAPHY_BODY2)
                                    .setColor(ColorBuilders.argb(WHITE))
                                    .build()
                            )
                            .addContent(Spacer.Builder().setWidth(dp(4f)).build())
                            .addContent(
                                Text.Builder(this, dirLabel)
                                    .setTypography(Typography.TYPOGRAPHY_CAPTION2)
                                    .setColor(ColorBuilders.argb(dirColor))
                                    .setModifiers(
                                        Modifiers.Builder()
                                            .setBackground(
                                                Background.Builder()
                                                    .setColor(ColorBuilders.argb(dirBg))
                                                    .setCorner(Corner.Builder().setRadius(dp(4f)).build())
                                                    .build()
                                            )
                                            .setPadding(Padding.Builder().setStart(dp(4f)).setEnd(dp(4f)).build())
                                            .build()
                                    )
                                    .build()
                            )
                            .addContent(Spacer.Builder().setWidth(expand()).build())
                            .addContent(
                                Text.Builder(this, if (opp.price > 0) "${"%.2f".format(opp.price)}" else "")
                                    .setTypography(Typography.TYPOGRAPHY_CAPTION2)
                                    .setColor(ColorBuilders.argb(WHITE_70))
                                    .build()
                            )
                            .build()
                    )
                    .addContent(
                        if (opp.analysis.isNotEmpty()) {
                            val snippet = if (opp.analysis.length > 40) opp.analysis.take(37) + "..." else opp.analysis
                            Column.Builder()
                                .addContent(Spacer.Builder().setHeight(dp(4f)).build())
                                .addContent(
                                    Text.Builder(this, snippet)
                                        .setTypography(Typography.TYPOGRAPHY_CAPTION2)
                                        .setColor(ColorBuilders.argb(WHITE_30))
                                        .setMaxLines(1)
                                        .build()
                                )
                                .build()
                        } else {
                            Spacer.Builder().setHeight(dp(0f)).build()
                        }
                    )
                    .build()
            )
            .build()
    }
}
