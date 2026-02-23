import 'package:flutter/material.dart';
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

class RecentUpdateScreen extends StatefulWidget {
  const RecentUpdateScreen({super.key});

  @override
  State<RecentUpdateScreen> createState() => _RecentUpdateScreenState();
}

class _RecentUpdateScreenState extends State<RecentUpdateScreen> {
  ParentService viewModel = ParentService();

  fetchList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    int? code = await viewModel.fetchRecentUpdates(userId ?? "");
    if (code == 200) {
      print("Fetch success recent update list");
    } else {
      print("Recent List Error : ${viewModel.apiError}");
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
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Recent Updates".tr,
                            style: NotoSansArabicCustomTextStyle.bold.copyWith(
                                fontSize: 18,
                                color: themeManager.isHighContrast
                                    ? AppColor.white
                                    : AppColor.buttonGreen),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                            child: viewModel.recentUpdatesList.isEmpty
                                ? Center(child: Text("norecordYet".tr))
                                : ListView.builder(
                                    itemCount:
                                        viewModel.recentUpdatesList.length,
                                    shrinkWrap: true,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Container(
                                          decoration: BoxDecoration(
                                              color: themeManager.isHighContrast
                                                  ? AppColor.labelText
                                                  : AppColor.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                                isMobile
                                                    ? Row(
                                                        children: [
                                                          Text("date".tr,
                                                              style: NotoSansArabicCustomTextStyle
                                                                  .bold
                                                                  .copyWith(
                                                                      fontSize:
                                                                          15,
                                                                      color: AppColor
                                                                          .black)),
                                                          Text(
                                                              "${viewModel.recentUpdatesList[index].date}",
                                                              style: NotoSansArabicCustomTextStyle
                                                                  .regular
                                                                  .copyWith(
                                                                      fontSize:
                                                                          14,
                                                                      color: AppColor
                                                                          .black))
                                                        ],
                                                      )
                                                    : const SizedBox(),
                                                isMobile
                                                    ? const SizedBox(height: 5)
                                                    : const SizedBox(),
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: RichText(
                                                        softWrap: true,
                                                        text: TextSpan(
                                                          children: [
                                                            TextSpan(
                                                              text:
                                                                  "${"subject".tr} : ",
                                                              style: NotoSansArabicCustomTextStyle
                                                                  .bold
                                                                  .copyWith(
                                                                      fontSize:
                                                                          15,
                                                                      color: AppColor
                                                                          .black),
                                                            ),
                                                            TextSpan(
                                                              text:
                                                                  "${viewModel.recentUpdatesList[index].subject}",
                                                              style: NotoSansArabicCustomTextStyle
                                                                  .regular
                                                                  .copyWith(
                                                                      fontSize:
                                                                          14,
                                                                      color: AppColor
                                                                          .black),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    isMobile
                                                        ? const SizedBox()
                                                        : Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    left: 12),
                                                            child: Text(
                                                              "${"date".tr} ${viewModel.recentUpdatesList[index].date}",
                                                              style: NotoSansArabicCustomTextStyle
                                                                  .bold
                                                                  .copyWith(
                                                                      fontSize:
                                                                          15,
                                                                      color: AppColor
                                                                          .black),
                                                            ),
                                                          )
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                RichText(
                                                  softWrap: true,
                                                  text: TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text:
                                                            "${"observation".tr} : ",
                                                        style: NotoSansArabicCustomTextStyle
                                                            .bold
                                                            .copyWith(
                                                                fontSize: 15,
                                                                color: AppColor
                                                                    .black),
                                                      ),
                                                      TextSpan(
                                                        text:
                                                            "${viewModel.recentUpdatesList[index].observation}",
                                                        style: NotoSansArabicCustomTextStyle
                                                            .regular
                                                            .copyWith(
                                                                fontSize: 14,
                                                                color: AppColor
                                                                    .black),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ))
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
