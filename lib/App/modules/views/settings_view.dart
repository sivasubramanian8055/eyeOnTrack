import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_settings_plus/open_settings_plus.dart';
import '../../../app_controller.dart';

class SettingsView extends GetView<AppController> {
  const SettingsView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Center(
          child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Sound Alert',
                    style: GoogleFonts.openSans(
                        fontSize: 18, fontWeight: FontWeight.w400),
                  ),
                ),
                Obx(() => Switch(
                    value: controller.soundAlert.value,
                    onChanged: (val) {
                      controller.soundAlert.value = val;
                    }))
              ],
            ),
          ),

          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //   child: Row(children: [
          //      Expanded(child: Text('Notification', style: GoogleFonts.openSans(
          //        fontSize: 18, fontWeight: FontWeight.w400
          //      ),),),
          //     Obx(() => Switch(value: controller.notificationAlert.value, onChanged: (val){
          //       controller.notificationAlert.value = val;
          //     }))
          //   ],),
          // ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Wakelock enable',
                    style: GoogleFonts.openSans(
                        fontSize: 18, fontWeight: FontWeight.w400),
                  ),
                ),
                Obx(() => Switch(
                    value: controller.wakeLock.value,
                    onChanged: (val) {
                      controller.wakeLock.value = val;
                    }))
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Speed Radar Alert',
                    style: GoogleFonts.openSans(
                        fontSize: 18, fontWeight: FontWeight.w400),
                  ),
                ),
                Obx(() => Switch(
                    value: controller.speedAlert.value,
                    onChanged: (val) {
                      controller.speedAlert.value = val;
                    }))
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Radar Radius',
                  style: GoogleFonts.openSans(
                      fontSize: 18, fontWeight: FontWeight.w400),
                ),
                Expanded(
                    child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(() => Text(
                          '${controller.radarRadius.value.toStringAsFixed(0)} KM',
                          style: GoogleFonts.openSans(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        )),
                    Obx(() => Slider(
                        value: controller.radarRadius.value.toDouble(),
                        min: 1,
                        max: 10,
                        label: '${controller.radarRadius.value}',
                        onChanged: (val) {
                          controller.radarRadius.value = val;
                        })),
                  ],
                )),
              ],
            ),
          ),
        ],
      )),
    );
  }
}

class MyAApp extends StatelessWidget {
  const MyAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (OpenSettingsPlus.shared) {
        OpenSettingsPlusAndroid settings => _buildAndroidList(settings),
        OpenSettingsPlusIOS settings => _buildIOSList(settings),
        _ => const Center(
          child: Text(
            "Unsupported platform.",
          ),
        ),
      },
    );
  }

  ListView _buildIOSList(OpenSettingsPlusIOS settings) {
    return ListView(
      children: [
        ListTile(
          onTap: settings,
          title: const Text("Open settings"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.wifi,
          title: const Text("Open wi-fi"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.about,
          title: const Text("Open about"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.accessibility,
          title: const Text("Open accessibility"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.accountSettings,
          title: const Text("Open account settings"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.autoLock,
          title: const Text("Open auto lock"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.battery,
          title: const Text("Open battery"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.bluetooth,
          title: const Text("Open bluetooth"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.dateAndTime,
          title: const Text("Open date and time"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.faceIDAndPasscode,
          title: const Text("Open face ID and passcode"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.cellular,
          title: const Text("Open cellular"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.dictionary,
          title: const Text("Open dictionary"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.displayAndBrightness,
          title: const Text("Open display and brightness"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.general,
          title: const Text("Open general"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.iCloud,
          title: const Text("Open iCloud"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.music,
          title: const Text("Open music"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.keyboard,
          title: const Text("Open keyboard"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.keyboards,
          title: const Text("Open keyboards"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.languageAndRegion,
          title: const Text("Open language and region"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.locationServices,
          title: const Text("Open location services"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.personalHotspot,
          title: const Text("Open personal hotspot"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.phone,
          title: const Text("Open phone"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.photosAndCamera,
          title: const Text("Open photos and camera"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.privacy,
          title: const Text("Open privacy"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.profilesAndDeviceManagement,
          title: const Text("Open Profiles"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.storageAndBackup,
          title: const Text("Open storage and backup"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.siri,
          title: const Text("Open siri"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.soundsAndHaptics,
          title: const Text("Open sounds and haptics"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.wallpapers,
          title: const Text("Wallpaper settings"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.healthKit,
          title: const Text("Open health kit"),
          trailing: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  ListView _buildAndroidList(OpenSettingsPlusAndroid settings) {
    return ListView(
      children: [
        ListTile(
          onTap: settings.wifi,
          title: const Text("Open wifi"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.accessibility,
          title: const Text("Open accessibility"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.addAccount,
          title: const Text("Open add account"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.airplaneMode,
          title: const Text("Open airplane mode"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.apnSettings,
          title: const Text("Open apn settings"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.appNotification,
          title: const Text("Open app notification"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.appSettings,
          title: const Text("Open app settings"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.applicationDetails,
          title: const Text("Open application details"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.applicationDevelopment,
          title: const Text("Open application development"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.applicationNotification,
          title: const Text("Open application notification"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.applicationSettings,
          title: const Text("Open application settings"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.applicationWriteSettings,
          title: const Text("Open application write settings"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.batterySaver,
          title: const Text("Open battery saver"),
          trailing: const Icon(Icons.chevron_right),
        ),
        ListTile(
          onTap: settings.locationSource,
          title: const Text("Open loca"),
          trailing: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
