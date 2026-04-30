package com.fintrack.fintrack

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

class BuxBuxQuickListWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    private data class ButtonIds(
        val container: Int,
        val label: Int,
        val sub: Int,
    )

    private val buttonIdMap = listOf(
        ButtonIds(R.id.btn_quick_1, R.id.btn_quick_1_label, R.id.btn_quick_1_sub),
        ButtonIds(R.id.btn_quick_2, R.id.btn_quick_2_label, R.id.btn_quick_2_sub),
        ButtonIds(R.id.btn_quick_3, R.id.btn_quick_3_label, R.id.btn_quick_3_sub),
        ButtonIds(R.id.btn_quick_4, R.id.btn_quick_4_label, R.id.btn_quick_4_sub),
    )

    private fun updateWidget(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.buxbux_quicklist_widget)
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        for (i in 1..4) {
            val ids = buttonIdMap[i - 1]

            val type = prefs.getString("q${i}_type", if (i <= 2) "expense" else "income") ?: "expense"

            // SharedPreferences may hold String (new), Float, or Long (stale) depending on
            // which version of home_widget wrote the value — try all three to avoid ClassCastException.
            val default_amt = if (i % 2 == 1) 10000f else 50000f
            val amount: Float = try {
                prefs.getString("q${i}_amount", null)?.toDoubleOrNull()?.toFloat() ?: default_amt
            } catch (e: ClassCastException) {
                try {
                    prefs.getFloat("q${i}_amount", default_amt)
                } catch (e2: ClassCastException) {
                    try {
                        prefs.getLong("q${i}_amount", default_amt.toLong()).toFloat()
                    } catch (e3: ClassCastException) {
                        default_amt
                    }
                }
            }

            val label = prefs.getString(
                "q${i}_label",
                if (type == "expense") "-${formatAmount(amount)}" else "+${formatAmount(amount)}"
            ) ?: if (type == "expense") "-${formatAmount(amount)}" else "+${formatAmount(amount)}"

            val sub = prefs.getString("q${i}_categoryName", null)
                ?: if (type == "expense") "Expense" else "Income"

            views.setTextViewText(ids.label, label)
            views.setTextViewText(ids.sub, sub)

            val bgRes = if (type == "expense") R.drawable.widget_btn_expense_alt
                        else R.drawable.widget_btn_income_alt
            views.setInt(ids.container, "setBackgroundResource", bgRes)

            // Use background intent so transactions are posted without opening the app.
            val accountId = prefs.getString("q${i}_accountId", "") ?: ""
            val categoryId = prefs.getString("q${i}_categoryId", "") ?: ""
            val note = prefs.getString("q${i}_note", "") ?: ""
            val uri = Uri.parse(
                "buxbux://quickadd?type=$type&amount=${amount.toInt()}" +
                "&accountId=${Uri.encode(accountId)}" +
                "&categoryId=${Uri.encode(categoryId)}" +
                "&note=${Uri.encode(note)}"
            )
            val pendingIntent = HomeWidgetBackgroundIntent.getBroadcast(context, uri)
            views.setOnClickPendingIntent(ids.container, pendingIntent)
        }

        manager.updateAppWidget(widgetId, views)
    }

    private fun formatAmount(amount: Float): String {
        return when {
            amount >= 1_000_000 -> "${(amount / 1_000_000).toInt()}M"
            amount >= 1_000 -> "${(amount / 1_000).toInt()}k"
            else -> amount.toInt().toString()
        }
    }
}
