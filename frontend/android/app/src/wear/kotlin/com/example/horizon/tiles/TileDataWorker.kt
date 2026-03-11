package com.example.horizon.tiles

import android.content.Context
import androidx.work.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.TimeUnit

/**
 * Background worker that fetches briefing data from the API and caches it
 * for tile rendering. Runs every 15 minutes via WorkManager.
 */
class TileDataWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        try {
            val token = TileDataCache.getAuthToken(applicationContext)
                ?: return@withContext Result.retry()

            val baseUrl = TileDataCache.getApiBaseUrl()
            val url = URL("$baseUrl/briefing")
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "GET"
            conn.setRequestProperty("Content-Type", "application/json")
            conn.setRequestProperty("Authorization", "Bearer $token")
            conn.connectTimeout = 15_000
            conn.readTimeout = 15_000

            if (conn.responseCode != 200) {
                conn.disconnect()
                return@withContext Result.retry()
            }

            val body = conn.inputStream.bufferedReader().readText()
            conn.disconnect()

            val parsed = parseBriefingResponse(body)
            TileDataCache.saveWatchlist(applicationContext, parsed.watchlist)
            TileDataCache.saveOpportunities(applicationContext, parsed.opportunities)

            // Request tile updates
            WatchlistTileService.requestUpdate(applicationContext)
            AlphaTileService.requestUpdate(applicationContext)

            Result.success()
        } catch (_: Exception) {
            Result.retry()
        }
    }

    private fun parseBriefingResponse(body: String): ParsedData {
        val watchlist = mutableListOf<StockTileData>()
        val opportunities = mutableListOf<OpportunityTileData>()

        val decoded: Any = try {
            val arr = JSONArray(body)
            if (arr.length() > 0) arr.getJSONObject(0) else return ParsedData(watchlist, opportunities)
        } catch (_: Exception) {
            try {
                val obj = JSONObject(body)
                if (obj.has("data") && obj.get("data") is JSONArray) {
                    val dataArr = obj.getJSONArray("data")
                    if (dataArr.length() > 0) dataArr.getJSONObject(0) else return ParsedData(watchlist, opportunities)
                } else obj
            } catch (_: Exception) {
                return ParsedData(watchlist, opportunities)
            }
        }

        val briefing = decoded as? JSONObject ?: return ParsedData(watchlist, opportunities)
        val rawData = briefing.opt("data") ?: return ParsedData(watchlist, opportunities)

        val content: JSONObject = when (rawData) {
            is String -> {
                var cleaned = rawData
                if (cleaned.contains("```")) {
                    val regex = Regex("```(?:json)?\\s*(\\{[\\s\\S]*})\\s*```")
                    val match = regex.find(cleaned)
                    if (match != null) cleaned = match.groupValues[1]
                }
                try { JSONObject(cleaned) } catch (_: Exception) { return ParsedData(watchlist, opportunities) }
            }
            is JSONObject -> rawData
            else -> return ParsedData(watchlist, opportunities)
        }

        // Extract market analysis items (watchlist stocks)
        val marketKeys = listOf("market", "market_analyst", "market_analysis")
        for (key in marketKeys) {
            if (!content.has(key)) continue
            val container = content.get(key)
            val items = extractItems(container)
            for (item in items) {
                val ticker = item.optString("ticker", "").uppercase()
                if (ticker.isEmpty()) continue
                watchlist.add(StockTileData(
                    ticker = ticker,
                    name = item.optString("name", ticker),
                    price = extractPrice(item),
                    changePercent = extractChange(item)
                ))
            }
        }

        // Extract opportunity items
        val oppKeys = listOf("opportunities", "opportunity_scout")
        for (key in oppKeys) {
            if (!content.has(key)) continue
            val container = content.get(key)
            val items = extractItems(container)
            for (item in items) {
                val ticker = item.optString("ticker", "").uppercase()
                if (ticker.isEmpty()) continue
                opportunities.add(OpportunityTileData(
                    ticker = ticker,
                    price = extractPrice(item),
                    direction = item.optString("direction", ""),
                    analysis = item.optString("explanation",
                        item.optString("takeaway", ""))
                ))
            }
        }

        // Also pull tickers from news categories
        val newsKeys = listOf("news", "news_intel", "news_categories")
        for (key in newsKeys) {
            if (!content.has(key)) continue
            val newsContainer = content.optJSONObject(key) ?: continue
            val keys = newsContainer.keys()
            while (keys.hasNext()) {
                val catKey = keys.next()
                val catItems = extractItems(newsContainer.get(catKey))
                for (item in catItems) {
                    val ticker = item.optString("ticker", "").uppercase()
                    if (ticker.isEmpty() || watchlist.any { it.ticker == ticker }) continue
                    watchlist.add(StockTileData(
                        ticker = ticker,
                        name = item.optString("name", ticker),
                        price = extractPrice(item),
                        changePercent = extractChange(item)
                    ))
                }
            }
        }

        return ParsedData(watchlist.take(5), opportunities.take(3))
    }

    private fun extractItems(container: Any?): List<JSONObject> {
        if (container == null) return emptyList()
        if (container is JSONArray) {
            return (0 until container.length()).mapNotNull {
                container.optJSONObject(it)
            }
        }
        if (container is JSONObject) {
            val items = mutableListOf<JSONObject>()
            val keys = container.keys()
            while (keys.hasNext()) {
                val v = container.get(keys.next())
                if (v is JSONObject) items.add(v)
                if (v is JSONArray) items.addAll(extractItems(v))
            }
            return items
        }
        return emptyList()
    }

    private fun extractPrice(item: JSONObject): Double {
        val priceStr = item.optString("price", "")
        val cleaned = priceStr.replace(Regex("[^\\d.]"), "")
        val price = cleaned.toDoubleOrNull()
        if (price != null && price > 0) return price
        // Try extracting from potential_price_action
        val ppa = item.optString("potential_price_action", "")
        val match = Regex("\\$(\\d+(?:\\.\\d+)?)").find(ppa)
        return match?.groupValues?.get(1)?.toDoubleOrNull() ?: 0.0
    }

    private fun extractChange(item: JSONObject): Double {
        val changeStr = item.optString("change", "")
        val cleaned = changeStr.replace(Regex("[^\\d.+-]"), "")
        val change = cleaned.toDoubleOrNull()
        if (change != null) return change
        val ppa = item.optString("potential_price_action", "")
        val match = Regex("([+-]?\\d+(?:\\.\\d+)?)\\s*%").find(ppa)
        return match?.groupValues?.get(1)?.toDoubleOrNull() ?: 0.0
    }

    private data class ParsedData(
        val watchlist: List<StockTileData>,
        val opportunities: List<OpportunityTileData>
    )

    companion object {
        private const val WORK_NAME = "horizon_tile_data_sync"

        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<TileDataWorker>(
                15, TimeUnit.MINUTES
            )
                .setConstraints(
                    Constraints.Builder()
                        .setRequiredNetworkType(NetworkType.CONNECTED)
                        .build()
                )
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 5, TimeUnit.MINUTES)
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request
            )
        }

        fun runOnce(context: Context) {
            val request = OneTimeWorkRequestBuilder<TileDataWorker>()
                .setConstraints(
                    Constraints.Builder()
                        .setRequiredNetworkType(NetworkType.CONNECTED)
                        .build()
                )
                .build()

            WorkManager.getInstance(context).enqueue(request)
        }
    }
}
