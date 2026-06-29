import 'package:flutter_foundation_kit/wcore/settings/AppEnvironment.dart';
import 'package:flutter_foundation_kit/wcore/settings/Settings.dart';
import 'package:flutter_foundation_kit/wcore/settings/SettingsLoader.dart';
import 'package:injectable/injectable.dart';

class Settings extends SettingsBase {
  final AppEnvironment _environment;
  final String _packageName;
  final String baseUrl;
  Settings({
    required AppEnvironment environment,
    required String packageName,
    required this.baseUrl,
  }) : _environment = environment,
       _packageName = packageName;

  @override
  AppEnvironment get environment => _environment;

  @override
  String get packageName => _packageName;

  @override
  Map<String, dynamic> toJson() {
    return {
      'environment': _environment.name,
      'packageName': _packageName,
      'baseUrl': baseUrl,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      environment: _environmentFromJson(json['environment']),
      packageName: json['packageName'] as String,
      baseUrl: json['baseUrl'] as String,
    );
  }

  static AppEnvironment _environmentFromJson(Object? value) {
    if (value is Map<String, dynamic>) {
      return AppEnvironment.fromJson(value);
    }
    if (value is String) {
      return AppEnvironment(value);
    }
    throw ArgumentError.value(
      value,
      "environment",
      "Unsupported app environment.",
    );
  }
}

@LazySingleton(as: SettingsLoader)
class DefaultSettingsLoader extends SettingsLoader {
  @override
  String getPackageName() {
    return "com.example.app.development";
  }

  @override
  AppEnvironment getEnvironment({required String packageName}) {
    if (packageName.contains("development")) {
      return AppEnvironment.development;
    } else if (packageName.contains("production")) {
      return AppEnvironment.production;
    } else if (packageName.contains("test")) {
      return AppEnvironment.test;
    } else {
      throw ArgumentError.value(
        packageName,
        "packageName",
        "Unsupported package name.",
      );
    }
  }

  @override
  String assetPathForEnvironment(AppEnvironment environment) {
    if (environment == AppEnvironment.development) {
      return "lib/base/store/settings/development.json";
    } else if (environment == AppEnvironment.production) {
      return "lib/base/store/settings/release.json";
    } else if (environment == AppEnvironment.test) {
      return "lib/base/store/settings/development.json";
    } else {
      throw ArgumentError.value(
        environment,
        "environment",
        "Unsupported app environment.",
      );
    }
  }
}
