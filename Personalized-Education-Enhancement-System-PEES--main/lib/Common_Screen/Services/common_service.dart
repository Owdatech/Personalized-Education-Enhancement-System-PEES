import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pees/API_SERVICES/app_constant.dart/constant.dart';
import 'package:pees/API_SERVICES/config.dart';
import 'package:pees/Common_Screen/Model/alert_model.dart';
import 'package:pees/Models/base_viewmodel.dart';
import 'package:pees/Models/profile_model.dart';

class CommonService extends BaseVM {
  String selectedLanguage = Get.locale?.languageCode ?? 'en';
  Future<int?> changePasswordApi(
      String userId, String newPassword, String confrimPassword) async {
    setLoading(true);

    try {
      final url = Config.baseURL + ApiEndPoint.changePassword;
      print("URL : $url");
      final jsonBody = {
        "userId": userId,
        "newPassword": newPassword,
        "confirmNewPassword": confrimPassword
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

  Future<int?> addNotification(String title, String description,
      String receiverId, String senderId) async {
    setLoading(true);

    try {
      final url = "${Config.baseURL}add-notification";
      print("URL : $url");
      final jsonBody = {
        "title": title,
        "description": description,
        "recevier_id": receiverId,
        "sender_id": senderId
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

  Future<int?> deliveryMethodApi(
      String userId, bool email, bool app, bool sms) async {
    setLoading(true);

    try {
      final url = "${Config.baseURL}update-delivery-method";
      print("URL : $url");
      final jsonBody = {
        "user_id": userId,
        "delivery_method": {"email": email, "app": app, "sms": sms}
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

  Future<int?> alertsAPI(String studId, String studName, int previousScore,
      int currentScore, String language) async {
    setLoading(true);

    try {
      final url = "${Config.baseURL}api/alerts";
      print("URL : $url");
      final jsonBody = {
        "student_id": studId,
        "student_name": studName,
        "pervious_score": previousScore,
        "current_score": currentScore,
        "language": language
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

  Future<ProfileModel?> getProfileApicall(String userId) async {
    setLoading(true);
    try {
      final url = "${Config.baseURL}${ApiEndPoint.getProfile}$userId";
      print("URL : $url");

      // Send POST request
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ProfileModel profileModel = ProfileModel.fromJson(data);
        print("Response: $data");
        setLoading(false);
        notifyListeners();
        return profileModel;
      } else {
        print("Failed with status code: ${response.statusCode}");
        print("Error: ${response.body}");
        setLoading(false);
        return null;
      }
    } catch (error) {
      print("Request failed: $error");
      setLoading(false);
    }
    return null;
  }

  Future<int?> updatePersonalInfo(String token, String userId, String name,
      String email, String phone, String role) async {
    setLoading(true);
    final url = "${Config.baseURL}api/headmaster/users/$userId";
    print("URL : $url");
    final Map<String, dynamic> requestBody = {
      "name": name,
      "email": email,
      "contactNumber": phone,
      "role": role,
    };
    print("Request Body  : $requestBody");
    setLoading(true);
    try {
      final response = await http.put(Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody));
      if (response.statusCode == 200) {
        setLoading(false);
        print('User updated successfully: ${response.body}');
        return response.statusCode;
      } else {
        print('Failed to update user. Status code: ${response.statusCode}');
        print('Response: ${response.body}');
        setLoading(false);
        return response.statusCode;
      }
    } catch (e) {
      print('Error updating user: $e');
      setLoading(false);
      return null;
    }
  }

  Future<int?> statusApi(String notificationId) async {
    setLoading(true);
    try {
      final url = "${Config.baseURL}mark-notification-read/$notificationId";
      print("URL : $url");
      // final jsonBody = {'notification_id': notificationId};
      // Send POST request
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        // body: jsonEncode(jsonBody),
      );

      if (response.statusCode == 200) {
        print("Response: ${jsonDecode(response.body)}");
        // final data = json.decode(response.body);
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

  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    final String url =
        '${Config.baseURL}get-notifications?user_id=$userId&lang=$selectedLanguage';
    setLoading(true);
    try {
      print("Notificaation list URL : $url");
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          List<dynamic> notificationsJson = data['notifications'];
          setLoading(false);
          return notificationsJson
              .map((json) => NotificationModel.fromJson(json))
              .toList();
        } else {
          setLoading(false);
          throw Exception("Failed to load notifications");
        }
      } else {
        setLoading(false);
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      setLoading(false);
      throw Exception("Error fetching notifications: $e");
    }
  }
}
