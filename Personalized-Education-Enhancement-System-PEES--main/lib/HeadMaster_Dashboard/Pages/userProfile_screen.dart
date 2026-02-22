import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pees/API_SERVICES/config.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/HeadMaster_Dashboard/Model/UserManageModel.dart';
import 'package:pees/HeadMaster_Dashboard/Pages/addNewUser_screen.dart';
import 'package:pees/HeadMaster_Dashboard/Services/headMaster_services.dart';
import 'package:pees/Parent_Dashboard/Services/parent_services.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/AppImage.dart';
import 'package:pees/Widgets/AppTextField.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/Widgets/utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Model/headMaster_model.dart';

class UserProfileScreen extends StatefulWidget {
  final UserManageModel model;
  UserProfileScreen({required this.model, super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  HeadMasterServices viewModel = HeadMasterServices();
  ParentService parentViewModel = ParentService();
  String selectedLanguage = Get.locale?.languageCode ?? 'en';
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailAddressController = TextEditingController();
  TextEditingController userIdController = TextEditingController();
  TextEditingController profileRoleController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  List<AssignGradeModel> assignGrade = [];
  List<Map<String, dynamic>> passGrade = [];
  Map<String, Map<String, List<String>>> studentGradeMap = {};
  List<Map<String, dynamic>> tempGrades = []; // contains full data to send

  List<dynamic> filteredStudents = [];
  Set<String> selectedStudentIds = {};
  TextEditingController searchStudentController = TextEditingController();
  List<dynamic> grades = [];
  List<dynamic> classes = [];
  List<dynamic> subjects = [];
  Set<String> selectedAssignedStudentIds = {};
  List<dynamic> allClasses = [];
  List<dynamic> allSubjects = [];
  String? selectedGrade;
  String? selectedClass;
  String? selectedSubject;
  List<dynamic> allStudents = [];
  List<String> userRole = ["Teacher", "Student", "Parent"];
  String? roleName;
  updateAction() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // String? userId = prefs.getString('userId');
    String? jwtToken = prefs.getString('jwtToken');
    String role = profileRoleController.text;
    String name = firstNameController.text;
    String? address = addressController.text;
    String? phone = phoneController.text;
    String? email = emailAddressController.text;
    if (name.isEmpty) {
      Utils.snackBar("nameEmpty".tr, context);
    } else {
      String className = classes.firstWhere((c) => c["id"] == selectedClass,
          orElse: () => {"name": "Unknown"})["name"];
      String subjectName = subjects.firstWhere(
          (s) => s["id"] == selectedSubject,
          orElse: () => {"name": "Unknown"})["name"];
      String gradeName = grades.firstWhere((g) => g["id"] == selectedGrade,
          orElse: () => {"name": "Unknown"})["name"];

      dynamic gradesPayload;

      if (roleName == "Student") {
        gradesPayload = studentGradeMap; // ⬅ student structure
      } else {
        gradesPayload = tempGrades; // ⬅ teacher structure
      }
      // if (widget.model.role == "student") {
      //   passGrade = {
      //     gradeName: {
      //       className: [] // No subjects for students
      //     }
      //   };
      //   print("Student : ${gradeName} ${className}");
      // } else {
      //   passGrade = {
      //     gradeName: {
      //       className: [subjectName],
      //     },
      //   };
      //   print("Teacher : ${gradeName} ${className} ${subjectName}");
      // }
      ApiResponse response = await viewModel.updateUser(
        email,
        name,
        phone,
        widget.model.role.toString(),
        gradesPayload,
        widget.model.userID ?? "",
        jwtToken ?? "",
        associatedStudentIds:
            widget.model.role == "parent" && selectedStudentIds != null
                ? selectedStudentIds.toList()
                : null,
      );

      if (context.mounted) {
        if (response.statusCode == 200) {
          Navigator.pop(context, true);
          Utils.snackBar("successUserUpdated".tr, context);
        } else {
          Utils.snackBar(response.message ?? "Something went wrong", context);
        }
      }
    }
  }

  void handleGradeSubjectClassSelection() {
    if (selectedGrade == null ||
        selectedClass == null ||
        selectedSubject == null) return;

    String gradeName = grades.firstWhere((g) => g["id"] == selectedGrade,
        orElse: () => {"name": ""})["name"];
    String className = classes.firstWhere((c) => c["id"] == selectedClass,
        orElse: () => {"name": ""})["name"];
    String subjectName = subjects.firstWhere((s) => s["id"] == selectedSubject,
        orElse: () => {"name": ""})["name"];

    // Update tempGrades (used for saving)
    int index = tempGrades.indexWhere(
        (entry) => entry["grade"] == gradeName && entry["class"] == className);

    if (index != -1) {
      List<String> existingSubjects =
          List<String>.from(tempGrades[index]["subject"]);
      if (!existingSubjects.contains(subjectName)) {
        existingSubjects.add(subjectName);
        tempGrades[index]["subject"] = existingSubjects;
      }
    } else {
      tempGrades.add({
        "grade": gradeName,
        "class": className,
        "subject": [subjectName],
      });
    }

    // ✅ Also update assignGrade (used for view)
    assignGrade.add(AssignGradeModel(
      grade: selectedGrade ?? "",
      className: selectedClass ?? "",
      subject: selectedSubject ?? "",
    ));

    setState(() {});
  }

  deactiveUserAction() async {
    int? code = await viewModel.deactivateUser(widget.model.userID ?? "");
    if (context.mounted) {
      if (code == 200) {
        setState(() {
          widget.model.status?.toLowerCase() ==
              "inactive"; // ✅ update local model
        });
        Utils.snackBar("User successfully deactivated", context);
        Navigator.pop(context, true);
      } else {
        Utils.snackBar("${viewModel.apiError}", context);
        print("${viewModel.apiError}");
      }
    }
  }

  activeUserAction() async {
    int? code = await viewModel.activateUserAPI(widget.model.userID ?? "");
    if (context.mounted) {
      if (code == 200) {
        setState(() {
          widget.model.status?.toLowerCase() ==
              "active"; // ✅ update local model
        });
        Utils.snackBar("User successfully activated", context);
        Navigator.pop(context, true);
      } else {
        Utils.snackBar("${viewModel.apiError}", context);
        print("${viewModel.apiError}");
      }
    }
  }

  fetchParentChilds() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    List<Students>? code =
        await parentViewModel.fetchChildernDetails(widget.model.userID ?? "");
    setState(() {}); // Ensure UI rebuilds
    if (code.isNotEmpty) {
      print("Successfully fetch child information list");
    } else {
      print("Fetch child Error : ${viewModel.apiError}");
    }
  }

