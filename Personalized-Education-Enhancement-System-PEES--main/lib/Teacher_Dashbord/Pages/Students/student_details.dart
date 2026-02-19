// ignore_for_file: invalid_use_of_protected_member

import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
// import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:pees/API_SERVICES/config.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/HeadMaster_Dashboard/Model/report_model.dart';
import 'package:pees/HeadMaster_Dashboard/Model/studentModel.dart';
import 'package:pees/HeadMaster_Dashboard/Services/headMaster_services.dart';
import 'package:pees/Parent_Dashboard/Models/crriculumModel.dart';
import 'package:pees/Teacher_Dashbord/Pages/Students/pdf_ocr_show.dart';
import 'package:pees/Teacher_Dashbord/Pages/Students/show_history.dart';
import 'package:pees/Teacher_Dashbord/Services/teacher_service.dart';
import 'package:pees/Widgets/AppButton.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/AppImage.dart';
import 'package:pees/Widgets/AppTextField.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/Widgets/utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentDataScreen extends StatefulWidget {
  StudentModel? model;
  StudentDataScreen({this.model, super.key});

  @override
  State<StudentDataScreen> createState() => _StudentDataScreenState();
}

class _StudentDataScreenState extends State<StudentDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  TextEditingController dateController = TextEditingController();
  TextEditingController dynamicGradeController = TextEditingController();
  HeadMasterServices viewModel = HeadMasterServices();
  TeacherService teacherViewmodel = TeacherService();
  String selectedLanguage = Get.locale?.languageCode ?? 'en';
  TextEditingController markController = TextEditingController();
  TextEditingController gradeeController = TextEditingController();
  TextEditingController subjectTotalMarkController = TextEditingController();

  List<Curriculum> filteredCurriculumList = [];
  List<Curriculum> curriculumList = [];
  List<String> curriculumNames = [];
  List<String> subjects = [];
  // now
  List<Map<String, dynamic>> subjectsList = [];
  List<Map<String, dynamic>> allCurricula = [];
  List<Map<String, dynamic>> curricula = [];

  // String? selectedCurriculum;
  // String? selectedSubject;
  // String? selectedCurriculumId;

  // String? selectedCurriculumExam;
  // String? selectedSubjectExam;
  // String? selectedCurriculumIdExam;

  bool isSubjectSelcet = false;
  bool isSubjectSelectedExam = false;
  ReportCardModel? reportModel;
  DateTime? _selectedDate;
  TextEditingController subjectController = TextEditingController();
  TextEditingController coverageController = TextEditingController();
  TextEditingController totalMarksController = TextEditingController();
  TextEditingController obtainedMasrksController = TextEditingController();
  TextEditingController examNameController = TextEditingController();
  TextEditingController notesController = TextEditingController();
  bool isExamScript = false;
  html.File? file;
  String? gradeId;
  String? classId;
  String? pdfText;
  int? totalMarks;
  String? grade;
  bool showAll = false;
  int? obtainedMarks;
  String? activity;
  String? fileName;
  Uint8List? fileBytes;
  html.File? selectedFiles;
  List<Uint8List> selectedImages = [];
  List<String> selectedImageNames = [];

  _selectDate(BuildContext context) async {
    DateTime? newSelectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      // selectableDayPredicate: (DateTime value) =>
      //     value.isAfter(DateTime.now()) ? false : true,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColor.buttonGreen,
                onPrimary: Colors.white,
                surface: AppColor.lightYellow,
                onSurface: Colors.black,
              ),
              dialogBackgroundColor: Colors.white,
              textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                      foregroundColor: AppColor.white,
                      backgroundColor: AppColor.buttonGreen,
                      textStyle: const TextStyle(fontSize: 16)))),
          child: child!,
        );
      },
    );

    if (newSelectedDate != null) {
      setState(() {
        _selectedDate = newSelectedDate;
      });
      dateController
        ..text = DateFormat('dd-MM-yyyy').format(_selectedDate!)
        ..selection = TextSelection.fromPosition(TextPosition(
            offset: dateController.text.length,
            affinity: TextAffinity.upstream));
    }
  }

  List<Curriculum> filteredCurricula = [];
  List<String> filterSubject = [];
  List<Curriculum> filterCurriculm = [];
  String? fetchSelectSubject;
  Curriculum? selectedFetchCurriculum;
  String? fetchSelectCurriculumId;

  String? fetchSelectSubjectExam;
  Curriculum? selectedFetchCurriculumExam;
  String? fetchSelectCurriculumExamId;

  examScriptUpload(html.File selectFile) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String examName = examNameController.text;
    String date = _selectedDate.toString();
    String notes = notesController.text;
    String curriculumId = fetchSelectCurriculumExamId.toString();
    String? curriculumName =
        selectedFetchCurriculumExam?.curriculumName.toString();
    String curriculumCoverage = coverageController.text;
    String? subject = selectedFetchCurriculumExam?.subject.toString();
    if (examName.isEmpty) {
      Utils.snackBar("examEmpty".tr, context);
    } else if (notes.isEmpty) {
      Utils.snackBar("noteEmpty".tr, context);
    } else {
      print("filename:${selectFile.name}");
      print("Subject Name :${subject}");
      Map<String, String>? response = await teacherViewmodel.uploadExamScript(
          examName,
          date,
          curriculumId,
          curriculumName ?? "",
          curriculumCoverage,
          subject ?? "",
          notes,
          widget.model?.studentId ?? "",
          selectFile,
          selectedLanguage == "en" ? "en" : "ar",
          userId ?? "");

      if (context.mounted) {
        if (response != null) {
          setState(() {
            isExamScript = false;
          });

          String extractedText = response["extractText"] ?? "";
          String evaluationReport = response["evaluationReport"] ?? "";
          Utils.snackBar("successExamScripts".tr, context);
          cleaMethod();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfOcrScreen(
                pdfText: extractedText,
                evaluationReport: evaluationReport,
                examName: examName,
                curriculumCoverage: curriculumCoverage,
                date: date,
                observation: notes,
                studentId: widget.model?.studentId ?? "",
                curriculumId: curriculumId,
                curriculumName: curriculumName,
                subject: subject,
                lang: selectedLanguage == "en" ? "en" : "ar",
                file: selectedFiles,
              ),
            ),
          );

          int? code =
              await viewModel.analyzeStudentData(widget.model?.studentId ?? "");
          if (code == 200) {
            print("Analyze data fetch successfully");
          } else {
            print("Analyze data Error : ${viewModel.apiError}");
          }
        } else {
          Utils.snackBar(teacherViewmodel.apiError.toString(), context);
        }
      }
    }
  }

  void _pickFiles() {
    html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.multiple = true;
    uploadInput.accept = ".jpg,.jpeg,.png,.pdf";
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        if (files.length == 1 && files.first.type == "application/pdf") {
          processSelectedFile(files.first);
        } else {
          convertImagesToPdf(files);
        }
      }
    });
  }

  Future<void> processSelectedFile(html.File file) async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;

    setState(() {
      fileName = file.name;
      fileBytes = reader.result as Uint8List;
      selectedFiles = file;
    });
  }

  Future<void> convertImagesToPdf(List<html.File> imageFiles) async {
    final pdf = pw.Document();
    List<Future<Uint8List>> imageFutures = [];

    for (var imageFile in imageFiles) {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(imageFile);
      imageFutures
          .add(reader.onLoad.first.then((_) => reader.result as Uint8List));
    }

    final imageDataList = await Future.wait(imageFutures);

    setState(() {
      selectedImages.clear();
      selectedImageNames.clear();
    });

    for (var imageData in imageDataList) {
      final pdfImage = pw.MemoryImage(imageData);
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(child: pw.Image(pdfImage));
          },
        ),
      );

      setState(() {
        selectedImages.add(imageData);
        selectedImageNames.add("Image");
      });
    }

    final Uint8List pdfBytes = await pdf.save();
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    setState(() {
      selectedFiles =
          html.File([pdfBytes], "merged_images.pdf"); // Ensure it's set
      fileName = "merged_images.pdf";
      fileBytes = pdfBytes;
    });

    html.Url.revokeObjectUrl(url);
  }

  void _generatePdfFromSelectedImages() async {
    final pdf = pw.Document();

    for (var imageData in selectedImages) {
      final pdfImage = pw.MemoryImage(imageData);
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(child: pw.Image(pdfImage));
          },
        ),
      );
    }

    final Uint8List pdfBytes = await pdf.save();
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    setState(() {
      selectedFiles =
          html.File([pdfBytes], "merged_images.pdf"); // Ensure it's set
      fileName = "merged_images.pdf";
      fileBytes = pdfBytes;
    });

    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "merged_images.pdf")
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  void removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
      selectedImageNames.removeAt(index);
      if (selectedImages.isEmpty) {
        fileName = null;
        fileBytes = null;
        selectedFiles = null;
      } else {
        _generatePdfFromSelectedImages(); // Regenerate PDF with remaining images
      }
    });
  }

  void removePdf() {
    setState(() {
      fileName = null;
      fileBytes = null;
      selectedFiles = null;
    });
  }

  cleaMethod() {
    examNameController.clear();
    notesController.clear();
    dateController.clear();
    file = null;
    coverageController.clear();
    fetchSelectSubjectExam = null;
    selectedFetchCurriculumExam = null;
    // selectedCurriculumExam = null;
    // selectedSubjectExam = null;
    fileName = null;
    selectedImageNames.clear();
    selectedImages.clear();
  }

  saveReports() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? teacherId = prefs.getString('userId');
    String? studId = widget.model?.studentId ?? "";
    String? grade = widget.model?.grade ?? "";
    int marks = int.tryParse(markController.text.trim()) ?? 0;
    int subjectTotalMark =
        int.tryParse(subjectTotalMarkController.text.trim()) ?? 0;

    String grades = gradeeController.text.trim().isEmpty
        ? "N/A"
        : gradeeController.text.trim();
    String subject = fetchSelectSubject ?? "";
    String? curriculumName = selectedFetchCurriculum?.curriculumName.toString();
    String curriculumId = fetchSelectCurriculumId ?? "";
    String entryDate =
        DateFormat("yyyy-MM-dd").format(_selectedDate ?? DateTime.now());
    int? code = await teacherViewmodel.saveReports(
      teacherId ?? "",
      widget.model?.studentName ?? "",
      studId,
      grade,
      subject,
      curriculumId,
      curriculumName ?? "",
      marks,
      grades,
      subjectTotalMark,
      entryDate,
    );
    if (code == 200) {
      Utils.snackBar("updateSuccessReportCard".tr, context);
      clearMethodTable();
      fetchAcademicData();
      int? code =
          await viewModel.analyzeStudentData(widget.model?.studentId ?? "");
      if (code == 200) {
        print("Analyze data fetch successfully");
      } else {
        print("Analyze data Error : ${viewModel.apiError}");
      }
    } else {
      Utils.snackBar("${teacherViewmodel.apiError}", context);
      print("Api Error : ${teacherViewmodel.apiError}");
    }
    // }
  }

  clearMethodTable() {
    fetchSelectSubject = null;
    selectedFetchCurriculum = null;
    markController.clear();
    gradeeController.clear();
    subjectTotalMarkController.clear();
    _selectedDate = null;
  }

  // loadCurriculum() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String? userId = prefs.getString('userId');
  //   try {
  //     String url = '${Config.baseURL}curriculum';
  //     final response = await http.get(Uri.parse(url));

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       List<dynamic> curriculumJson = data['curriculum'];
  //       curriculumList =
  //           curriculumJson.map((json) => Curriculum.fromJson(json)).toList();
  //       print("Grade : ${widget.model?.grade}");
  //       filteredCurriculumList = curriculumList
  //           .where((item) => item.grade.toLowerCase() == widget.model?.grade?.toLowerCase())
  //           .toList();
  //       print("Filterd Curriculum List == ${filteredCurriculumList}");
  //       curriculumNames = filteredCurriculumList
  //           .map((e) => e.curriculumName)
  //           .toSet()
  //           .toList();
  //       // print("Curriculums Name : $curriculumNames");
  //       subjects = filteredCurriculumList.map((e) => e.subject).toSet().toList();
  //       print("Filterd Subject List == ${subjects}");
  //       setState(() {}); // Update UI
  //     } else {
  //       print("Error: ${response.statusCode}");
  //     }
  //   } catch (e) {
  //     print("Exception: $e");
  //   }
  // }

  // String url = '${Config.baseURL}curriculum';

  Future<void> loadCurriculum() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      final response = await http
          .get(Uri.parse('${Config.baseURL}curriculum?teacherId=$userId'));
      teacherViewmodel.setLoading(true);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> curriculumJson = data['curriculum'];
        print("Response  : ${response.body}");
        curriculumList =
            curriculumJson.map((item) => Curriculum.fromJson(item)).toList();
        setState(() {
          filteredCurricula = curriculumList
              .where((curriculum) =>
                  curriculum.grade.toLowerCase() ==
                  widget.model?.grade?.toLowerCase())
              .toList();
          print("Curriculum List Length : ${filteredCurricula.length}");
          print("Grade in widget model: ${widget.model?.grade}");
          print(
              "Available grades in curriculumList: ${curriculumList.map((e) => e.grade).toList()}");

          filterSubject = filteredCurricula
              .map((subject) => subject.subject)
              .toSet()
              .toList();
          print("Subject List : $filterSubject");
        });

        teacherViewmodel.setLoading(false);
        teacherViewmodel.notifyListeners();
      } else {
        teacherViewmodel.setLoading(false);
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      teacherViewmodel.setLoading(false);
      print("Exception: $e");
    }
  }

  void filterCurriculaBySubject(String subject) {
    setState(() {
      filteredCurriculumList = filteredCurricula
          .where((curriculum) => curriculum.subject == subject)
          .toList();
      selectedFetchCurriculum = null; // Reset curriculum selection
    });
  }

  void filterCurriculaBySubjectExam(String subject) {
    setState(() {
      // selectedSubject = subject;
      filteredCurriculumList = filteredCurricula
          .where((curriculum) => curriculum.subject == subject)
          .toList();
      // selectedFetchCurriculumExam = null; // Reset curriculum selection
    });
  }

  fetchAcademicData() async {
    ReportCardModel? rModel = await teacherViewmodel
        .getReportCardApicall(widget.model?.studentId ?? "");
    setState(() {
      reportModel = rModel;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchAcademicData();
    loadCurriculum();
  }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    for (var controller in teacherViewmodel.marksControllers) {
      controller.dispose();
    }
    for (var controller in teacherViewmodel.gradeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return ChangeNotifierProvider<TeacherService>(
        create: (BuildContext context) => teacherViewmodel,
        child: Consumer<TeacherService>(builder: (context, value, _) {
          return LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth <= 800;
            return Scaffold(
              body: Stack(
                children: [
                  isMobile ? const SizedBox() : const BackButtonWidget(),
                  Padding(
                    padding: EdgeInsets.only(
                        left: isMobile ? 12 : 100,
                        right: isMobile ? 12 : 100,
                        top: 30),
                    child: SingleChildScrollView(
                      child: Form(
                        key: viewModel.selectedExamTab == ExamScriptFor.academic
                            ? _formKey
                            : _formKey2,
                        child: Column(
                          children: [
                            isMobile
                                ? const BackButtonWidget()
                                : const SizedBox(),
                            SizedBox(height: isMobile ? 5 : 0),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                  color: themeManager.isHighContrast
                                      ? AppColor.labelText
                                      : AppColor.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                        blurRadius: 15,
                                        offset: Offset(0, 10),
                                        color: AppColor.greyShadow)
                                  ]),
                              child: Padding(
                                padding: EdgeInsets.only(
                                    left: isMobile ? 8 : 70,
                                    right: isMobile ? 8 : 70),
                                child: Column(
                                  children: [
                                    studentInformation(),
                                    const SizedBox(height: 10),
                                    topTabBar(),
                                    viewModel.selectedExamTab ==
                                            ExamScriptFor.academic
                                        ? academicTable()
                                        : formView(),
                                    const SizedBox(height: 15),
                                    viewModel.selectedExamTab ==
                                            ExamScriptFor.academic
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              AppFillButton3(
                                                  onPressed: () {
                                                    if (_formKey.currentState!
                                                        .validate()) {
                                                      if (markController
                                                          .text.isEmpty) {
                                                        Utils.snackBar(
                                                            "assignMarks".tr,
                                                            context);
                                                      }  else if (subjectTotalMarkController
                                                          .text.isEmpty) {
                                                        Utils.snackBar(
                                                            "assignTotalMark"
                                                                .tr,
                                                            context);
                                                      } else {
                                                        saveReports();
                                                      }
                                                    }
                                                  },
                                                  text: "save",
                                                  color: AppColor.buttonGreen),
                                            ],
                                          )
                                        : const SizedBox(),
                                    const SizedBox(height: 50),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 30)
                          ],
                        ),
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

  // Widget crriculumDropDown() {
  //   final themeManager = Provider.of<ThemeManager>(context, listen: false);
  //   return SizedBox(
  //     height: 50,
  //     width: 250,
  //     child: Padding(
  //       padding: const EdgeInsets.only(left: 4, right: 4, bottom: 10),
  //       child: DropdownButtonFormField<String>(
  //         decoration: InputDecoration(
  //           filled: true ,
  //           fillColor:
  //               themeManager.isHighContrast ? Colors.grey : Colors.grey[100],
  //           border: const OutlineInputBorder(),
  //           errorBorder: const OutlineInputBorder(
  //             borderSide: BorderSide(color: Colors.red, width: 1),
  //           ),
  //           focusedErrorBorder: const OutlineInputBorder(
  //             borderSide: BorderSide(color: Colors.red, width: 1),
  //           ),
  //           focusedBorder: const OutlineInputBorder(
  //             borderSide: BorderSide(color: AppColor.buttonGreen, width: 1),
  //           ),
  //           hintText: "selectCurriculumn".tr,
  //           contentPadding: EdgeInsets.only(
  //               bottom: 5,
  //               left: selectedLanguage == "en" ? 5 : 0,
  //               right: selectedLanguage == "en" ? 0 : 5),
  //           hintStyle: NotoSansArabicCustomTextStyle.regular.copyWith(
  //               fontSize: 13,
  //               color: themeManager.isHighContrast
  //                   ? AppColor.black
  //                   : AppColor.labelText),
  //         ),
  //         value: selectedCurriculum,
  //         validator: (value) => value == null ? "errorCurriculum".tr : null,
  //         onChanged: (value) {
  //           setState(() {
  //             selectedCurriculum = value;
  //             Curriculum? selected = curriculumList.firstWhere(
  //                 (element) => element.curriculumName == value,
  //                 orElse: () => Curriculum(
  //                     curriculumId: "",
  //                     curriculumName: "",
  //                     grade: "",
  //                     subject: ""));
  //             selectedCurriculumId = selected.curriculumId.isNotEmpty
  //                 ? selected.curriculumId
  //                 : null;
  //             print("Selected Curriculum ID: $selectedCurriculumId");
  //             _formKey.currentState!.validate();
  //           });
  //           // addSubjectAction(selectedSubject.toString());
  //         },
  //         items: isSubjectSelcet == true
  //             ? curriculumNames.map((String value) {
  //                 return DropdownMenuItem<String>(
  //                     value: value,
  //                     child: Text(value,
  //                         style: NotoSansArabicCustomTextStyle.regular.copyWith(
  //                             color: themeManager.isHighContrast
  //                                 ? AppColor.white
  //                                 : AppColor.text,
  //                             fontSize: 13)));
  //               }).toList()
  //             : null,
  //       ),
  //     ),
  //   );
  // }

  Widget subjectDropDown() {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    Color bgColor =
        themeManager.isHighContrast ? Colors.black54 : Colors.grey[100]!;
    Color textColor = themeManager.isHighContrast ? Colors.white : Colors.black;
    Color borderColor =
        themeManager.isHighContrast ? Colors.yellow : Colors.grey;
    return SizedBox(
      height: 50,
      width: 250,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          hintText: "Select a subject",
          hintStyle: TextStyle(color: textColor),
          filled: true,
          fillColor: bgColor,
          border:
              OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
          enabledBorder:
              OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green, width: 2)),
          errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2)),
        ),
        value: fetchSelectSubject, // Must be in subjects list
        items: filterSubject.map((subject) {
          return DropdownMenuItem<String>(
            value: subject,
            child: Text(subject, style: TextStyle(color: textColor)),
          );
        }).toList(),
        onChanged: (String? newSubject) {
          if (newSubject != null) {
            setState(() {
              fetchSelectSubject = newSubject;
              isSubjectSelcet = true;
              selectedFetchCurriculum = null;
              fetchSelectCurriculumId = null;
              filterCurriculaBySubject(newSubject);
              print("academic data subject = $fetchSelectSubject");
            });
          }
          _formKey.currentState?.validate();
        },
        validator: (value) => value == null ? "Please select a subject" : null,
      ),
    );
  }

  Widget crriculumDropDown() {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    Color bgColor =
        themeManager.isHighContrast ? Colors.black54 : Colors.grey[100]!;
    Color textColor = themeManager.isHighContrast ? Colors.white : Colors.black;
    Color borderColor =
        themeManager.isHighContrast ? Colors.yellow : Colors.grey;

    return SizedBox(
      width: 250,
      height: 50,
      child: DropdownButtonFormField<Curriculum>(
        isExpanded: true,
        decoration: InputDecoration(
          hintText: "Select Curriculum",
          hintStyle: TextStyle(color: textColor),
          filled: true,
          fillColor: bgColor,
          border:
              OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
          enabledBorder:
              OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green, width: 2)),
          errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2)),
        ),
        value: selectedFetchCurriculum,

        items: isSubjectSelcet
            ? filteredCurriculumList.map((curriculum) {
                return DropdownMenuItem<Curriculum>(
                    value: curriculum,
                    child: Text('${curriculum.curriculumName}',
                        style: TextStyle(color: textColor)));
              }).toList()
            : [],
        onChanged: isSubjectSelcet
            ? (Curriculum? newCurriculum) {
                setState(() {
                  selectedFetchCurriculum = newCurriculum;

                  // Curriculum? selected = curriculumList.firstWhere(
                  //     (element) => element.curriculumName == value,
                  //     orElse: () => Curriculum(
                  //         curriculumId: "",
                  //         curriculumName: "",
                  //         grade: "",
                  //         subject: ""));

                  // selectedCurriculumId = selected.curriculumId.isNotEmpty
                  //     ? selected.curriculumId
                  //     : null;
                  fetchSelectCurriculumId = newCurriculum?.curriculumId;
                  print(
                      "Selected Curriculum ID: ${newCurriculum?.curriculumId}");
                });
                _formKey.currentState?.validate();
              }
            : null, // Disabled if no subject is selected
        validator: (value) =>
            value == null ? "Please select a curriculum" : null,
      ),
    );
  }

  Widget academicTable() {
    List<DataRow> rows = [];
    reportModel?.subjects.forEach((subjectName, subject) {
      subject.history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      for (var history in subject.history) {
        // String formattedTimestamp =
        //     "${history.timestamp.substring(0, 10)} ${history.timestamp.substring(10)}";
        // DateTime dateTime = DateTime.parse(formattedTimestamp);
        // String formattedDate =
        //     DateFormat("dd-MM-yyyy hh:mm a").format(dateTime);
        rows.add(DataRow(cells: [
          DataCell(Text(subjectName,
              style: const TextStyle(color: AppColor.black))), // Subject
          DataCell(Text(history.curriculumName,
              style:
                  const TextStyle(color: AppColor.black))), // Curriculum Name
          DataCell(Center(
              child: Text(history.marks.toString(),
                  style: const TextStyle(color: AppColor.black)))), // Marks
          DataCell(Center(
              child: Text(history.totalMark?.toString() ?? "",
                  style:
                      const TextStyle(color: AppColor.black)))), // Total Marks
          DataCell(Center(
              child: Text(history.grade,
                  style: const TextStyle(color: AppColor.black)))), // Grade
          DataCell(Text(history.timestamp,
              style: const TextStyle(color: AppColor.black))), // Date
        ]));
      }
    });
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth <= 800;
      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
            color: AppColor.extralightGrey,
            borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(5),
                bottomLeft: Radius.circular(5))),
        child: Padding(
          padding: EdgeInsets.only(
              left: isMobile ? 10 : 30, right: isMobile ? 10 : 30, top: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isMobile
                      ? Column(
                          children: [
                            subjectDropDown(),
                            const SizedBox(height: 15),
                            crriculumDropDown(),
                            const SizedBox(height: 15),
                            SizedBox(
                                height: 50,
                                width: 250,
                                child: AppFillTextField(
                                    textController: dateController,
                                    readOnly: true,
                                    suffixIcon: IconButton(
                                        onPressed: () {
                                          _selectDate(context);
                                        },
                                        padding:
                                            const EdgeInsets.only(left: 15),
                                        icon: Image.asset(
                                          AppImage.calendar,
                                          width: 45,
                                        )),
                                    hintText: "selectDate".tr,
                                    icon: null)),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            subjectDropDown(),
                            const SizedBox(width: 20),
                            crriculumDropDown(),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 50,
                                  width: 250, // Adjust width as needed
                                  child: AppFillTextField(
                                    textController: dateController,
                                    readOnly: true,
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        _selectDate(context);
                                      },
                                      padding: const EdgeInsets.only(left: 15),
                                      icon: Image.asset(
                                        AppImage.calendar,
                                        width: 40,
                                      ),
                                    ),
                                    hintText: "selectDate".tr,
                                    icon: null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: fetchSelectSubject != null
                        ? DataTable(
                            headingRowColor: WidgetStateColor.resolveWith(
                                (states) =>
                                    AppColor.buttonGreen), // Header row color
                            decoration: BoxDecoration(
                              border:
                                  Border.all(width: 0.8, color: AppColor.black),
                            ),
                            columns: [
                                DataColumn(
                                    label: Text("subject".tr,
                                        style: NotoSansArabicCustomTextStyle
                                            .semibold
                                            .copyWith(
                                                color: AppColor.white,
                                                fontSize: 15))),
                                DataColumn(
                                    label: Text("obtainedMarks".tr,
                                        style: NotoSansArabicCustomTextStyle
                                            .semibold
                                            .copyWith(
                                                color: AppColor.white,
                                                fontSize: 15))),
                                DataColumn(
                                    label: Text("gradee".tr,
                                        style: NotoSansArabicCustomTextStyle
                                            .semibold
                                            .copyWith(
                                                color: AppColor.white,
                                                fontSize: 15))),
                                DataColumn(
                                    label: Text("totalMarks".tr,
                                        style: NotoSansArabicCustomTextStyle
                                            .semibold
                                            .copyWith(
                                                color: AppColor.white,
                                                fontSize: 15))),
                              ],
                            rows: [
                                DataRow(cells: [
                                  DataCell(
                                    Text(
                                      fetchSelectSubject ?? "",
                                      style: NotoSansArabicCustomTextStyle
                                          .regular
                                          .copyWith(
                                              fontSize: 15,
                                              color: AppColor.black),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      height: 36,
                                      width: 36,
                                      decoration: BoxDecoration(
                                        color: AppColor.white,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                            color: AppColor.buttonGreen,
                                            width: 1),
                                      ),
                                      child: TextFormField(
                                        // key: _formKey,
                                        textAlign: TextAlign.center,
                                        controller: markController,
                                        validator: (value) {
                                          value == null
                                              ? 'Please assign marks'
                                              : null;
                                        },
                                        style: PoppinsCustomTextStyle.regular
                                            .copyWith(
                                                color: AppColor.black,
                                                fontSize: 13),
                                        decoration: const InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(bottom: 10),
                                            border: InputBorder.none),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      height: 36,
                                      width: 36,
                                      decoration: BoxDecoration(
                                        color: AppColor.white,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                            color: AppColor.buttonGreen,
                                            width: 1),
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextFormField(
                                          // key: _formKey,
                                          textAlign: TextAlign.center,
                                          controller: gradeeController,
                                          // validator: (value) {
                                          //   value == null
                                          //       ? "Please assign grade"
                                          //       : null;
                                          // },
                                          style: PoppinsCustomTextStyle.regular
                                              .copyWith(
                                                  color: AppColor.black,
                                                  fontSize: 13),
                                          decoration: const InputDecoration(
                                              contentPadding:
                                                  EdgeInsets.only(bottom: 10),
                                              border: InputBorder.none),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Container(
                                    height: 36,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: AppColor.white,
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                          color: AppColor.buttonGreen,
                                          width: 1),
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextFormField(
                                        textAlign: TextAlign.center,
                                        controller: subjectTotalMarkController,
                                        validator: (value) {
                                          value == null
                                              ? "Please assign Total Marks"
                                              : null;
                                        },
                                        style: PoppinsCustomTextStyle.regular
                                            .copyWith(
                                                color: AppColor.black,
                                                fontSize: 13),
                                        decoration: const InputDecoration(
                                            contentPadding:
                                                EdgeInsets.only(bottom: 10),
                                            border: InputBorder.none),
                                      ),
                                    ),
                                  ))
                                ])
                              ])
                        : const SizedBox(),
                  ),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateColor.resolveWith(
                          (states) => AppColor.buttonGreen), // Header row color
                      decoration: BoxDecoration(
                        border: Border.all(width: 0.8, color: AppColor.black),
                      ),
                      columns: [
                        DataColumn(
                            label: Text("subject".tr,
                                style: NotoSansArabicCustomTextStyle.bold
                                    .copyWith(
                                        fontSize: 15, color: AppColor.white))),
                        DataColumn(
                            label: Text("curriculum".tr,
                                style: NotoSansArabicCustomTextStyle.bold
                                    .copyWith(
                                        fontSize: 15, color: AppColor.white))),
                        DataColumn(
                            label: Text("obtainedMarks".tr,
                                style: NotoSansArabicCustomTextStyle.bold
                                    .copyWith(
                                        fontSize: 15, color: AppColor.white))),
                        DataColumn(
                            label: Text("totalMarks".tr,
                                style: NotoSansArabicCustomTextStyle.bold
                                    .copyWith(
                                        fontSize: 15, color: AppColor.white))),
                        DataColumn(
                            label: Text("gradee".tr,
                                style: NotoSansArabicCustomTextStyle.bold
                                    .copyWith(
                                        fontSize: 15, color: AppColor.white))),
                        DataColumn(
                            label: Text("dateTitle".tr,
                                style: NotoSansArabicCustomTextStyle.bold
                                    .copyWith(
                                        fontSize: 15, color: AppColor.white))),
                      ],
                      rows: showAll ? rows : rows.take(5).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                      onPressed: () {
                        setState(() {
                          showAll = !showAll;
                        });
                      },
                      child: Text(showAll ? "showLess".tr : "showMore".tr,
                          style: NotoSansArabicCustomTextStyle.medium.copyWith(
                              fontSize: 15, color: AppColor.buttonGreen))),
                  const SizedBox(height: 30),
                ],
              ),
              const SizedBox(height: 10)
            ],
          ),
        ),
      );
    });
  }

  Widget formView() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth <= 800;
      return Container(
        decoration: const BoxDecoration(
            color: AppColor.extralightGrey,
            borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(5),
                bottomLeft: Radius.circular(5))),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 5 : 30),
          child: Column(
            children: [
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text("examName".tr,
                            style: NotoSansArabicCustomTextStyle.medium
                                .copyWith(
                                    fontSize: fontSizeProvider.fontSize,
                                    color: AppColor.black)),
                        const SizedBox(height: 5),
                        SizedBox(
                          height: 39,
                          child: AppFillTextField(
                              textController: examNameController,
                              hintText: "examNameTitle".tr,
                              icon: null),
                        ),
                        const SizedBox(height: 5),
                        Text("date".tr,
                            style: NotoSansArabicCustomTextStyle.medium
                                .copyWith(
                                    fontSize: fontSizeProvider.fontSize,
                                    color: AppColor.black)),
                        const SizedBox(height: 5),
                        SizedBox(
                            height: 39,
                            child: AppFillTextField(
                                textController: dateController,
                                readOnly: true,
                                suffixIcon: IconButton(
                                    onPressed: () {
                                      _selectDate(context);
                                    },
                                    padding: const EdgeInsets.only(left: 15),
                                    icon: Image.asset(
                                      AppImage.calendar,
                                      width: 45,
                                    )),
                                hintText: "selectDate".tr,
                                icon: null)),
                        const SizedBox(height: 5),
                        Text("${"selectSubject".tr} : ",
                            style: NotoSansArabicCustomTextStyle.medium
                                .copyWith(
                                    fontSize: fontSizeProvider.fontSize,
                                    color: AppColor.black)),
                        const SizedBox(height: 5),
                        subjectDropDownExam(isMobile),
                        const SizedBox(height: 5),
                        Text("${"curriculumName".tr} :",
                            style: NotoSansArabicCustomTextStyle.medium
                                .copyWith(
                                    fontSize: fontSizeProvider.fontSize,
                                    color: AppColor.black)),
                        const SizedBox(height: 5),
                        crriculumTextFieldExam(isMobile),
                        const SizedBox(height: 5),
                        Text("${"curriculumCoverage".tr} :".tr,
                            style: NotoSansArabicCustomTextStyle.medium
                                .copyWith(
                                    fontSize: fontSizeProvider.fontSize,
                                    color: AppColor.black)),
                        const SizedBox(height: 5),
                        SizedBox(
                            height: 39,
                            child: AppFillTextField(
                                textController: coverageController,
                                hintText: "curriculumCoverage".tr,
                                icon: null)),
                        const SizedBox(height: 20),
                      ],
                    )
                  : Column(
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text("examName".tr,
                                    style: NotoSansArabicCustomTextStyle.medium
                                        .copyWith(
                                            fontSize: fontSizeProvider.fontSize,
                                            color: AppColor.black)),
                                const SizedBox(width: 10),
                                SizedBox(
                                  height: 39,
                                  width: 250,
                                  child: AppFillTextField(
                                      textController: examNameController,
                                      hintText: "examNameTitle".tr,
                                      validator: (value) => value!.isEmpty
                                          ? "Exam name is required"
                                          : null,
                                      icon: null),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text("date".tr,
                                    style: NotoSansArabicCustomTextStyle.medium
                                        .copyWith(
                                            fontSize: fontSizeProvider.fontSize,
                                            color: AppColor.black)),
                                const SizedBox(width: 10),
                                SizedBox(
                                    height: 39,
                                    width: 250,
                                    child: AppFillTextField(
                                        textController: dateController,
                                        readOnly: true,
                                        suffixIcon: IconButton(
                                            onPressed: () {
                                              _selectDate(context);
                                            },
                                            padding:
                                                const EdgeInsets.only(left: 15),
                                            icon: Image.asset(
                                              AppImage.calendar,
                                              width: 45,
                                            )),
                                        hintText: "selectDate".tr,
                                        icon: null)),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text("${"selectSubject".tr} : ",
                                    style: NotoSansArabicCustomTextStyle.medium
                                        .copyWith(
                                            fontSize: fontSizeProvider.fontSize,
                                            color: AppColor.black)),
                                const SizedBox(width: 10),
                                subjectDropDownExam(isMobile)
                              ],
                            ),
                            Row(
                              children: [
                                Text("${"curriculumName".tr} :",
                                    style: NotoSansArabicCustomTextStyle.medium
                                        .copyWith(
                                            fontSize: fontSizeProvider.fontSize,
                                            color: AppColor.black)),
                                const SizedBox(width: 10),
                                crriculumTextFieldExam(isMobile)
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text("${"curriculumCoverage".tr} :",
                                style: NotoSansArabicCustomTextStyle.medium
                                    .copyWith(
                                        fontSize: fontSizeProvider.fontSize,
                                        color: AppColor.black)),
                            const SizedBox(width: 10),
                            SizedBox(
                                height: 39,
                                width: 250,
                                child: AppFillTextField(
                                    textController: coverageController,
                                    hintText: "curriculumCoverage".tr,
                                    icon: null)),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
              // Container(
              //     height: 100,
              //     width: double.infinity,
              //     decoration: BoxDecoration(
              //         color: AppColor.white,
              //         borderRadius: BorderRadius.circular(5)),
              //     child: Column(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: [
              //         if (selectedImages.isNotEmpty) ...[
              //           Wrap(
              //             children: selectedImages.map((img) {
              //               return Padding(
              //                 padding: const EdgeInsets.all(5.0),
              //                 child: Image.memory(img, width: 70, height: 70),
              //               );
              //             }).toList(),
              //           ),
              //         ] else if (fileName != null) ...[
              //           Align(
              //               alignment: Alignment.center,
              //               child: Text("$fileName"))
              //         ] else ...[
              //           Align(
              //             alignment: Alignment.center,
              //             child: Text("supportedFileTypesPDF,JPG".tr,
              //                 style: PoppinsCustomTextStyle.regular.copyWith(
              //                     fontSize: fontSizeProvider.fontSize,
              //                     color: AppColor.black)),
              //           ),
              //         ]
              //       ],
              //     )),
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: AppColor.white,
                    borderRadius: BorderRadius.circular(5)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (selectedImages.isNotEmpty) ...[
                      Wrap(
                        children: List.generate(selectedImages.length, (index) {
                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Image.memory(selectedImages[index],
                                    width: 70, height: 70),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () => removeImage(
                                      index), // Remove image function
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 14),
                                  ),
                                ),
                              )
                            ],
                          );
                        }),
                      ),
                    ] else if (fileName != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("$fileName"),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: removePdf, // Remove PDF function
                          ),
                        ],
                      ),
                    ] else ...[
                      Align(
                        alignment: Alignment.center,
                        child: Text("supportedFileTypesPDF,JPG".tr,
                            style: PoppinsCustomTextStyle.regular.copyWith(
                                fontSize: fontSizeProvider.fontSize,
                                color: AppColor.black)),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Align(
                  alignment: Alignment.centerRight,
                  child: AppFillButton3(
                      onPressed: () {
                        _pickFiles();
                      },
                      text: "upload",
                      color: AppColor.buttonGreen)),
              const SizedBox(height: 20),
              Container(
                height: 96,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: AppColor.white,
                    borderRadius: BorderRadius.circular(5)),
                child: TextField(
                  controller: notesController,
                  style: PoppinsCustomTextStyle.medium
                      .copyWith(fontSize: 13, color: AppColor.black),
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "notesHint".tr,
                      hintStyle: PoppinsCustomTextStyle.medium.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: AppColor.labelText),
                      contentPadding: const EdgeInsets.only(left: 10)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                      alignment: Alignment.centerRight,
                      child: AppFillButton3(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ShowHistoryScreen(
                                        studId: widget.model?.studentId)));
                          },
                          text: "showHistory",
                          color: AppColor.buttonGreen)),
                  Align(
                      alignment: Alignment.centerRight,
                      child: AppFillButton3(
                          onPressed: () {
                            if (_formKey2.currentState!.validate()) {
                              if (selectedFiles != null) {
                                examScriptUpload(selectedFiles!);
                              } else if (_selectedDate == null) {
                                Utils.snackBar("dateEmpty".tr, context);
                              } else {
                                Utils.snackBar("attachFile".tr, context);
                              }
                            }
                            // pdfOcr();
                          },
                          text: "submit",
                          color: AppColor.buttonGreen)),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      );
    });
  }

  Widget crriculumTextFieldExam(bool isMobile) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    Color bgColor =
        themeManager.isHighContrast ? Colors.black54 : Colors.grey[100]!;
    Color textColor = themeManager.isHighContrast ? Colors.white : Colors.black;
    Color borderColor =
        themeManager.isHighContrast ? Colors.yellow : Colors.grey;
    return SizedBox(
      width: 250,
      height: 50,
      child: DropdownButtonFormField<Curriculum>(
        isExpanded: true,
        decoration: InputDecoration(
          hintText: "selectCurriculumn".tr,
          hintStyle: TextStyle(color: textColor),
          filled: true,
          fillColor: bgColor,
          border:
              OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
          enabledBorder:
              OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green, width: 2)),
          errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2)),
        ),
        value: selectedFetchCurriculumExam,
        items: isSubjectSelectedExam
            ? filteredCurriculumList.map((curriculum) {
                return DropdownMenuItem<Curriculum>(
                  value: curriculum,
                  child: Text(curriculum.curriculumName),
                );
              }).toList()
            : [],
        onChanged: isSubjectSelectedExam
            ? (Curriculum? newCurriculum) {
                setState(() {
                  selectedFetchCurriculumExam = newCurriculum;
                  // Curriculum? selected = curriculumList.firstWhere(
                  //     (element) => element.curriculumName == value,
                  //     orElse: () => Curriculum(
                  //         curriculumId: "",
                  //         curriculumName: "",
                  //         grade: "",
                  //         subject: ""));

                  // selectedCurriculumId = selected.curriculumId.isNotEmpty
                  //     ? selected.curriculumId
                  //     : null;
                  fetchSelectCurriculumExamId = newCurriculum?.curriculumId;
                  print(
                      "Selected Curriculum ID Exam: ${newCurriculum?.curriculumId}");
                });
                _formKey.currentState?.validate();
              }
            : null,
        validator: (value) =>
            value == null ? "Please select a curriculum" : null,
      ),
    );
  }

  Widget subjectDropDownExam(bool isMobile) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    Color bgColor =
        themeManager.isHighContrast ? Colors.black54 : Colors.grey[100]!;
    Color textColor = themeManager.isHighContrast ? Colors.white : Colors.black;
    Color borderColor =
        themeManager.isHighContrast ? Colors.yellow : Colors.grey;

    if (fetchSelectSubjectExam != null &&
        !subjects.contains(fetchSelectSubjectExam)) {
      fetchSelectSubjectExam = null;
    }

    return SizedBox(
      height: 50,
      width: 250,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          hintText: "selectSubject".tr,
          hintStyle: TextStyle(color: textColor),
          filled: true,
          fillColor: bgColor,
          border:
              OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
          enabledBorder:
              OutlineInputBorder(borderSide: BorderSide(color: borderColor)),
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green, width: 2)),
          errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2)),
        ),
        value: fetchSelectSubjectExam,
        items: filterSubject.map((subject) {
          return DropdownMenuItem<String>(
            value: subject,
            child: Text(subject),
          );
        }).toList(),
        onChanged: (String? newSubject) {
          if (newSubject != null) {
            setState(() {
              fetchSelectSubjectExam = newSubject;
              isSubjectSelectedExam = true;
              selectedFetchCurriculumExam = null;
              fetchSelectCurriculumExamId = null;
              filterCurriculaBySubjectExam(newSubject);
            });
            print("Subject : $fetchSelectSubjectExam");
          }
        },
        validator: (value) => value == null ? "Please select a subject" : null,
      ),
    );
  }

  Widget topTabBar() {
    return Center(
        child: Row(
      children: [
        tabTitle("academicData", ExamScriptFor.academic, 0),
        tabTitle("examScript", ExamScriptFor.examScript, 1),
      ],
    ));
  }

  changeTabAction(ExamScriptFor type) async {
    viewModel.selectedExamTab = type;
    if (viewModel.selectedExamTab == ExamScriptFor.academic) {
    } else {}
  }

  tabTitle(text, ExamScriptFor type, int selectedItem) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    bool isSelected = type == viewModel.selectedExamTab;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            changeTabAction(type);
            viewModel.selectedScripts = selectedItem;
          });
        },
        child: Container(
          width: 460,
          // height: 40,
          decoration: BoxDecoration(
              color: isSelected == true
                  ? AppColor.buttonGreen
                  : AppColor.lightYellow,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(type == ExamScriptFor.academic
                      ? selectedLanguage == "en"
                          ? 5
                          : 0
                      : selectedLanguage == "en"
                          ? 0
                          : 5),
                  topRight: Radius.circular(type == ExamScriptFor.academic
                      ? selectedLanguage == "en"
                          ? 0
                          : 5
                      : selectedLanguage == "en"
                          ? 5
                          : 0))),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: Text("$text".tr,
                  style: PoppinsCustomTextStyle.bold.copyWith(
                      fontSize: fontSizeProvider.fontSize + 1,
                      color: AppColor.white)),
            ),
          ),
        ),
      ),
    );
  }

  Widget studentInformation() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth <= 800;
      return Padding(
        padding: const EdgeInsets.only(top: 25),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  isMobile
                      ? Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColor.lightGrey),
                          child: ClipRRect(
                            child: CircleAvatar(
                                radius: 50,
                                backgroundImage:
                                    NetworkImage(widget.model?.photourl ?? "")),
                          ),
                        )
                      : const SizedBox(),
                  const SizedBox(height: 15),
                  Text(widget.model?.studentName ?? "",
                      style: NotoSansArabicCustomTextStyle.bold.copyWith(
                          fontSize: fontSizeProvider.fontSize + 2,
                          color: AppColor.black)),
                  const SizedBox(height: 15),
                  Text("${"email".tr} ${widget.model?.email ?? ""}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: NotoSansArabicCustomTextStyle.medium.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: AppColor.black)),
                  const SizedBox(height: 15),
                  Text(widget.model?.classSection ?? "",
                      style: NotoSansArabicCustomTextStyle.medium
                          .copyWith(fontSize: 13, color: AppColor.black)),
                  const SizedBox(height: 15),
                  Text("${"grade".tr} : ${widget.model?.grade ?? ""}",
                      style: NotoSansArabicCustomTextStyle.medium
                          .copyWith(fontSize: 13, color: AppColor.black)),
                  const SizedBox(height: 5),
                ],
              ),
            ),
            isMobile
                ? const SizedBox()
                : Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: AppColor.lightGrey),
                    child: ClipRRect(
                      child: CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              NetworkImage(widget.model?.photourl ?? "")),
                    ),
                  ),
          ],
        ),
      );
    });
  }

  String formatTimestamp(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd-MM-yyyy').format(date); // Example: 01-01-2022
  }
}
