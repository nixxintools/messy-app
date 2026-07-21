import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../transport/lan/udp_discovery.dart';

/// Lets a user pass Messy on to the people around them — the way an
/// offline-first app should spread.
///
/// Two ways:
///  - **Share sheet** (WhatsApp, Bluetooth, Quick Share, Files…): copies our
///    own installed APK somewhere shareable and hands it to Android.
///  - **Over hotspot/Wi-Fi**: serves that APK from a tiny local HTTP server so
///    anyone on the same hotspot can install it with **no internet at all** —
///    they just open the link (or scan the QR).
class ApkShareService {
  static const _channel = MethodChannel('messy/app');
  static const port = 8088;

  HttpServer? _server;
  File? _cachedApk;

  bool get isServing => _server != null;

  Future<String?> versionName() async {
    try {
      return await _channel.invokeMethod<String>('versionName');
    } on Object {
      return null;
    }
  }

  /// Copies our installed APK into the cache dir with a friendly filename so
  /// it can be shared or served.
  Future<File?> prepareApk() async {
    if (_cachedApk != null && await _cachedApk!.exists()) return _cachedApk;
    try {
      final src = await _channel.invokeMethod<String>('apkPath');
      if (src == null) return null;
      final version = await versionName();
      final cache = await getTemporaryDirectory();
      final out = File(
        p.join(cache.path, 'Messy${version == null ? '' : '-v$version'}.apk'),
      );
      await File(src).copy(out.path);
      _cachedApk = out;
      return out;
    } on Object {
      return null;
    }
  }

  /// The first non-loopback IPv4 address — the address peers on this hotspot
  /// or Wi-Fi can reach us at.
  Future<String?> localAddress() async {
    try {
      final addrs = await UdpDiscovery.localAddresses();
      return addrs.isEmpty ? null : addrs.first.address;
    } on Object {
      return null;
    }
  }

  /// Starts the local download server. Returns the URL others should open,
  /// or null if it couldn't start.
  Future<String?> startServing() async {
    final apk = await prepareApk();
    if (apk == null) return null;
    final ip = await localAddress();
    if (ip == null) return null;
    if (_server == null) {
      try {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      } on Object {
        return null;
      }
      _server!.listen((req) async {
        try {
          if (req.uri.path == '/messy.apk') {
            req.response.headers
              ..contentType =
                  ContentType('application', 'vnd.android.package-archive')
              ..add('Content-Disposition', 'attachment; filename="Messy.apk"');
            req.response.contentLength = await apk.length();
            await req.response.addStream(apk.openRead());
          } else {
            // A tiny landing page so a plain browser hit works too.
            req.response.headers.contentType = ContentType.html;
            req.response.write(
              '<!doctype html><meta name="viewport" '
              'content="width=device-width,initial-scale=1">'
              '<body style="background:#0e1116;color:#e6edf3;'
              'font-family:system-ui;text-align:center;padding:48px 24px">'
              '<h1 style="color:#ffd60a">Messy</h1>'
              '<p>Offline mesh messenger.</p>'
              '<p><a style="display:inline-block;background:#ffd60a;'
              'color:#201a00;padding:14px 28px;border-radius:24px;'
              'font-weight:700;text-decoration:none" '
              'href="/messy.apk">Download the app</a></p>'
              '<p style="opacity:.7;font-size:14px">Then open the file to '
              'install. You may need to allow installs from your browser.</p>'
              '</body>',
            );
          }
        } on Object {
          // Client went away mid-transfer; nothing to do.
        } finally {
          await req.response.close();
        }
      });
    }
    return 'http://$ip:$port/';
  }

  Future<void> stopServing() async {
    await _server?.close(force: true);
    _server = null;
  }
}