  Future<void> fetchGradesOnly() async {
    try {
      String url = "${Config.baseURL}api/grades-classes-subjects";
      viewModel.setLoading(true);

      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic> fetchedGrades = [];

        for (var grade in data["grades"]) {
          fetchedGrades.add({"id": grade["grade_id"], "name": grade["grade"]});
        }

        setState(() {
          grades = fetchedGrades;
        });
      } else {
        print("Failed to fetch grades: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching grades: $e");
    } finally {
      viewModel.setLoading(false);
    }
  }

  Future<void> fetchGradeWiseClassesAndSubjects(String gradeId) async {
    try {
      String url =
          "${Config.baseURL}api/grades-classes-subjects?grade_id=$gradeId";
      viewModel.setLoading(true);
      print("Fetching data for grade: $gradeId");

      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API Response: ${jsonEncode(data)}");
        List<dynamic> fetchedClasses = [];
        Map<String, Map<String, String>> uniqueSubjects = {};

        for (var grade in data["grades"]) {
          for (var classItem in grade["classes"]) {
            fetchedClasses.add(
                {"id": classItem["class_id"], "name": classItem["class_name"]});
            print("Classes fetched: ${classes.map((c) => c['name'])}");

            for (var subject in classItem["subjects"]) {
              uniqueSubjects[subject["subject_id"]] = {
                "id": subject["subject_id"],
                "name": subject["subject_name"]
              };
            }
          }
        }

        setState(() {
          classes = fetchedClasses;
          subjects = uniqueSubjects.values.toList();
          if (subjects.isNotEmpty) {
            selectedSubject = subjects.first["id"]?.toString();
          } else {
            selectedSubject = null;
          }

          // Merge into global list
          allClasses.addAll(fetchedClasses.where((newClass) =>
              !allClasses.any((existing) => existing["id"] == newClass["id"])));

          allSubjects.addAll(uniqueSubjects.values.where((newSubject) =>
              !allSubjects
                  .any((existing) => existing["id"] == newSubject["id"])));
        });
      } else {
        print("Failed to fetch data for grade: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching grade-wise data: $e");
    } finally {
      viewModel.setLoading(false);
    }
  }

