import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/Parent_Dashboard/Pages/alerts&Noti_Screen.dart';
import 'package:pees/Teacher_Dashbord/Pages/RecentActivity/upcomingActions_screen.dart';
import 'package:pees/Teacher_Dashbord/Services/teacher_service.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  TeacherService viewModel = TeacherService();
  List<String> list = ["", "", "", "", ""];
  String selectedLanguage = Get.locale?.languageCode ?? 'en';

  fetchClassDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    int? code = await viewModel.fetchClassDetails(userId ?? "");
    if (code == 200) {
      print("Successfully fetch class details");
    } else {
      print("Class details Error : ${viewModel.apiError}");
    }
  }

  @override
  void initState() {
    fetchClassDetails();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return ChangeNotifierProvider<TeacherService>(
        create: (BuildContext context) => viewModel,
        child: Consumer<TeacherService>(builder: (context, value, _) {
          return LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth <= 800;
            return Scaffold(
              backgroundColor: AppColor.panelDark,
              body: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            // height: MediaQuery.of(context).size.height,
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: isMobile ? 12 : 20,
                                  right: isMobile ? 12 : 20,
                                  top: isMobile ? 12 : 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  classTable(isMobile),
                                  const SizedBox(height: 30),
                                  isMobile
                                      ? Column(
                                          children: [
                                            recentActivity("recentsAlerts", () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          AlertsNotificationScreen(
                                                              isAlerts: true)));
                                            }),
                                            const SizedBox(height: 20),
                                            recentActivity("upcomingActions",
                                                () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          const UpcomingActionScreen()));
                                            }),
                                            const SizedBox(height: 100),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              flex: 1,
                                              child: recentActivity(
                                                  "recentsAlerts", () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            AlertsNotificationScreen(
                                                                isAlerts:
                                                                    true)));
                                              }),
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              flex: 1,
                                              child: recentActivity(
                                                  "upcomingActions", () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const UpcomingActionScreen()));
                                              }),
                                            )
                                          ],
                                        ),
                                  const SizedBox(height: 100)
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                  value.loading ? const LoaderView() : Container()
                ],
              ),
            );
          });
        }));
  }

  Widget recentActivity(String title, Function() onTap) {
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
            color: AppColor.panelDarkSoft),
        child: Center(
            child: Text(
          title.tr,
          style: NotoSansArabicCustomTextStyle.medium.copyWith(
              fontSize: fontSizeProvider.fontSize, color: AppColor.text),
        )),
      ),
    );
  }

  Widget recentAlerts() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Container(
      // width: 450,
      height: 280,
      decoration: BoxDecoration(
          color: AppColor.panelDarkSoft,
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [
            BoxShadow(
                color: AppColor.greyShadow,
                blurRadius: 15,
                offset: Offset(0, 10))
          ]),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton(
                onPressed: () {},
                child: Text(
                  "viewall".tr,
                  style: PoppinsCustomTextStyle.medium.copyWith(
                      fontSize: fontSizeProvider.fontSize,
                      color: AppColor.accentPrimary),
                )),
          ),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      // height: 28,
                      decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                              topRight: Radius.circular(5),
                              topLeft: Radius.circular(5)),
                          color: AppColor.buttonGreen),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5, bottom: 5),
                        child: Text(
                          "recentsAlerts".tr,
                          textAlign: TextAlign.center,
                          style: PoppinsCustomTextStyle.bold.copyWith(
                              fontSize: fontSizeProvider.fontSize + 1,
                              color: AppColor.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: viewModel.recentsAlertsList.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                          left: selectedLanguage == 'en' ? 13 : 0,
                          top: 12,
                          bottom: 15,
                          right: selectedLanguage == 'en' ? 0 : 13),
                      child: Text(
                        viewModel.recentsAlertsList[index],
                        style: PoppinsCustomTextStyle.medium.copyWith(
                            fontSize: fontSizeProvider.fontSize,
                            color: AppColor.text),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget upcomingActions() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Container(
      // width: 450,
      height: 280,
      decoration: BoxDecoration(
          color: AppColor.panelDarkSoft,
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
                  // height: 28,
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(5),
                          topLeft: Radius.circular(5)),
                      color: AppColor.buttonGreen),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 5),
                    child: Text(
                      "upcomingActions".tr,
                      textAlign: TextAlign.center,
                      style: PoppinsCustomTextStyle.bold.copyWith(
                          fontSize: fontSizeProvider.fontSize + 1,
                          color: AppColor.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: viewModel.upComingAletsList.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                      left: selectedLanguage == 'en' ? 13 : 0,
                      top: 12,
                      bottom: 10,
                      right: selectedLanguage == 'en' ? 0 : 13),
                  child: Text(
                    viewModel.upComingAletsList[index],
                    style: PoppinsCustomTextStyle.medium.copyWith(
                        fontSize: fontSizeProvider.fontSize,
                        color: AppColor.text),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget classTable(bool isMobile) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: Container(
              // height: 50,
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5)),
                  color: AppColor.buttonGreen),
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text("className".tr,
                          textAlign: selectedLanguage == "en"
                              ? TextAlign.left
                              : TextAlign.right,
                          style: PoppinsCustomTextStyle.bold.copyWith(
                              fontSize: fontSizeProvider.fontSize + 1,
                              color: AppColor.white)),
                    ),
                    Expanded(
                      child: Text(
                        "numberofStudents".tr,
                        textAlign: TextAlign.center,
                        style: PoppinsCustomTextStyle.bold.copyWith(
                            fontSize: fontSizeProvider.fontSize + 1,
                            color: AppColor.white),
                      ),
                    ),
                  ],
                ),
              ),
            ))
          ],
        ),
        Container(
          // height: 300,
          decoration: BoxDecoration(
            color: AppColor.panelDarkSoft,
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(5),
                bottomRight: Radius.circular(5)),
            border: Border.all(color: AppColor.lightGrey, width: 0.8),
            boxShadow: const [
              BoxShadow(
                  color: AppColor.greyShadow,
                  offset: Offset(0, 10),
                  blurRadius: 15)
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              viewModel.classGradeList.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                          child: Text("norecordYet".tr,
                              style: NotoSansArabicCustomTextStyle.medium
                                  .copyWith(color: AppColor.text))),
                    )
                  : ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: viewModel.classGradeList.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 1.2),
                          child: Row(
                            children: [
                              Expanded(
                                flex: isMobile ? 5 : 4,
                                child: Container(
                                  height: 35,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColor.panelDark,
                                    // borderRadius: BorderRadius.only(
                                    //     bottomLeft: Radius.circular(
                                    //         index == list.length - 1 ? 5 : 0))
                                  ),
                                  child: Align(
                                    alignment: selectedLanguage == 'en'
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          left:
                                              selectedLanguage == "en" ? 10 : 0,
                                          right: selectedLanguage == "en"
                                              ? 0
                                              : 10),
                                      child: Text(
                                        "${viewModel.classGradeList[index].gradeName}",
                                        style: NotoSansArabicCustomTextStyle
                                            .regular
                                            .copyWith(
                                                fontSize: 15,
                                                color: AppColor.text),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 1.2),
                              Expanded(
                                child: Container(
                                  height: 35,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColor.panelDark,
                                    // borderRadius: BorderRadius.only(
                                    //     bottomRight: Radius.circular(
                                    //         index == list.length - 1 ? 5 : 0)
                                    //         )
                                  ),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      "${viewModel.classGradeList[index].studentCount}",
                                      style: NotoSansArabicCustomTextStyle
                                          .regular
                                          .copyWith(
                                              fontSize: 15,
                                              color: AppColor.text),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    )
            ],
          ),
        ),
      ],
    );
  }

  // Widget tableList(int index, bool isMobile) {
  //   final themeManager = Provider.of<ThemeManager>(context, listen: false);
  //   return
  // }
}
