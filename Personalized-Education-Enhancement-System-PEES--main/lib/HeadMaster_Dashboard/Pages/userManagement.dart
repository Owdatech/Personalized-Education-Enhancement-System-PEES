// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/HeadMaster_Dashboard/Model/UserManageModel.dart';
import 'package:pees/HeadMaster_Dashboard/Pages/addNewUser_screen.dart';
import 'package:pees/HeadMaster_Dashboard/Pages/userProfile_screen.dart';
import 'package:pees/HeadMaster_Dashboard/Services/headMaster_services.dart';
import 'package:pees/Widgets/AppButton.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/AppImage.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/custom_class/my_appBar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  HeadMasterServices viewModel = HeadMasterServices();
  String selectedLanguage = Get.locale?.languageCode ?? 'en';
  bool isCheck = false;
  bool isAddNewUser = false;
  int? selectedIndex;
  bool isUserProfile = false;
  List<String> userRole = ["Teacher", "Student", "Parent"];
  String? roleName;
  TextEditingController searchController = TextEditingController();
  List<UserManageModel> searchResults = [];
  String searchText = '';
  bool isSearching = false;
  int currentPage = 1;
  final int itemsPerPage = 6;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController roleController = TextEditingController();
  UserManageModel? model;
  Map<String, dynamic> grades = {};

  clearMethod() {
    nameController.clear();
    emailController.clear();
    mobileController.clear();
    roleName = null;
  }

  fetchUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jwtToken = prefs.getString('jwtToken');

    List<UserManageModel>? userModel =
        await viewModel.fetchUserList(jwtToken ?? "");

    if (userModel != null) {
      setState(() {
        viewModel.userList = userModel; // ✅ Update the actual list
        // Optionally update other lists if you’re filtering by role
        viewModel.teachersList =
            userModel.where((u) => u.role == 'teacher').toList();
        viewModel.studentsList =
            userModel.where((u) => u.role == 'student').toList();
        viewModel.parentsList =
            userModel.where((u) => u.role == 'parent').toList();
      });
    }
  }

  viewProfileAction(UserManageModel models) {
    Route route = MaterialPageRoute(
        builder: (context) => UserProfileScreen(model: models));
    Navigator.push(context, route).then(onGoBack);
  }

  addNewUserAction() {
    Route route =
        MaterialPageRoute(builder: (context) => const AddNewUserScreen());
    Navigator.push(context, route).then(onGoBack);
  }

  FutureOr onGoBack(dynamic isRefesh) {
    if (isRefesh) {
      refreshUserList();
    }
  }

  refreshUserList() async {
    await fetchUsers();
    setState(() {
      _filterSearchResults(viewModel.selectedList == UserEnum.all
          ? viewModel.userList
          : viewModel.selectedList == UserEnum.teacher
              ? viewModel.teachersList
              : viewModel.selectedList == UserEnum.student
                  ? viewModel.studentsList
                  : viewModel.parentsList);
    });
  }

  void _filterSearchResults(List<UserManageModel> list) {
    setState(() {
      isSearching = true;
      searchResults = list
          .where((element) =>
              element.name!.toLowerCase().contains(searchText.toLowerCase()) ||
              element.role!.toLowerCase().contains(searchText.toLowerCase()) ||
              element.status!.toLowerCase().contains(searchText.toLowerCase()))
          .toList();
      currentPage = 1;
    });
  }

  @override
  void initState() {
    fetchUsers().then((_) {
      _filterSearchResults(viewModel.selectedList == UserEnum.all
          ? viewModel.userList
          : viewModel.selectedList == UserEnum.teacher
              ? viewModel.teachersList
              : viewModel.selectedList == UserEnum.student
                  ? viewModel.studentsList
                  : viewModel.parentsList);
    });
    _filterSearchResults(viewModel.selectedList == UserEnum.all
        ? viewModel.userList
        : viewModel.selectedList == UserEnum.teacher
            ? viewModel.teachersList
            : viewModel.selectedList == UserEnum.student
                ? viewModel.studentsList
                : viewModel.parentsList);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (searchResults.isEmpty) {
      setState(() {
        _filterSearchResults(viewModel.selectedList == UserEnum.all
            ? viewModel.userList
            : viewModel.selectedList == UserEnum.teacher
                ? viewModel.teachersList
                : viewModel.selectedList == UserEnum.student
                    ? viewModel.studentsList
                    : viewModel.parentsList);
      });
    }

    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = (currentPage * itemsPerPage) < searchResults.length
        ? currentPage * itemsPerPage
        : searchResults.length;
    final currentList = searchResults.sublist(startIndex, endIndex);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return ChangeNotifierProvider<HeadMasterServices>(
        create: (BuildContext context) => viewModel,
        child: Consumer<HeadMasterServices>(builder: (context, value, _) {
          return LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth <= 800;
            return Scaffold(
              appBar: PreferredSize(
                  preferredSize: const Size(double.infinity, 50),
                  child: isMobile ? MyAppBar("") : const SizedBox()),
              body: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width: isMobile
                                ? null
                                : MediaQuery.of(context).size.width,
                            height: isMobile
                                ? MediaQuery.of(context).size.height
                                : null,
                            child: Padding(
                                padding: EdgeInsets.only(
                                    left: isMobile ? 10 : 20,
                                    right: isMobile ? 10 : 20,
                                    top: 20),
                                child: Column(
                                  children: [
                                    searchBox(),
                                    const SizedBox(height: 20),
                                    tabBar(isMobile),
                                    const SizedBox(height: 7),
                                    if (viewModel.selectedList == UserEnum.all)
                                      isMobile
                                          ? Expanded(
                                              child: ListView.builder(
                                                padding: EdgeInsets.zero,
                                                itemCount: currentList.length,
                                                shrinkWrap: true,
                                                itemBuilder: (context, index) {
                                                  return usresItems(
                                                      currentList[index],
                                                      isMobile);
                                                },
                                              ),
                                            )
                                          : ListView.builder(
                                              padding: EdgeInsets.zero,
                                              itemCount: currentList.length,
                                              shrinkWrap: true,
                                              itemBuilder: (context, index) {
                                                return usresItems(
                                                    currentList[index],
                                                    isMobile);
                                              },
                                            )
                                    else if (viewModel.selectedList ==
                                        UserEnum.teacher)
                                      isMobile
                                          ? Expanded(
                                              child: ListView.builder(
                                                  padding: EdgeInsets.zero,
                                                  itemCount: currentList.length,
                                                  shrinkWrap: true,
                                                  itemBuilder:
                                                      (context, index) {
                                                    return usresItems(
                                                        currentList[index],
                                                        isMobile);
                                                  }),
                                            )
                                          : ListView.builder(
                                              padding: EdgeInsets.zero,
                                              itemCount: currentList.length,
                                              shrinkWrap: true,
                                              itemBuilder: (context, index) {
                                                return usresItems(
                                                    currentList[index],
                                                    isMobile);
                                              })
                                    else if (viewModel.selectedList ==
                                        UserEnum.student)
                                      isMobile
                                          ? Expanded(
                                              child: ListView.builder(
                                                  padding: EdgeInsets.zero,
                                                  itemCount: currentList.length,
                                                  shrinkWrap: true,
                                                  itemBuilder:
                                                      (context, index) {
                                                    return usresItems(
                                                        currentList[index],
                                                        isMobile);
                                                  }),
                                            )
                                          : ListView.builder(
                                              padding: EdgeInsets.zero,
                                              itemCount: currentList.length,
                                              shrinkWrap: true,
                                              itemBuilder: (context, index) {
                                                return usresItems(
                                                    currentList[index],
                                                    isMobile);
                                              })
                                    else if (viewModel.selectedList ==
                                        UserEnum.parent)
                                      isMobile
                                          ? Expanded(
                                              child: ListView.builder(
                                                  padding: EdgeInsets.zero,
                                                  itemCount: currentList.length,
                                                  shrinkWrap: true,
                                                  itemBuilder:
                                                      (context, index) {
                                                    return usresItems(
                                                        currentList[index],
                                                        isMobile);
                                                  }),
                                            )
                                          : ListView.builder(
                                              padding: EdgeInsets.zero,
                                              itemCount: currentList.length,
                                              shrinkWrap: true,
                                              itemBuilder: (context, index) {
                                                return usresItems(
                                                    currentList[index],
                                                    isMobile);
                                              }),
                                    isMobile
                                        ? const SizedBox(height: 100)
                                        : const SizedBox(height: 15),
                                    isMobile
                                        ? SizedBox()
                                        : Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: AppFillButton3(
                                                        onPressed: () {
                                                          addNewUserAction();
                                                        },
                                                        color: AppColor
                                                            .buttonGreen,
                                                        text: "addNewUser")),
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      onPressed: () {
                                                        if (currentPage > 1) {
                                                          setState(() {
                                                            currentPage--;
                                                          });
                                                        }
                                                      },
                                                      icon: const Icon(
                                                          Icons.arrow_back),
                                                    ),
                                                    Text(
                                                        "$currentPage/${(searchResults.length / itemsPerPage).ceil()}"),
                                                    IconButton(
                                                      onPressed: () {
                                                        if (currentPage <
                                                            (searchResults
                                                                        .length /
                                                                    itemsPerPage)
                                                                .ceil()) {
                                                          setState(() {
                                                            currentPage++;
                                                          });
                                                        }
                                                      },
                                                      icon: const Icon(
                                                          Icons.arrow_forward),
                                                    ),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                    const SizedBox(height: 15),
                                  ],
                                )),
                          ),
                        ),
                      ),
                      isMobile
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: AppFillButton3(
                                          onPressed: () {
                                            addNewUserAction();
                                          },
                                          color: AppColor.buttonGreen,
                                          text: "addNewUser")),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          if (currentPage > 1) {
                                            setState(() {
                                              currentPage--;
                                            });
                                          }
                                        },
                                        icon: const Icon(Icons.arrow_back),
                                      ),
                                      Text(
                                          "$currentPage/${(searchResults.length / itemsPerPage).ceil()}"),
                                      IconButton(
                                        onPressed: () {
                                          if (currentPage <
                                              (searchResults.length /
                                                      itemsPerPage)
                                                  .ceil()) {
                                            setState(() {
                                              currentPage++;
                                            });
                                          }
                                        },
                                        icon: const Icon(Icons.arrow_forward),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            )
                          : SizedBox(),
                    ],
                  ),
                  viewModel.loading ? const LoaderView() : Container()
                ],
              ),
            );
          });
        }));
  }

  Widget tabBar(bool isMobile) {
    return Container(
      // height: 40,
      decoration: const BoxDecoration(
          color: AppColor.lightYellow,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(5), topRight: Radius.circular(5))),
      child: isMobile
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal, child: topTabBar())
          : topTabBar(),
    );
  }

  Widget topTabBar() {
    return Center(
        child: Row(
      children: [
        tabTitle("all", UserEnum.all, 0),
        tabTitle("teachers", UserEnum.teacher, 1),
        tabTitle("student", UserEnum.student, 2),
        tabTitle("parents", UserEnum.parent, 3),
      ],
    ));
  }

  changeTabAction(UserEnum type) async {
    viewModel.selectedList = type;
    if (viewModel.selectedList == UserEnum.all) {
      _filterSearchResults(viewModel.userList);
    } else if (viewModel.selectedList == UserEnum.teacher) {
      _filterSearchResults(viewModel.teachersList);
    } else if (viewModel.selectedList == UserEnum.student) {
      _filterSearchResults(viewModel.studentsList);
    } else if (viewModel.selectedList == UserEnum.parent) {
      _filterSearchResults(viewModel.parentsList);
    } else {
      _filterSearchResults(viewModel.userList);
    }
  }

  tabTitle(text, UserEnum type, int selectedListTab) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    bool isSelected = type == viewModel.selectedList;
    return InkWell(
      onTap: () {
        setState(() {
          changeTabAction(type);
          viewModel.selectedListTab = selectedListTab;
        });
      },
      child: Container(
        // height: 40,
        decoration: BoxDecoration(
            color: isSelected == true
                ? AppColor.buttonGreen
                : AppColor.lightYellow,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5), topRight: Radius.circular(5))),
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 8),
            child: Text("$text".tr,
                style: PoppinsCustomTextStyle.bold.copyWith(
                    fontSize: fontSizeProvider.fontSize + 1,
                    color: AppColor.white)),
          ),
        ),
      ),
    );
  }

  Widget crudButton() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppFillButton2(
                onPressed: () {
                  setState(() {
                    isUserProfile = true;
                  });
                },
                text: "Edit"),
            AppFillButton2(
                onPressed: () {
                  deactivate();
                },
                text: "Deactivate"),
            AppFillButton2(onPressed: () {}, text: "Reset Password"),
          ],
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget roleSelect() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return SizedBox(
      height: 25,
      width: 250,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            color: themeManager.isHighContrast
                ? AppColor.text
                : AppColor.textField,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(width: 1.0, color: AppColor.textGrey)),
        child: DropdownButton(
          dropdownColor:
              themeManager.isHighContrast ? AppColor.black : AppColor.white,
          hint: Padding(
            padding: const EdgeInsets.only(left: 15, top: 2),
            child: Text("userRole".tr,
                style: NotoSansArabicCustomTextStyle.medium.copyWith(
                    fontSize: 13,
                    color: themeManager.isHighContrast
                        ? AppColor.white
                        : AppColor.textGrey)),
          ),
          icon: Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Image.asset(AppImage.arrowDown,
                width: 16,
                color: themeManager.isHighContrast
                    ? AppColor.white
                    : AppColor.black),
          ),
          isExpanded: true,
          value: roleName,
          underline: SizedBox.fromSize(),
          onChanged: (value) {
            setState(() {
              roleName = value.toString();
            });
          },
          items: userRole.map((value) {
            return DropdownMenuItem(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, left: 10),
                  child: Text(
                    value,
                    style: NotoSansArabicCustomTextStyle.regular.copyWith(
                        color: themeManager.isHighContrast
                            ? AppColor.white
                            : AppColor.text,
                        fontSize: 13),
                  ),
                ));
          }).toList(),
        ),
      ),
    );
  }

  Widget usresItems(UserManageModel model, bool isMobile) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        // height: 65,
        width: double.infinity,
        decoration: BoxDecoration(
          color:
              themeManager.isHighContrast ? AppColor.labelText : AppColor.white,
          boxShadow: const [
            BoxShadow(
                blurRadius: 15,
                offset: Offset(0, 10),
                color: AppColor.greyShadow)
          ],
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            isMobile
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              decoration: const BoxDecoration(
                                color: AppColor.lightGrey,
                                shape: BoxShape.circle,
                              ),
                              // child: Image.network(model.phonenumber.toString()),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "${model.name}",
                              overflow: TextOverflow.ellipsis,
                              style: NotoSansArabicCustomTextStyle.bold
                                  .copyWith(
                                      fontSize: fontSizeProvider.fontSize + 1,
                                      color: AppColor.black),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "${model.role}",
                          overflow: TextOverflow.ellipsis,
                          style: NotoSansArabicCustomTextStyle.bold.copyWith(
                              fontSize: fontSizeProvider.fontSize - 1,
                              color: AppColor.text),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "${model.status}",
                          overflow: TextOverflow.ellipsis,
                          style: NotoSansArabicCustomTextStyle.bold.copyWith(
                              fontSize: fontSizeProvider.fontSize - 1,
                              color: AppColor.buttonGreen),
                        ),
                        const SizedBox(height: 5),
                        AppFillButton3(
                            onPressed: () {
                              viewProfileAction(model);
                            },
                            text: "viewDetails",
                            color: AppColor.buttonGreen),
                        const SizedBox(height: 5),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: selectedLanguage == 'en' ? 30 : 0,
                              right: selectedLanguage == 'en' ? 0 : 30),
                          child: Row(
                            children: [
                              Container(
                                height: 40,
                                width: 40,
                                decoration: const BoxDecoration(
                                  color: AppColor.lightGrey,
                                  shape: BoxShape.circle,
                                ),
                                // child: Image.network(model.phonenumber.toString()),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${model.name}",
                                      overflow: TextOverflow.ellipsis,
                                      style: NotoSansArabicCustomTextStyle.bold
                                          .copyWith(
                                              fontSize:
                                                  fontSizeProvider.fontSize + 1,
                                              color: AppColor.black),
                                    ),
                                    Text(
                                      "${model.role}",
                                      overflow: TextOverflow.ellipsis,
                                      style: NotoSansArabicCustomTextStyle.bold
                                          .copyWith(
                                              fontSize:
                                                  fontSizeProvider.fontSize - 1,
                                              color: AppColor.text),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: selectedLanguage == 'en' ? 110 : 0,
                              left: selectedLanguage == 'en' ? 0 : 110),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    "${model.status}",
                                    overflow: TextOverflow.ellipsis,
                                    style: NotoSansArabicCustomTextStyle.bold
                                        .copyWith(
                                            fontSize:
                                                fontSizeProvider.fontSize - 1,
                                            color: AppColor.buttonGreen),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: AppFillButton3(
                                    onPressed: () {
                                      viewProfileAction(model);
                                    },
                                    text: "viewDetails",
                                    color: AppColor.buttonGreen),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget searchBox() {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
          color:
              themeManager.isHighContrast ? AppColor.labelText : AppColor.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: AppColor.greyShadow,
              blurRadius: 15,
              offset: Offset(0, 10),
            ),
          ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SizedBox(
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                    _filterSearchResults(viewModel.userList);
                  });
                },
                style: NotoSansArabicCustomTextStyle.regular.copyWith(
                    color: themeManager.isHighContrast
                        ? AppColor.black
                        : AppColor.labelText,
                    fontSize: fontSizeProvider.fontSize + 1),
                decoration: InputDecoration(
                    border: InputBorder.none,
                    hintStyle: NotoSansArabicCustomTextStyle.regular.copyWith(
                        color: themeManager.isHighContrast
                            ? AppColor.black
                            : AppColor.labelText,
                        fontSize: fontSizeProvider.fontSize + 1),
                    hintText: "searchHint".tr,
                    contentPadding: EdgeInsets.only(
                        left: selectedLanguage == 'en' ? 20 : 0,
                        right: selectedLanguage == 'en' ? 0 : 20)),
              ),
            ),
          ),
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
                color: AppColor.buttonGreen,
                borderRadius: BorderRadius.only(
                  bottomRight:
                      Radius.circular(selectedLanguage == 'en' ? 10 : 0),
                  topRight: Radius.circular(selectedLanguage == 'en' ? 10 : 0),
                  bottomLeft:
                      Radius.circular(selectedLanguage == 'en' ? 0 : 10),
                  topLeft: Radius.circular(selectedLanguage == 'en' ? 0 : 10),
                )),
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(Icons.search, size: 30, color: AppColor.white),
            ),
          )
        ],
      ),
    );
  }
}

enum UserEnum { all, teacher, parent, student }
