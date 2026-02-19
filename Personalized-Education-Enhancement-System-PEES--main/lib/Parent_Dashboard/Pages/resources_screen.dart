import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Parent_Dashboard/Services/parent_services.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/custom_class/my_appBar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  ParentService viewModel = ParentService();
  String selectedLanguage = Get.locale?.languageCode ?? 'en';

  fetchList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    int? code = await viewModel.fetchResources(userId ?? "", selectedLanguage);
    if (code == 200) {
      print("Fetch success resource list");
    } else {
      print("Resource List Error : ${viewModel.apiError}");
    }
  }

  @override
  void initState() {
    fetchList();
    // TODO: implement initState
    super.initState();
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
                          alignment: selectedLanguage == "en"
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: Text(
                            "resourcesTitle".tr,
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
                          itemCount: viewModel.students.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            final student = viewModel.students[index];
                            final studentId = student["student_id"];
                            final studentName = student["name"];
                            final studentGrade = student["grade"];
                            final subjectData = student["subjects"] ?? {};
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                    color: themeManager.isHighContrast
                                        ? AppColor.labelText
                                        : AppColor.white,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text("name".tr,
                                              style:
                                                  NotoSansArabicCustomTextStyle
                                                      .semibold
                                                      .copyWith(
                                                          fontSize: 17,
                                                          color:
                                                              AppColor.black)),
                                          Text("$studentName",
                                              style:
                                                  NotoSansArabicCustomTextStyle
                                                      .semibold
                                                      .copyWith(
                                                          fontSize: 17,
                                                          color:
                                                              AppColor.black)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text("grade".tr,
                                              style:
                                                  NotoSansArabicCustomTextStyle
                                                      .semibold
                                                      .copyWith(
                                                          fontSize: 15,
                                                          color:
                                                              AppColor.black)),
                                          const SizedBox(width: 7),
                                          Text("$studentGrade",
                                              style:
                                                  NotoSansArabicCustomTextStyle
                                                      .regular
                                                      .copyWith(
                                                          fontSize: 15,
                                                          color:
                                                              AppColor.black)),
                                        ],
                                      ),
                                      if (subjectData.isNotEmpty)
                                        ...subjectData.entries.map((entry) {
                                          String subjectName = entry.key;
                                          var subjectDetails = entry.value;
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 8),
                                              Text(
                                                "$subjectName: ${subjectDetails['grade']} (${subjectDetails['marks']} marks)",
                                                style:
                                                    NotoSansArabicCustomTextStyle
                                                        .regular
                                                        .copyWith(
                                                            color:
                                                                AppColor.black,
                                                            fontSize: 13),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      if (viewModel.recommendations
                                          .containsKey(studentId))
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "recommendations".tr,
                                                style:
                                                    NotoSansArabicCustomTextStyle
                                                        .bold
                                                        .copyWith(
                                                            color:
                                                                AppColor.black,
                                                            fontSize: 15),
                                              ),
                                              MarkdownBody(
                                                  data:
                                                      "${viewModel.recommendations[studentId]['recommendations']}")
                                            ],
                                          ),
                                        ),
                                      const SizedBox(height: 30),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )),
                      ],
                    ),
                  ),
                  value.loading ? const LoaderView() : Container(),
                ],
              ),
            );
          });
        }));
  }
}
