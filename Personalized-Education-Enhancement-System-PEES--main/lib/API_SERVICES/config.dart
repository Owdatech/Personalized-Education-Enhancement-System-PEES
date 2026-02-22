// ignore_for_file: constant_identifier_names

enum Flavor {
  DEVELOPMENT,
  RELEASE,
}

class Config {
  static Flavor appFlavor = Flavor.RELEASE;
  static const String _baseUrlFromEnv = String.fromEnvironment('API_BASE_URL');

  static String get helloMessage {
    switch (appFlavor) {
      case Flavor.RELEASE:
        return 'RELEASE';
      case Flavor.DEVELOPMENT:
      return 'DEVELOPMENT';
    }
  }

  static String get baseURL {
    if (_baseUrlFromEnv.trim().isNotEmpty) {
      final custom = _baseUrlFromEnv.trim();
      return custom.endsWith('/') ? custom : '$custom/';
    }

    switch (appFlavor) {
      case Flavor.RELEASE:
        return "https://api.edupaths.app/";
      case Flavor.DEVELOPMENT:
        return '';
    }
  }

  static String getProfileUrl(String path) {
    if (path.isEmpty) {
      return '';
    }
    return '${baseURL}storage/$path';
  }
}
