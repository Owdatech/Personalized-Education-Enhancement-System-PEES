import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pees/API_SERVICES/config.dart';
import 'package:pees/Models/base_viewmodel.dart';
import 'package:pees/Parent_Dashboard/Models/alerts_noti_model.dart';
import 'package:pees/Parent_Dashboard/Models/parent_model.dart';
import 'package:pees/Parent_Dashboard/Models/recentUpdateModel.dart';
import 'package:pees/Parent_Dashboard/Models/resourceModel.dart';
import 'package:pees/Widgets/AppImage.dart';

enum ParentFor { all, sara }

class ParentService extends BaseVM {
  ParentFor selectedType = ParentFor.all;
  int selectedIndex = 0;
  List<Students> studentsList = [];
  List<RecentUpdates> recentUpdatesList = [];
  List<Resources> resourcesList = [];
  // List<AlertsModel>  alertslist =[];
  List<Alerts> alertsList = [];
  List<Notifications> notificationsList = [];
  String selectedLanguage = Get.locale?.languageCode ?? 'en';
  Future<List<Students>> fetchChildernDetails(String userId) async {
    try {
      setLoading(true);
      String url = "${Config.baseURL}get_students?userId=$userId";
      print("Children Info URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> studentsJson = data['students'];
        studentsList = studentsJson.map((e) => Students.fromJson(e)).toList();
        print("Respone : $data");
        setLoading(false);
        return studentsList;
      } else {
        setLoading(false);
        print("Repsonse Code : ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Request failed: $e");
      setLoading(false);
      return [];
    }
  }

  Future<ProgressModel?> fetchProgressReport(
      String parentId, String studentId) async {
    setLoading(true);
    try {
      final url = Uri.parse(
          '${Config.baseURL}api/progress-report?parent_id=$parentId&student_id=$studentId');
      print("Fetch Report card info : $url");
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        ProgressModel model =
            ProgressModel.fromJson(json.decode(response.body));
        print(
            "Progress Report Repsonse Code : ${response.statusCode} ${response.body}");
        setLoading(false);
        return model;
      } else {
        print(
            "Progress Report Repsonse Code : ${response.statusCode} ${response.body}");
        setLoading(false);
        return null;
      }
    } catch (e) {
      setLoading(false);
      print("Progress Report failed : $e");
      return null;
    }
  }

  Future<int?> fetchRecentUpdates(String parentId) async {
    try {
      setLoading(true);
      String apiUrl =
          "${Config.baseURL}api/recent-updates?parent_id=$parentId&lang=$selectedLanguage";
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        RecentUpdateModel model = RecentUpdateModel.fromJson(data);
        recentUpdatesList = model.recentUpdates ?? [];
        print("Respone : $data");
        setLoading(false);
        return response.statusCode;
      } else {
        print("Failed Recents Error : ${response.statusCode} ${response.body}");
        setLoading(false);
        return response.statusCode;
      }
    } catch (error) {
      setLoading(false);
      print('Error fetching data: $error');
      return null;
    }
  }

  List<dynamic> students = [];
  Map<String, dynamic> recommendations = {};

  Future<int?> fetchResources(String parentId, String lang) async {
    try {
      setLoading(true);
      String apiUrl =
          "${Config.baseURL}api/resources-analysis?parent_id=$parentId&lang=$lang";
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        students = data["students"] as List<dynamic>;
        recommendations = data["recommendations"] as Map<String, dynamic>;

        print("Respone : $data");
        setLoading(false);
        return response.statusCode;
      } else {
        print("Failed Recents Error : ${response.statusCode} ${response.body}");
        setLoading(false);
        return response.statusCode;
      }
    } catch (error) {
      setLoading(false);
      print('Error fetching data: $error');
      return null;
    }
  }

  Future<int?> fetchAlertsNotification(String parentId) async {
    try {
      setLoading(true);
      String apiUrl =
          "${Config.baseURL}api/alerts-notifications?teacher_id=$parentId&lang=$selectedLanguage";
      print("Alerts & Notification URL : $apiUrl");
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        alertsList = (jsonData['alerts'] as List)
            .map((item) => Alerts.fromJson(item))
            .toList();
        notificationsList = (jsonData['notifications'] as List)
            .map((item) => Notifications.fromJson(item))
            .toList();
        print("Respone : $jsonData");
        setLoading(false);
        return response.statusCode;
      } else {
        print("Failed Recents Error : ${response.statusCode} ${response.body}");
        setLoading(false);
        return response.statusCode;
      }
    } catch (error) {
      setLoading(false);
      print('Error fetching data: $error');
      return null;
    }
  }

  List<ParentModel> dashBoardList = [
    ParentModel("DASHBOARD", ParentListType.dashBoard, AppImage.dashboardFill,
        AppImage.dashboardWhite),
    ParentModel("SETTINGS", ParentListType.settings, AppImage.settingsFill,
        AppImage.settingsWhite)
  ];
}

class Students {
  String? name;
  String? photoUrl;
  String? studentId;
  String? assignTeacherName;
  String? className;
  String? email;
  String? grade;

  Students(
      {this.name,
      this.photoUrl,
      this.studentId,
      this.assignTeacherName,
      this.className,
      this.email,
      this.grade});

  factory Students.fromJson(Map<String, dynamic> json) {
    return Students(
      name: json['name'],
      photoUrl: json['photoUrl'],
      studentId: json['studentId'],
      assignTeacherName: json['assignedTeacherName'],
      className: json['class'],
      email: json['email'],
      grade: json['grade'],
    );
  }
}

enum ParentListType { dashBoard, settings }

class ParentModel {
  String title;
  ParentListType type;
  String fillImage;
  String colorImage;

  ParentModel(this.title, this.type, this.fillImage, this.colorImage);
}
