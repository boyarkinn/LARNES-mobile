import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:larnes_mobile/core/api/api_error_body.dart';
import 'package:larnes_mobile/core/app_update/app_update_info.dart';
import 'package:larnes_mobile/core/config/app_config.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class AppUpdateService {
  AppUpdateService({Dio? dio}) : _dio = dio ?? _buildDio();

  final Dio _dio;

  static Dio _buildDio() {
    return Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        headers: const {'Content-Type': 'application/json'},
        receiveTimeout: const Duration(seconds: 30),
        validateStatus: apiStatusAcceptable,
      ),
    );
  }

  Dio _downloadDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
  }

  Future<bool> get isAndroidPlatform async => Platform.isAndroid;

  Future<int> readLocalVersionCode() async {
    final info = await PackageInfo.fromPlatform();
    return int.tryParse(info.buildNumber) ?? 0;
  }

  Future<String> readLocalVersionLabel() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }

  Future<AppUpdateInfo?> fetchRemoteUpdate() async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/mobile/app-update',
        queryParameters: const {'platform': 'android'},
      );
      final data = response.data;
      if (data == null || data['status'] != 'success') {
        return null;
      }

      final update = data['update'];
      if (update is! Map<String, dynamic>) {
        return null;
      }

      return AppUpdateInfo.fromJson(update);
    } on DioException {
      return null;
    }
  }

  Future<AppUpdateInfo?> fetchAvailableUpdate() async {
    final remote = await fetchRemoteUpdate();
    if (remote == null) {
      return null;
    }

    final localVersionCode = await readLocalVersionCode();
    if (!isRemoteAppUpdateNewer(
      remote: remote,
      localVersionCode: localVersionCode,
    )) {
      return null;
    }

    return remote;
  }

  Future<String> downloadApk({
    required AppUpdateInfo update,
    void Function(int received, int? total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final directory = await getApplicationSupportDirectory();
    final targetPath = '${directory.path}/larnes-${update.versionCode}.apk';
    final file = File(targetPath);
    if (await file.exists()) {
      try {
        await verifySha256(filePath: targetPath, expectedSha256: update.sha256);
        final size = await file.length();
        onProgress?.call(size, size);
        return targetPath;
      } on AppUpdateVerificationException {
        await file.delete();
      }
    }
    final partial = File('$targetPath.part');
    try {
      await _downloadDio().download(
        update.url,
        partial.path,
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
      );
      if (cancelToken?.isCancelled == true) throw cancelToken!.cancelError!;
      await partial.rename(targetPath);
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    }
    return targetPath;
  }

  Future<void> verifySha256({
    required String filePath,
    required String expectedSha256,
  }) async {
    final digest = (await sha256.bind(File(filePath).openRead()).first)
        .toString();
    if (digest.toLowerCase() != expectedSha256.toLowerCase()) {
      throw AppUpdateVerificationException();
    }
  }

  Future<void> openInstaller(String filePath) async {
    final result = await OpenFilex.open(
      filePath,
      type: 'application/vnd.android.package-archive',
    );

    if (result.type != ResultType.done) {
      throw AppUpdateInstallException(result.message);
    }
  }
}

class AppUpdateVerificationException implements Exception {}

class AppUpdateInstallException implements Exception {
  AppUpdateInstallException(this.message);

  final String message;
}
