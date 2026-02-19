// ignore_for_file: avoid_print, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pees/API_SERVICES/app_constant.dart/constant.dart';
import 'package:pees/API_SERVICES/config.dart';
import 'package:pees/HeadMaster_Dashboard/Model/report_model.dart';
import 'package:pees/Models/base_viewmodel.dart';
import 'package:pees/Teacher_Dashbord/Models/exam_history_model.dart';
import 'package:pees/Teacher_Dashbord/Pages/Progress/progress_screen.dart';
import 'package:pees/Widgets/AppImage.dart';

import '../../HeadMaster_Dashboard/Services/headMaster_services.dart';

enum StudentsFor { academic, teachingPlan, observation, progress }

enum ExamScriptFor { academic, examScript }

class TeacherService extends BaseVM {
  String selectedLanguage = Get.locale?.languageCode ?? 'en';
  List<TextEditingController> marksControllers = [];
  List<TextEditingController> gradeControllers = [];
  List<String> subjectListName = [];
  List<ExamHistory> examHistoryList = [];
  int selectedIndex = 0;
  int selectedScripts = 0;
  List subjectList = [];
  List observationsList = [];
  List<AttendanceModel> attendanceChartData = [];
  List<SujbectPerfomanceModel> subjectsData = [];
  List<GradeData> gradeData = [];
  Map<String, dynamic> academicData = {};
  ExamScriptFor selectedExamTab = ExamScriptFor.academic;
  StudentsFor selectedType = StudentsFor.academic;
  Map<String, dynamic> analysisData = {};
  List teachingPlansList = [];
  // List<FeedbackModel>? feedbackList = [];
  List<dynamic> feedbackList = [];
  List<ClassModel> classGradeList = [];
  String? improvementList;

