// ignore_for_file: constant_identifier_names

enum Flavor {
  DEVELOPMENT,
  RELEASE,
}

class Config {
  static Flavor appFlavor = Flavor.RELEASE;
  static String get helloMessage {
    switch (appFlavor) {
      case Flavor.RELEASE:
        return 'RELEASE';
      case Flavor.DEVELOPMENT:
      return 'DEVELOPMENT';
    }
  }

  static String get baseURL {
    switch (appFlavor) {
      case Flavor.RELEASE:
        return "https://pees.ddnsking.com/"; 
        //'https://ec2-13-53-130-249.eu-north-1.compute.amazonaws.com/';
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
