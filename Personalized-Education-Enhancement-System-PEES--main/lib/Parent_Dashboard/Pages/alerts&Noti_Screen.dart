import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Parent_Dashboard/Services/parent_services.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/custom_class/my_appBar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlertsNotificationScreen extends StatefulWidget {
  bool? isAlerts = false;
  AlertsNotificationScreen({this.isAlerts, super.key});

  @override
  State<AlertsNotificationScreen> createState() =>
      _AlertsNotificationScreenState();
}

class _AlertsNotificationScreenState extends State<AlertsNotificationScreen> {
  ParentService viewModel = ParentService();

  fetchNotification() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    int? code = await viewModel.fetchAlertsNotification(userId ?? "");
    if (code == 200) {
      print("Fetch success notification list");
    } else {
      print("Notification List Error : ${viewModel.apiError}");
    }
  }

  String formatDate(String dateString) {
    DateTime parsedDate =
        DateTime.parse(dateString); // Parse the string into DateTime
    return DateFormat('dd-MM-yyyy')
        .format(parsedDate); // Format it as dd-MM-yyyy
  }

  @override
  void initState() {
    // TODO: implement initState
    fetchNotification();
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
                            widget.isAlerts == true
                                ? "recentsAlerts".tr
                                : "alerts&Noti".tr,
                            style: NotoSansArabicCustomTextStyle.bold.copyWith(
                                fontSize: 18,
                                color: themeManager.isHighContrast
                                    ? AppColor.white
                                    : AppColor.buttonGreen),
                          ),
                        ),
                        const SizedBox(height: 10),
                        viewModel.alertsList.isEmpty &&
                                viewModel.notificationsList.isEmpty
                            ? Center(
                                child: Text("norecordYet".tr),
                              )
                            : Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      viewModel.alertsList.isEmpty
                                          ? Center(
                                              child: Text("norecordYet".tr),
                                            )
                                          : ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              primary: false,
                                              itemCount:
                                                  viewModel.alertsList.length,
                                              itemBuilder: (context, index) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 7),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        color: themeManager
                                                                .isHighContrast
                                                            ? AppColor.labelText
                                                            : AppColor.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        boxShadow: const [
                                                          BoxShadow(
                                                              color: AppColor
                                                                  .greyShadow,
                                                              blurRadius: 5,
                                                              offset:
                                                                  Offset(0, 5))
                                                        ]),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Column(
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Text("date".tr,
                                                                  style: NotoSansArabicCustomTextStyle
                                                                      .bold
                                                                      .copyWith(
                                                                          fontSize:
                                                                              15,
                                                                          color:
                                                                              AppColor.black)),
                                                              Text(
                                                                  formatDate(
                                                                      "${viewModel.alertsList[index].date}"),
                                                                  style: NotoSansArabicCustomTextStyle
                                                                      .regular
                                                                      .copyWith(
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              AppColor.black))
                                                            ],
                                                          ),
                                                          SizedBox(height: 7),
                                                          Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                  "${"message".tr} : ",
                                                                  style: NotoSansArabicCustomTextStyle
                                                                      .bold
                                                                      .copyWith(
                                                                          fontSize:
                                                                              15,
                                                                          color:
                                                                              AppColor.black)),
                                                              Expanded(
                                                                child: Text(
                                                                    "${viewModel.alertsList[index].aiGeneratedMessage}",
                                                                    // maxLines: 2,
                                                                    // overflow: TextOverflow.ellipsis,
                                                                    style: NotoSansArabicCustomTextStyle
                                                                        .regular
                                                                        .copyWith(
                                                                            fontSize:
                                                                                14,
                                                                            color:
                                                                                AppColor.black)),
                                                              ),
                                                            ],
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                      SizedBox(height: 5),
                                      widget.isAlerts == true
                                          ? SizedBox()
                                          : viewModel.notificationsList.isEmpty
                                              ? Center(
                                                  child: Text("norecordYet".tr),
                                                )
                                              : ListView.builder(
                                                  itemCount: viewModel
                                                      .notificationsList.length,
                                                  shrinkWrap: true,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  primary: false,
                                                  itemBuilder:
                                                      (context, index) {
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 7),
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                            color: themeManager
                                                                    .isHighContrast
                                                                ? AppColor.labelText
                                                                : AppColor.white,
                                                            borderRadius: BorderRadius.circular(8),
                                                            boxShadow: const [
                                                              BoxShadow(
                                                                  color: AppColor
                                                                      .greyShadow,
                                                                  blurRadius: 5,
                                                                  offset:
                                                                      Offset(
                                                                          0, 5))
                                                            ]),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Column(
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                      "date".tr,
                                                                      style: NotoSansArabicCustomTextStyle.bold.copyWith(
                                                                          fontSize:
                                                                              15,
                                                                          color:
                                                                              AppColor.black)),
                                                                  Text(
                                                                      formatDate(
                                                                          "${viewModel.notificationsList[index].createdAt}"),
                                                                      style: NotoSansArabicCustomTextStyle.regular.copyWith(
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              AppColor.black))
                                                                ],
                                                              ),
                                                              SizedBox(
                                                                  height: 7),
                                                              Row(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                      "${"message".tr} : ",
                                                                      style: NotoSansArabicCustomTextStyle.bold.copyWith(
                                                                          fontSize:
                                                                              15,
                                                                          color:
                                                                              AppColor.black)),
                                                                  Expanded(
                                                                    child: Text(
                                                                        "${viewModel.notificationsList[index].title}",
                                                                        // maxLines: 2,
                                                                        // overflow: TextOverflow.ellipsis,
                                                                        style: NotoSansArabicCustomTextStyle.regular.copyWith(
                                                                            fontSize:
                                                                                14,
                                                                            color:
                                                                                AppColor.black)),
                                                                  ),
                                                                ],
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                      SizedBox(height: 50),
                                    ],
                                  ),
                                ),
                              ),
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
