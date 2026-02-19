import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pees/API_SERVICES/config.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/HeadMaster_Dashboard/Services/headMaster_services.dart';
import 'package:pees/Widgets/AppButton.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/AppImage.dart';
import 'package:pees/Widgets/AppTextField.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/Widgets/utils.dart';
import 'package:provider/provider.dart';

class AddNewUserScreen extends StatefulWidget {
  const AddNewUserScreen({super.key});

  @override
  State<AddNewUserScreen> createState() => _AddNewUserScreenState();
}

class _AddNewUserScreenState extends State<AddNewUserScreen> {
  HeadMasterServices viewModel = HeadMasterServices();
  List<String> userRole = ["Teacher", "Student", "Parent"];
  String? roleName;
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController roleController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  List<AssignGradeModel> assignGrade = [];
  List<Map<String, dynamic>> passGrade = [];
  List<dynamic> allStudents = [];
  List<dynamic> filteredStudents = [];
  Set<String> selectedStudentIds = {};
  TextEditingController searchStudentController = TextEditingController();
  List<dynamic> allClasses = [];
  List<dynamic> allSubjects = [];
  void saveTempGradeSelection() {
    if (selectedGrade == null ||
        selectedClass == null ||
        selectedSubject == null) return;

    String gradeName = grades.firstWhere((g) => g["id"] == selectedGrade,
        orElse: () => {"name": ""})["name"];
    String className = classes.firstWhere((c) => c["id"] == selectedClass,
        orElse: () => {"name": ""})["name"];
    String subjectName = subjects.firstWhere((s) => s["id"] == selectedSubject,
        orElse: () => {"name": ""})["name"];

    if (gradeName.isEmpty || className.isEmpty || subjectName.isEmpty) return;

    // Check if this grade-class combo already exists
    int existingIndex = passGrade.indexWhere(
        (item) => item["grade"] == gradeName && item["class"] == className);

    if (existingIndex != -1) {
      // Add subject to existing grade/class if not already present
      List subjects = passGrade[existingIndex]["subject"];
      if (!subjects.contains(subjectName)) {
        subjects.add(subjectName);
      }
    } else {
      // Add new entry
      passGrade.add({
        "grade": gradeName,
        "class": className,
        "subject": [subjectName],
      });
    }
  }

  addUserAction(bool isMobile) async {
    String email = emailController.text;
    String name = nameController.text;
    String mobile = mobileController.text;
    String role = roleName.toString();
    String password = passwordController.text;

    if (name.isEmpty) {
      Utils.snackBar("nameEmpty".tr, context);
      return;
    }

    if (email.isEmpty) {
      Utils.snackBar("emailEmpty".tr, context);
      return;
    }

    if ((roleName == "Teacher" || roleName == "Parent")) {
      if (mobile.length < 8) {
        Utils.snackBar("length8greater".tr, context);
        return;
      } else if (mobile.length > 8) {
        Utils.snackBar("length8less".tr, context);
        return;
      }
    }

    if (role.isEmpty) {
      Utils.snackBar("roleEmpty".tr, context);
      return;
    }

    if (password.isEmpty) {
      Utils.snackBar("passwordEmpty".tr, context);
      return;
    }

    if (password.length < 8) {
      Utils.snackBar("Password must be at least 8 characters long.", context);
      return;
    }

    final hasUppercase = RegExp(r'[A-Z]');
    final hasDigits = RegExp(r'\d');
    final hasSpecialCharacters = RegExp(r'[!@#\$%^&*(),.?":{}|<>]');

    if (!hasUppercase.hasMatch(password)) {
      Utils.snackBar(
          "Password must contain at least one uppercase letter.", context);
      return;
    }

    if (!hasDigits.hasMatch(password)) {
      Utils.snackBar("Password must contain at least one number.", context);
      return;
    }

    if (!hasSpecialCharacters.hasMatch(password)) {
      Utils.snackBar(
          "Password must contain at least one special character.", context);
      return;
    }

    dynamic gradesPayload;

    if (roleName == "Student") {
      // ✅ Build Map<String, Map<String, List>> like:
      // { "Grade 4": { "Class A": [] } }

      String gradeName = grades.firstWhere((g) => g["id"] == selectedGrade,
              orElse: () => {"name": ""})["name"] ??
          "";
      String className = classes.firstWhere((c) => c["id"] == selectedClass,
              orElse: () => {"name": ""})["name"] ??
          "";

      if (gradeName.isEmpty || className.isEmpty) {
        Utils.snackBar("Please select grade and class for student.", context);
        return;
      }

      gradesPayload = {
        gradeName: {className: []}
      };
    } else if (roleName == "Teacher") {
      if (passGrade.isEmpty) {
        Utils.snackBar(
            "Please assign at least one grade/class/subject.", context);
        return;
      }

      gradesPayload = passGrade;
    }

    List<String> assignedStudents = selectedStudentIds.toList();

    int? code = await viewModel.addUserApicall(
      name,
      email,
      mobile,
      role.toLowerCase(),
      password,
      gradesPayload,
      associatedIds: roleName == "Parent" ? assignedStudents : null,
    );

    if (context.mounted) {
      if (code == 201) {
        setState(() {
          Navigator.pop(context, true);
          Utils.snackBar("userCreate".tr, context);
          nameController.clear();
          emailController.clear();
          mobileController.clear();
          roleName = null;
          passGrade.clear();
          selectedStudentIds.clear();
          selectedGrade = null;
          selectedClass = null;
          selectedSubject = null;
        });
      } else {
        Utils.snackBar("${viewModel.apiError}", context);
        print("API Fail: ${viewModel.apiError}");
      }
    }
  }

