// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/API_SERVICES/preference_manager.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/HeadMaster_Dashboard/Model/headMaster_model.dart';
import 'package:pees/HeadMaster_Dashboard/Pages/reports_screen.dart';
import 'package:pees/HeadMaster_Dashboard/Pages/userManagement.dart';
import 'package:pees/HeadMaster_Dashboard/Services/headMaster_services.dart';
import 'package:pees/Models/user_model.dart';
import 'package:pees/Parent_Dashboard/Pages/alerts&Noti_Screen.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class MasterDashboard extends StatefulWidget {
  const MasterDashboard({super.key});

  @override
  State<MasterDashboard> createState() => _MasterDashboardState();
}

class _MasterDashboardState extends State<MasterDashboard> {
  HeadMasterServices viewModel = HeadMasterServices();
  String? userId;

  List<dynamic> metrics = [];
  Future<void> fetchPerformanceData() async {
    final response = await http
        .get(Uri.parse('https://pees.ddnsking.com/api/school-performance'));

    if (response.statusCode == 200) {
      setState(() {
        metrics = json.decode(response.body)['metrics'];
        print("Martics : $metrics");
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  void initState() {
    fetchPerformanceData();
    loadUser();
    super.initState();
  }

  loadUser() async {
    AIUser? users = await PreferencesManager.shared.loadUser();
    userId = users?.userId;
    print("User Ids : ${users?.userId}");
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
                  Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: isMobile ? 12 : 20,
                                  right: isMobile ? 12 : 20,
                                  top: isMobile ? 12 : 20),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    schoolPerformance(isMobile),
                                    const SizedBox(height: 40),
                                    isMobile
                                        ? Column(
                                            children: [
                                              recentActivity(
                                                "userManagement",
                                                () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              const UserManagementScreen()));
                                                },
                                              ),

                                              // userManagement(isMobile),
                                              const SizedBox(height: 10),
                                              recentActivity(
                                                "reports",
                                                () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              const ReposrtsScreen()));
                                                },
                                              ),
                                              // reports(),
                                              const SizedBox(height: 10),
                                              // alertsAndNotification(),
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
                                              const SizedBox(height: 70),
                                            ],
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                  flex: 1,
                                                  child:
                                                      userManagement(isMobile)),
                                              const SizedBox(width: 15),
                                              Expanded(
                                                  flex: 1,
                                                  child: recentActivity(
                                                    "reports",
                                                    () {
                                                      Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  const ReposrtsScreen()));
                                                    },
                                                  )),
                                              const SizedBox(width: 15),
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
                  value.loading ? LoaderView() : Container()
                ],
              ),
            );
          });
        }));
  }

  Widget recentActivity(String title, VoidCallback onPressed) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return InkWell(
      onTap: () {
        onPressed();
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

  Widget userManagement(bool isMobile) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return InkWell(
      onTap: () {
        final headMasterServices =
            Provider.of<HeadMasterServices>(context, listen: false);
        headMasterServices.selectedIndex = 2; // Set index for User Management
        headMasterServices.notifyListeners();
      },
      child: Container(
        // width: 330,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "userManagement".tr,
              textAlign: TextAlign.center,
              style: NotoSansArabicCustomTextStyle.medium.copyWith(
                  fontSize: fontSizeProvider.fontSize, color: AppColor.black),
            ),
          ],
        ),
      ),
    );
  }

  // Widget userManagement(bool isMobile) {
  //   final fontSizeProvider = Provider.of<FontSizeProvider>(context);
  //   final themeManager = Provider.of<ThemeManager>(context, listen: false);
  //   return Container(
  //     // width: 330,
  //     height: 280,
  //     decoration: BoxDecoration(
  //         color:
  //             themeManager.isHighContrast ? AppColor.labelText : AppColor.white,
  //         borderRadius: BorderRadius.circular(5),
  //         boxShadow: const [
  //           BoxShadow(
  //               color: AppColor.greyShadow,
  //               blurRadius: 15,
  //               offset: Offset(0, 10))
  //         ]),
  //     child: Column(
  //       children: [
  //         Row(
  //           children: [
  //             Expanded(
  //               child: Container(
  //                 // height: 28,
  //                 decoration: const BoxDecoration(
  //                     borderRadius: BorderRadius.only(
  //                         topRight: Radius.circular(5),
  //                         topLeft: Radius.circular(5)),
  //                     color: AppColor.buttonGreen),
  //                 child: Padding(
  //                   padding: const EdgeInsets.only(top: 5, bottom: 5),
  //                   child: Text(
  //                     "userManagement".tr,
  //                     textAlign: TextAlign.center,
  //                     style: PoppinsCustomTextStyle.bold.copyWith(
  //                         fontSize: fontSizeProvider.fontSize,
  //                         color: AppColor.white),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         Padding(
  //           padding: const EdgeInsets.only(left: 8, top: 10),
  //           child: Column(
  //             children: [
  //               Text(
  //                 "userManagesubList".tr,
  //                 style: PoppinsCustomTextStyle.medium.copyWith(
  //                     fontSize: fontSizeProvider.fontSize,
  //                     color: AppColor.black),
  //               ),
  //               const SizedBox(height: 10),
  //               isMobile
  //                   ? AppFillButton2(
  //                       onPressed: () {
  //                         Navigator.push(
  //                             context,
  //                             MaterialPageRoute(
  //                                 builder: (context) =>
  //                                     UserManagementScreen()));
  //                       },
  //                       text: "userMange")
  //                   : AppFillButton2(
  //                       onPressed: () {
  //                         final headMasterServices =
  //                             Provider.of<HeadMasterServices>(context,
  //                                 listen: false);
  //                         headMasterServices.selectedIndex =
  //                             2; // Set index for User Management
  //                         headMasterServices.notifyListeners();
  //                         // Navigator.push(
  //                         //     context,
  //                         //     MaterialPageRoute(
  //                         //         builder: (context) => UserManagementScreen()));
  //                       },
  //                       text: "userMange")
  //             ],
  //           ),
  //         )
  //       ],
  //     ),
  //   );
  // }

  Widget reports() {
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
                  // height: 28,
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(5),
                          topLeft: Radius.circular(5)),
                      color: AppColor.buttonGreen),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 5),
                    child: Text(
                      "reports".tr,
                      textAlign: TextAlign.center,
                      style: PoppinsCustomTextStyle.bold.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: AppColor.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 10),
            child: Text(
              "reportssubList".tr,
              style: PoppinsCustomTextStyle.medium.copyWith(
                  fontSize: fontSizeProvider.fontSize, color: AppColor.black),
            ),
          )
        ],
      ),
    );
  }

  Widget alertsAndNotification() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
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
                  // height: 28,
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(5),
                          topLeft: Radius.circular(5)),
                      color: AppColor.buttonGreen),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 5),
                    child: Text(
                      "alerts&Noti".tr,
                      textAlign: TextAlign.center,
                      style: PoppinsCustomTextStyle.bold.copyWith(
                          fontSize: fontSizeProvider.fontSize,
                          color: AppColor.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 10),
            child: Text(
              "subAlert".tr,
              style: PoppinsCustomTextStyle.medium.copyWith(
                  fontSize: fontSizeProvider.fontSize, color: AppColor.black),
            ),
          )
        ],
      ),
    );
  }

  Widget schoolPerformance(bool isMobile) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Column(
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
                padding: const EdgeInsets.only(left: 32, top: 8, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("schoolperfo".tr,
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
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              itemCount: metrics.length,
              itemBuilder: (context, index) {
                final item = metrics[index];
                final grade = item['grade'] ?? 'Unknown';
                final subjects = item['subjects'] as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    decoration: BoxDecoration(
                        color: AppColor.white,
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: const [
                          BoxShadow(
                              blurRadius: 5,
                              color: AppColor.greyShadow,
                              offset: Offset(0, 5))
                        ]),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Text('${"grade".tr} : ',
                                  style: NotoSansArabicCustomTextStyle.semibold
                                      .copyWith(
                                          fontSize: 15, color: AppColor.black)),
                              Text('$grade',
                                  style: NotoSansArabicCustomTextStyle.regular
                                      .copyWith(
                                          fontSize: 15, color: AppColor.black)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${"subject".tr} : ',
                                  style: NotoSansArabicCustomTextStyle.semibold
                                      .copyWith(
                                          fontSize: 15, color: AppColor.black)),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: subjects.entries
                                      .map((e) => Text(
                                          "${e.key} - ${"Average Grade"} : ${e.value} "))
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                          // const SizedBox(height: 5),
                          // Row(
                          //   crossAxisAlignment: CrossAxisAlignment.start,
                          //   children: [
                          //     Text('${"Average Grade"} : ',
                          //         style: NotoSansArabicCustomTextStyle.semibold
                          //             .copyWith(
                          //                 fontSize: 15, color: AppColor.black)),
                          //     const SizedBox(width: 5),
                          //     Column(
                          //       crossAxisAlignment: CrossAxisAlignment.start,
                          //       children: subjects.entries
                          //           .map((e) => Text("${e.value}"))
                          //           .toList(),
                          //     ),
                          //   ],
                          // ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        )
      ],
    );
  }

  onTap(HeadMasterListType? type) {}
  Widget listItem(HeadMasterModel model, int index) {
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
