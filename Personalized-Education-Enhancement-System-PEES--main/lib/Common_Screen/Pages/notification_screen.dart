import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pees/Common_Screen/Model/alert_model.dart';
import 'package:pees/Common_Screen/Pages/notification_setting.dart';
import 'package:pees/Common_Screen/Services/common_service.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/AppImage.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/custom_class/my_appBar.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationScreen extends StatefulWidget {
  String? name;
  NotificationScreen({this.name, super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  CommonService viewModel = CommonService();
  String selectedLanguage = Get.locale?.languageCode ?? 'en';
  bool isShow = false;
  String? userId;
  List<NotificationModel> notifications = [];
  int? expandedIndex;

  notificationSettingAction() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const NotiificationSettingScreen()));
  }

  Future<void> _fetchNot() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    try {
      List<NotificationModel> fetchedNotifications =
          await viewModel.fetchNotifications(userId ?? "");
      setState(() {
        notifications = fetchedNotifications;
      });
    } catch (e) {
      setState(() {
        print("User Notification : $e");
      });
    }
  }

  String formatDate(String dateString) {
    DateTime parsedDate =
        DateTime.parse(dateString); // Parse the string into DateTime
    return DateFormat('dd-MM-yyyy')
        .format(parsedDate); // Format it as dd-MM-yyyy
  }

  statusapicall(String notificationId) async {
    int? code = await viewModel.statusApi(notificationId);
    if (code == 200) {
      print("Successfully notification status");
      // ignore: use_build_context_synchronously
      // Navigator.pop(context, true);
      _fetchNot();
    } else {
      print("Error : ${viewModel.apiError}");
    }
  }

  @override
  void initState() {
    _fetchNot();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return ChangeNotifierProvider<CommonService>(
        create: (BuildContext context) => viewModel,
        child: Consumer<CommonService>(builder: (context, value, _) {
          return LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth <= 800;
            return Scaffold(
                body: Stack(
              children: [
                MyAppBar(widget.name),
                isMobile
                    ? SizedBox()
                    : Align(
                        alignment: selectedLanguage == "en"
                            ? Alignment.topLeft
                            : Alignment.topRight,
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: selectedLanguage == "en" ? 20 : 0,
                              top: 20,
                              right: selectedLanguage == "en" ? 0 : 20),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context, true);
                            },
                            child: Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColor.black, width: 0.2),
                                    color: AppColor.white),
                                child: const Padding(
                                  padding: EdgeInsets.all(5.0),
                                  child: Icon(Icons.arrow_back,
                                      size: 30, color: AppColor.black),
                                )),
                          ),
                        )),
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: double.infinity,
                            child: notifications.isEmpty
                                ? Center(child: Text("norecordYet".tr))
                                : ListView.builder(
                                    itemCount: notifications.length,
                                    itemBuilder: (context, index) {
                                      final notification = notifications[index];
                                      return listItem(
                                          context, notification, isMobile);
                                    },
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                viewModel.loading ? const LoaderView() : Container()
              ],
            ));
          });
        }));
  }

  Widget listItem(
      BuildContext context, NotificationModel model, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(
        onTap: () {
          print("Opening Dialog...");
          showDialog(
            context: context, // Ensure the correct context is used
            barrierDismissible:
                true, // Allows closing the dialog by tapping outside
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10), // Rounded corners for dialog
                ),
                content: Column(
                  mainAxisSize: MainAxisSize
                      .min, // Ensures the dialog only takes necessary space
                  children: [
                    Text(
                      model.description,
                      textAlign: TextAlign.start,
                      style: NotoSansArabicCustomTextStyle.regular.copyWith(
                        fontSize: 15,
                        color: AppColor.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        statusapicall(model.id); // Call API
                        Navigator.pop(dialogContext); // Close dialog
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.buttonGreen,
                      ),
                      child: const Text("OK",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Container(
          height: 70,
          decoration: BoxDecoration(
              color:
                  model.status == true ? AppColor.white : Colors.green.shade100,
              borderRadius: BorderRadius.circular(5),
              boxShadow: const [
                BoxShadow(
                    color: AppColor.blueShadow,
                    offset: Offset(0, 10),
                    blurRadius: 15)
              ]),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            model.type == "alert"
                                ? AppImage.error
                                : AppImage.messageIcon,
                            width: 30,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(model.title.toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: NotoSansArabicCustomTextStyle.medium
                                    .copyWith(
                                        color: AppColor.black, fontSize: 13)),
                          )
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(model.date.toString(),
                          style: NotoSansArabicCustomTextStyle.medium
                              .copyWith(color: AppColor.black, fontSize: 13)),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            model.type == "alert"
                                ? AppImage.error
                                : AppImage.messageIcon,
                            width: 30,
                          ),
                          const SizedBox(width: 15),
                          Text(model.title.toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: NotoSansArabicCustomTextStyle.medium
                                  .copyWith(
                                      color: AppColor.black, fontSize: 13))
                        ],
                      ),
                      Text(model.date.toString(),
                          style: NotoSansArabicCustomTextStyle.medium
                              .copyWith(color: AppColor.black, fontSize: 13)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // int? selectedIndex;
  // Widget notificationListItem(int index) {
  //   bool isShow = selectedIndex == index;
  //   return Padding(
  //     padding: const EdgeInsets.only(top: 12),
  //     child: Column(
  //       children: [
  //         Container(
  //           height: 50,
  //           decoration: BoxDecoration(
  //               color: AppColor.white,
  //               borderRadius: BorderRadius.circular(5),
  //               boxShadow: const [
  //                 BoxShadow(
  //                     color: AppColor.blueShadow,
  //                     offset: Offset(0, 10),
  //                     blurRadius: 15)
  //               ]),
  //           child: Column(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Row(children: [
  //                     const SizedBox(width: 20),
  //                     Image.asset(
  //                       viewModel.alertsList[index].typeOfAlert == "Warning"
  //                           ? AppImage.error
  //                           : AppImage.messageIcon,
  //                       width: 30,
  //                     ),
  //                     const SizedBox(width: 15),
  //                     Text(viewModel.alertsList[index].message,
  //                         style: NotoSansArabicCustomTextStyle.medium
  //                             .copyWith(color: AppColor.black, fontSize: 13)),
  //                   ]),
  //                   Text(viewModel.alertsList[index].date,
  //                       style: NotoSansArabicCustomTextStyle.medium
  //                           .copyWith(color: AppColor.black, fontSize: 13)),
  //                   Text(
  //                     viewModel.alertsList[index].isSeen,
  //                     style: NotoSansArabicCustomTextStyle.medium
  //                         .copyWith(color: AppColor.black, fontSize: 13),
  //                   ),
  //                   Padding(
  //                     padding: const EdgeInsets.only(right: 15),
  //                     child: InkWell(
  //                         onTap: () {
  //                           setState(() {
  //                             isShow = !isShow;
  //                             selectedIndex = index;
  //                           });
  //                         },
  //                         child: Image.asset(AppImage.arrowDown, width: 30)),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //         isShow == true
  //             ? Align(
  //                 alignment: Alignment.center,
  //                 child: Container(
  //                   height: 203,
  //                   decoration: const BoxDecoration(
  //                       color: AppColor.white,
  //                       borderRadius: BorderRadius.only(
  //                         bottomLeft: Radius.circular(5),
  //                         bottomRight: Radius.circular(5),
  //                       ),
  //                       boxShadow: [
  //                         BoxShadow(
  //                             color: AppColor.blueShadow,
  //                             offset: Offset(0, 10),
  //                             blurRadius: 15)
  //                       ]),
  //                   child: Stack(
  //                     children: [
  //                       Padding(
  //                         padding: const EdgeInsets.only(left: 25, top: 10),
  //                         child: Text(
  //                           "Full Message: Detailed information.",
  //                           style: NotoSansArabicCustomTextStyle.medium
  //                               .copyWith(fontSize: 13, color: AppColor.black),
  //                         ),
  //                       ),
  //                       Align(
  //                         alignment: Alignment.bottomRight,
  //                         child: Padding(
  //                           padding:
  //                               const EdgeInsets.only(bottom: 20, right: 20),
  //                           child: AppFillButton3(
  //                               onPressed: () {
  //                                 setState(() {
  //                                   isShow = false;
  //                                 });
  //                               },
  //                               text: "Actions",
  //                               color: AppColor.buttonGreen),
  //                         ),
  //                       )
  //                     ],
  //                   ),
  //                 ),
  //               )
  //             : SizedBox()
  //       ],
  //     ),
  //   );
  // }
}
