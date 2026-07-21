import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

import 'app.dart';
import 'services/security/secure_screen_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Route sqlite3 to the SQLCipher native library so the database is
  // encrypted at rest (see MessyDatabase / DbKey).
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  }
  // Apply the stored FLAG_SECURE preference before the first frame.
  await SecureScreenService().applyStored();
  runApp(const ProviderScope(child: MessyApp()));
}
