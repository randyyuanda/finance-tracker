package com.fintrack.fintrack

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class BuxBuxWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.buxbux_widget)

        // Localization
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val flutterPrefs = context.getSharedPreferences("${context.packageName}_preferences", Context.MODE_PRIVATE)
        
        val lang = prefs.getString("language", null) 
                   ?: flutterPrefs.getString("flutter.language", "en") 
                   ?: "en"
        
        val title = when(lang) {
            "id" -> "TRANSAKSI"
            "zh" -> "交易记录"
            else -> "TRANSACTIONS"
        }
        val income = when(lang) {
            "id" -> "MASUK"
            "zh" -> "收入"
            else -> "INCOME"
        }
        val expense = when(lang) {
            "id" -> "KELUAR"
            "zh" -> "支出"
            else -> "EXPENSE"
        }

        views.setTextViewText(R.id.widget_title, title)
        views.setTextViewText(R.id.btn_income, income)
        views.setTextViewText(R.id.btn_expense, expense)

        val expensePending = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("buxbux://add?type=expense")
        )
        views.setOnClickPendingIntent(R.id.btn_expense, expensePending)

        val incomePending = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("buxbux://add?type=income")
        )
        views.setOnClickPendingIntent(R.id.btn_income, incomePending)

        manager.updateAppWidget(widgetId, views)
    }
}
