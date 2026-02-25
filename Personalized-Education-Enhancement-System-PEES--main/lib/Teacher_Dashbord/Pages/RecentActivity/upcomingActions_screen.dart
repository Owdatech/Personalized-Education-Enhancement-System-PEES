import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Teacher_Dashbord/Services/teacher_service.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/custom_class/my_appBar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpcomingActionScreen extends StatefulWidget {
  const UpcomingActionScreen({super.key});

  @override
  State<UpcomingActionScreen> createState() => _UpcomingActionScreenState();
}

class _UpcomingActionScreenState extends State<UpcomingActionScreen> {
  TeacherService viewModel = TeacherService();
  String selectedLanguage = Get.locale?.languageCode ?? 'en';

  fetchUpcomingData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? teacherId = prefs.getString('userId');
    int? code =
        await viewModel.fetchUpcomingActions(teacherId ?? "", selectedLanguage);
    if (code == 200) {
      print("Successfully fetch upcoming details");
    } else {
      print("upcoming details Error : ${viewModel.apiError}");
    }
  }

  @override
  void initState() {
    fetchUpcomingData();
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
              backgroundColor: AppColor.bgLavender,
              appBar: PreferredSize(
                  preferredSize: const Size(double.infinity, 50),
                  child: isMobile ? MyAppBar("") : const SizedBox()),
              body: Stack(
                children: [
                  isMobile ? const SizedBox() : const BackButtonWidget(),
                  Padding(
                    padding: EdgeInsets.only(
                        top: isMobile ? 5 : 30,
                        left: isMobile ? 12 : 100,
                        right: isMobile ? 12 : 30),
                    child: Column(
                      children: [
                        const SizedBox(height: 5),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "upcomingActions".tr,
                            style: NotoSansArabicCustomTextStyle.bold.copyWith(
                                fontSize: 18,
                                color: themeManager.isHighContrast
                                    ? AppColor.white
                                    : AppColor.buttonGreen),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: viewModel.upcomingActions.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: AppColor.panelDarkSoft,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: AppColor.greyShadow,
                                            blurRadius: 5,
                                            offset: Offset(0, 5))
                                      ]),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            viewModel.upcomingActions[index]
                                                ["name"],
                                            style: NotoSansArabicCustomTextStyle
                                                .semibold
                                                .copyWith(
                                                    fontSize: 14,
                                                    color: AppColor.black)),
                                        const SizedBox(height: 5),
                                        InkWell(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: Text(
                                                      viewModel.upcomingActions[
                                                          index]["name"],
                                                      style: NotoSansArabicCustomTextStyle
                                                          .semibold
                                                          .copyWith(
                                                              fontSize: 15,
                                                              color: themeManager
                                                                      .isHighContrast
                                                                  ? AppColor
                                                                      .white
                                                                  : AppColor
                                                                      .black),
                                                    ),
                                                    content:
                                                        SingleChildScrollView(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: (viewModel.upcomingActions[
                                                                        index]
                                                                    ["details"]
                                                                as Map<String,
                                                                    dynamic>)
                                                            .entries
                                                            .where((entry) =>
                                                                (entry.value
                                                                        as List)
                                                                    .isNotEmpty)
                                                            .map((entry) {
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    bottom: 8),
                                                            child: Text(
                                                              "${entry.key.replaceAll('_', ' ').toUpperCase()}:\n${(entry.value as List).join("\n")}",
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          14),
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        child:
                                                            Text("cancel".tr),
                                                      )
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            child: Text(
                                              "viewDetails".tr,
                                              style:
                                                  NotoSansArabicCustomTextStyle
                                                      .semibold
                                                      .copyWith(
                                                          fontSize: 13,
                                                          color: AppColor
                                                              .buttonGreen),
                                            ))
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  viewModel.loading ? const LoaderView() : Container()
                ],
              ),
            );
          });
        }));
  }
}
