import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/Authentication/Page/login_screen.dart';
import 'package:pees/Authentication/Services/auth_service.dart';
import 'package:pees/Common_Screen/Pages/notification_screen.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/HeadMaster_Dashboard/Pages/master_dashboard.dart';
import 'package:pees/Common_Screen/Pages/settings_screen.dart';
import 'package:pees/HeadMaster_Dashboard/Pages/students_list_screen.dart';
import 'package:pees/HeadMaster_Dashboard/Pages/userManagement.dart';
import 'package:pees/HeadMaster_Dashboard/Services/headMaster_services.dart';
import 'package:pees/Models/profile_model.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/AppImage.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/Widgets/utils.dart';
import 'package:pees/custom_class/my_appBar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HeadMasterDashboardUI extends StatefulWidget {
  String? UserId;
  HeadMasterDashboardUI({this.UserId, super.key});

  @override
  State<HeadMasterDashboardUI> createState() => _HeadMasterDashboardUIState();
}

class _HeadMasterDashboardUIState extends State<HeadMasterDashboardUI> {
  HeadMasterServices viewModel = HeadMasterServices();
  AuthVM authViewmodel = AuthVM();
  ProfileModel? model;
  String? userName;
  final List<Widget> _pages = [
     MasterDashboard(),
    const StudentListScreen(),
    const UserManagementScreen(),
    const SettingScreen(),
  ];

  fetchProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    ProfileModel? profileModel =
        await viewModel.getProfileApicall(userId ?? "");
    if (profileModel != null) {
      model = profileModel;
      userName = model?.user.name;
      print("Name : ${model?.user.name}");
    }
  }

  @override
  void initState() {
    fetchProfileData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return ChangeNotifierProvider<HeadMasterServices>(
        create: (BuildContext context) => viewModel,
        child: Consumer<HeadMasterServices>(builder: (context, value, _) {
          return LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth <= 800;
            return Scaffold(
                appBar: isMobile
                    ? AppBar(
                        iconTheme: IconThemeData(color: AppColor.white),
                        backgroundColor: AppColor.buttonGreen,
                        centerTitle: true,
                        title: Text(
                            "${"welcome".tr}, ${model?.user.name ?? ""}!",
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
                                                NotificationScreen(
                                                    name: model?.user.name ??
                                                        "")));
                                  },
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.asset(AppImage.notification,
                                          width: 22),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 15),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.red),
                                          child: const Padding(
                                            padding: EdgeInsets.all(3.0),
                                            child: Text(
                                              "0",
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: AppColor.white),
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
                                    width: 20),
                              ),
                              const SizedBox(width: 10),
                            ],
                          ),
                        ], //
                      )
                    : null,
                drawer: isMobile
                    ? Drawer(
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: viewModel.masterDrawerList.length,
                                itemBuilder: (context, index) {
                                  return mobileDrawerListItem(
                                      viewModel.masterDrawerList[index], index);
                                },
                              ),
                            )
                          ],
                        ),
                      )
                    : null,
                body: Stack(
                  children: [
                    Column(
                      children: [
                        isMobile
                            ? const SizedBox()
                            : MyAppBar(model?.user.name ?? ""),
                        isMobile
                            ? Expanded(
                                child: _pages[viewModel.selectedIndex],
                              )
                            : Expanded(
                                child: Row(children: [
                                Container(
                                  width: 300,
                                  decoration: BoxDecoration(
                                      color: themeManager.isHighContrast
                                          ? AppColor.labelText
                                          : AppColor.whiteBorder),
                                  child: Column(
                                    children: [
                                      listItem(
                                          "dashboard",
                                          AppImage.dashboardFill,
                                          AppImage.dashboardWhite,
                                          0),
                                      listItem(
                                          "students",
                                          AppImage.studentsFill,
                                          AppImage.studentsWhite,
                                          1),
                                      listItem(
                                          "userManagement",
                                          AppImage.userManagementFill,
                                          AppImage.userManagementWhite,
                                          2),
                                      listItem(
                                          "settings",
                                          AppImage.settingsFill,
                                          AppImage.settingsWhite,
                                          3),
                                    ],
                                  ),
                                ),
                                Expanded(
                                    flex: 2,
                                    child: _pages[viewModel.selectedIndex]),
                              ]))
                      ],
                    ),
                    value.loading ? const LoaderView() : Container(),
                  ],
                ));
          });
        }));
  }

  Widget listItem(
      String title, String imageFill, String imageWhite, int index) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);

    bool isSelected = index == viewModel.selectedIndex;
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15, top: 15),
      child: InkWell(
        onTap: () {
          setState(() {
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
                isSelected ? imageWhite.toString() : imageFill.toString(),
                width: 25,
                height: 25,
              ),
              const SizedBox(width: 22),
              Text(
                title.toString().tr,
                style: NotoSansArabicCustomTextStyle.medium.copyWith(
                    fontSize: fontSizeProvider.fontSize + 2,
                    color: isSelected
                        ? AppColor.white
                        : themeManager.isHighContrast
                            ? Colors.grey.shade800
                            : AppColor.textGrey),
              )
            ],
          ),
        ),
      ),
    );
  }

  void onpress(MasterDrawerType type) {
    switch (type) {
      case MasterDrawerType.dashboard:
      // Navigator.pop(context);
      // Navigator.push(context,
      //     MaterialPageRoute(builder: (context) => const TeacherDashboard()));
      // break;
      case MasterDrawerType.students:
        Navigator.pop(context);
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const StudentListScreen()));
        break;
      case MasterDrawerType.userManagement:
        Navigator.pop(context);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const UserManagementScreen()));
        break;
      case MasterDrawerType.settings:
        Navigator.pop(context);
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const SettingScreen()));
        break;
    }
  }

  Widget mobileDrawerListItem(MasterDrawerModel model, int index) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    bool isSelected = index == viewModel.selectedIndex;
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15, top: 15),
      child: InkWell(
        onTap: () {
          // setState(() {
          // viewModel.updateSelectedIndex(index);
          onpress(model.type);
          // });
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
                isSelected ? model.whiteImage : model.fillImage,
                width: 25,
                height: 25,
              ),
              const SizedBox(width: 22),
              Text(
                model.title.toString().tr,
                style: NotoSansArabicCustomTextStyle.medium.copyWith(
                    fontSize: fontSizeProvider.fontSize + 2,
                    color: isSelected ? AppColor.white : AppColor.textGrey),
              )
            ],
          ),
        ),
      ),
    );
  }

  logoutAPI() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    int? code = await authViewmodel.logoutApi(token ?? "");
    if (context.mounted) {
      if (code == 200 || code == 401) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false);
        Utils.snackBar("Logout Successfully", context);
      } else if (authViewmodel.apiError != null) {
        Utils.snackBar(authViewmodel.apiError!, context);
      }
    }
  }
}
