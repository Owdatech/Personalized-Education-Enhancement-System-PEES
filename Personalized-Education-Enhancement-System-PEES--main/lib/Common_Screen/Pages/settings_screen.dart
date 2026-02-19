import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Common_Screen/Services/common_service.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/Models/profile_model.dart';
import 'package:pees/Widgets/AppButton.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/AppTextField.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/Widgets/utils.dart';
import 'package:pees/custom_class/my_appBar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Language { english, arabic }

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  CommonService viewModel = CommonService();
  ProfileModel? model;
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController contactNoController = TextEditingController();
  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool isSwitch = true;

  bool isChecked1 = false;
  bool isChecked2 = false;
  bool isChecked3 = false;

  bool emailSelected = false;
  bool smsSelected = false;
  bool appSelected = false;

  String selectedLanguage = Get.locale?.languageCode ?? 'en';

  updateLanguage(Locale locale) {
    Get.updateLocale(locale);
  }

  deliveryMethodApi() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    int? code = await viewModel.deliveryMethodApi(
        userId ?? "", emailSelected, appSelected, smsSelected);
    if (context.mounted) {
      if (code == 200) {
        print("delevery method succes");
        print("email : $emailSelected");
        print("sms : $smsSelected");
        print("app : $appSelected");
      } else {
        print("${viewModel.apiError}");
      }
    }
  }

  Future<void> savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('emailSelected', emailSelected);
    await prefs.setBool('smsSelected', smsSelected);
    await prefs.setBool('appSelected', appSelected);
  }

  Future<void> loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      emailSelected = prefs.getBool('emailSelected') ?? false;
      smsSelected = prefs.getBool('smsSelected') ?? false;
      appSelected = prefs.getBool('appSelected') ?? false;
    });
  }

  chnagePasswordAction() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String usersID = userId.toString();
    String newPassword = newPasswordController.text;
    String confirmPassword = confirmPasswordController.text;
    if (newPassword.isEmpty) {
      Utils.snackBar("newPasswordEmpty".tr, context);
    } else if (confirmPassword.isEmpty) {
      Utils.snackBar("confirmPasswordEmpty".tr, context);
    } else {
      int? code = await viewModel.changePasswordApi(
          usersID, newPassword, confirmPassword);
      if (context.mounted) {
        if (code == 200) {
          Utils.snackBar("passwordChange".tr, context);
          oldPasswordController.clear();
          newPasswordController.clear();
          confirmPasswordController.clear();
        } else {
          Utils.snackBar("${viewModel.apiError}", context);
          print("Api Error change password : ${viewModel.apiError}");
        }
      }
    }
  }

  updatePersonalInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwtToken');
    String? userId = prefs.getString('userId');
    String? role = prefs.getString('role');
    String name = nameController.text;
    String email = emailController.text;
    String contact = contactNoController.text;
    if (name.isEmpty) {
      Utils.snackBar("nameEmpty".tr, context);
    } else if (email.isEmpty) {
      Utils.snackBar("emailEmpty".tr, context);
    } else if (contact.isEmpty) {
      Utils.snackBar("contactEmpty".tr, context);
    } else if (contact.length < 8) {
      Utils.snackBar("length8greater".tr, context);
    } else if (contact.length > 8) {
      Utils.snackBar("length8less".tr, context);
    } else {
      int? code = await viewModel.updatePersonalInfo(
          token ?? "", userId ?? "", name, email, contact, role ?? "  ");
      if (context.mounted) {
        if (code == 200) {
          Utils.snackBar("successInfo".tr, context);
          Provider.of<UserProvider>(context, listen: false).setUserName(name);
          setState(() {
            fetchPersonalInfo();
          });
        } else {
          print("Update personal info. API Error : ${viewModel.apiError}");
          Utils.snackBar("${viewModel.apiError}", context);
        }
      }
    }
  }

  fetchPersonalInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String usersID = userId.toString();
    print("Fetching for userId: $userId");
    ProfileModel? profileModel = await viewModel.getProfileApicall(usersID);
    if (profileModel != null) {
      setState(() {
        model = profileModel;
      });
      nameController.text = model?.user.name ?? "";
      emailController.text = model?.user.email ?? '';
      contactNoController.text = model?.user.contactNumber ?? "";
      appSelected = model?.user.deliveryMethod.app ?? false;
      emailSelected = model?.user.deliveryMethod.email ?? false;
      smsSelected = model?.user.deliveryMethod.sms ?? false;
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      await fetchPersonalInfo();
      await loadPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return ChangeNotifierProvider<CommonService>(
        create: (BuildContext context) => viewModel,
        child: Consumer<CommonService>(builder: (context, value, _) {
          return LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth <= 800;
            return Scaffold(
              appBar: PreferredSize(
                  preferredSize: const Size(double.infinity, 50),
                  child: isMobile ? MyAppBar("") : const SizedBox()),
              body: Stack(
                children: [
                  SingleChildScrollView(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Padding(
                        padding: EdgeInsets.only(
                            top: isMobile ? 10 : 30,
                            left: isMobile ? 10 : 20,
                            right: isMobile ? 10 : 20),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              personalInfo(),
                              const SizedBox(height: 20),
                              language(),
                              const SizedBox(height: 20),
                              notificationSetting(),
                              const SizedBox(height: 20),
                              accessibilityOption(),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  viewModel.loading ? const LoaderView() : Container()
                ],
              ),
            );
          });
        }));
  }

  Widget accessibilityOption() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth <= 800;
      return Column(
        children: [
          Container(
            height: 40,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColor.buttonGreen,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: Align(
              alignment: selectedLanguage == "en"
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(
                    top: 7,
                    bottom: 7,
                    left: selectedLanguage == "en" ? 22 : 0,
                    right: selectedLanguage == "en" ? 0 : 22),
                child: Text("accessibilityOptions".tr,
                    style: NotoSansArabicCustomTextStyle.bold.copyWith(
                        fontSize: fontSizeProvider.fontSize + 2,
                        color: AppColor.white)),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            // height: 100,
            decoration: BoxDecoration(
              color: themeManager.isHighContrast
                  ? AppColor.labelText
                  : AppColor.white,
              boxShadow: const [
                BoxShadow(
                    blurRadius: 5,
                    color: AppColor.buttonShadow,
                    offset: Offset(0, 5))
              ],
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10)),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                  left: selectedLanguage == "en" ? 15 : 0,
                  right: selectedLanguage == 'en' ? 0 : 15),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  isMobile
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("fontSize".tr,
                                style: NotoSansArabicCustomTextStyle.medium
                                    .copyWith(
                                        fontSize: fontSizeProvider.fontSize,
                                        color: AppColor.black)),
                            const SizedBox(width: 20),
                            Row(
                              children: [
                                Text("0",
                                    style: NotoSansArabicCustomTextStyle.medium
                                        .copyWith(
                                            fontSize: fontSizeProvider.fontSize,
                                            color: AppColor.black)),
                                fontPlayer(),
                                Text("100",
                                    style: NotoSansArabicCustomTextStyle.medium
                                        .copyWith(
                                            fontSize: fontSizeProvider.fontSize,
                                            color: AppColor.black)),
                              ],
                            ),
                            Text("contrastMode".tr,
                                style: NotoSansArabicCustomTextStyle.medium
                                    .copyWith(
                                        fontSize: fontSizeProvider.fontSize,
                                        color: AppColor.black)),
                            const SizedBox(height: 5),
                            Padding(
                              padding: EdgeInsets.only(
                                  left: selectedLanguage == "en" ? 0 : 7),
                              child: AppFillButton3(
                                  onPressed: () {
                                    setState(() {
                                      themeManager.toggleContrastMode();
                                    });
                                  },
                                  text: themeManager.isHighContrast
                                      ? "disable"
                                      : "enable",
                                  color: AppColor.buttonGreen),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text("fontSize".tr,
                                    style: NotoSansArabicCustomTextStyle.medium
                                        .copyWith(
                                            fontSize: fontSizeProvider.fontSize,
                                            color: AppColor.black)),
                                const SizedBox(width: 20),
                                Row(
                                  children: [
                                    Text("0",
                                        style: NotoSansArabicCustomTextStyle
                                            .medium
                                            .copyWith(
                                                fontSize:
                                                    fontSizeProvider.fontSize,
                                                color: AppColor.black)),
                                    fontPlayer(),
                                    Text("100",
                                        style: NotoSansArabicCustomTextStyle
                                            .medium
                                            .copyWith(
                                                fontSize:
                                                    fontSizeProvider.fontSize,
                                                color: AppColor.black)),
                                  ],
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 30),
                              child: Row(
                                children: [
                                  Text("contrastMode".tr,
                                      style: NotoSansArabicCustomTextStyle
                                          .medium
                                          .copyWith(
                                              fontSize:
                                                  fontSizeProvider.fontSize,
                                              color: AppColor.black)),
                                  const SizedBox(width: 30),
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left:
                                            selectedLanguage == "en" ? 0 : 20),
                                    child: AppFillButton3(
                                        onPressed: () {
                                          setState(() {
                                            themeManager.toggleContrastMode();
                                          });
                                        },
                                        text: themeManager.isHighContrast
                                            ? "disable"
                                            : "enable",
                                        color: AppColor.buttonGreen),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          )
        ],
      );
    });
  }

  Widget notificationSetting() {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Column(
      children: [
        Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColor.buttonGreen,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: Align(
              alignment: selectedLanguage == "en"
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(
                    top: 7,
                    bottom: 7,
                    left: selectedLanguage == "en" ? 22 : 0,
                    right: selectedLanguage == "en" ? 0 : 22),
                child: Text("notificationSettings".tr,
                    style: NotoSansArabicCustomTextStyle.bold.copyWith(
                        fontSize: fontSizeProvider.fontSize + 2,
                        color: AppColor.white)),
              ),
            )),
        Container(
          decoration: BoxDecoration(
              color: themeManager.isHighContrast
                  ? AppColor.labelText
                  : AppColor.white,
              boxShadow: const [
                BoxShadow(
                    blurRadius: 5,
                    color: AppColor.buttonShadow,
                    offset: Offset(0, 5))
              ],
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text("deliveryMethods".tr,
                    style: NotoSansArabicCustomTextStyle.bold.copyWith(
                        color: AppColor.black,
                        fontSize: fontSizeProvider.fontSize)),
                const SizedBox(height: 17),
                customRadioButton("emailTitle", emailSelected, () {
                  setState(() {
                    emailSelected = !emailSelected;
                  });
                }),
                const SizedBox(height: 7),
                customRadioButton("sms", smsSelected, () {
                  setState(() {
                    smsSelected = !smsSelected;
                  });
                }),
                const SizedBox(height: 7),
                customRadioButton("inApp", appSelected, () {
                  setState(() {
                    appSelected = !appSelected;
                  });
                }),
                const SizedBox(height: 10),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget language() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return Column(
      children: [
        Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColor.buttonGreen,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: Align(
              alignment: selectedLanguage == "en"
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(
                    top: 7,
                    bottom: 7,
                    left: selectedLanguage == "en" ? 22 : 0,
                    right: selectedLanguage == "en" ? 0 : 22),
                child: Text("languagePreferences".tr,
                    style: NotoSansArabicCustomTextStyle.bold.copyWith(
                        fontSize: fontSizeProvider.fontSize + 2,
                        color: AppColor.white)),
              ),
            )),
        Container(
            height: 100,
            decoration: BoxDecoration(
                color: themeManager.isHighContrast
                    ? AppColor.labelText
                    : AppColor.white,
                boxShadow: const [
                  BoxShadow(
                      blurRadius: 5,
                      color: AppColor.buttonShadow,
                      offset: Offset(0, 5))
                ],
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                languageUI("english", "en"),
                languageUI("arabic", "ar"),
              ],
            )),
      ],
    );
  }

  Widget personalInfo() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth <= 800;
      return Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColor.buttonGreen,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: Align(
              alignment: selectedLanguage == "en"
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(
                    left: selectedLanguage == "en" ? 22 : 0,
                    right: selectedLanguage == "en" ? 0 : 22,
                    top: 7,
                    bottom: 7),
                child: Text("profileSettings".tr,
                    style: NotoSansArabicCustomTextStyle.bold.copyWith(
                        fontSize: fontSizeProvider.fontSize + 2 /*18 */,
                        color: AppColor.white)),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: themeManager.isHighContrast
                  ? AppColor.labelText
                  : AppColor.white,
              boxShadow: const [
                BoxShadow(
                    blurRadius: 5,
                    color: AppColor.buttonShadow,
                    offset: Offset(0, 5))
              ],
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: isMobile
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              left: selectedLanguage == "en" ? 7 : 0,
                              top: 5,
                              right: selectedLanguage == "en" ? 0 : 7),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text("personalInformation".tr,
                                  style: NotoSansArabicCustomTextStyle.bold
                                      .copyWith(
                                          color: AppColor.black,
                                          fontSize:
                                              fontSizeProvider.fontSize + 1)),
                              const SizedBox(height: 17),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("name".tr,
                                      style: NotoSansArabicCustomTextStyle.bold
                                          .copyWith(
                                              fontSize:
                                                  fontSizeProvider.fontSize,
                                              color: AppColor.black)),
                                  const SizedBox(height: 5),
                                  SizedBox(
                                    height: 20,
                                    width: 250,
                                    child: AppFillTextField(
                                        textController: nameController,
                                        hintText: "",
                                        icon: null),
                                  ),
                                  const SizedBox(height: 5),
                                  Text("email".tr,
                                      style: NotoSansArabicCustomTextStyle.bold
                                          .copyWith(
                                              fontSize:
                                                  fontSizeProvider.fontSize,
                                              color: AppColor.black)),
                                  const SizedBox(height: 5),
                                  SizedBox(
                                    height: 20,
                                    width: 250,
                                    child: AppFillTextField(
                                        color: "true",
                                        readOnly: true,
                                        textController: emailController,
                                        hintText: "",
                                        icon: null),
                                  ),
                                  const SizedBox(height: 5),
                                  Text("contactNo".tr,
                                      style: NotoSansArabicCustomTextStyle.bold
                                          .copyWith(
                                              fontSize:
                                                  fontSizeProvider.fontSize,
                                              color: AppColor.black)),
                                  const SizedBox(width: 15),
                                  SizedBox(
                                    height: 20,
                                    width: 250,
                                    child: AppFillTextField(
                                        textController: contactNoController,
                                        hintText: "",
                                        icon: null),
                                  )
                                ],
                              ),
                              const SizedBox(height: 17),
                              AppFillButton2(
                                onPressed: () {
                                  updatePersonalInfo();
                                },
                                text: "updateInformation",
                              ),
                              const SizedBox(height: 17),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        Padding(
                          padding: EdgeInsets.only(
                              left: selectedLanguage == "en" ? 15 : 0,
                              top: 5,
                              right: selectedLanguage == "en" ? 0 : 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text("changePassword".tr,
                                  style: NotoSansArabicCustomTextStyle.bold
                                      .copyWith(
                                          color: AppColor.black,
                                          fontSize:
                                              fontSizeProvider.fontSize + 1)),
                              const SizedBox(height: 17),
                              Text("oldPassword".tr,
                                  style: NotoSansArabicCustomTextStyle.bold
                                      .copyWith(
                                          fontSize: fontSizeProvider.fontSize,
                                          color: AppColor.black)),
                              const SizedBox(height: 5),
                              SizedBox(
                                  height: 20,
                                  width: 250,
                                  child: AppFillTextField(
                                      textController: oldPasswordController,
                                      hintText: "",
                                      icon: null)),
                              const SizedBox(height: 5),
                              Text("newPassword".tr,
                                  style: NotoSansArabicCustomTextStyle.bold
                                      .copyWith(
                                          fontSize: fontSizeProvider.fontSize,
                                          color: AppColor.black)),
                              const SizedBox(height: 5),
                              SizedBox(
                                height: 20,
                                width: 250,
                                child: AppFillTextField(
                                    textController: newPasswordController,
                                    hintText: "",
                                    icon: null),
                              ),
                              const SizedBox(height: 5),
                              Text("confirmPassword".tr,
                                  style: NotoSansArabicCustomTextStyle.bold
                                      .copyWith(
                                          fontSize: fontSizeProvider.fontSize,
                                          color: AppColor.black)),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 20,
                                width: 250,
                                child: AppFillTextField(
                                    textController: confirmPasswordController,
                                    hintText: "",
                                    icon: null),
                              ),
                              const SizedBox(height: 17),
                              AppFillButton2(
                                onPressed: () {
                                  chnagePasswordAction();
                                },
                                text: "changePassword",
                              ),
                              const SizedBox(height: 17),
                            ],
                          ),
                        )
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              left: selectedLanguage == "en" ? 25 : 0,
                              top: 5,
                              right: selectedLanguage == "en" ? 0 : 25),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text("personalInformation".tr,
                                  style: NotoSansArabicCustomTextStyle.bold
                                      .copyWith(
                                          color: AppColor.black,
                                          fontSize:
                                              fontSizeProvider.fontSize + 1)),
                              const SizedBox(height: 17),
                              Row(
                                children: [
                                  Text("name".tr,
                                      style: NotoSansArabicCustomTextStyle.bold
                                          .copyWith(
                                              fontSize:
                                                  fontSizeProvider.fontSize,
                                              color: AppColor.black)),
                                  SizedBox(
                                      width:
                                          selectedLanguage == 'en' ? 46 : 15),
                                  SizedBox(
                                    height: 20,
                                    width: 250,
                                    child: AppFillTextField(
                                        textController: nameController,
                                        hintText: "",
                                        icon: null),
                                  )
                                ],
                              ),
                              const SizedBox(height: 17),
                              Row(
                                children: [
                                  Text("email".tr,
                                      style: NotoSansArabicCustomTextStyle.bold
                                          .copyWith(
                                              fontSize:
                                                  fontSizeProvider.fontSize,
                                              color: AppColor.black)),
                                  SizedBox(
                                      width:
                                          selectedLanguage == 'en' ? 50 : 15),
                                  SizedBox(
                                    height: 20,
                                    width: 250,
                                    child: AppFillTextField(
                                        color: "true",
                                        readOnly: true,
                                        textController: emailController,
                                        hintText: "",
                                        icon: null),
                                  )
                                ],
                              ),
                              const SizedBox(height: 17),
                              Row(
                                children: [
                                  Text("contactNo".tr,
                                      style: NotoSansArabicCustomTextStyle.bold
                                          .copyWith(
                                              fontSize:
                                                  fontSizeProvider.fontSize,
                                              color: AppColor.black)),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    height: 20,
                                    width: 250,
                                    child: AppFillTextField(
                                        textController: contactNoController,
                                        hintText: "",
                                        icon: null),
                                  )
                                ],
                              ),
                              const SizedBox(height: 17),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: AppFillButton2(
                                  onPressed: () {
                                    updatePersonalInfo();
                                  },
                                  text: "updateInformation",
                                ),
                              ),
                              const SizedBox(height: 17),
                            ],
                          ),
                        ),
                        const SizedBox(width: 40),
                        Container(
                          width: 1,
                          // height: 160,
                          decoration: const BoxDecoration(
                            color: AppColor.buttonGreen,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              left: selectedLanguage == "en" ? 25 : 0,
                              top: 5,
                              right: selectedLanguage == "en" ? 0 : 25),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text("changePassword".tr,
                                  style: NotoSansArabicCustomTextStyle.bold
                                      .copyWith(
                                          color: AppColor.black,
                                          fontSize:
                                              fontSizeProvider.fontSize + 1)),
                              const SizedBox(height: 17),
                              Row(
                                children: [
                                  Text("oldPassword".tr,
                                      style: NotoSansArabicCustomTextStyle.bold
                                          .copyWith(
                                              fontSize:
                                                  fontSizeProvider.fontSize,
                                              color: AppColor.black)),
                                  SizedBox(
                                      width:
                                          selectedLanguage == 'en' ? 40 : 15),
                                  SizedBox(
                                    height: 20,
                                    width: 250,
                                    child: AppFillTextField(
                                        textController: oldPasswordController,
                                        hintText: "",
                                        icon: null),
                                  )
                                ],
                              ),
                              const SizedBox(height: 17),
                              Row(
                                children: [
                                  Text("newPassword".tr,
                                      style: NotoSansArabicCustomTextStyle.bold
                                          .copyWith(
                                              fontSize:
                                                  fontSizeProvider.fontSize,
                                              color: AppColor.black)),
                                  SizedBox(
                                      width:
                                          selectedLanguage == 'en' ? 34 : 20),
                                  SizedBox(
                                    height: 20,
                                    width: 250,
                                    child: AppFillTextField(
                                        textController: newPasswordController,
                                        hintText: "",
                                        icon: null),
                                  )
                                ],
                              ),
                              const SizedBox(height: 17),
                              Row(
                                children: [
                                  Text("confirmPassword".tr,
                                      style: NotoSansArabicCustomTextStyle.bold
                                          .copyWith(
                                              fontSize:
                                                  fontSizeProvider.fontSize,
                                              color: AppColor.black)),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    height: 20,
                                    width: 250,
                                    child: AppFillTextField(
                                        textController:
                                            confirmPasswordController,
                                        hintText: "",
                                        icon: null),
                                  )
                                ],
                              ),
                              const SizedBox(height: 17),
                              Align(
                                alignment: Alignment.centerRight,
                                child: AppFillButton2(
                                  onPressed: () {
                                    chnagePasswordAction();
                                  },
                                  text: "changePassword",
                                ),
                              ),
                              const SizedBox(height: 17),
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

  Widget fontPlayer() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Slider(
        value: fontSizeProvider.fontSize,
        min: 12,
        max: 18,
        activeColor: AppColor.buttonGreen,
        inactiveColor: AppColor.grey,
        thumbColor: AppColor.buttonGreen,
        label: fontSizeProvider.fontSize.round().toString(),
        onChanged: (double value) {
          setState(() {
            fontSizeProvider.setFontSize(value);
          });
        });
  }

  void _changeLanguage(String languageCode) {
    setState(() {
      selectedLanguage = languageCode;
    });
    LocalizationService.changeLocale(languageCode);
  }

  Widget languageUI(String text, String type) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    bool isSelected = selectedLanguage == type;
    return InkWell(
      onTap: () {
        setState(() {
          _changeLanguage(type);
        });
      },
      child: Container(
        height: 50,
        width: 150,
        decoration: BoxDecoration(
            color: isSelected ? AppColor.buttonGreen : AppColor.white,
            border: Border.all(color: AppColor.buttonGreen, width: 2),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isSelected ? 10 : 0),
              bottomLeft: Radius.circular(isSelected ? 10 : 0),
              bottomRight: Radius.circular(isSelected ? 0 : 10),
              topRight: Radius.circular(isSelected ? 0 : 10),
            )),
        child: Center(
            child: Text(text.tr,
                style: NotoSansArabicCustomTextStyle.medium.copyWith(
                    fontSize: fontSizeProvider.fontSize,
                    color: isSelected ? AppColor.white : AppColor.black))),
      ),
    );
  }

  Widget customRadioButton(String text, bool isSelected, VoidCallback onTap) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return GestureDetector(
      onTap: () {
        onTap();
        savePreferences();
        deliveryMethodApi();
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 15),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.circle, size: 16, color: Colors.green)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              text.tr,
              style: NotoSansArabicCustomTextStyle.medium.copyWith(
                  color: AppColor.black, fontSize: fontSizeProvider.fontSize),
            ),
          ],
        ),
      ),
    );
  }
}

class LocalizationService {
  static const String languageKey = 'language';

  // Supported languages
  static final List<Locale> supportedLocales = [
    const Locale('en', 'US'),
    const Locale('ar', 'AE'),
  ];

  // Default locale
  static Locale get defaultLocale => const Locale('en', 'US');

  // Load saved language or default to English
  static Future<Locale> loadSavedLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString(languageKey);

    if (languageCode != null) {
      return Locale(languageCode);
    } else {
      return defaultLocale;
    }
  }

  // Change language and save to shared preferences
  static Future<void> changeLocale(String languageCode) async {
    Locale newLocale = Locale(languageCode);
    Get.updateLocale(newLocale);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(languageKey, languageCode);
  }
}
