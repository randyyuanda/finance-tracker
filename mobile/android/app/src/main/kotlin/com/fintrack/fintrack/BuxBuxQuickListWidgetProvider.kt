package com.fintrack.fintrack

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
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

        // Localization
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val flutterPrefs = context.getSharedPreferences("${context.packageName}_preferences", Context.MODE_PRIVATE)
        
        val lang = prefs.getString("language", null) 
                   ?: flutterPrefs.getString("flutter.language", "en") 
                   ?: "en"
        
        val title = when(lang) {
            "id" -> "TAMBAH CEPAT"
            "zh" -> "快速添加"
            else -> "QUICK ADD"
        }
        val outLabel = when(lang) {
            "id" -> "KELUAR"
            "zh" -> "支出"
            else -> "OUT"
        }
        val inLabel = when(lang) {
            "id" -> "MASUK"
            "zh" -> "收入"
            else -> "IN"
        }

        views.setTextViewText(R.id.widget_title, title)
        
        // Setup background intents for quick add buttons
        for (i in 1..4) {
            val id = when(i) {
                1 -> R.id.btn_quick_exp_1
                2 -> R.id.btn_quick_exp_2
                3 -> R.id.btn_quick_inc_1
                else -> R.id.btn_quick_inc_2
            }
            
            val type = prefs.getString("q${i}_type", if (i <= 2) "expense" else "income") ?: "expense"
            val amount = prefs.getFloat("q${i}_amount", if (i % 2 == 1) 10000f else 50000f)
            val label = prefs.getString("q${i}_label", if (type == "expense") "- ${amount.toInt()}" else "+ ${amount.toInt()}") ?: ""
            
            val accountId = prefs.getString("q${i}_accountId", "")
            val categoryId = prefs.getString("q${i}_categoryId", "")
            val note = prefs.getString("q${i}_note", "")

            val uri = Uri.parse("buxbux://quickadd?type=$type&amount=$amount&accountId=$accountId&categoryId=$categoryId&note=$note")
            
            views.setTextViewText(id, label)

            val intent = Intent(context, HomeWidgetBackgroundReceiver::class.java).apply {
                action = "es.antonborri.home_widget.action.BACKGROUND"
                data = uri
                setPackage(context.packageName)
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                id,
                intent,
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
            )
            
            views.setOnClickPendingIntent(id, pendingIntent)
        }

        manager.updateAppWidget(widgetId, views)
    }
}
