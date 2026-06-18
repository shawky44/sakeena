import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      // الطريقة السريعة: In-App Update من Play Store
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // إذا فيه تحديث، نعرض Dialog
        if (!context.mounted) return;
        _showUpdateDialog(context, updateInfo);
      }
    } catch (e) {
      debugPrint('❌ Error checking for update: $e');
    }
  }

  static void _showUpdateDialog(
      BuildContext context, AppUpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: false, // يمنع الإغلاق بالضغط برا
      builder: (_) => AlertDialog(
        title: const Text('تحديث متوفر'),
        content:
            const Text('يوجد نسخة جديدة من التطبيق. هل تريد التحديث الآن؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لاحقًا'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // تحديث مباشر داخل التطبيق
                await InAppUpdate.performImmediateUpdate();
              } catch (e) {
                debugPrint('❌ Error performing immediate update: $e');
                // إذا فشل، فتح Play Store مباشرة
                const packageName = 'com.example.azkar_app';
                const url =
                    'https://play.google.com/store/apps/details?id=$packageName';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                }
              }
            },
            child: const Text('تحديث'),
          ),
        ],
      ),
    );
  }
}
