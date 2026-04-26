package com.fintrack.fintrack

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent

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

    private fun updateWidget(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.buxbux_quicklist_widget)

        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        for (i in 1..4) {
            val id = when(i) {
                1 -> R.id.btn_quick_exp_1
                2 -> R.id.btn_quick_exp_2
                3 -> R.id.btn_quick_inc_1
                else -> R.id.btn_quick_inc_2
            }

            val type = prefs.getString("q${i}_type", if (i <= 2) "expense" else "income") ?: "expense"
            val amount = prefs.getFloat("q${i}_amount", if (i % 2 == 1) 10000f else 50000f)
            val label = prefs.getString("q${i}_label", if (type == "expense") "-${formatK(amount)}" else "+${formatK(amount)}") ?: ""

            views.setTextViewText(id, label)

            // Open QuickAddScreen with pre-filled type + amount for popup with notes
            val uri = Uri.parse("buxbux://add?type=$type&amount=${amount.toInt()}")
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                uri
            )
            views.setOnClickPendingIntent(id, pendingIntent)
        }

        manager.updateAppWidget(widgetId, views)
    }

    private fun formatK(amount: Float): String {
        return when {
            amount >= 1_000_000 -> "${(amount / 1_000_000).toInt()}M"
            amount >= 1_000 -> "${(amount / 1_000).toInt()}k"
            else -> amount.toInt().toString()
        }
    }
}
