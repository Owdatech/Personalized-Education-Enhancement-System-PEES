// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:pees/API_SERVICES/app_constant.dart/constant.dart';
import 'package:pees/API_SERVICES/config.dart';
import 'package:pees/HeadMaster_Dashboard/Model/UserManageModel.dart';
import 'package:pees/HeadMaster_Dashboard/Model/report_model.dart';
import 'package:pees/HeadMaster_Dashboard/Model/studentModel.dart';
import 'package:pees/HeadMaster_Dashboard/Model/student_profile.dart';
import 'package:pees/Models/base_viewmodel.dart';
import 'package:pees/Models/profile_model.dart';
import 'package:pees/Teacher_Dashbord/Pages/Progress/progress_screen.dart';
import 'package:pees/Teacher_Dashbord/Services/teacher_service.dart';
import 'package:pees/Widgets/AppImage.dart';

import '../Model/headMaster_model.dart';
import '../Pages/userManagement.dart';

class HeadMasterServices extends BaseVM {
  List<UserManageModel> teachersList = [];
  List<UserManageModel> studentsList = [];
  Map<String, dynamic>? analysisData;
  List<UserManageModel> parentsList = [];
  List<TextEditingController> marksControllers = [];
  List<TextEditingController> gradeControllers = [];
  List<String> subjectListName = [];
  List<GradeData> gradeData = [];
  UserEnum selectedList = UserEnum.all;
  int selectedIndex = 0;
  int selectedTab = 0;
  int selectedListTab = 0;
  int selectedScripts = 0;
  ExamScriptFor selectedExamTab = ExamScriptFor.academic;
  StudentsFor selectedType = StudentsFor.academic;
  List<StudentModel>? studentList = [];
  List<AttendanceModel> chartData = [];
  List<SujbectPerfomanceModel> subjectsData = [];
  List<UserManageModel> userList = [];
  List<String> subjectNames = [];
  List observationsList = [];
  List subjectList = [];
  List teachingPlans = [];
  String selectedLanguage = Get.locale?.languageCode ?? 'en';
  List<SubjectPercentage> subjectPercentages = [];
  Map<String, dynamic> dataTable = {};
  List<LineGraphModel> subjectNewData = [];
  List<SubjectEntry> fullDataTableEntries = [];
  Future<int?> fetchProgressData(
      String studentID, String? fromDate, String? toDate) async {
    final url = Uri.parse(
        '${Config.baseURL}api/student/progress/$studentID?startDate=$fromDate&endDate=$toDate');
    setLoading(true);
    print("Progress : $url");
    try {
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Reponse : $data");
        final graphData = data['dataTable'] as Map<String, dynamic>;
        List<LineGraphModel> loadedSubjects = [];
        List<SubjectEntry> allSubjectEntries = [];
        graphData.forEach((subjectName, entries) {
          for (var entry in entries) {
            String subject = subjectName.trim();
            double percentage = entry['percentage']?.toDouble() ?? 0.0;
            String date = entry['timestamp'];
            int marks = entry['marks'] ?? 0;
            int totalMarks = entry['totalMark'] ?? 0;
            loadedSubjects.add(
              LineGraphModel(
                  subject: subjectName.trim(),
                  percentage: percentage,
                  date: date),
            );
            allSubjectEntries.add(SubjectEntry(
              subject: subject,
              marks: marks,
              totalMarks: totalMarks,
              timestamp: date,
            ));
          }
        });

        subjectNewData = loadedSubjects;
        fullDataTableEntries = allSubjectEntries;

        final averages =
            data['averageSubjectPercentages'] as Map<String, dynamic>;

        subjectPercentages = averages.entries
            .map((e) => SubjectPercentage(
                subject: e.key.trim(), percentage: (e.value as num).toDouble()))
            .toList();
        dataTable = data['dataTable'];
        setLoading(false);
        return response.statusCode;
      } else {
        print("Failed with status code: ${response.statusCode}");
        print("Error: ${response.body}");
        setLoading(false);
        return response.statusCode;
      }
    } catch (e) {
      print("Request failed: $e");
      setLoading(false);
      return null;
    }
  }

  Future<int?> fetchTeachingPlans(String studentId) async {
    setLoading(true);
    try {
      String url =
          "${Config.baseURL}api/teaching-plan-detail?student_id=$studentId";
      print("URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        teachingPlans = data['data'];
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
      setLoading(false);
      return null;
    }
  }

  Future<int?> addSubject(String studId, String subjectName) async {
    setLoading(true);
    final url = Uri.parse(
        '${Config.baseURL}api/student/add-subject'); // replace with actual API URL

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'studentId': studId,
          'subject_name': subjectName,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Subject added successfully: ${responseData['message']}');
        setLoading(false);
        return response.statusCode;
      } else {
        print('Failed to add subject: ${response.body}');
        setLoading(false);
        return response.statusCode;
      }
    } catch (e) {
      print('Error: $e');
    }
    return null;
  }

  Future<int?> getSubjects(String gradeId, String classId,
      {String? subjectName}) async {
    final String apiUrl = '${Config.baseURL}grades/classes/subjects';
    print("URL : $apiUrl");
    setLoading(true);
    // Construct query parameters
    Map<String, String> queryParams = {
      'grade_id': gradeId,
      'class_id': classId,
    };

    if (subjectName != null && subjectName.isNotEmpty) {
      queryParams['subject_name'] = subjectName;
    }

    // Encode query parameters
    final uri = Uri.parse(apiUrl).replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        setLoading(false);
        final data = jsonDecode(response.body);
        subjectList = data;
        // marksControllers = List.generate(
        //     subjectList.length, (index) => TextEditingController());
        // gradeControllers = List.generate(
        //     subjectList.length, (index) => TextEditingController());
        print('Subjects: $subjectList');
        return response.statusCode;
      } else if (response.statusCode == 404) {
        print('No subjects found');
        setLoading(false);
        return response.statusCode;
      } else {
        print('Error: ${response.body}');
        print("Status code : ${response.statusCode}");
        setLoading(false);
        return response.statusCode;
      }
    } catch (e) {
      print('Exception: $e');
      setLoading(false);
    }
    return null;
  }

  Future<int?> deactivateUser(String userId) async {
    final String url = Config.baseURL + ApiEndPoint.deactiveUser;
    print("Url : $url");
    setLoading(true);
    final jsonBody = {"userId": userId};
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(jsonBody),
      );

      if (response.statusCode == 200) {
        print("Response : ${response.body}");
        setLoading(false);
        print('User deactivated successfully.');
        return response.statusCode;
      } else {
        print('Failed to deactivate user Status code: ${response.statusCode}');
        print('Response: ${response.body}');
        setLoading(false);
        return response.statusCode;
      }
    } catch (e) {
      print('Error deactivating user: $e');
      setLoading(false);
      return null;
    }
  }

  Future<int?> activateUserAPI(String userId) async {
    final String url = "${Config.baseURL}api/headmaster/activate";

    print("Url : $url");
    setLoading(true);
    final jsonBody = {"userId": userId};
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(jsonBody),
      );

      if (response.statusCode == 200) {
        print("Response : ${response.body}");
        setLoading(false);
        print('User deactivated successfully.');
        return response.statusCode;
      } else {
        print('Failed to deactivate user Status code: ${response.statusCode}');
        print('Response: ${response.body}');
        setLoading(false);
        return response.statusCode;
      }
    } catch (e) {
      print('Error deactivating user: $e');
      setLoading(false);
      return null;
    }
  }

  Future<ApiResponse> updateUser(String email, String name, String phone,
      String role, dynamic grades, String userId, String token,
      {List<String>? associatedStudentIds,
      String? password} // Optional parameter
      ) async {
    final String url = '${Config.baseURL}${ApiEndPoint.updateUser}$userId';
    final Map<String, dynamic> requestBody = {
      "email": email,
      "name": name,
      "phoneNumber": phone,
      "role": role,
      "grades": grades,
    };

    // Conditionally add associatedStudentIds if role is 'parent' and value is provided
    if (role.toLowerCase() == 'parent' && associatedStudentIds != null) {
      requestBody["associatedStudentIds"] = associatedStudentIds;
    }
    if (password != null && password.trim().isNotEmpty) {
      requestBody["password"] = password.trim();
    }

    setLoading(true);
    print("Update User URL : $url");
    print("Update Request Body : $requestBody");

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      setLoading(false);

      if (response.statusCode == 200) {
        print('User updated successfully: ${response.body}');
        return ApiResponse(statusCode: 200);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
        print('Failed to update user. Status code: ${response.statusCode}');
        print('Error message: $error');
        return ApiResponse(statusCode: response.statusCode, message: error);
      }
    } catch (e) {
      print('Error updating user: $e');
      setLoading(false);
      return ApiResponse(statusCode: 500, message: e.toString());
    }
  }

  List<Map<String, dynamic>> allGradeData = [];
  Future<List<UserManageModel>?> fetchUserList(String token) async {
    setLoading(true);
    try {
      final url = Config.baseURL + ApiEndPoint.getUserList;
      print("URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<UserManageModel> users =
            data.map((json) => UserManageModel.fromJson(json)).toList();
        userList = users;
        print("User List Response : $data");
        teachersList = users.where((user) => user.role == "teacher").toList();
        studentsList = users.where((user) => user.role == "student").toList();
        parentsList = users.where((user) => user.role == "parent").toList();
        setLoading(false);
        return users;
      } else {
        print("Failed with status code: ${response.statusCode}");
        print("Error: ${response.body}");
        setLoading(false);
        return null;
      }
    } catch (error) {
      print("Request failed: $error");
      setLoading(false);
      return null;
    }
  }

  Future<List<StudentModel>?> fetchStudentList(String userId) async {
    setLoading(true);
    try {
      final url = "${Config.baseURL}${ApiEndPoint.studentlist}?userId=$userId";
      print("URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          List<StudentModel> students =
              data.map((json) => StudentModel.fromJson(json)).toList();

          studentList = students;
          setLoading(false);
          notifyListeners();

          print("Response: $data");
          return students;
        } else {
          print("Unexpected response format");
          setLoading(false);
          return null;
        }
      } else {
        print("Failed with status code: ${response.statusCode}");
        print("Error: ${response.body}");
        setLoading(false);
        return null;
      }
    } catch (error) {
      print("Request failed: $error");
      setLoading(false);
      return null;
    }
  }

  Future<List<StudentModel>?> fetchStudentListHeadmaster() async {
    setLoading(true);
    try {
      final url = "${Config.baseURL}${ApiEndPoint.studentlist}";
      print("URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          List<StudentModel> students =
              data.map((json) => StudentModel.fromJson(json)).toList();

          studentList = students;
          setLoading(false);
          notifyListeners();

          print("Response: $data");
          return students;
        } else {
          print("Unexpected response format");
          setLoading(false);
          return null;
        }
      } else {
        print("Failed with status code: ${response.statusCode}");
        print("Error: ${response.body}");
        setLoading(false);
        return null;
      }
    } catch (error) {
      print("Request failed: $error");
      setLoading(false);
      return null;
    }
  }

  Future<int?> creatteAccountApi(
    String name,
    String phone,
    String role,
    String email,
    String password,
  ) async {
    setLoading(true);
    try {
      final url = Config.baseURL + ApiEndPoint.createAccount;
      print("URL : $url");
      final jsonBody = {
        "name": name,
        "email": email,
        "contactNumber": phone,
        "role": role,
      };
      // Send POST request
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(jsonBody),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print("Response: $data");
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
      setLoading(false);
    }
    return null;
  }

  Future<int?> addUserApicall(
    String name,
    String email,
    String phone,
    String role,
    String password,
    dynamic grades, {
    List<String>? associatedIds, // ✅ new optional parameter
  }) async {
    setLoading(true);
    try {
      final url = "${Config.baseURL}api/headmaster/add-users1";
      print("URL : $url");

      final jsonBody = {
        "name": name,
        "email": email,
        "contactNumber": phone,
        "role": role,
        "password": password,
        "grades": grades,
      };

      // ✅ Add associated_ids key ONLY if parent role
      if (associatedIds != null && associatedIds.isNotEmpty) {
        jsonBody["associated_ids"] = associatedIds;
      }

      print("Payload: $jsonBody"); // Debug

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(jsonBody),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print("Response: $data");
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
      setLoading(false);
    }
    return null;
  }

  Map<String, dynamic> academicData = {};
  Future<ReportCardModel?> getReportCardApicall(
    String studId,
  ) async {
    setLoading(true);
    try {
      final url = '${Config.baseURL}api/student/report-card/$studId';
      print("URl: $url");
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ReportCardModel model = ReportCardModel.fromJson(data);
        if (data['academicData'] == null ||
            data['academicData']['subjects'] == null) {
          print("Error: academicData or subjects is null");
          return null;
        }
        // academicData = data['academicData']['subjects'];
        // subjectListName = academicData.keys.toList();
        // chartData = [
        //   AttendanceModel(
        //       "present", data["attendance"]["presentDays"], Colors.green),
        //   AttendanceModel(
        //       "absent", data["attendance"]["absentDays"], Colors.red),
        //   AttendanceModel(
        //       "halfDay", data["attendance"]["halfDays"], Colors.blue)
        // ];
        final subjects =
            data["academicData"]["subjects"] as Map<String, dynamic>;
        List<SujbectPerfomanceModel> marksList = [];
        extractLatestMarks(data);
        setLoading(false);
        print("Response: $data");
        ReportCardModel academicData =
            ReportCardModel.fromJson(data['academicData']);
        return academicData;
      } else {
        print("Failed with status code: ${response.statusCode}");
        print("Error: ${response.body}");
        setLoading(false);
        throw Exception("Failed to load data");
      }
    } catch (error) {
      print("Get Reposr Card Request failed: $error");
      setLoading(false);
      throw Exception("Failed to load data");
    }
  }

  final List<Color> colors = [
    Colors.purple,
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.amber,
    Colors.indigo,
    Colors.lightGreen,
    Colors.redAccent,
    Colors.purpleAccent,
    Colors.teal,
    Colors.limeAccent,
    Colors.pink,
    Colors.deepPurple,
    Colors.brown,
    Colors.cyan,
    Colors.greenAccent,
    Colors.deepOrangeAccent,
    Colors.indigoAccent,
    Colors.purpleAccent,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.amber,
    Colors.indigo,
    Colors.lightGreen,
  ];

  void extractLatestMarks(Map<String, dynamic> data) {
    Map<String, int> latestMarks = {};
    Map<String, int> totalMarks = {};
    data["academicData"]["subjects"].forEach((subject, details) {
      if (details["history"].isNotEmpty) {
        var latestEntry = details["history"].last; // Get the latest marks entry
        latestMarks[subject] = latestEntry["marks"];
        totalMarks[subject] = latestEntry.containsKey("totalMarks")
            ? latestEntry["totalMarks"]
            : 100;
      }
    });

    subjectsData = latestMarks.entries
        .map((e) => SujbectPerfomanceModel(
            subjectName: e.key,
            marks: e.value,
            color: colors[
                latestMarks.keys.toList().indexOf(e.key) % colors.length],
            totalMarks: totalMarks[e.key] ?? 100))
        .toList();
  }

  Future<int?> getObservationList(String studId) async {
    setLoading(true);
    final url = Uri.parse("${Config.baseURL}students/$studId/observations");
    try {
      print("URL : $url");
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Observation Response : $data");
        observationsList = data['observations'];
        setLoading(false);
        notifyListeners();
        return response.statusCode;
      } else {
        print("Failed with status code: ${response.statusCode}");
        print("Error: ${response.body}");
        setLoading(false);
        return null;
      }
    } catch (error) {
      print("Request failed: $error");
      setLoading(false);
      return null;
    }
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

  Future<String?> uploadExamScript(
    String examName,
    String date,
    String curriculumCoverage,
    String observation,
    String studentId,
    html.File file, // Ensure this is passed correctly
  ) async {
    setLoading(true);
    try {
      final url = Uri.parse(Config.baseURL + ApiEndPoint.examScriptUpload);
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll({"Content-type": "multipart/form-data"});
      print("URL:  $url");
      request.fields['exam_name'] = examName;
      request.fields['curriculumId'] = curriculumCoverage.toString();
      request.fields['date'] = date;
      request.fields['observation'] = observation;
      request.fields['studentId'] = studentId;

      // Convert `html.File` to bytes
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      final bytes = reader.result as Uint8List;

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        ),
      );

      var res = await request.send();
      http.Response response = await http.Response.fromStream(res);

      if (response.statusCode == 200) {
        setLoading(false);
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData["extractText"];
      } else {
        setApiError('Something went wrong');
        print("Response code: ${response.statusCode}");
        setLoading(false);
      }
    } catch (error) {
      print("Request failed: $error");
      setLoading(false);
    }
    return null;
  }

  Future<int?> updateReportCardApiCall(
      // List<TextEditingController> marksControllers,
      // List<TextEditingController> gradeControllers,
      String studID,
      String grade,
      String absent,
      String half,
      String present,
      String working,
      String activity,
      String overGrades,
      String obtain,
      String totalMark) async {
    setLoading(true);

    Map<String, dynamic> subjectData = {};
    if (marksControllers.length != subjectListName.length ||
        gradeControllers.length != subjectListName.length) {
      print("Error: Controllers lists are not properly initialized.");
      setLoading(false);
    }

    for (int i = 0; i < subjectListName.length; i++) {
      if (i < marksControllers.length && i < gradeControllers.length) {
        String subjectName = subjectListName[i];
        subjectData[subjectName] = {
          "marks": int.parse(marksControllers[i].text),
          "grade": gradeControllers[i].text
        };
      } else {
        print(
            "Error: Marks or Grade controller for index $i is not initialized.");
        setLoading(false); // Stop loading state
        // Exit the function
      }
    }
    final Map<String, dynamic> jsonBody = {
      "studentId": studID,
      "academicData": {
        "grade": grade,
        "subjects": subjectData, // Pass as a map instead of a list
      },
      "attendance": {
        "absentDays": int.parse(absent),
        "halfDays": int.parse(half),
        "presentDays": int.parse(present),
        "totalWorkingDays": int.parse(working),
      },
      "reportCard": {
        "activity": activity,
        "grade": overGrades,
        "obtainedMarks": int.parse(obtain),
        "totalMarks": int.parse(totalMark),
      },
    };

    print("Json Body : $jsonBody");

    try {
      final url = Config.baseURL + ApiEndPoint.updateReportCard;
      print("URL : $url");

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(jsonBody),
      );

      if (response.statusCode == 200) {
        print("Success: ${response.body}");
        setLoading(false);
        notifyListeners();
        return response.statusCode;
      } else {
        print("Error: ${response.statusCode}");
        print("Response Error : ${apiError}");
        setLoading(false);
        return response.statusCode;
      }
    } catch (error) {
      print("Request failed: $error");
      setLoading(false);
    }
    return null;
  }

  Future<int?> updateStudentDetails(
      String studentId,
      String name,
      String address,
      String email,
      String phone,
      String grade,
      String classSection) async {
    setLoading(true);
    Map<String, dynamic> data = {
      "studentId": studentId,
      "name": name,
      "address": address,
      "email": email,
      "phoneNumber": phone,
      "grade": grade,
      "classSection": classSection,
    };
    try {
      final url = Config.baseURL + ApiEndPoint.updateStudentDetail;
      print("URL : $url");
      final response = await http.put(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Response: $data");
        setLoading(false);
        print("Update successful!");
        return response.statusCode;
      } else {
        print("Failed with status code: ${response.statusCode}");
        // print("Error: ${response.body}");
        setLoading(false);
        return response.statusCode;
      }
    } catch (error) {
      print("Request failed: $error");
    }
    return null;
  }

  Future<int?> uploadStudentImage(String studentId, Uint8List file) async {
    final url = Uri.parse(Config.baseURL + ApiEndPoint.uploadStudentPhoto);
    print("Upload Image URL : $url");
    try {
      setLoading(true);
      var request = http.MultipartRequest("POST", url)
        ..fields["studentId"] = studentId
        ..files.add(
          http.MultipartFile.fromBytes(
            'photo',
            file,
            filename: "student_image.jpg",
            contentType: MediaType('image', 'jpeg'),
          ),
        );

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setLoading(false);
        print("Upload Successful: $data");
        return response.statusCode;
      } else {
        print("Failed: ${response.statusCode}, Error: ${response.body}");
        setLoading(false);
        return response.statusCode;
      }
    } catch (error) {
      print("Request failed: $error");
      setLoading(false);
      return null;
    }
  }

  Future<int?> getGradeGraphWithFilter(
      String studId, String startDate, String endDate) async {
    setLoading(true);
    try {
      final url =
          '${Config.baseURL}api/student/grades/$studId?startDate=$startDate&endDate=$endDate';
      print("URl: $url");
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> gradeList = jsonData['gradeProgression'];
        gradeData = gradeList.map((item) {
          return GradeData(
            timestamp:
                // DateTime.parse(
                item['timestamp'],
            // ),
            points: item['linepoints'],
          );
        }).toList();
        print("Response : $jsonData");
        setLoading(false);
        return response.statusCode;
      } else {
        print("Failed with status code: ${response.statusCode}");
        print("Error: ${response.body}");
        setLoading(false);
        return response.statusCode;
      }
    } catch (error) {
      print("Get Reposr Card Request failed: $error");
      setLoading(false);
    }
    return null;
  }

  Future<int?> getGradeGraph(String studId) async {
    setLoading(true);
    try {
      final url = '${Config.baseURL}api/student/grades/$studId';
      print("URl: $url");
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> gradeList = jsonData['gradeProgression'];
        gradeData = gradeList.map((item) {
          return GradeData(
            timestamp:
                // DateTime.parse(
                item['timestamp'],
            // ),
            points: item['linepoints'],
          );
        }).toList();
        print("Response : $jsonData");
        setLoading(false);
        return response.statusCode;
      } else {
        print("Failed with status code: ${response.statusCode}");
        print("Error: ${response.body}");
        setLoading(false);
        return response.statusCode;
      }
    } catch (error) {
      print("Get Reporr Card Request failed: $error");
      setLoading(false);
    }
    return null;
  }

  Future<StudentProfileModel?> fetchStudentProfileDetails(
      String studentId) async {
    final String apiUrl = "${Config.baseURL}getStudent?studentId=$studentId";

    try {
      setLoading(true);
      print("URL : $apiUrl");
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print("Response : $data");
        setLoading(false);
        return StudentProfileModel.fromJson(data); // ✅ Convert JSON to Model
      } else {
        print("Error: ${response.statusCode}, ${response.body}");
        setLoading(false);
        return null;
      }
    } catch (e) {
      setLoading(false);
      print("Exception: $e");
      return null;
    }
  }

  Future<String?> exportProgress(String studentId, String fileType,
      String startDate, String endDate, String lang) async {
    try {
      final url = Uri.parse(
          "${Config.baseURL}export_analysis?student_id=$studentId&format_type=$fileType&startDate=$startDate&endDate=$endDate&lang=$lang");
      setLoading(true);
      print("URL : $url");
      final response =
          await http.get(url, headers: {"Content-Type": "application/json"});
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        setLoading(false);
        print("Response : $responseData");
        return responseData['download_url'];
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        setLoading(false);
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      setLoading(false);
      return null;
    }
  }

  List<dynamic> metrics = [];
  Future<int?> schoolPerformance() async {
    final url = Uri.parse("${Config.baseURL}api/school-performance");
    setLoading(true);
    try {
      print("School performaance API : $url");
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        metrics = json.decode(response.body)['metrics'];
        // classGradeList = data.map((json) => ClassModel.fromJson(json)).toList();

        print("School Performance Response : $data");
        setLoading(false);
        notifyListeners();
        return response.statusCode;
      } else {
        print("Failed with status code: ${response.statusCode}");
        print("Error: ${response.body}");
        setLoading(false);
        return null;
      }
    } catch (error) {
      print("Request failed: $error");
      setLoading(false);
      return null;
    }
  }

  List<dynamic> reports = [];
  Future<int?> reportsApi() async {
    final url = Uri.parse(
        "${Config.baseURL}api/reports-overview?lang=$selectedLanguage");
    setLoading(true);
    try {
      print("Reports API : $url");
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        reports = data['reports']['important_reports'];

        print("Reports API Response : $data");
        setLoading(false);
        notifyListeners();
        return response.statusCode;
      } else {
        print("Failed with status code: ${response.statusCode}");
        print("Error: ${response.body}");
        setLoading(false);
        return null;
      }
    } catch (error) {
      print("Request failed: $error");
      setLoading(false);
      return null;
    }
  }

  void updateSelectedIndex(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  set selectedIndexs(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  Future<int?> analyzeStudentData(String studId) async {
    try {
      setLoading(true);
      final url = Uri.parse("${Config.baseURL}analyze_student_data");
      print("Student Analyze URL : $url");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'student_id': studId}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Student Analyze created');
        analysisData = responseData['analysis'];
        print("Student Report Data : $responseData");
        setLoading(false);
        return response.statusCode;
      } else {
        print("Failed Analyze data : ${response.body}");
        setLoading(false);
        return response.statusCode;
      }
    } catch (error) {
      print('Error: $error');
      setLoading(false);
    }
    return null;
  }

  List<MasterDrawerModel> masterDrawerList = [
    MasterDrawerModel('dashboard', MasterDrawerType.dashboard,
        AppImage.dashboardFill, AppImage.dashboardWhite),
    MasterDrawerModel('students', MasterDrawerType.students,
        AppImage.studentsFill, AppImage.studentsWhite),
    MasterDrawerModel('userManagement', MasterDrawerType.userManagement,
        AppImage.userManagementFill, AppImage.userManagementWhite),
    MasterDrawerModel('settings', MasterDrawerType.settings,
        AppImage.settingsFill, AppImage.settingsWhite)
  ];
}

enum MasterDrawerType { dashboard, students, userManagement, settings }

class MasterDrawerModel {
  String title;
  MasterDrawerType type;
  String fillImage;
  String whiteImage;
  MasterDrawerModel(this.title, this.type, this.fillImage, this.whiteImage);
}

class AttendanceModel {
  final String title;
  final int attendence;
  final Color color;
  AttendanceModel(this.title, this.attendence, this.color);
}

class SujbectPerfomanceModel {
  String? subjectName;
  int? marks;
  Color? color;
  int? totalMarks;
  bool isVisible;
  SujbectPerfomanceModel(
      {required this.subjectName,
      required this.marks,
      required this.color,
      required this.totalMarks,
      this.isVisible = true});
}

class GradeData {
  String? grade;
  double? points;
  String? timestamp;
  GradeData({this.grade, this.points, this.timestamp});

  factory GradeData.fromJson(Map<String, dynamic> json) {
    return GradeData(
        grade: json['grade'],
        points: json['linepoints'],
        timestamp:
            // DateTime.parse(

            json['timestamp']
        // ),
        );
  }
}