  Future<int?> saveReports(
    String teacherId,
    String studentName,
    String studID,
    String mainGrade,
    String subject,
    String curriculumId,
    String curriculumName,
    int marks,
    String grade,
    int totalMark, String entryDate,

    // String activity,
    // String overallGrade,
  ) async {
    final url = Config.baseURL + ApiEndPoint.addReportCard;
    print("Save Url : $url");

    setLoading(true);
    final Map<String, dynamic> jsonBody = {
      "teacher_id": teacherId,
      "student_name": studentName,
      "studentId": studID,
      "entryDate": entryDate,
      "academicData": {
        "grade": mainGrade,
        "subjects": {
          subject: {
            "curriculumId": curriculumId,
            "curriculumName": curriculumName,
            "marks": marks,
            "grade": grade,
            "totalMark": totalMark,
          }
        }
      },
    };

    print("Json Body : $jsonBody");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(jsonBody), // Convert to JSON
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
      print("Exception: $error");
      setLoading(false);
      return null;
    }
  }

  Future<List<ExamHistory>> fetchExamHistory(String studId) async {
    String url = "${Config.baseURL}get_exam_history/$studId";
    print("Fetching Exam History from: $url");

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      print("API Status Code: ${response.statusCode}");
      print("API Response: ${response.body}");

      final Map<String, dynamic> data = json.decode(response.body);

      if (response.statusCode == 200) {
        List<dynamic> examList = data["exam_history"] ?? [];
        return examList.map((e) => ExamHistory.fromJson(e)).toList();
      } else if (response.statusCode == 404) {
        print("No exam history found: ${data["message"]}");
        return [];
      } else {
        print("Unexpected response: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error fetching exam history: $e");
      return [];
    }
  }

  Future<int?> createOrUpdateGrade(int grade, List<String> classes) async {
    final url = Uri.parse(
        '${Config.baseURL}/grades'); // Replace with your actual API URL

    final Map<String, dynamic> payload = {"grade": grade, "classes": classes};
    setLoading(true);
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("Success: ${responseData['message']}");
        setLoading(true);
        return response.statusCode;
      } else {
        print("Error: ${response.body}");
        setLoading(true);
        return response.statusCode;
      }
    } catch (e) {
      print("Exception: $e");
      setLoading(true);
    }
    return null;
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
        // print('Failed to add subject: ${response.body}');
        setLoading(false);
        return response.statusCode;
      }
    } catch (e) {
      setLoading(false);
      print('Error: $e');
    }
    return null;
  }

  Future<int?> getGrades() async {
    final url = Uri.parse("${Config.baseURL}grades");
    setLoading(true);
    try {
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Grades Response : $data");
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
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          print('Subjects: $data');
          // Optionally store subject names as a string
          subjectName = data.join(", ");
          // List subjectNames =
          //     data.map((subject) => subject["subject_name"]!).toList();
          // subjectList = subjectNames;

          // print("Subject List : $subjectNames");
          setLoading(false);
        } else {
          print('No subjects found in response');
          setLoading(false);
          return 404; // Indicate no subjects were found
        }

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

  // Future<int?> addReportCardApicall(
  //   String studentId,
  // ) async {
  //   setLoading(true);
  //   try {
  //     final url = Config.baseURL + ApiEndPoint.addReportCard;
  //     print("URL : $url");
  //     final jsonBody = {
  //       "studentId": studentId,
  //       // "subjects": subjectList,
  //       // "attendance": attendanceDetails,
  //       // "reportCard": report
  //     };
  //     final response = await http.post(
  //       Uri.parse(url),
  //       headers: {"Content-Type": "application/json"},
  //       body: jsonEncode(jsonBody),
  //     );

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       print("Response: $data");
  //       setLoading(false);
  //       return response.statusCode;
  //     } else {
  //       print("Failed with status code: ${response.statusCode}");
  //       print("Error: ${response.body}");
  //       setLoading(false);
  //       return response.statusCode;
  //     }
  //   } catch (error) {
  //     print("Request failed: $error");
  //   }
  //   return null;
  // }

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

  Future<int?> addObservation(String studId, html.File? file, String subject,
      String observation) async {
    final data = {"file": file, "subject": subject, "observation": observation};
    print("Request Data : $data");
    setLoading(true);
    try {
      final url = Uri.parse("${Config.baseURL}students/$studId/observations");
      var request = http.MultipartRequest("POST", url);

      // Attach the file
      if (file != null) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;

        var byteData = reader.result as List<int>;
        var multipartFile = http.MultipartFile.fromBytes(
          'file',
          byteData,
          filename: file.name,
        );

        request.files.add(multipartFile);
      }

      request.fields['subject'] = subject;
      request.fields['observation'] = observation;
      // Send the request
      var streamedResponse = await request.send();

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Response: $data");
        setLoading(false);
        print("Add Observation successful!");
        return response.statusCode;
      } else {
        print("Failed with status code: ${response.statusCode}");
        // print("Error: ${response.body}");
        setLoading(false);
        return response.statusCode;
      }
    } catch (error) {
      print("Request failed: $error");
      setLoading(false);
    }
    return null;
  }

  Future<int?> updateTeachingPlan(
    String studId,
    String planId,
    String name,
    String grade,
    Map<String, String> objective,
    Map<String, String> strategies,
    Map<String, String> resource,
    Map<String, String> additionalSupport,
    Map<String, String> timeline,
    int version,
  ) async {
    // String url = "${Config.baseURL}${ApiEndPoint.updateTeachingPlan}$planId";
    String url = "${Config.baseURL}teaching-plan";
    print("URL: $url");

    Map<String, dynamic> requestBody = {
      "planId": planId,
      "studentId": studId,
      "updates": {
        "assessmentMethods": additionalSupport,
        "instructionalStrategies": strategies,
        "learningObjectives": objective,
        "recommendedResources": resource,
        "timeline": timeline
      }
    };

    print("Sending Request Body: ${jsonEncode(requestBody)}");

    setLoading(true);
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      print("API Response Code: ${response.statusCode}");
      print("API Response Body: ${response.body}");
      print("Update Teaching Plan");

      setLoading(false);
      if (response.statusCode == 200) {
        print("Success: ${response.body}");
        return response.statusCode;
      } else {
        print("Failed: ${response.statusCode}, ${response.body}");
        return response.statusCode;
      }
    } catch (e) {
      setLoading(false);
      print("Error: $e");
      return null;
    }
  }

  Future<String?> exportTeachingPlan(
      String studId, String planId, String lang) async {
    String url = "${Config.baseURL}api/teaching-plan/export";
    setLoading(true);

    Map<String, dynamic> requestBody = {
      "planId": planId,
      "studentId": studId,
      "lang": lang
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody), // Encode the body properly
      );

      print("URL : $url");
      print("Body : ${jsonEncode(requestBody)}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("Export Successful: ${response.body}");
        setLoading(false);
        return responseData["pdfUrl"]; // Return the PDF URL
      } else {
        print("Export Failed: ${response.statusCode}, ${response.body}");
        setLoading(false);
        return null;
      }
    } catch (e) {
      print("Error: $e");
      setLoading(false);
      return null;
    }
    return null;
  }

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
        if (data['academicData'] == null ||
            data['academicData']['subjects'] == null) {
          print("Error: academicData or subjects is null");
          return null;
        }
        ReportCardModel model = ReportCardModel.fromJson(data);
        subjectListName = data['academicData']['subjects'].keys.toList();
        extractLatestMarks(data);
        ReportCardModel academicData =
            ReportCardModel.fromJson(data['academicData']);
        setLoading(false);
        print("Response: $data");
        return academicData;
      } else {
        print("Failed with status code: ${response.statusCode}");
        print("Error: ${response.body}");
        setLoading(false);
        throw Exception("Failed to load data");
      }
    } catch (error) {
      print("Get Reporr Card Request failed: $error");
      setLoading(false);
      throw Exception("Failed to load data");
    }
  }

  Future<Map<String, String>?> uploadExamScript(
    String examName,
    String date,
    String curriculumId,
    String curriculumName,
    String curriculumCoverage,
    String subject,
    String observation,
    String studentId,
    html.File file,
    String language,
    String teacherId, // Ensure this is passed correctly
  ) async {
    setLoading(true);
    try {
      final url = Uri.parse(Config.baseURL + ApiEndPoint.examScriptUpload);
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll({"Content-type": "multipart/form-data"});
      print("URL:  $url");
      request.fields['exam_name'] = examName;
      request.fields['curriculumId'] = curriculumId.toString();
      request.fields['curriculumName'] = curriculumName.toString();
      request.fields['curriculum_coverage[]'] = curriculumCoverage;
      request.fields['subject'] = subject.toString();
      request.fields['date'] = date;
      request.fields['observation'] = observation;
      request.fields['studentId'] = studentId;
      request.fields['language'] = language;
      request.fields['teacherId'] = teacherId;

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
      print("REQUEST : $res");
      if (response.statusCode == 200) {
        setLoading(false);
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print("Exam script Response : $responseData");
        return {
          "extractText": responseData["extractText"] ?? "",
          "evaluationReport": responseData["evaluationReport"] ?? "",
        };
      } else {
        setApiError('Something went wrong');
        print("Response code: ${response.statusCode} ${response.body}");
        setLoading(false);
      }
    } catch (error) {
      print("Exam Script Error");
      print("Request failed: $error");
      setLoading(false);
    }
    return null;
  }

  Future<String?> pdfEvaluateApi(String text) async {
    setLoading(true);
    final url = Uri.parse(Config.baseURL + ApiEndPoint.pdfEvaluate);
    final jsonBody = {"text": text};
    try {
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(jsonBody));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('PDF Evaluate Successfully : $responseData');
        setLoading(false);
        return responseData['evaluation'];
      } else {
        print('Failed API : ${response.body}');
        setLoading(false);
        return null;
      }
    } catch (e) {
      print('Error: $e');
    }
    return null;
  }

  Future<int?> getGradeGraphwithFilter(
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

  List<String> recentsAlertsList = [
    "Brief description with timestamp.",
    "Brief description with timestamp.",
    "Brief description with timestamp.",
    "Brief description with timestamp.",
    "Brief description with timestamp.",
  ];

  List<String> upComingAletsList = [
    "List of pending tasks or actions to be taken.",
    "List of pending tasks or actions to be taken.",
    "List of pending tasks or actions to be taken.",
    "List of pending tasks or actions to be taken.",
    "List of pending tasks or actions to be taken.",
    "List of pending tasks or actions to be taken.",
  ];

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

  Future<int?> analyzeStudentData(String studId, String lang) async {
    try {
      setLoading(true);
      final url = Uri.parse(
          "${Config.baseURL}get_student_analysis?student_id=$studId&lang=$lang");
      print("Student Analyze URL : $url");
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Student Analyze created');
        analysisData = responseData;
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

  Future<int?> fetchTeachingPlanForStudent(
      String teacherId, String studentId) async {
    try {
      setLoading(true);
      String url =
          "https://pees.ddnsking.com/teaching-plans1?teacher_id=$teacherId&student_id=$studentId&lang=$selectedLanguage";

      print("URL: $url");
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        teachingPlansList = data['data'];
        print(
            "Fetch Teaching Pan For Student : ${response.statusCode} - Response : ${data}");
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

  int selectedMobileIndex = 0; // Default selected index

  void updateSelectedIndex(int index) {
    selectedMobileIndex = index;
    notifyListeners();
  }

  List<TeacherDrawerModel> teacherDrawerList = [
    TeacherDrawerModel('dashboard', TeacherDrawerType.dashboard,
        AppImage.dashboardFill, AppImage.dashboardWhite),
    TeacherDrawerModel('students', TeacherDrawerType.students,
        AppImage.studentsFill, AppImage.studentsWhite),
    TeacherDrawerModel('teachingPlan', TeacherDrawerType.teachingPlan,
        AppImage.teachingFill, AppImage.teachingWhite),
    TeacherDrawerModel('observationHeading', TeacherDrawerType.observation,
        AppImage.obsFill, AppImage.obsWhite),
    TeacherDrawerModel('reportTitle', TeacherDrawerType.reports,
        AppImage.progressFill, AppImage.progressWhite),
    TeacherDrawerModel('settings', TeacherDrawerType.settings,
        AppImage.settingsFill, AppImage.settingsWhite)
  ];

  Future<int?> feedBackPlan(String teacherId, String planId,
      String feedbackMessage, String studentId) async {
    setLoading(true);
    // replace with actual API URL

    try {
      String url = '${Config.baseURL}api/teaching-plans/feedback';
      print("Feedback URL : $url");
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "teacherid": teacherId,
          "planid": planId,
          "feedback": feedbackMessage,
          "studentid": studentId
        }),
      );
      print("Response RequestBody : ${response.body}");
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Feedback added successfully: ${responseData['message']}');
        setLoading(false);
        return response.statusCode;
      } else {
        // print('Failed to add subject: ${response.body}');
        setLoading(false);
        return response.statusCode;
      }
    } catch (e) {
      setLoading(false);
      print('Error: $e');
    }
    return null;
  }

  Future<int?> fetchFeedbacks(String teacherId, String planId) async {
    final url = Uri.parse(
        "${Config.baseURL}api/teaching-plans/feedback?teacherid=$teacherId&planid=$planId");
    setLoading(true);
    try {
      print("Feedback List API : $url");
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        feedbackList = data["feedback"];
        print("Feedback List Response : $data");
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

  Future<int?> fetchClassDetails(String teacherId) async {
    final url = Uri.parse(
        "${Config.baseURL}api/grade-student-count1?teacherid=$teacherId");
    setLoading(true);
    try {
      print("Class Details List API : $url");
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        classGradeList = data.map((json) => ClassModel.fromJson(json)).toList();

        print("Class Details List Response : $data");
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

  List<Map<String, dynamic>> upcomingActions = [];
  Future<int?> fetchUpcomingActions(String teacherId, String lang) async {
    final url = Uri.parse(
        "${Config.baseURL}api/upcoming-actions?teacherId=$teacherId&lang=$lang");
    setLoading(true);
    try {
      print("Upcoming Action API : $url");
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        // classGradeList = data.map((json) => ClassModel.fromJson(json)).toList();
        final data = json.decode(response.body);
        final List<dynamic> actions = data["upcoming_actions"];

        upcomingActions = actions.map((action) {
          return {
            "name": action["name"].toString(),
            "details": action["actions"],
          };
        }).toList();

        print("Upcoming Actions Response : $data");
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

  Future<int?> sendEvaluateFeedback(
    String exmName,
    String curriculumCoverage,
    String date,
    String observation,
    String studentId,
    String curriculumId,
    String curriculumName,
    String subject,
    String lang,
    String teacherId,
    String feedbackMessage,
    String status,
    html.File? file,
  ) async {
    setLoading(true);
    try {
      String url = '${Config.baseURL}submit_feedback';
      print("Feedback URL : $url");

      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add form fields
      request.fields['exam_name'] = exmName;
      request.fields['curriculum_coverage'] = curriculumCoverage;
      request.fields['date'] = date;
      request.fields['observation'] = observation;
      request.fields['studentId'] = studentId;
      request.fields['curriculumId'] = curriculumId;
      request.fields['curriculumName'] = curriculumName;
      request.fields['subject'] = subject;
      request.fields['language'] = lang;
      request.fields['teacherId'] = teacherId;
      request.fields['feedback'] = feedbackMessage;
      request.fields['status'] = status;

      // Handle file upload (optional)
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file!);
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
      print("Response 1 : $response");
      print("REQUEST : $res");
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Feedback sent successfully: ${responseData['message']}');
        setLoading(false);
        return response.statusCode;
      } else {
        print('Failed to send feedback: ${response.body}');
        setLoading(false);
        return response.statusCode;
      }
    } catch (e) {
      setLoading(false);
      print('Error: $e');
    }
    return null;
  }

  List<String> improvementAreas = [];
  Future<int?> fetchImprovement(String studId) async {
    setLoading(true);
    final url = Uri.parse(
        "${Config.baseURL}student/area_need_improvement?studentId=$studId&lang=$selectedLanguage");
    try {
      print("Imrovement URL : $url");
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final String responseBody = response.body;
        print("API Response: $responseBody");
        final Map<String, dynamic> data = json.decode(responseBody);
        if (data.containsKey('areas_for_improvement')) {
          var improvementData = data['areas_for_improvement'];
          if (improvementData is List) {
            improvementAreas = List<String>.from(improvementData);
          } else {
            print("Unexpected data format: Expected a list.");
          }
        }
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
    return null;
  }

  Future<int?> deleteEvaluation(String studId, String evaluatedId) async {
    setLoading(true);
    final url = Uri.parse(
        "https://pees.ddnsking.com/delete_exam_history?student_id=$studId&evaluation_id=$evaluatedId");
    try {
      print("Delete Evaluation URL : $url");
      final response = await http.delete(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Delete success: ${data['message']}");
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

  List<SubjectEntry> fullDataTableEntries = [];
  List<SubjectPercentage> subjectPercentages = [];
  Map<String, dynamic> dataTable = {};
  List<LineGraphModel> subjectNewData = [];
  Future<int?> fetchProgressData(
      String studentID, String? fromDate, String? toDate) async {
    final url = Uri.parse(
        'https://pees.ddnsking.com/api/student/progress/$studentID?startDate=$fromDate&endDate=$toDate');
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
}

class SubjectEntry {
  final String subject;
  final int marks;
  final int totalMarks;
  final String timestamp;

  SubjectEntry({
    required this.subject,
    required this.marks,
    required this.totalMarks,
    required this.timestamp,
  });
}

enum TeacherDrawerType {
  dashboard,
  students,
  teachingPlan,
  observation,
  reports,
  settings
}

class TeacherDrawerModel {
  String title;
  TeacherDrawerType type;
  String fillImage;
  String whiteImage;
  TeacherDrawerModel(this.title, this.type, this.fillImage, this.whiteImage);
}

class ClassModel {
  String? gradeName;
  int? studentCount;

  ClassModel({this.gradeName, this.studentCount});

  ClassModel.fromJson(Map<String, dynamic> json) {
    gradeName = json['grade_name'];
    studentCount = json['student_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['grade_name'] = this.gradeName;
    data['student_count'] = this.studentCount;
    return data;
  }
}

// class LineGraphModel {
//   final String subject;
//   final double percentage;
//   final String date;
//   final String month;

//   LineGraphModel({
//     required this.subject,
//     required this.percentage,
//     required this.date,
//   }) : month = _extractMonthName(date);

//   static String _extractMonthName(String dateString) {
//     try {
//       final date = DateTime.parse(dateString);
//       return _monthName(date.month);
//     } catch (_) {
//       return '';
//     }
//   }

//   static String _monthName(int month) {
//     const months = [
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'May',
//       'Jun',
//       'Jul',
//       'Aug',
//       'Sep',
//       'Oct',
//       'Nov',
//       'Dec'
//     ];
//     return months[month - 1];
//   }
// }

class LineGraphModel {
  final String subject;
  final double percentage;
  final String date;
  final String month;
  final DateTime dateTime;

  LineGraphModel({
    required this.subject,
    required this.percentage,
    required this.date,
  })  : dateTime = DateTime.parse(date),
        month = _extractMonthName(date);

  static String _extractMonthName(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return _monthName(date.month);
    } catch (_) {
      return '';
    }
  }

  static String _monthName(int monthNumber) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[monthNumber];
  }
}
