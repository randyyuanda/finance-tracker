import 'package:home_widget/home_widget.dart';
import 'formatters.dart';

class WidgetService {
  static Future<void> updateBalance(double totalBalance) async {
    try {
      await HomeWidget.saveWidgetData<String>('balance', formatCurrency(totalBalance));
      await HomeWidget.updateWidget(
        qualifiedAndroidName: 'com.fintrack.fintrack.BuxBuxWidgetProvider',
      );
    } catch (_) {}
  }
}