  // addUserAction(bool isMobile) async {
  //   String email = emailController.text;
  //   String name = nameController.text;
  //   String mobile = mobileController.text;
  //   String role = roleName.toString();
  //   String password = passwordController.text;
  //
  //   if (name.isEmpty) {
  //     Utils.snackBar("nameEmpty".tr, context);
  //     return;
  //   }
  //
  //   if (email.isEmpty) {
  //     Utils.snackBar("emailEmpty".tr, context);
  //     return;
  //   }
  //
  //   // ✅ Apply mobile validation ONLY if role is Teacher or Parent
  //   if ((roleName == "Teacher" || roleName == "Parent")) {
  //     if (mobile.length < 8) {
  //       Utils.snackBar("length8greater".tr, context);
  //       return;
  //     } else if (mobile.length > 8) {
  //       Utils.snackBar("length8less".tr, context);
  //       return;
  //     }
  //   }
  //
  //   if (role.isEmpty) {
  //     Utils.snackBar("roleEmpty".tr, context);
  //     return;
  //   }
  //
  //   if (password.isEmpty) {
  //     Utils.snackBar("passwordEmpty".tr, context);
  //     return;
  //   }
  //
  //   if (password.length < 8) {
  //     Utils.snackBar("Password must be at least 8 characters long.", context);
  //     return;
  //   }
  //
  //   final hasUppercase = RegExp(r'[A-Z]');
  //   final hasDigits = RegExp(r'\d');
  //   final hasSpecialCharacters = RegExp(r'[!@#\$%^&*(),.?":{}|<>]');
  //
  //   if (!hasUppercase.hasMatch(password)) {
  //     Utils.snackBar(
  //         "Password must contain at least one uppercase letter.", context);
  //     return;
  //   }
  //
  //   if (!hasDigits.hasMatch(password)) {
  //     Utils.snackBar("Password must contain at least one number.", context);
  //     return;
  //   }
  //
  //   if (!hasSpecialCharacters.hasMatch(password)) {
  //     Utils.snackBar(
  //         "Password must contain at least one special character.", context);
  //     return;
  //   }
  //
  //   // Proceed to form payload
  //   String className = classes.firstWhere((c) => c["id"] == selectedClass,
  //       orElse: () => {"name": "Unknown"})["name"];
  //   String subjectName = subjects.firstWhere((s) => s["id"] == selectedSubject,
  //       orElse: () => {"name": "Unknown"})["name"];
  //   String gradeName = grades.firstWhere((g) => g["id"] == selectedGrade,
  //       orElse: () => {"name": "Unknown"})["name"];
  //   List<Map<String, dynamic>> gradesPayload = [];
  //
  //   if (roleName == "Student") {
  //     gradesPayload = [
  //       {
  //         "grade": grades.firstWhere(
  //               (g) => g["id"] == selectedGrade,
  //               orElse: () => {"name": ""},
  //             )["name"] ??
  //             "",
  //         "class": classes.firstWhere(
  //               (c) => c["id"] == selectedClass,
  //               orElse: () => {"name": ""},
  //             )["name"] ??
  //             "",
  //         "subject": [],
  //       }
  //     ];
  //   } else {
  //     for (var item in assignGrade) {
  //       final gradeName = grades.firstWhere((g) => g["id"] == item.grade,
  //               orElse: () => {"name": ""})["name"] ??
  //           "";
  //       final className = classes.firstWhere((c) => c["id"] == item.className,
  //               orElse: () => {"name": ""})["name"] ??
  //           "";
  //       final subjectName = subjects.firstWhere((s) => s["id"] == item.subject,
  //               orElse: () => {"name": ""})["name"] ??
  //           "";
  //
  //       gradesPayload.add({
  //         "grade": gradeName,
  //         "class": className,
  //         "subject": subjectName.isNotEmpty ? [subjectName] : [],
  //       });
  //     }
  //   }
  //
  //   passGrade = gradesPayload;
  //
  //   // if (roleName == "Student") {
  //   //   passGrade = {
  //   //     gradeName: {
  //   //       className: [] // No subjects for students
  //   //     }
  //   //   };
  //   // } else {
  //   //   passGrade = {
  //   //     gradeName: {
  //   //       className: [subjectName],
  //   //     },
  //   //   };
  //   // }
  //
  //   List<String> assignedStudents = selectedStudentIds.toList();
  //   int? code = await viewModel.addUserApicall(
  //     name,
  //     email,
  //     mobile,
  //     role.toLowerCase(),
  //     password,
  //     gradesPayload,
  //     associatedIds: roleName == "Parent" ? assignedStudents : null,
  //   );
  //
  //   if (context.mounted) {
  //     if (code == 201) {
  //       setState(() {
  //         Navigator.pop(context, true);
  //         Utils.snackBar("userCreate".tr, context);
  //         nameController.clear();
  //         emailController.clear();
  //         mobileController.clear();
  //         roleName = null;
  //       });
  //     } else {
  //       Utils.snackBar("${viewModel.apiError}", context);
  //       print("API Fail: ${viewModel.apiError}");
  //     }
  //   }
  // }

