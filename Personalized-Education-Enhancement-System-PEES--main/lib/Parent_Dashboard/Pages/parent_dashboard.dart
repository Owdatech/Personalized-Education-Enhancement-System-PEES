import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/HeadMaster_Dashboard/Services/headMaster_services.dart';
import 'package:pees/Parent_Dashboard/Pages/alerts&Noti_Screen.dart';
import 'package:pees/Parent_Dashboard/Pages/recents_update_screen.dart';
import 'package:pees/Parent_Dashboard/Pages/resources_screen.dart';
import 'package:pees/Parent_Dashboard/Services/parent_services.dart';
import 'package:pees/Widgets/AppButton.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../HeadMaster_Dashboard/Model/studentModel.dart';
import '../../Teacher_Dashbord/Pages/Progress/progress_screen.dart';
import 'observation-screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  HeadMasterServices masterViewModel = HeadMasterServices();
  ParentService viewModel = ParentService();
  String selectedLanguage = Get.locale?.languageCode ?? 'en';
  StudentModel? model;
  fetchStudents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    List<Students>? code = await viewModel.fetchChildernDetails(userId ?? "");
    setState(() {}); // Ensure UI rebuilds
    if (code.isNotEmpty) {
      print("Successfully fetch child information list");
    } else {
      print("Fetch child Error : ${viewModel.apiError}");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return ChangeNotifierProvider<ParentService>(
        create: (BuildContext context) => viewModel,
        child: Consumer<ParentService>(builder: (context, value, _) {
          return LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth <= 800;
            return Scaffold(
              // ignore: deprecated_member_use
              backgroundColor: Colors.grey.withOpacity(0.2),
              resizeToAvoidBottomInset: false,
              body: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: SizedBox(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: isMobile ? 12 : 20,
                                  right: isMobile ? 12 : 20,
                                  top: isMobile ? 12 : 30),
                              child: SingleChildScrollView(
                                primary: true,
                                physics: const FixedExtentScrollPhysics(),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // overallPerformance(isMobile),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          decoration: const BoxDecoration(
                                              color: AppColor.buttonGreen,
                                              borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(5),
                                                  topRight:
                                                      Radius.circular(5))),
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                                top: 12,
                                                bottom: 12,
                                                left: 10,
                                                right: selectedLanguage == "en"
                                                    ? 0
                                                    : 10),
                                            child: Text(
                                              "childInformation".tr,
                                              style:
                                                  NotoSansArabicCustomTextStyle
                                                      .bold
                                                      .copyWith(
                                                          color: AppColor.white,
                                                          fontSize: 15),
                                            ),
                                          ),
                                        ),
                                        Container(
                                            height: 300,
                                            decoration: BoxDecoration(
                                                color:
                                                    themeManager.isHighContrast
                                                        ? AppColor.labelText
                                                        : AppColor.white,
                                                borderRadius:
                                                    const BorderRadius.only(
                                                        bottomLeft:
                                                            Radius.circular(5),
                                                        bottomRight:
                                                            Radius.circular(
                                                                5))),
                                            child:
                                                viewModel.studentsList.isEmpty
                                                    ? Center(
                                                        child: Text(
                                                            "nostudentsfound"
                                                                .tr))
                                                    : ListView.builder(
                                                        shrinkWrap: true,
                                                        itemCount: viewModel
                                                            .studentsList
                                                            .length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    left: 10,
                                                                    right: 10,
                                                                    top: 7),
                                                            child: Container(
                                                                width: double
                                                                    .infinity,
                                                                decoration: BoxDecoration(
                                                                    color: AppColor
                                                                        .white,
                                                                    borderRadius: BorderRadius.circular(7),
                                                                    boxShadow: const [
                                                                      BoxShadow(
                                                                          color: AppColor
                                                                              .greyShadow,
                                                                          offset: Offset(
                                                                              0,
                                                                              5),
                                                                          blurRadius:
                                                                              15)
                                                                    ]),
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          8.0),
                                                                  child: isMobile
                                                                      ? Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Row(
                                                                              children: [
                                                                                CircleAvatar(
                                                                                  radius: 25,
                                                                                  backgroundImage: NetworkImage(viewModel.studentsList[index].photoUrl ?? ""),
                                                                                ),
                                                                                const SizedBox(width: 10),
                                                                                Text(
                                                                                  viewModel.studentsList[index].name ?? "",
                                                                                  style: NotoSansArabicCustomTextStyle.bold.copyWith(fontSize: 16, color: AppColor.black),
                                                                                )
                                                                              ],
                                                                            ),
                                                                            const SizedBox(height: 5),
                                                                            AppFillButton2(
                                                                                onPressed: () {
                                                                                  Navigator.push(
                                                                                      context,
                                                                                      MaterialPageRoute(
                                                                                          builder: (context) => ProgressScreen.fromParent(
                                                                                                studentId: viewModel.studentsList[index].studentId ?? "",
                                                                                                userName: viewModel.studentsList[index].name ?? "",
                                                                                                photoUrl: viewModel.studentsList[index].photoUrl ?? "",
                                                                                                teacherName: viewModel.studentsList[index].assignTeacherName ?? "",
                                                                                                grade: viewModel.studentsList[index].grade ?? "",
                                                                                                className: viewModel.studentsList[index].className ?? "",
                                                                                                email: viewModel.studentsList[index].email ?? "",
                                                                                              )));
                                                                                },
                                                                                text: "viewDetails"),
                                                                          ],
                                                                        )
                                                                      : Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            Row(
                                                                              children: [
                                                                                CircleAvatar(
                                                                                  radius: 25,
                                                                                  backgroundImage: NetworkImage(viewModel.studentsList[index].photoUrl ?? ""),
                                                                                ),
                                                                                const SizedBox(width: 10),
                                                                                Text(
                                                                                  viewModel.studentsList[index].name ?? "",
                                                                                  style: NotoSansArabicCustomTextStyle.bold.copyWith(fontSize: 16, color: AppColor.black),
                                                                                )
                                                                              ],
                                                                            ),
                                                                            Padding(
                                                                              padding: const EdgeInsets.all(5.0),
                                                                              child: AppFillButton2(
                                                                                  onPressed: () {
                                                                                    Navigator.push(
                                                                                        context,
                                                                                        MaterialPageRoute(
                                                                                            builder: (context) => ProgressScreen.fromParent(
                                                                                                  studentId: viewModel.studentsList[index].studentId ?? "",
                                                                                                  userName: viewModel.studentsList[index].name ?? "",
                                                                                                  photoUrl: viewModel.studentsList[index].photoUrl ?? "",
                                                                                                  teacherName: viewModel.studentsList[index].assignTeacherName ?? "",
                                                                                                  grade: viewModel.studentsList[index].grade ?? "",
                                                                                                  className: viewModel.studentsList[index].className ?? "",
                                                                                                  email: viewModel.studentsList[index].email ?? "",
                                                                                                )));
                                                                                  },
                                                                                  text: "viewDetails"),
                                                                            )
                                                                          ],
                                                                        ),
                                                                )),
                                                          );
                                                        },
                                                      )),
                                      ],
                                    ),
                                    const SizedBox(height: 40),
                                    isMobile
                                        ? Column(
                                            children: [
                                              recentActivity("recentUpdates",
                                                  () {
                                                showRecentUpdateDialog();
                                              }),
                                              const SizedBox(height: 10),
                                              recentActivity(
                                                "alerts&Noti",
                                                () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              AlertsNotificationScreen(
                                                                  isAlerts:
                                                                      false)));
                                                },
                                              ),
                                              const SizedBox(height: 10),
                                              recentActivity(
                                                "resourcesTitle",
                                                () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              const ResourcesScreen()));
                                                },
                                              ),
                                              const SizedBox(height: 10),
                                              recentActivity("observation", () {
                                                showObservationDialog();
                                              }),
                                            ],
                                          )
                                        : Row(
                                            children: [
                                              Expanded(
                                                flex: 1,
                                                child: recentActivity(
                                                    "recentUpdates", () {
                                                  showRecentUpdateDialog();
                                                }),
                                              ),
                                              const SizedBox(width: 7),
                                              Expanded(
                                                flex: 1,
                                                child: recentActivity(
                                                  "alerts&Noti",
                                                  () {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                AlertsNotificationScreen(
                                                                    isAlerts:
                                                                        false)));
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 7),
                                              Expanded(
                                                flex: 1,
                                                child: recentActivity(
                                                  "resourcesTitle",
                                                  () {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                const ResourcesScreen()));
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 7),
                                              Expanded(
                                                flex: 1,
                                                child: recentActivity(
                                                    "observation", () {
                                                  showObservationDialog();
                                                }),
                                              ),
                                              const SizedBox(width: 7),
                                            ],
                                          ),
                                    const SizedBox(height: 30),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  viewModel.loading ? const LoaderView() : Container()
                ],
              ),
            );
          });
        }));
  }

  void showRecentUpdateDialog() {
    final fontSizeProvider =
        Provider.of<FontSizeProvider>(context, listen: false);
    String? selectedStudentName;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "Select Student",
                style: TextStyle(fontSize: fontSizeProvider.fontSize + 2),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: viewModel.studentsList.length,
                  itemBuilder: (context, index) {
                    final student = viewModel.studentsList[index];
                    return RadioListTile<String>(
                      title: Text(
                        "${student.name} (Grade: ${student.grade}, Class: ${student.className})",
                        style: TextStyle(fontSize: fontSizeProvider.fontSize),
                      ),
                      value: student.name ?? "",
                      groupValue: selectedStudentName,
                      onChanged: (value) {
                        setState(() {
                          selectedStudentName = value;
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: selectedStudentName == null
                      ? null
                      : () {
                          Navigator.of(context).pop();

                          // Navigate without studentId
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RecentUpdateScreen(),
                            ),
                          );
                        },
                  child: const Text("OK"),
                )
              ],
            );
          },
        );
      },
    );
  }

  Widget recentActivity(String title, Function() onTap) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return InkWell(
      onTap: () {
        onTap();
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                  color: AppColor.greyShadow,
                  blurRadius: 5,
                  offset: Offset(0, 5))
            ],
            color: themeManager.isHighContrast
                ? AppColor.labelText
                : AppColor.white),
        child: Center(
            child: Text(
          title.tr,
          style: NotoSansArabicCustomTextStyle.medium.copyWith(
              fontSize: fontSizeProvider.fontSize, color: AppColor.black),
        )),
      ),
    );
  }

  void showObservationDialog() {
    final fontSizeProvider =
        Provider.of<FontSizeProvider>(context, listen: false);
    String? selectedStudentId;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text("Select Student",
                style: TextStyle(fontSize: fontSizeProvider.fontSize + 2)),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: viewModel.studentsList.length,
                itemBuilder: (context, index) {
                  final student = viewModel.studentsList[index];
                  return RadioListTile<String>(
                    title: Text(
                      "${student.name} (Grade: ${student.grade}, Class: ${student.className})",
                      style: TextStyle(fontSize: fontSizeProvider.fontSize),
                    ),
                    value: student.studentId ?? "",
                    groupValue: selectedStudentId,
                    onChanged: (value) {
                      setState(() {
                        selectedStudentId = value;
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: selectedStudentId == null
                    ? null
                    : () {
                        final selectedStudent = viewModel.studentsList
                            .firstWhere(
                                (s) => s.studentId == selectedStudentId);

                        Navigator.of(context).pop(); // Close dialog

                        // Navigate to Observation screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ObservationScreenParent(
                              studentId: selectedStudent.studentId ?? "",
                              userName: selectedStudent.name ?? "",
                              photoUrl: selectedStudent.photoUrl ?? "",
                              teacherName:
                                  selectedStudent.assignTeacherName ?? "",
                              grade: selectedStudent.grade ?? "",
                              className: selectedStudent.className ?? "",
                              email: selectedStudent.email ?? "",
                            ),
                          ),
                        );
                      },
                child: const Text("OK"),
              )
            ],
          ),
        );
      },
    );
  }

  Widget recentUpdates() {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Container(
      // width: 330,
      height: 280,
      decoration: BoxDecoration(
          color:
              themeManager.isHighContrast ? AppColor.labelText : AppColor.white,
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [
            BoxShadow(
                color: AppColor.greyShadow,
                blurRadius: 15,
                offset: Offset(0, 10))
          ]),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 28,
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(5),
                          topLeft: Radius.circular(5)),
                      color: AppColor.buttonGreen),
                  child: Text(
                    "recentsAlerts".tr,
                    textAlign: TextAlign.center,
                    style: PoppinsCustomTextStyle.bold.copyWith(
                        fontSize: fontSizeProvider.fontSize,
                        color: AppColor.white),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
                left: selectedLanguage == "en" ? 8 : 0,
                right: selectedLanguage == "en" ? 0 : 8,
                top: 10),
            child: Text(
              "assList".tr,
              style: PoppinsCustomTextStyle.medium.copyWith(
                  fontSize: fontSizeProvider.fontSize, color: AppColor.black),
            ),
          )
        ],
      ),
    );
  }

  Widget alertsAndNotification() {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Container(
      // width: 330,
      height: 280,
      decoration: BoxDecoration(
          color:
              themeManager.isHighContrast ? AppColor.labelText : AppColor.white,
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [
            BoxShadow(
                color: AppColor.greyShadow,
                blurRadius: 15,
                offset: Offset(0, 10))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 28,
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(5),
                          topLeft: Radius.circular(5)),
                      color: AppColor.buttonGreen),
                  child: Text(
                    "alerts&Noti".tr,
                    textAlign: TextAlign.center,
                    style: PoppinsCustomTextStyle.bold.copyWith(
                        fontSize: fontSizeProvider.fontSize,
                        color: AppColor.white),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
                left: selectedLanguage == "en" ? 8 : 0,
                right: selectedLanguage == "en" ? 0 : 8,
                top: 10),
            child: Text(
              "alertsSub".tr,
              style: PoppinsCustomTextStyle.medium.copyWith(
                  fontSize: fontSizeProvider.fontSize, color: AppColor.black),
            ),
          )
        ],
      ),
    );
  }

  Widget resources() {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Container(
      // width: 330,
      height: 280,
      decoration: BoxDecoration(
          color:
              themeManager.isHighContrast ? AppColor.labelText : AppColor.white,
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [
            BoxShadow(
                color: AppColor.greyShadow,
                blurRadius: 15,
                offset: Offset(0, 10))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 28,
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(5),
                          topLeft: Radius.circular(5)),
                      color: AppColor.buttonGreen),
                  child: Text(
                    "resourcesTitle".tr,
                    textAlign: TextAlign.center,
                    style: PoppinsCustomTextStyle.bold.copyWith(
                        fontSize: fontSizeProvider.fontSize,
                        color: AppColor.white),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
                left: selectedLanguage == "en" ? 8 : 0,
                right: selectedLanguage == "en" ? 0 : 8,
                top: 10),
            child: Text(
              "resounceList".tr,
              style: PoppinsCustomTextStyle.medium.copyWith(
                  fontSize: fontSizeProvider.fontSize, color: AppColor.black),
            ),
          )
        ],
      ),
    );
  }

  Widget overallPerformance(bool isMobile) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Column(
      children: [
        topTabbar(),
        Row(
          children: [
            Expanded(
                child: Container(
              height: 50,
              decoration: const BoxDecoration(color: AppColor.buttonGreen),
              child: Padding(
                padding: EdgeInsets.only(
                    left: selectedLanguage == "en" ? 32 : 0,
                    right: selectedLanguage == "en" ? 0 : 32),
                child: Align(
                  alignment: selectedLanguage == "en"
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Text("overallPerformance".tr,
                      style: PoppinsCustomTextStyle.bold.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: AppColor.white)),
                ),
              ),
            ))
          ],
        ),
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
              color: themeManager.isHighContrast
                  ? AppColor.labelText
                  : AppColor.white,
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(5),
                  bottomRight: Radius.circular(5)),
              boxShadow: const [
                BoxShadow(
                    color: AppColor.greyShadow,
                    blurRadius: 15,
                    offset: Offset(0, 10))
              ]),
          child: Padding(
            padding: EdgeInsets.only(
                left: selectedLanguage == "en" ? 25 : 0,
                right: selectedLanguage == "en" ? 0 : 25,
                top: 25),
            child: Text(
              "parentsub".tr,
              style: PoppinsCustomTextStyle.medium.copyWith(
                  fontSize: fontSizeProvider.fontSize, color: AppColor.black),
            ),
          ),
        )
      ],
    );
  }

  Widget topTabbar() {
    return Center(
      child: Row(children: [
        tabTitle('all', ParentFor.all),
        tabTitle('sara', ParentFor.sara)
      ]),
    );
  }

  changeTabAction(ParentFor type) async {
    viewModel.selectedType = type;
    if (viewModel.selectedType == ParentFor.all) {
    } else {}
  }

  tabTitle(text, ParentFor type) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    bool isSelected = type == viewModel.selectedType;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            changeTabAction(type);
            viewModel.selectedType = type;
          });
        },
        child: Container(
          width: 500,
          height: 80,
          decoration: BoxDecoration(
              color: isSelected == true ? AppColor.lightYellow : AppColor.white,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(type == ParentFor.all ? 5 : 0),
                  topRight: Radius.circular(type == ParentFor.all ? 0 : 5))),
          child: Padding(
            padding: EdgeInsets.only(
                left: selectedLanguage == "en" ? 29 : 0,
                right: selectedLanguage == "en" ? 5 : 29),
            child: Row(
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected == true
                          ? AppColor.white
                          : AppColor.lightGrey),
                ),
                const SizedBox(width: 15),
                Text("$text".tr,
                    style: PoppinsCustomTextStyle.bold.copyWith(
                        fontSize: fontSizeProvider.fontSize,
                        color: isSelected == true
                            ? AppColor.white
                            : AppColor.black))
              ],
            ),
          ),
        ),
      ),
    );
  }

  onTap(ParentListType? type) {}
  Widget listItem(ParentModel model, int index) {
    bool isSelected = index == viewModel.selectedIndex;
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15, top: 15),
      child: InkWell(
        onTap: () {
          setState(() {
            onTap(model.type);
            viewModel.selectedIndex = index;
          });
        },
        child: Container(
          height: 73,
          width: 269,
          decoration: BoxDecoration(
              color: isSelected ? AppColor.buttonGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    offset: const Offset(0, 10),
                    blurRadius: 15,
                    color:
                        isSelected ? AppColor.buttonShadow : Colors.transparent)
              ]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 27),
              Image.asset(
                isSelected
                    ? model.colorImage.toString()
                    : model.fillImage.toString(),
                width: 25,
                height: 25,
              ),
              const SizedBox(width: 22),
              Text(
                model.title.toString(),
                style: NotoSansArabicCustomTextStyle.medium.copyWith(
                    fontSize: 18,
                    color: isSelected ? AppColor.white : AppColor.textGrey),
              )
            ],
          ),
        ),
      ),
    );
  }
}
