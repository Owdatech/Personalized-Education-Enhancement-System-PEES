import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/Authentication/Page/login_screen.dart';
import 'package:pees/Authentication/Services/auth_service.dart';
import 'package:pees/Common_Screen/Pages/notification_screen.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/HeadMaster_Dashboard/Services/headMaster_services.dart';
import 'package:pees/Models/profile_model.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/AppImage.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/Widgets/utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyAppBar extends StatefulWidget {
  String? userName;
  MyAppBar(this.userName, {super.key});

  @override
  State<MyAppBar> createState() => _MyAppBarState();
}

class _MyAppBarState extends State<MyAppBar> {
  AuthVM viewModel = AuthVM();
  HeadMasterServices masterViewModel = HeadMasterServices();
  String? userName;
  ProfileModel? model;

  fetchProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    ProfileModel? profileModel =
        await masterViewModel.getProfileApicall(userId ?? "");
    if (profileModel != null) {
      model = profileModel;
       Provider.of<UserProvider>(context, listen: false)
        .setUserName(profileModel.user.name ?? "");
      // setState(() {
      //   userName = model?.user.name ?? "";
      // });
    }
  }

  @override
  void initState() {
    fetchProfileData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String userName = Provider.of<UserProvider>(context).userName;
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth <= 800;
      return isMobile
          ? Scaffold(
              appBar: AppBar(
                iconTheme: const IconThemeData(color: AppColor.white),
                backgroundColor: AppColor.buttonGreen,
                centerTitle: true,
                title: Text("${"welcome".tr},${userName ?? ""}!",
                    style: PoppinsCustomTextStyle.bold
                        .copyWith(fontSize: 15, color: AppColor.white)),
                actions: [
                  Row(
                    // mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        NotificationScreen(name: "")));
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(AppImage.notification, width: 22),
                              Padding(
                                padding: const EdgeInsets.only(left: 15),
                                child: Container(
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red),
                                  child: const Padding(
                                    padding: EdgeInsets.all(3.0),
                                    child: Text(
                                      "0",
                                      style: TextStyle(
                                          fontSize: 10, color: AppColor.white),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          )),
                      const SizedBox(width: 10),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          print('Selected: $value');
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                              value: "Option 1",
                              onTap: () {
                                // logout(context);
                                logoutAPI();
                              },
                              child: Text(
                                "logOut".tr,
                                style: PoppinsCustomTextStyle.medium.copyWith(
                                    color: themeManager.isHighContrast
                                        ? AppColor.white
                                        : AppColor.buttonGreen,
                                    fontSize: 15),
                              )),
                        ],
                        offset: const Offset(0, 50),
                        child: Image.asset(AppImage.userProfile, width: 20),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ], //
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: Container(
                    height: 75,
                    decoration:
                        const BoxDecoration(color: AppColor.buttonGreen),
                    child: Stack(
                      children: [
                        Align(
                            alignment: Alignment.center,
                            child: Text("${"welcome".tr}, ${userName}!",
                                style: PoppinsCustomTextStyle.bold.copyWith(
                                    fontSize: 30, color: AppColor.white))),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                NotificationScreen(
                                                    name: widget.userName)));
                                  },
                                  child: Stack(
                                    children: [
                                      Image.asset(AppImage.notification,
                                          width: 50),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 25),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.red),
                                          child: const Padding(
                                            padding: EdgeInsets.all(5.0),
                                            child: Text(
                                              "0",
                                              style: TextStyle(
                                                  color: AppColor.white),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  )),
                              const SizedBox(width: 34),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  print('Selected: $value');
                                },
                                itemBuilder: (BuildContext context) => [
                                  PopupMenuItem(
                                      value: "Option 1",
                                      onTap: () {
                                        // logout(context);
                                        logoutAPI();
                                      },
                                      child: Text(
                                        "logOut".tr,
                                        style: PoppinsCustomTextStyle.medium
                                            .copyWith(
                                                color:
                                                    themeManager.isHighContrast
                                                        ? AppColor.white
                                                        : AppColor.buttonGreen,
                                                fontSize: 15),
                                      )),
                                ],
                                offset: const Offset(0, 50),
                                child: Image.asset(AppImage.userProfile,
                                    width: 50),
                              ),
                              const SizedBox(width: 34),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            );
    });
  }

  logoutAPI() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    int? code = await viewModel.logoutApi(token ?? "");
    if (context.mounted) {
      if (code == 200 || code == 401) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false);
        Utils.snackBar("logoutSuccess".tr, context);
      } else if (viewModel.apiError != null) {
        Utils.snackBar(viewModel.apiError!, context);
      }
    }
  }
}

class UserProvider with ChangeNotifier {
  String _userName = "";

  String get userName => _userName;

  void setUserName(String name) {
    _userName = name;
    notifyListeners(); // Notify all listening widgets
  }
}
