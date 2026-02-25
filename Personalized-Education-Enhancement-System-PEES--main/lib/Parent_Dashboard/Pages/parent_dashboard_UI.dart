import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/Authentication/Page/login_screen.dart';
import 'package:pees/Authentication/Services/auth_service.dart';
import 'package:pees/Parent_Dashboard/Pages/alerts&Noti_Screen.dart';
import 'package:pees/Common_Screen/Pages/settings_screen.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/HeadMaster_Dashboard/Services/headMaster_services.dart';
import 'package:pees/Models/profile_model.dart';
import 'package:pees/Parent_Dashboard/Pages/parent_dashboard.dart';
import 'package:pees/Parent_Dashboard/Services/parent_services.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/AppImage.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/Widgets/utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentDashboardUI extends StatefulWidget {
  const ParentDashboardUI({super.key});

  @override
  State<ParentDashboardUI> createState() => _ParentDashboardUIState();
}

class _ParentDashboardUIState extends State<ParentDashboardUI> {
  static const Color _bgLavender = Color(0xFFD9D6F5);
  static const Color _panelDark = Color(0xFF11131A);
  static const Color _panelDarkSoft = Color(0xFF171A22);
  static const Color _textLight = Color(0xFFF3F2FF);
  static const Color _textMuted = Color(0xFFB2B6C6);
  static const Color _accentPrimary = Color(0xFF8E7CFF);
  static const Color _accentBorder = Color(0xFFB9ABFF);

  BoxDecoration _glassPanelDecoration({double radius = 20}) {
    return BoxDecoration(
      color: _panelDark.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFF2A2E3A), width: 1),
      boxShadow: const [
        BoxShadow(
          color: Color(0x44000000),
          blurRadius: 24,
          offset: Offset(0, 12),
        )
      ],
    );
  }

  ParentService viewModel = ParentService();
  HeadMasterServices masterViewmodel = HeadMasterServices();
  ProfileModel? model;
  final List<Widget> _pages = [const ParentDashboard(), const SettingScreen()];

  fetchProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId == null || userId.isEmpty) {
      print("Error: User ID is null or empty.");
      return;
    }

    ProfileModel? profileModel =
        await masterViewmodel.getProfileApicall(userId);

    if (profileModel != null) {
      model = profileModel;
      print("Model value : ${model?.user.email}");
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
        create: (BuildContext context) => masterViewmodel,
        child: Consumer<HeadMasterServices>(builder: (context, value, _) {
          return LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth <= 800;
            return Scaffold(
                backgroundColor: _bgLavender,
                appBar: isMobile
                    ? AppBar(
                        iconTheme: IconThemeData(color: AppColor.white),
                        backgroundColor: _panelDark,
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
                                                AlertsNotificationScreen(
                                                    isAlerts: false)));
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
                                                color: _accentPrimary,
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
                                itemCount: viewModel.dashBoardList.length,
                                itemBuilder: (context, index) {
                                  return mobileDrawerListItem(
                                      viewModel.dashBoardList[index], index);
                                },
                              ),
                            )
                          ],
                        ),
                      )
                    : null,
                body: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFD9D6F5), Color(0xFFC9C3EE)],
                        ),
                      ),
                      child: Column(
                        children: [
                          isMobile ? const SizedBox() : _buildDesktopHeader(),
                          if (!isMobile) _buildTopTabs(),
                          Expanded(
                            child: isMobile
                                ? _pages[viewModel.selectedIndex]
                                : Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        18, 0, 18, 18),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(22),
                                      child: Container(
                                        decoration:
                                            _glassPanelDecoration(radius: 22),
                                        child: _pages[viewModel.selectedIndex],
                                      ),
                                    ),
                                  ),
                          )
                        ],
                      ),
                    ),
                    // masterViewmodel.loading ? LoaderView() : Container()
                  ],
                ));
          });
        }));
  }

  Widget _buildTopTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: _glassPanelDecoration(radius: 20),
        child: Row(
          children: [
            Expanded(
                child: _topTabItem(
                    title: "dashboard",
                    iconFill: AppImage.dashboardFill,
                    iconWhite: AppImage.dashboardWhite,
                    index: 0)),
            const SizedBox(width: 10),
            Expanded(
                child: _topTabItem(
                    title: "settings",
                    iconFill: AppImage.settingsFill,
                    iconWhite: AppImage.settingsWhite,
                    index: 1)),
          ],
        ),
      ),
    );
  }

  Widget _topTabItem({
    required String title,
    required String iconFill,
    required String iconWhite,
    required int index,
  }) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final isSelected = index == viewModel.selectedIndex;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() {
          viewModel.selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected ? _accentPrimary : _panelDarkSoft,
          border: Border.all(
            color: isSelected ? _accentBorder : const Color(0xFF2A2E3A),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Image.asset(isSelected ? iconWhite : iconFill,
                width: 20, height: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: NotoSansArabicCustomTextStyle.medium.copyWith(
                  fontSize: fontSizeProvider.fontSize,
                  color: _textLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Container(
        height: 78,
        decoration: _glassPanelDecoration(radius: 20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              AlertsNotificationScreen(isAlerts: false)));
                },
                child: Stack(
                  children: [
                    Image.asset(AppImage.notification, width: 23),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                        padding: const EdgeInsets.all(3),
                        child: const Text("0",
                            style:
                                TextStyle(fontSize: 10, color: AppColor.white)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              PopupMenuButton<String>(
                onSelected: (_) {},
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: "logout",
                    onTap: logoutAPI,
                    child: Text(
                      "logOut".tr,
                      style: PoppinsCustomTextStyle.medium
                          .copyWith(color: _accentPrimary, fontSize: 15),
                    ),
                  ),
                ],
                offset: const Offset(0, 50),
                child: Image.asset(AppImage.userProfile, width: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  "${"welcome".tr}, ${model?.user.name ?? ""}!",
                  textAlign: TextAlign.center,
                  style: PoppinsCustomTextStyle.bold
                      .copyWith(fontSize: 26, color: _textLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                    fontSize: fontSizeProvider.fontSize,
                    color: isSelected
                        ? AppColor.white
                        : themeManager.isHighContrast
                            ? _textMuted
                            : _textMuted),
              )
            ],
          ),
        ),
      ),
    );
  }

  void onpress(ParentListType type) {
    switch (type) {
      case ParentListType.dashBoard:
      // Navigator.pop(context);
      // Navigator.push(context,
      //     MaterialPageRoute(builder: (context) => const TeacherDashboard()));
      // break;
      case ParentListType.settings:
        Navigator.pop(context);
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const SettingScreen()));
        break;
    }
  }

  Widget mobileDrawerListItem(ParentModel model, int index) {
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
                isSelected ? model.colorImage : model.fillImage,
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

  AuthVM authViewmodel = AuthVM();
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
