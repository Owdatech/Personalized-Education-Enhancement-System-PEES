// ignore_for_file: constant_identifier_names

enum Flavor {
  DEVELOPMENT,
  RELEASE,
}

class Config {
  static Flavor appFlavor = Flavor.DEVELOPMENT;
  static const String _baseUrlFromEnv = String.fromEnvironment('API_BASE_URL');
  static const String _curriculumBaseUrlFromEnv =
      String.fromEnvironment('CURRICULUM_API_BASE_URL');

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
        return "http://127.0.0.1:5001/";
    }
  }

  static String get curriculumBaseURL {
    if (_curriculumBaseUrlFromEnv.trim().isNotEmpty) {
      final custom = _curriculumBaseUrlFromEnv.trim();
      return custom.endsWith('/') ? custom : '$custom/';
    }

    return "https://api.edupaths.app/";
  }

  static String getProfileUrl(String path) {
    if (path.isEmpty) {
      return '';
    }
    return '${baseURL}storage/$path';
  }
}