  Future<void> deleteUser(String userId) async {
    viewModel.setLoading(true);
    final String baseUrl = '${Config.baseURL}';
    final Uri url = Uri.parse('${baseUrl}api/headmasters/deleteuser');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode == 200) {
      Utils.snackBar("User deleted successfully", context);
      Navigator.pop(context, true);
      viewModel.setLoading(false);
    } else {
      print('❌ Failed to delete user: ${response.statusCode}');
      print(response.body);
    }
  }

  Future<void> fetchStudentsList() async {
    try {
      final response = await http.get(
        Uri.parse("${Config.baseURL}students/list"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          allStudents = data;
          filteredStudents = List.from(allStudents);
        });
      } else {
        print("Failed to load students: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching students: $e");
    }
  }

  @override
  void initState() {
    fetchGradesOnly();
    fetchStudentsList();
    firstNameController.text = widget.model.name.toString() ?? "";
    profileRoleController.text = widget.model.role.toString() ?? "";
    emailAddressController.text = widget.model.email.toString() ?? "";
    userIdController.text = widget.model.userID.toString() ?? "";
    roleName = widget.model.role.toString(); // set the role globally
    tempGrades = List<Map<String, dynamic>>.from(passGrade); // clone old data

    if (roleName == "Student") {
      // Convert backend format to studentGradeMap
      if (widget.model.assignedGrades != null) {
        widget.model.assignedGrades!.forEach((grade, classes) {
          Map<String, List<String>> classMap = {};
          classes.forEach((className, subjectList) {
            classMap[className] = List<String>.from(subjectList);
          });
          studentGradeMap[grade] = classMap;
        });
      }
    } else if (roleName == "Teacher") {
      // Convert assignedGrades to passGrade list format
      if (widget.model.assignedGrades != null) {
        widget.model.assignedGrades!.forEach((grade, classes) {
          classes.forEach((className, subjectList) {
            passGrade.add({
              "grade": grade,
              "class": className,
              "subject": List<String>.from(subjectList),
            });
          });
        });
      }
    }

    widget.model.role == "parent" ? fetchParentChilds() : null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print("dfggfd:${widget.model.userID ?? ""}");
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return ChangeNotifierProvider<HeadMasterServices>(
        create: (BuildContext context) => viewModel,
        child: Consumer<HeadMasterServices>(builder: (context, value, _) {
          return LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth <= 800;
            return Scaffold(
              body: Stack(
                children: [
                  isMobile ? const SizedBox() : const BackButtonWidget(),
                  Padding(
                    padding: EdgeInsets.only(
                        left: isMobile ? 12 : 100,
                        right: isMobile ? 12 : 30,
                        top: 30),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          isMobile
                              ? const BackButtonWidget()
                              : const SizedBox(),
                          isMobile
                              ? const SizedBox(height: 10)
                              : const SizedBox(),
                          Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                                color: AppColor.buttonGreen,
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(5),
                                    topRight: Radius.circular(5))),
                            child: Padding(
                              padding: EdgeInsets.only(
                                  top: 15,
                                  bottom: 15,
                                  left: selectedLanguage == 'en' ? 20 : 0,
                                  right: selectedLanguage == 'en' ? 0 : 20),
                              child: Align(
                                alignment: selectedLanguage == 'en'
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                child: Text(
                                  "${widget.model.name}",
                                  style: PoppinsCustomTextStyle.bold.copyWith(
                                      fontSize: fontSizeProvider.fontSize + 1,
                                      color: AppColor.white),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            // height: 570,
                            decoration: BoxDecoration(
                                color: themeManager.isHighContrast
                                    ? AppColor.labelText
                                    : AppColor.white,
                                boxShadow: const [
                                  BoxShadow(
                                      color: AppColor.greyShadow,
                                      blurRadius: 15,
                                      offset: Offset(0, 10)),
                                ],
                                borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(5),
                                    bottomRight: Radius.circular(5))),
                            child: Padding(
                              padding: EdgeInsets.only(
                                  top: 20,
                                  bottom: 20,
                                  left: selectedLanguage == 'en'
                                      ? isMobile
                                          ? 7
                                          : 30
                                      : isMobile
                                          ? 7
                                          : 0,
                                  right: selectedLanguage == 'en'
                                      ? isMobile
                                          ? 7
                                          : 0
                                      : isMobile
                                          ? 7
                                          : 30),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  isMobile ? mobileFormview() : webFormView(),
                                  const SizedBox(height: 5),
                                  widget.model.role == "parent"
                                      ? parentchildView(isMobile)
                                      : SizedBox(
                                          height: 200,
                                          child: assignGradeListview()),
                                  const SizedBox(height: 15),
                                  isMobile
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    widget.model.status
                                                                ?.toLowerCase() ==
                                                            "active"
                                                        ? deactiveUserAction()
                                                        : activeUserAction();
                                                  },
                                                  child: Container(
                                                    width: 130,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: AppColor.white,
                                                      border: Border.all(
                                                          width: 1.5,
                                                          color: Colors.red),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        widget.model.status
                                                                    ?.toLowerCase() ==
                                                                "active"
                                                            ? "deactiveUser".tr
                                                            : "Active User",
                                                        style: PoppinsCustomTextStyle
                                                            .medium
                                                            .copyWith(
                                                                fontSize:
                                                                    fontSizeProvider
                                                                        .fontSize,
                                                                color:
                                                                    Colors.red),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    deleteUser(
                                                        widget.model.userID ??
                                                            "");
                                                  },
                                                  child: Container(
                                                    width: 170,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                        color: AppColor
                                                            .buttonGreen,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5),
                                                        boxShadow: const [
                                                          BoxShadow(
                                                            color: AppColor
                                                                .buttonShadow,
                                                            blurRadius: 5,
                                                            offset:
                                                                Offset(0, 5),
                                                          )
                                                        ]),
                                                    child: Center(
                                                      child: Text(
                                                        "deleteUser".tr,
                                                        style: PoppinsCustomTextStyle
                                                            .medium
                                                            .copyWith(
                                                                fontSize:
                                                                    fontSizeProvider
                                                                        .fontSize,
                                                                color: AppColor
                                                                    .white),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    Navigator.pop(
                                                        context, true);
                                                  },
                                                  child: Container(
                                                    width: 140,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: AppColor.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                      border: Border.all(
                                                          width: 1,
                                                          color: AppColor
                                                              .buttonGreen),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        "cancel".tr,
                                                        style: PoppinsCustomTextStyle
                                                            .medium
                                                            .copyWith(
                                                                fontSize:
                                                                    fontSizeProvider
                                                                        .fontSize,
                                                                color: AppColor
                                                                    .buttonGreen),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            //cancel
                                            const SizedBox(height: 10),
                                            //save changes
                                            InkWell(
                                              onTap: () {
                                                updateAction();
                                              },
                                              child: Container(
                                                width: 170,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                    color: AppColor.buttonGreen,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                    boxShadow: const [
                                                      BoxShadow(
                                                        color: AppColor
                                                            .buttonShadow,
                                                        blurRadius: 5,
                                                        offset: Offset(0, 5),
                                                      )
                                                    ]),
                                                child: Center(
                                                  child: Text(
                                                    "saveChanges".tr,
                                                    style: PoppinsCustomTextStyle
                                                        .medium
                                                        .copyWith(
                                                            fontSize:
                                                                fontSizeProvider
                                                                    .fontSize,
                                                            color:
                                                                AppColor.white),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Padding(
                                          padding: EdgeInsets.only(
                                              right: selectedLanguage == "en"
                                                  ? 25
                                                  : 0,
                                              left: selectedLanguage == "en"
                                                  ? 0
                                                  : 25),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  widget.model.status
                                                              ?.toLowerCase() ==
                                                          "active"
                                                      ? deactiveUserAction()
                                                      : activeUserAction();
                                                },
                                                child: Container(
                                                  width: 150,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: AppColor.white,
                                                    border: Border.all(
                                                        width: 1.5,
                                                        color: Colors.red),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      widget.model.status
                                                                  ?.toLowerCase() ==
                                                              "active"
                                                          ? "deactiveUser".tr
                                                          : "Active User",
                                                      style: PoppinsCustomTextStyle
                                                          .medium
                                                          .copyWith(
                                                              fontSize:
                                                                  fontSizeProvider
                                                                      .fontSize,
                                                              color:
                                                                  Colors.red),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  deleteUser(
                                                      widget.model.userID ??
                                                          "");
                                                },
                                                child: Container(
                                                  width: 170,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                      color:
                                                          AppColor.buttonGreen,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                      boxShadow: const [
                                                        BoxShadow(
                                                          color: AppColor
                                                              .buttonShadow,
                                                          blurRadius: 5,
                                                          offset: Offset(0, 5),
                                                        )
                                                      ]),
                                                  child: Center(
                                                    child: Text(
                                                      "deleteUser".tr,
                                                      style: PoppinsCustomTextStyle
                                                          .medium
                                                          .copyWith(
                                                              fontSize:
                                                                  fontSizeProvider
                                                                      .fontSize,
                                                              color: AppColor
                                                                  .white),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  Navigator.pop(context, true);
                                                },
                                                child: Container(
                                                  width: 170,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: AppColor.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                    border: Border.all(
                                                        width: 1,
                                                        color: AppColor
                                                            .buttonGreen),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      "cancel".tr,
                                                      style: PoppinsCustomTextStyle
                                                          .medium
                                                          .copyWith(
                                                              fontSize:
                                                                  fontSizeProvider
                                                                      .fontSize,
                                                              color: AppColor
                                                                  .buttonGreen),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  updateAction();
                                                },
                                                child: Container(
                                                  width: 170,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                      color:
                                                          AppColor.buttonGreen,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                      boxShadow: const [
                                                        BoxShadow(
                                                          color: AppColor
                                                              .buttonShadow,
                                                          blurRadius: 5,
                                                          offset: Offset(0, 5),
                                                        )
                                                      ]),
                                                  child: Center(
                                                    child: Text(
                                                      "saveChanges".tr,
                                                      style: PoppinsCustomTextStyle
                                                          .medium
                                                          .copyWith(
                                                              fontSize:
                                                                  fontSizeProvider
                                                                      .fontSize,
                                                              color: AppColor
                                                                  .white),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                  const SizedBox(height: 15),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  value.loading ? const LoaderView() : Container()
                ],
              ),
            );
          });
        }));
  }

  Widget assignGradeListview() {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    return widget.model.assignedGrades != null &&
            widget.model.assignedGrades!.isNotEmpty
        ? Padding(
            padding: EdgeInsets.only(
                right: selectedLanguage == "en" ? 20 : 0,
                left: selectedLanguage == "en" ? 0 : 20),
            child: ListView.builder(
              itemCount: widget.model.assignedGrades!.keys.length,
              itemBuilder: (context, index) {
                String grade =
                    widget.model.assignedGrades!.keys.elementAt(index);
                Map<String, dynamic> classes =
                    widget.model.assignedGrades![grade];

                return Card(
                  color: themeManager.isHighContrast
                      ? AppColor.grey
                      : AppColor.white,
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "${"grade".tr} : ",
                                  style: NotoSansArabicCustomTextStyle.bold
                                      .copyWith(
                                          fontSize: 16, color: AppColor.black),
                                ),
                                Text(
                                  grade,
                                  style: NotoSansArabicCustomTextStyle.regular
                                      .copyWith(
                                          fontSize: 15, color: AppColor.black),
                                ),
                              ],
                            ),
                            widget.model.role == "teacher"
                                ? IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      _confirmDeleteGrade(grade);
                                    },
                                  )
                                : const SizedBox
                                    .shrink(), // Hides the delete button for students
                          ],
                        ),
                        const SizedBox(height: 5),
                        ...classes.entries.map((classEntry) {
                          String className = classEntry.key;
                          List<dynamic> subjects = classEntry.value;
                          return Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${"className".tr} : $className",
                                  style: NotoSansArabicCustomTextStyle.regular
                                      .copyWith(
                                          fontSize: 14, color: AppColor.black),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "${"subjectTitle".tr} : ${subjects.join(', ')}",
                                  style: NotoSansArabicCustomTextStyle.regular
                                      .copyWith(
                                          fontSize: 14, color: AppColor.black),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        : const Center(child: Text("No assigned grades."));
  }

  void _confirmDeleteGrade(String gradeName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Grade"),
        content: Text("Are you sure you want to delete grade $gradeName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGrade(gradeName);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGrade(String gradeName) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? jwtToken = prefs.getString('jwtToken');
      String userId = widget.model.userID ?? "";

      if (jwtToken == null || jwtToken.isEmpty) {
        Utils.snackBar("User not authenticated", context);
        return;
      }

      // Construct your API URL
      final String url =
          "${Config.baseURL}api/headmaster/users/$userId/grade/$gradeName";

      // Send DELETE request
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        // ✅ Remove locally
        setState(() {
          widget.model.assignedGrades?.remove(gradeName);
        });

        Utils.snackBar("Grade '$gradeName' deleted successfully", context);
      } else {
        final Map<String, dynamic> body = jsonDecode(response.body);
        Utils.snackBar(body["error"] ?? "Failed to delete grade", context);
        print("Error deleting grade: ${response.body}");
      }
    } catch (e) {
      print("Exception deleting grade: $e");
      Utils.snackBar("Something went wrong", context);
    }
  }

  Future<void> _deleteAssociatedStudents(
      List<String> studentIds, String parentId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? jwtToken = prefs.getString('jwtToken');
      String? userId =
          prefs.getString('userId'); // parent userId from the screen

      if (jwtToken == null || jwtToken.isEmpty) {
        Utils.snackBar("User not authenticated", context);
        return;
      }

      if (userId == null || userId.isEmpty) {
        Utils.snackBar("User ID not found", context);
        return;
      }

      // ✅ Correct URL format — userId in the path
      final String url =
          "${Config.baseURL}api/headmaster/users/$userId/associatedStudents";

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          "student_ids": studentIds, // ✅ student list inside the body
          "parent_id": parentId,
        }),
      );

      if (response.statusCode == 200) {
        // ✅ Update local list
        setState(() {
          parentViewModel.studentsList.removeWhere(
            (student) => studentIds.contains(student.studentId),
          );
          selectedAssignedStudentIds.removeAll(studentIds);
        });

        Utils.snackBar("Selected students removed successfully", context);
      } else {
        final Map<String, dynamic> body = jsonDecode(response.body);
        Utils.snackBar(
          body["error"] ?? "Failed to delete associated students",
          context,
        );
        print("Error deleting associated students: ${response.body}");
      }
    } catch (e) {
      print("Exception deleting associated students: $e");
      Utils.snackBar("Something went wrong", context);
    }
  }

  void _confirmDeleteAssociatedStudents(
      List<String> studentIds, String parentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Students"),
        content: Text(
            "Are you sure you want to remove ${studentIds.length} selected student(s)?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAssociatedStudents(studentIds, parentId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget studentSelectionWidget() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text("Assign Student(s)",
            style: NotoSansArabicCustomTextStyle.bold.copyWith(
                fontSize: fontSizeProvider.fontSize, color: AppColor.black)),
        const SizedBox(height: 10),

        // Search Bar
        SizedBox(
          height: 30,
          width: 300,
          child: TextField(
            controller: searchStudentController,
            onChanged: (query) {
              setState(() {
                filteredStudents = allStudents
                    .where((student) =>
                        student['student_name']
                            .toString()
                            .toLowerCase()
                            .contains(query.toLowerCase()) ||
                        student['grade']
                            .toString()
                            .toLowerCase()
                            .contains(query.toLowerCase()) ||
                        student['classSection']
                            .toString()
                            .toLowerCase()
                            .contains(query.toLowerCase()))
                    .toList();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search by name, grade or class',
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: const BorderSide(color: AppColor.textGrey),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Student List
        SizedBox(
          height: 200,
          child: filteredStudents.isEmpty
              ? const Center(child: Text("No students found"))
              : ListView.builder(
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    final isSelected =
                        selectedStudentIds.contains(student['student_id']);

                    return CheckboxListTile(
                      value: isSelected,
                      activeColor: AppColor.darkGreen,
                      checkColor: AppColor.white,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected!) {
                            selectedStudentIds.add(student['student_id']);
                          } else {
                            selectedStudentIds.remove(student['student_id']);
                          }
                        });
                      },
                      title: Text(student['student_name'],
                          style: TextStyle(
                              fontSize: fontSizeProvider.fontSize,
                              color: AppColor.black)),
                      subtitle: Text(
                          "Grade: ${student['grade']} | Class: ${student['classSection']}",
                          style: const TextStyle(
                              fontSize: 12, color: AppColor.textGrey)),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget parentchildView(bool isMobile) {
    return Column(
      children: [
        // ✅ Add student selection widget as a card
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(7),
              boxShadow: const [
                BoxShadow(
                  color: AppColor.greyShadow,
                  offset: Offset(0, 5),
                  blurRadius: 15,
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child:
                  studentSelectionWidget(), // ✅ Your existing selection widget
            ),
          ),
        ),

        // ✅ Existing ListView
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: parentViewModel.studentsList.length,
          itemBuilder: (context, index) {
            final student = parentViewModel.studentsList[index];
            final isSelected =
                selectedAssignedStudentIds.contains(student.studentId ?? "");

            return Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 7),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColor.greyShadow,
                      offset: Offset(0, 5),
                      blurRadius: 15,
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // ✅ Checkbox for selecting assigned student
                      Checkbox(
                        value: isSelected,
                        activeColor: AppColor.darkGreen,
                        onChanged: (bool? selected) {
                          setState(() {
                            if (selected == true) {
                              selectedAssignedStudentIds
                                  .add(student.studentId ?? "");
                            } else {
                              selectedAssignedStudentIds
                                  .remove(student.studentId ?? "");
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(student.photoUrl ?? ""),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        student.name ?? "",
                        style: NotoSansArabicCustomTextStyle.bold
                            .copyWith(fontSize: 16, color: AppColor.black),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (selectedAssignedStudentIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10, right: 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () {
                  _confirmDeleteAssociatedStudents(
                    selectedAssignedStudentIds.toList(),
                    widget.model.userID ?? "",
                  );
                },
                icon: const Icon(Icons.delete),
                label: const Text("Remove Selected Students"),
              ),
            ),
          ),
      ],
    );
  }

  Widget webFormView() {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "nameTitle".tr,
              style: PoppinsCustomTextStyle.semibold.copyWith(
                  color: AppColor.black, fontSize: fontSizeProvider.fontSize),
            ),
            const SizedBox(width: 30),
            SizedBox(
              height: 35,
              width: 650,
              child: AppTextFieldBlank(
                  textController: firstNameController,
                  hintText: "fName".tr,
                  icon: null),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Text("emailTitle".tr,
                style: PoppinsCustomTextStyle.semibold.copyWith(
                    color: AppColor.black,
                    fontSize: fontSizeProvider.fontSize)),
            const SizedBox(width: 34),
            SizedBox(
              height: 35,
              width: 650,
              child: AppTextFieldBlank(
                  textController: emailAddressController,
                  readOnly: true,
                  hintText: "emailHintTitle".tr,
                  icon: null),
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (widget.model.role == "student")
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${"grade".tr} :",
                  style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                      color: AppColor.black,
                      fontSize: fontSizeProvider.fontSize)),
              const SizedBox(height: 5),
              SizedBox(height: 25, width: 250, child: gradeSelect()),
              const SizedBox(height: 10),
              Text("${"Class".tr} :",
                  style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                      color: AppColor.black,
                      fontSize: fontSizeProvider.fontSize)),
              const SizedBox(height: 5),
              SizedBox(height: 25, width: 250, child: classSelect2()),
            ],
          ),
        if (widget.model.role == "teacher")
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${"grade".tr} :",
                  style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                      color: AppColor.black,
                      fontSize: fontSizeProvider.fontSize)),
              const SizedBox(height: 5),
              SizedBox(height: 25, width: 250, child: gradeSelect()),
              const SizedBox(height: 10),
              Text("${"subject".tr} :",
                  style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                      color: AppColor.black,
                      fontSize: fontSizeProvider.fontSize)),
              const SizedBox(height: 5),
              SizedBox(height: 25, width: 250, child: selectSubject()),
              const SizedBox(height: 10),
              Text("${"Class".tr} :",
                  style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                      color: AppColor.black,
                      fontSize: fontSizeProvider.fontSize)),
              const SizedBox(height: 5),
              SizedBox(height: 25, width: 250, child: classSelect()),
              const SizedBox(height: 10),
              addButton(),
              const SizedBox(height: 10),
            ],
          ),
        const SizedBox(height: 10),
        // list show
        widget.model.role == "teacher"
            ? SizedBox(
                // height: 150,
                child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: assignGrade.length,
                    itemBuilder: (context, index) {
                      String className = allClasses.firstWhere(
                        (c) => c["id"] == assignGrade[index].className,
                        orElse: () => {"name": ""},
                      )["name"];

                      String subjectName = allSubjects.firstWhere(
                        (s) => s["id"] == assignGrade[index].subject,
                        orElse: () => {"name": ""},
                      )["name"];

                      String gradeName = grades.firstWhere(
                        (g) => g["id"] == assignGrade[index].grade,
                        orElse: () => {"name": ""},
                      )["name"];
                      return Padding(
                        padding:
                            const EdgeInsets.only(top: 8, right: 25, left: 5),
                        child: Container(
                          decoration: BoxDecoration(
                              color: themeManager.isHighContrast
                                  ? AppColor.labelText
                                  : AppColor.white,
                              borderRadius: BorderRadius.circular(7),
                              boxShadow: const [
                                BoxShadow(
                                    blurRadius: 5,
                                    offset: Offset(0, 5),
                                    color: AppColor.greyShadow)
                              ]),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${"grade".tr} : $gradeName"),
                                const SizedBox(height: 5),
                                Text("${"class".tr} : $className"),
                                const SizedBox(height: 5),
                                Text("${"subject".tr} : $subjectName"),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
              )
            : const SizedBox(),
        const SizedBox(height: 10)
      ],
    );
  }

  Widget mobileFormview() {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        "nameTitle".tr,
        style: PoppinsCustomTextStyle.semibold.copyWith(
            color: AppColor.black, fontSize: fontSizeProvider.fontSize),
      ),
      const SizedBox(height: 5),
      SizedBox(
        height: 35,
        width: 650,
        child: AppTextFieldBlank(
            textController: firstNameController,
            hintText: "fName".tr,
            icon: null),
      ),
      const SizedBox(height: 10),
      Text("emailTitle".tr,
          style: PoppinsCustomTextStyle.semibold.copyWith(
              color: AppColor.black, fontSize: fontSizeProvider.fontSize)),
      const SizedBox(height: 5),
      SizedBox(
        height: 35,
        width: 650,
        child: AppTextFieldBlank(
            textController: emailAddressController,
            readOnly: true,
            hintText: "emailHintTitle".tr,
            icon: null),
      ),
      const SizedBox(height: 10),
      if (widget.model.role == "student")
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${"grade".tr} :",
                style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                    color: AppColor.black,
                    fontSize: fontSizeProvider.fontSize)),
            const SizedBox(height: 5),
            SizedBox(height: 25, width: 250, child: gradeSelect()),
            const SizedBox(height: 10),
            Text("${"Class".tr} :",
                style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                    color: AppColor.black,
                    fontSize: fontSizeProvider.fontSize)),
            const SizedBox(height: 5),
            SizedBox(height: 25, width: 250, child: classSelect2()),
          ],
        ),
      if (widget.model.role == "teacher")
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${"grade".tr} :",
                style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                    color: AppColor.black,
                    fontSize: fontSizeProvider.fontSize)),
            const SizedBox(height: 5),
            SizedBox(height: 25, width: 250, child: gradeSelect()),
            const SizedBox(height: 10),
            Text("${"subject".tr} :",
                style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                    color: AppColor.black,
                    fontSize: fontSizeProvider.fontSize)),
            const SizedBox(height: 5),
            SizedBox(height: 25, width: 250, child: selectSubject()),
            const SizedBox(height: 10),
            Text("${"Class".tr} :",
                style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                    color: AppColor.black,
                    fontSize: fontSizeProvider.fontSize)),
            const SizedBox(height: 5),
            SizedBox(height: 25, width: 250, child: classSelect()),
            const SizedBox(height: 10),
            addButton(),
            const SizedBox(height: 10),
          ],
        ),
      const SizedBox(height: 10),
      widget.model.role == "teacher"
          ? SizedBox(
              height: 150,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: tempGrades.length,
                itemBuilder: (context, index) {
                  final gradeName = tempGrades[index]["grade"] ?? "Unknown";
                  final className = tempGrades[index]["class"] ?? "Unknown";
                  final subjects = tempGrades[index]["subject"] ?? [];

                  return Padding(
                    padding: const EdgeInsets.only(top: 8, right: 25, left: 5),
                    child: Container(
                      decoration: BoxDecoration(
                        color: themeManager.isHighContrast
                            ? AppColor.labelText
                            : AppColor.white,
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 5,
                            offset: Offset(0, 5),
                            color: AppColor.greyShadow,
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${"grade".tr} : $gradeName"),
                            const SizedBox(height: 5),
                            Text("${"class".tr} : $className"),
                            const SizedBox(height: 5),
                            Text("${"subject".tr} : ${subjects.join(', ')}"),
                            const SizedBox(height: 5),
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    tempGrades.removeAt(index);
                                  });
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ))
          : const SizedBox(),
      const SizedBox(height: 10)
    ]);
  }

  addButton() {
    return Container(
      decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(width: 0.3, color: AppColor.text),
          boxShadow: const [
            BoxShadow(
                blurRadius: 5, color: AppColor.greyShadow, offset: Offset(5, 5))
          ]),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: IconButton(
            onPressed: () {
              setState(() {
                handleGradeSubjectClassSelection();
              });
            },
            icon: const Icon(Icons.add, size: 25, color: AppColor.black)),
      ),
    );
  }

  Widget roleSelect() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return SizedBox(
      height: 25,
      width: 250,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            color: themeManager.isHighContrast
                ? AppColor.text
                : AppColor.textField,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(width: 1.0, color: AppColor.textGrey)),
        child: DropdownButton(
          dropdownColor:
              themeManager.isHighContrast ? AppColor.black : AppColor.white,
          hint: Padding(
            padding: const EdgeInsets.only(left: 15, top: 2),
            child: Text("userRole".tr,
                style: NotoSansArabicCustomTextStyle.medium.copyWith(
                    fontSize: 13,
                    color: themeManager.isHighContrast
                        ? AppColor.white
                        : AppColor.textGrey)),
          ),
          icon: Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Image.asset(AppImage.arrowDown,
                width: 16,
                color: themeManager.isHighContrast
                    ? AppColor.white
                    : AppColor.black),
          ),
          isExpanded: true,
          value: roleName,
          underline: SizedBox.fromSize(),
          onChanged: (value) {
            setState(() {
              roleName = value.toString();
            });
          },
          items: userRole.map((value) {
            return DropdownMenuItem(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, left: 10),
                  child: Text(
                    value,
                    style: NotoSansArabicCustomTextStyle.regular.copyWith(
                        color: themeManager.isHighContrast
                            ? AppColor.white
                            : AppColor.text,
                        fontSize: 13),
                  ),
                ));
          }).toList(),
        ),
      ),
    );
  }

  Widget classSelect() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    bool isEnabled = selectedSubject != null;

    return SizedBox(
      height: 25,
      width: 250,
      child: IgnorePointer(
        ignoring: !isEnabled,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: themeManager.isHighContrast
                ? AppColor.text
                : isEnabled
                    ? AppColor.textField
                    : AppColor.lightGrey.withOpacity(0.5),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
                width: 1.0,
                color: isEnabled ? AppColor.textGrey : AppColor.lightGrey),
          ),
          child: DropdownButton<String>(
            dropdownColor:
                themeManager.isHighContrast ? AppColor.black : AppColor.white,
            hint: Padding(
              padding: const EdgeInsets.only(left: 15, top: 2),
              child: Text("Class".tr,
                  style: NotoSansArabicCustomTextStyle.medium.copyWith(
                      fontSize: 13,
                      color: isEnabled
                          ? (themeManager.isHighContrast
                              ? AppColor.white
                              : AppColor.textGrey)
                          : AppColor.lightGrey)),
            ),
            icon: Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Image.asset(
                AppImage.arrowDown,
                width: 16,
                color: isEnabled
                    ? (themeManager.isHighContrast
                        ? AppColor.white
                        : AppColor.black)
                    : AppColor.lightGrey,
              ),
            ),
            isExpanded: true,
            value: selectedClass,
            underline: const SizedBox.shrink(),
            onChanged: (value) {
              setState(() {
                selectedClass = value;

                if (roleName == "Teacher") {
                  assignGrade.add(AssignGradeModel(
                    className: selectedClass,
                    grade: selectedGrade,
                    subject: selectedSubject,
                  ));
                }
              });
            },
            items: classes.map((classItem) {
              return DropdownMenuItem<String>(
                value: classItem["id"],
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, left: 10),
                  child: Text(
                    "${classItem["name"]}",
                    style: NotoSansArabicCustomTextStyle.regular.copyWith(
                        color: themeManager.isHighContrast
                            ? AppColor.white
                            : AppColor.text,
                        fontSize: 13),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget classSelect2() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    bool isEnabled = selectedGrade != null;

    return SizedBox(
      height: 25,
      width: 250,
      child: IgnorePointer(
        ignoring: !isEnabled,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: themeManager.isHighContrast
                ? AppColor.text
                : isEnabled
                    ? AppColor.textField
                    : AppColor.lightGrey.withOpacity(0.5),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
                width: 1.0,
                color: isEnabled ? AppColor.textGrey : AppColor.lightGrey),
          ),
          child: DropdownButton<String>(
            dropdownColor:
                themeManager.isHighContrast ? AppColor.black : AppColor.white,
            hint: Padding(
              padding: const EdgeInsets.only(left: 15, top: 2),
              child: Text("Class".tr,
                  style: NotoSansArabicCustomTextStyle.medium.copyWith(
                      fontSize: 13,
                      color: isEnabled
                          ? (themeManager.isHighContrast
                              ? AppColor.white
                              : AppColor.textGrey)
                          : AppColor.lightGrey)),
            ),
            icon: Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Image.asset(
                AppImage.arrowDown,
                width: 16,
                color: isEnabled
                    ? (themeManager.isHighContrast
                        ? AppColor.white
                        : AppColor.black)
                    : AppColor.lightGrey,
              ),
            ),
            isExpanded: true,
            value: selectedClass,
            underline: const SizedBox.shrink(),
            onChanged: (value) {
              setState(() {
                selectedClass = value;
                if (roleName == "Teacher") {
                  assignGrade.add(AssignGradeModel(
                    className: selectedClass,
                    grade: selectedGrade,
                    subject: selectedSubject,
                  ));
                }
              });
            },
            items: classes.map((classItem) {
              return DropdownMenuItem<String>(
                value: classItem["id"],
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, left: 10),
                  child: Text(
                    "${classItem["name"]}",
                    style: NotoSansArabicCustomTextStyle.regular.copyWith(
                        color: themeManager.isHighContrast
                            ? AppColor.white
                            : AppColor.text,
                        fontSize: 13),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget selectSubject() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    bool isEnabled = selectedGrade != null;

    return SizedBox(
      height: 25,
      width: 250,
      child: IgnorePointer(
        ignoring: !isEnabled,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: themeManager.isHighContrast
                ? AppColor.text
                : isEnabled
                    ? AppColor.textField
                    : AppColor.lightGrey.withOpacity(0.5),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
                width: 1.0,
                color: isEnabled ? AppColor.textGrey : AppColor.lightGrey),
          ),
          child: DropdownButton<String>(
            dropdownColor:
                themeManager.isHighContrast ? AppColor.black : AppColor.white,
            hint: Padding(
              padding: const EdgeInsets.only(left: 15, top: 2),
              child: Text("subject".tr,
                  style: NotoSansArabicCustomTextStyle.medium.copyWith(
                      fontSize: 13,
                      color: isEnabled
                          ? (themeManager.isHighContrast
                              ? AppColor.white
                              : AppColor.textGrey)
                          : AppColor.lightGrey)),
            ),
            icon: Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Image.asset(
                AppImage.arrowDown,
                width: 16,
                color: isEnabled
                    ? (themeManager.isHighContrast
                        ? AppColor.white
                        : AppColor.black)
                    : AppColor.lightGrey, // <-- make icon grey if disabled
              ),
            ),
            isExpanded: true,
            value: (selectedSubject != null &&
                    subjects.any((s) => s["id"] == selectedSubject))
                ? selectedSubject
                : (subjects.isNotEmpty ? subjects.first["id"]?.toString() : null),
            underline: const SizedBox.shrink(),
            onChanged: (newValue) {
              setState(() {
                selectedSubject = newValue;
              });
            },
            items: subjects.map((subject) {
              return DropdownMenuItem<String>(
                value: subject['id'],
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, left: 10),
                  child: Text(
                    "${subject['name']}",
                    style: NotoSansArabicCustomTextStyle.regular.copyWith(
                        color: themeManager.isHighContrast
                            ? AppColor.white
                            : AppColor.text,
                        fontSize: 13),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget gradeSelect() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return SizedBox(
      height: 25,
      width: 250,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            color: themeManager.isHighContrast
                ? AppColor.text
                : AppColor.textField,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(width: 1.0, color: AppColor.textGrey)),
        child: DropdownButton<String>(
          dropdownColor:
              themeManager.isHighContrast ? AppColor.black : AppColor.white,
          hint: Padding(
            padding: const EdgeInsets.only(left: 15, top: 2),
            child: Text("grade".tr,
                style: NotoSansArabicCustomTextStyle.medium.copyWith(
                    fontSize: 13,
                    color: themeManager.isHighContrast
                        ? AppColor.white
                        : AppColor.textGrey)),
          ),
          icon: Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Image.asset(AppImage.arrowDown,
                width: 16,
                color: themeManager.isHighContrast
                    ? AppColor.white
                    : AppColor.black),
          ),
          isExpanded: true,
          value: selectedGrade,
          underline: SizedBox.fromSize(),
          onChanged: (value) {
            setState(() {
              selectedGrade = value.toString();
              print("Selected Grade: $selectedGrade");
              selectedClass = null;
              selectedSubject = null;
              classes.clear();
              subjects.clear();
            });
            fetchGradeWiseClassesAndSubjects(value.toString());
          },
          items: grades.map((grade) {
            return DropdownMenuItem<String>(
                value: grade["id"],
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, left: 10),
                  child: Text(
                    "${grade["name"]}",
                    style: NotoSansArabicCustomTextStyle.regular.copyWith(
                        color: themeManager.isHighContrast
                            ? AppColor.white
                            : AppColor.text,
                        fontSize: 13),
                  ),
                ));
          }).toList(),
        ),
      ),
    );
  }
}
