package com.example.horizon.tiles

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

/**
 * Local cache for tile data. WorkManager writes, TileServices read.
 */
object TileDataCache {
    private const val PREFS_NAME = "horizon_tile_cache"
    private const val KEY_WATCHLIST = "watchlist_stocks"
    private const val KEY_OPPORTUNITIES = "opportunity_stocks"
    private const val KEY_LAST_UPDATE = "last_update_ms"

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun saveWatchlist(context: Context, stocks: List<StockTileData>) {
        val arr = JSONArray()
        stocks.forEach { s ->
            arr.put(JSONObject().apply {
                put("ticker", s.ticker)
                put("name", s.name)
                put("price", s.price)
                put("change", s.changePercent)
            })
        }
        prefs(context).edit()
            .putString(KEY_WATCHLIST, arr.toString())
            .putLong(KEY_LAST_UPDATE, System.currentTimeMillis())
            .apply()
    }

    fun saveOpportunities(context: Context, stocks: List<OpportunityTileData>) {
        val arr = JSONArray()
        stocks.forEach { s ->
            arr.put(JSONObject().apply {
                put("ticker", s.ticker)
                put("price", s.price)
                put("direction", s.direction)
                put("analysis", s.analysis)
            })
        }
        prefs(context).edit()
            .putString(KEY_OPPORTUNITIES, arr.toString())
            .putLong(KEY_LAST_UPDATE, System.currentTimeMillis())
            .apply()
    }

    fun getWatchlist(context: Context): List<StockTileData> {
        val raw = prefs(context).getString(KEY_WATCHLIST, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { i ->
                val obj = arr.getJSONObject(i)
                StockTileData(
                    ticker = obj.getString("ticker"),
                    name = obj.optString("name", ""),
                    price = obj.getDouble("price"),
                    changePercent = obj.getDouble("change")
                )
            }
        } catch (_: Exception) { emptyList() }
    }

    fun getOpportunities(context: Context): List<OpportunityTileData> {
        val raw = prefs(context).getString(KEY_OPPORTUNITIES, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { i ->
                val obj = arr.getJSONObject(i)
                OpportunityTileData(
                    ticker = obj.getString("ticker"),
                    price = obj.getDouble("price"),
                    direction = obj.optString("direction", ""),
                    analysis = obj.optString("analysis", "")
                )
            }
        } catch (_: Exception) { emptyList() }
    }

    fun getAuthToken(context: Context): String? {
        // Flutter SharedPreferences uses a different prefs file
        val flutterPrefs = context.getSharedPreferences(
            "FlutterSharedPreferences", Context.MODE_PRIVATE
        )
        return flutterPrefs.getString("flutter.auth_token", null)
    }

    fun getApiBaseUrl(): String = "https://horizon.adamzborovsky.com/api/v1"
}

data class StockTileData(
    val ticker: String,
    val name: String,
    val price: Double,
    val changePercent: Double
)

data class OpportunityTileData(
    val ticker: String,
    val price: Double,
    val direction: String,
    val analysis: String
)
