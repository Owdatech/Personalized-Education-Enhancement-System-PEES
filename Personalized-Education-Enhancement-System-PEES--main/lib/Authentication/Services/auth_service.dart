// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pees/API_SERVICES/app_constant.dart/constant.dart';
import 'package:pees/API_SERVICES/config.dart';
import 'package:pees/API_SERVICES/preference_manager.dart';
import 'package:pees/Models/base_viewmodel.dart';
import 'package:http/http.dart' as http;
import 'package:pees/Models/user_model.dart';

class AuthVM extends BaseVM {
  Future<Map<String, String?>> loginApicall(
      String email, String password) async {
    setLoading(true);
    try {
      final url = Config.baseURL + ApiEndPoint.login;
      print("URL : $url");

      final jsonBody = {"email": email.trim(), "password": password.trim()};

      print("Request Body: ${jsonEncode(jsonBody)}"); // Debugging

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(jsonBody),
      );

      if (response.statusCode == 200) {
        print("Response: ${jsonDecode(response.body)}");
        final data = json.decode(response.body);

        if (data.containsKey('role')) {
          AIUser user = AIUser.fromJson(data);
          user.idToken = data["idToken"];
          AIUser.shared = user;

          final token = data['idToken'];
          final userId = data['user_id'];
          final role = data['role'];
          final jwtToken = data['jwtToken'];
          final refreshToken = data['refreshToken'];

          // Save credentials
          PreferencesManager.shared.saveUser(user);
          PreferencesManager.shared
              .saveCredentials(token, userId, role, jwtToken, refreshToken);

          setLoading(false);
          return {"role": role, "error": null};
        } else {
          setLoading(false);
          return {"role": null, "error": "Role not found in response"};
        }
      } else {
        print("Failed with status code: ${response.statusCode}");
        print("Error: ${response.body}");
        final errorMessage =
            json.decode(response.body)['error'] ?? "Login failed";
        setLoading(false);
        return {"role": null, "error": errorMessage};
      }
    } catch (error) {
      print("Request failed: $error");
      setLoading(false);
      return {"role": null, "error": "An unexpected error occurred"};
    }
  }

  Future<int?> logoutApi(String token) async {
    setLoading(true);
    try {
      final url = Config.baseURL + ApiEndPoint.logout;
      print("URL : $url");
      final jsonBody = {"id_token": token};
      // Send POST request
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(jsonBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await PreferencesManager.shared.logout();
        print("Response: $data");
        setLoading(false);
        return response.statusCode;
      } else {
        print("Failed with status code: ${response.statusCode}");
        await PreferencesManager.shared.logout();
        print("Error: ${response.body}");
        setLoading(false);
        return response.statusCode;
      }
    } catch (error) {
      print("Request failed: $error");
    }
    return null;
  }

  Future<int?> updateProfile(String role, String email, String password,
      String confirmPassword, File? image, String userId) async {
    setLoading(true);
    try {
      final url = Uri.parse(Config.baseURL + ApiEndPoint.updateProfile);

      print("Url : $url");
      final jsonBody = {
        "role": role,
        "email": email,
        "password": password,
        "confirmPassword": confirmPassword,
        "photo": image,
        "userId": userId,
      };
      var request = http.MultipartRequest('POST', url);
      Map<String, String> headers = {"Content-type": "multipart/form-data"};
      headers['Authorization'] = 'Bearer ${AIUser.shared.jwtToken}';
      request.headers.addAll(headers);

      request.fields['role'] = role;
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['confirmPassword'] = confirmPassword;
      request.fields['userId'] = userId;

      if (image != null) {
        request.files.add(
          http.MultipartFile(
            'profile',
            image.readAsBytes().asStream(),
            image.lengthSync(),
            filename: image.path.split('/').last,
          ),
        );
      }

      debugPrint("Update profile API: ${request.toString()}");
      var res = await request.send();
      http.Response response = await http.Response.fromStream(res);
      debugPrint('Profile Api Response: ${response.body}');
      if (response.statusCode == 200) {
        Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        AIUser user = AIUser.fromJson(data);
        setLoading(false);
        return response.statusCode;
      } else {
        setApiError('Somthing went wrong');
        setLoading(false);
      }
    } catch (error) {
      print("Request failed: $error");
      setLoading(false);
    }
    return null;
  }

  Future<int?> sendOTPApi(String email) async {
    setLoading(true);
    try {
      final url = Config.baseURL + ApiEndPoint.sendOTP;
      print("URL : $url");
      final jsonBody = {"email": email};
      // Send POST request
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(jsonBody),
      );

      if (response.statusCode == 200) {
        print("Response: ${jsonDecode(response.body)}");
        final data = json.decode(response.body);
        setLoading(false);
        return response.statusCode;
      } else {
        print("Failed with status code: ${response.statusCode}");
        print("Error: ${response.body}");
        setLoading(false);
        return response.statusCode;
      }
    } catch (error) {
      print("Request failed: $error");
    }
    return null;
  }

  Future<int?> forgotPasswordAPI(String email) async {
    setLoading(true);
    try {
      final url = '${Config.baseURL}forgot_password';
      print("URL : $url");
      final jsonBody = {"email": email};
      // Send POST request
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(jsonBody),
      );

      if (response.statusCode == 200) {
        print("Response: ${jsonDecode(response.body)}");
        final data = json.decode(response.body);
        setLoading(false);
        return response.statusCode;
      } else {
        print("Failed with status code: ${response.statusCode}");
        print("Error: ${response.body}");
        setLoading(false);
        return response.statusCode;
      }
    } catch (error) {
      print("Request failed: $error");
    }
    return null;
  }

  Future<int?> verifyOTPApi(String email, String otp) async {
    setLoading(true);
    try {
      final url = Config.baseURL + ApiEndPoint.verifyOTP;
      print("URL : $url");
      final jsonBody = {"email": email, "otp": otp};
      // Send POST request
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(jsonBody),
      );

      if (response.statusCode == 200) {
        print("Response: ${jsonDecode(response.body)}");
        final data = json.decode(response.body);
        setLoading(false);
        return response.statusCode;
      } else {
        print("Failed with status code: ${response.statusCode}");
        print("Error: ${response.body}");
        setLoading(false);
        return response.statusCode;
      }
    } catch (error) {
      print("Request failed: $error");
    }
    return null;
  }

  Future<int?> resetPassword(
      String userId, String password, String confrimPassword) async {
    setLoading(true);
    try {
      final url = '${Config.baseURL}api/auth/resetpassword12';
      print("URL : $url");
      final jsonBody = {
        "userId": userId,
        "password": password,
        "confirmPasswrod": confrimPassword
      };
      // Send POST request
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(jsonBody),
      );

      if (response.statusCode == 200) {
        print("Response: ${jsonDecode(response.body)}");
        final data = json.decode(response.body);
        setLoading(false);
        return response.statusCode;
      } else {
        print("Failed with status code: ${response.statusCode}");
        print("Error: ${response.body}");
        setLoading(false);
        return response.statusCode;
      }
    } catch (error) {
      print("Request failed: $error");
    }
    return null;
  }
}