  List<dynamic> grades = [];
  List<dynamic> classes = [];
  List<dynamic> subjects = [];

  String? selectedGrade;
  String? selectedClass;
  String? selectedSubject;
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

        List<dynamic> fetchedClasses = [];
        Map<String, Map<String, String>> uniqueSubjects = {};

        for (var grade in data["grades"]) {
          for (var classItem in grade["classes"]) {
            fetchedClasses.add(
                {"id": classItem["class_id"], "name": classItem["class_name"]});

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

  Future<void> fetchStudentsList() async {
    try {
      final response = await http.get(
        Uri.parse("https://pees.ddnsking.com/students/list"),
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
    super.initState();
    fetchGradesOnly(); // Fetch all grades initially
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);

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
                        top: 30,
                        left: isMobile ? 12 : 100,
                        right: isMobile ? 12 : 30),
                    child: Column(
                      children: [
                        isMobile ? const BackButtonWidget() : const SizedBox(),
                        SizedBox(height: isMobile ? 5 : 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "addNewUser".tr,
                            style: NotoSansArabicCustomTextStyle.bold.copyWith(
                                fontSize: 18,
                                color: themeManager.isHighContrast
                                    ? AppColor.white
                                    : AppColor.buttonGreen),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: AppColor.white),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 15, right: 15, top: 15),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("name".tr,
                                        style: NotoSansArabicCustomTextStyle
                                            .medium
                                            .copyWith(
                                                color: AppColor.black,
                                                fontSize:
                                                    fontSizeProvider.fontSize)),
                                    const SizedBox(height: 5),
                                    SizedBox(
                                      height: 25,
                                      width: 250,
                                      child: AppFillTextField(
                                          textController: nameController,
                                          hintText: "username".tr,
                                          icon: null),
                                    ),
                                    const SizedBox(height: 10),
                                    Text("email".tr,
                                        style: NotoSansArabicCustomTextStyle
                                            .medium
                                            .copyWith(
                                                color: AppColor.black,
                                                fontSize:
                                                    fontSizeProvider.fontSize)),
                                    const SizedBox(height: 5),
                                    SizedBox(
                                        height: 25,
                                        width: 250,
                                        child: AppFillTextField(
                                            textController: emailController,
                                            hintText: "emailHint".tr,
                                            icon: null)),
                                    const SizedBox(height: 10),
                                    Text("roleAssignment".tr,
                                        style: NotoSansArabicCustomTextStyle
                                            .medium
                                            .copyWith(
                                                color: AppColor.black,
                                                fontSize:
                                                    fontSizeProvider.fontSize)),
                                    const SizedBox(height: 5),
                                    SizedBox(
                                        height: 25,
                                        width: 250,
                                        child: roleSelect()),
                                    // if (roleName == "Teacher")
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 10),
                                        Text("passwordTitle".tr,
                                            style: NotoSansArabicCustomTextStyle
                                                .medium
                                                .copyWith(
                                                    color: AppColor.black,
                                                    fontSize: fontSizeProvider
                                                        .fontSize)),
                                        const SizedBox(height: 5),
                                        SizedBox(
                                          height: 25,
                                          width: 250,
                                          child: AppFillTextField(
                                              textController:
                                                  passwordController,
                                              hintText: "passwordTitle".tr,
                                              icon: null),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    if (roleName == "Teacher" ||
                                        roleName == "Parent")
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text("contactNumber".tr,
                                              style:
                                                  NotoSansArabicCustomTextStyle
                                                      .medium
                                                      .copyWith(
                                                          color: AppColor.black,
                                                          fontSize:
                                                              fontSizeProvider
                                                                  .fontSize)),
                                          const SizedBox(height: 5),
                                          SizedBox(
                                            height: 25,
                                            width: 250,
                                            child: AppFillTextField(
                                                textController:
                                                    mobileController,
                                                hintText: "phoneNumber".tr,
                                                // maxLength: 8,
                                                inputType: TextInputType.phone,
                                                icon: null),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 10),
                                    if (roleName == "Teacher" ||
                                        roleName == "Student")
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text("${"grade".tr} :",
                                              style:
                                                  NotoSansArabicCustomTextStyle
                                                      .medium
                                                      .copyWith(
                                                          color: AppColor.black,
                                                          fontSize:
                                                              fontSizeProvider
                                                                  .fontSize)),
                                          const SizedBox(height: 5),
                                          SizedBox(
                                              height: 25,
                                              width: 250,
                                              child: gradeSelect()),
                                          roleName == "Teacher"
                                              ? Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const SizedBox(height: 10),
                                                    Text("${"subject".tr} :",
                                                        style: NotoSansArabicCustomTextStyle
                                                            .medium
                                                            .copyWith(
                                                                color: AppColor
                                                                    .black,
                                                                fontSize:
                                                                    fontSizeProvider
                                                                        .fontSize)),
                                                    const SizedBox(height: 5),
                                                    SizedBox(
                                                        height: 25,
                                                        width: 250,
                                                        child: selectSubject()),
                                                  ],
                                                )
                                              : const SizedBox(),
                                          const SizedBox(height: 10),
                                          Text("${"Class".tr} :",
                                              style:
                                                  NotoSansArabicCustomTextStyle
                                                      .medium
                                                      .copyWith(
                                                          color: AppColor.black,
                                                          fontSize:
                                                              fontSizeProvider
                                                                  .fontSize)),
                                          const SizedBox(height: 5),
                                          SizedBox(
                                              height: 25,
                                              width: 250,
                                              child: classSelect()),
                                        ],
                                      ),
                                    const SizedBox(height: 10),
                                    if (roleName == "Parent")
                                      studentSelectionWidget(),
                                    const SizedBox(height: 10),
                                    // list show
                                    roleName == "Teacher"
                                        ? SizedBox(
                                            height: 150,
                                            child: ListView.builder(
                                                shrinkWrap: true,
                                                itemCount: assignGrade.length,
                                                itemBuilder: (context, index) {
                                                  String className =
                                                      allClasses.firstWhere(
                                                    (c) =>
                                                        c["id"] ==
                                                        assignGrade[index]
                                                            .className,
                                                    orElse: () => {"name": ""},
                                                  )["name"];

                                                  String subjectName =
                                                      allSubjects.firstWhere(
                                                    (s) =>
                                                        s["id"] ==
                                                        assignGrade[index]
                                                            .subject,
                                                    orElse: () => {"name": ""},
                                                  )["name"];

                                                  String gradeName =
                                                      grades.firstWhere(
                                                    (g) =>
                                                        g["id"] ==
                                                        assignGrade[index]
                                                            .grade,
                                                    orElse: () => {"name": ""},
                                                  )["name"];

                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 8),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                          color: themeManager
                                                                  .isHighContrast
                                                              ? AppColor.labelText
                                                              : AppColor.white,
                                                          borderRadius: BorderRadius.circular(7),
                                                          boxShadow: const [
                                                            BoxShadow(
                                                                blurRadius: 5,
                                                                offset: Offset(
                                                                    0, 5),
                                                                color: AppColor
                                                                    .greyShadow)
                                                          ]),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                                "${"grade".tr} : $gradeName"),
                                                            const SizedBox(
                                                                height: 5),
                                                            Text(
                                                                "${"class".tr} : $className"),
                                                            const SizedBox(
                                                                height: 5),
                                                            Text(
                                                                "${"subject".tr} : $subjectName"),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }),
                                          )
                                        : const SizedBox(),
                                    SizedBox(height: 10)
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                    padding: const EdgeInsets.only(
                                        right: 30, top: 10),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        width: 100,
                                        height: 40,
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                width: 2,
                                                color: AppColor.buttonGreen),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            color: AppColor.white),
                                        child: Center(
                                            child: Text(
                                          "cancel".tr,
                                          style: PoppinsCustomTextStyle.semibold
                                              .copyWith(
                                                  color: AppColor.buttonGreen,
                                                  fontSize: fontSizeProvider
                                                      .fontSize),
                                        )),
                                      ),
                                    ))),
                            Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(right: 30, top: 10),
                                  child: AppFillButton2(
                                      onPressed: () {
                                        if (roleName == null ||
                                            roleName == "null") {
                                          Utils.snackBar(
                                              "roleEmpty".tr, context);
                                        } else {
                                          addUserAction(false);
                                        }
                                      },
                                      text: "save"),
                                ))
                          ],
                        ),
                      ],
                    ),
                  ),
                  value.loading ? LoaderView() : Container()
                ],
              ),
            );
          });
        }));
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
            if (roleName == "Parent") {
              fetchStudentsList();
            }
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

  Widget classSelect() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    bool isEnabled =
        roleName == "Student" ? selectedGrade != null : selectedSubject != null;

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
                saveTempGradeSelection();
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
            value: selectedSubject,
            underline: const SizedBox.shrink(),
            onChanged: (newValue) {
              setState(() {
                selectedSubject = newValue;
                saveTempGradeSelection();
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

class AssignGradeModel {
  String? className;
  String? grade;
  String? subject;

  AssignGradeModel({this.className, this.grade, this.subject});
}

// Row(
//   children: [
//     const SizedBox(width: 20),
//     Checkbox(
//         value: isCheck,
//         onChanged: (value) {
//           setState(() {
//             isCheck = !isCheck;
//           });
//         },
//         activeColor: AppColor.darkGreen,
//         checkColor: AppColor.white,
//         side: const BorderSide(
//             color: AppColor.textGrey, width: 1)),
//     const SizedBox(width: 10),
//     Text(
//       "checkboxtext".tr,
//       style: NotoSansArabicCustomTextStyle.medium.copyWith(
//           fontSize: fontSizeProvider.fontSize,
//           color: AppColor.black),
//     ),
//   ],
// ),
