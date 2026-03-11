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
 * Wear OS Tile showing top watchlist stocks with price and change %.
 * Styled in Horizon's Obsidian + Gold Amber theme.
 */
class WatchlistTileService : TileService() {

    companion object {
        // Horizon colors - slightly brighter obsidian for better depth
        private const val OBSIDIAN = 0xFF0F0F0F.toInt()
        private const val GOLD_AMBER = 0xFFFFB800.toInt()
        private const val SOFT_CRIMSON = 0xFFFF4B5C.toInt()
        private const val WHITE = 0xFFFFFFFF.toInt()
        private const val WHITE_70 = 0xB3FFFFFF.toInt()
        private const val WHITE_30 = 0x4DFFFFFF.toInt()

        private const val FRESHNESS_INTERVAL_MS = 15L * 60 * 1000 // 15 min

        fun requestUpdate(context: Context) {
            getUpdater(context).requestUpdate(WatchlistTileService::class.java)
        }
    }

    override fun onTileRequest(requestParams: RequestBuilders.TileRequest): ListenableFuture<TileBuilders.Tile> {
        TileDataWorker.schedule(this)

        val stocks = TileDataCache.getWatchlist(this)
        val layout = buildLayout(stocks)

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

    private fun buildLayout(stocks: List<StockTileData>): LayoutElement {
        val column = Column.Builder()
            .setWidth(expand())
            .setHorizontalAlignment(HORIZONTAL_ALIGN_CENTER)

        // Title: HORIZON
        column.addContent(
            Text.Builder(this, "HORIZON")
                .setTypography(Typography.TYPOGRAPHY_CAPTION1)
                .setColor(ColorBuilders.argb(GOLD_AMBER))
                .setModifiers(
                    Modifiers.Builder()
                        .setPadding(Padding.Builder().setBottom(dp(6f)).build())
                        .build()
                )
                .build()
        )

        if (stocks.isEmpty()) {
            column.addContent(
                Text.Builder(this, "No data yet")
                    .setTypography(Typography.TYPOGRAPHY_CAPTION2)
                    .setColor(ColorBuilders.argb(WHITE_30))
                    .build()
            )
        } else {
            // Show top 3 stocks to keep layout clean on round screens
            for ((i, stock) in stocks.take(3).withIndex()) {
                column.addContent(buildStockRow(stock))
                if (i < 2 && i < stocks.size - 1) {
                    column.addContent(Spacer.Builder().setHeight(dp(4f)).build())
                }
            }
        }

        // Main Container
        val mainBox = Box.Builder()
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

        // Add the styled content column
        mainBox.addContent(column.build())
        
        return mainBox.build()
    }

    private fun buildStockRow(stock: StockTileData): LayoutElement {
        val isPositive = stock.changePercent >= 0
        val changeColor = if (isPositive) GOLD_AMBER else SOFT_CRIMSON
        val changeText = "${if (isPositive) "+" else ""}${"%.1f".format(stock.changePercent)}%"
        val priceText = if (stock.price > 0) "${"%.2f".format(stock.price)}" else "—"

        // Row wrapped in a "Glass" card - matching app's translucent UI
        return Box.Builder()
            .setWidth(expand())
            .setModifiers(
                Modifiers.Builder()
                    .setBackground(
                        Background.Builder()
                            .setColor(ColorBuilders.argb(0x1AFFFFFF)) // 10% white translucency
                            .setCorner(Corner.Builder().setRadius(dp(10f)).build())
                            .build()
                    )
                    .setPadding(Padding.Builder().setAll(dp(8f)).build())
                    .build()
            )
            .addContent(
                Row.Builder()
                    .setWidth(expand())
                    .setVerticalAlignment(VERTICAL_ALIGN_CENTER)
                    .addContent(
                        Text.Builder(this, stock.ticker)
                            .setTypography(Typography.TYPOGRAPHY_BODY2)
                            .setColor(ColorBuilders.argb(WHITE))
                            .build()
                    )
                    .addContent(Spacer.Builder().setWidth(dp(4f)).build())
                    .addContent(
                        Text.Builder(this, priceText)
                            .setTypography(Typography.TYPOGRAPHY_CAPTION2)
                            .setColor(ColorBuilders.argb(WHITE_70))
                            .build()
                    )
                    .addContent(Spacer.Builder().setWidth(expand()).build())
                    .addContent(
                        Text.Builder(this, changeText)
                            .setTypography(Typography.TYPOGRAPHY_CAPTION2)
                            .setColor(ColorBuilders.argb(changeColor))
                            .setModifiers(
                                Modifiers.Builder()
                                    .setBackground(
                                        Background.Builder()
                                            .setColor(ColorBuilders.argb(if (isPositive) 0x22FFB800 else 0x22FF4B5C))
                                            .setCorner(Corner.Builder().setRadius(dp(4f)).build())
                                            .build()
                                    )
                                    .setPadding(Padding.Builder().setStart(dp(4f)).setEnd(dp(4f)).build())
                                    .build()
                            )
                            .build()
                    )
                    .build()
            )
            .build()
    }
}
