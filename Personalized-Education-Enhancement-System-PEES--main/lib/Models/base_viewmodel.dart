import 'package:flutter/material.dart';

class BaseVM extends ChangeNotifier {
  bool _loading = false;
  String? _loadingMessage;
  String? apiError;

  bool get loading => _loading;
  String? get loadingMessage => _loadingMessage;

  void setLoading(bool value) {
    _loading = value;
    apiError = null;
    notifyListeners();
  }

  void setApiError(String? userError) {
    apiError = userError;
    notifyListeners();
  }
}
