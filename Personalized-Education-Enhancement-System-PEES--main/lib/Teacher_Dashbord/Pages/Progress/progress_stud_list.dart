import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/HeadMaster_Dashboard/Model/studentModel.dart';
import 'package:pees/HeadMaster_Dashboard/Services/headMaster_services.dart';
import 'package:pees/Teacher_Dashbord/Pages/Progress/progress_screen.dart';
import 'package:pees/Widgets/AppButton.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/custom_class/my_appBar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressStudList extends StatefulWidget {
  const ProgressStudList({super.key});

  @override
  State<ProgressStudList> createState() => _ProgressStudListState();
}

class _ProgressStudListState extends State<ProgressStudList> {
  HeadMasterServices viewModel = HeadMasterServices();
  TextEditingController searchController = TextEditingController();
  String selectedLanguage = Get.locale?.languageCode ?? 'en';
  StudentModel? model;
  List<StudentModel> searchResults = [];
  String searchText = '';
  bool isSearching = false;
  int currentPage = 1;
  final int itemsPerPage = 5;

  viewDetailsAction(StudentModel model) async {
    // Route route = MaterialPageRoute(
    //     builder: (context) => ProgressScreen(model: model));
    // Navigator.push(context, route).then(onGoBack);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ProgressScreen.fromModel(model: model)));
  }

  FutureOr onGoBack(dynamic isRefesh) {
    if (isRefesh) {
      refreshStudentList();
    }
  }

  refreshStudentList() {
    fetchDetails();
  }

  fetchDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? teacherId = prefs.getString('userId');
    List<StudentModel>? models =
        await viewModel.fetchStudentList(teacherId ?? "");
    if (models != null) {
      model = models.first;
    }
  }

  void _filterSearchResults(List<StudentModel> list) {
    setState(() {
      isSearching = true;
      searchResults = list
          .where((element) =>
              element.studentName!
                  .toLowerCase()
                  .contains(searchText.toLowerCase()) ||
              element.grade!.toLowerCase().contains(searchText.toLowerCase()) ||
              element.classSection!
                  .toLowerCase()
                  .contains(searchText.toLowerCase()))
          .toList();
      currentPage = 1;
    });
  }

  @override
  void initState() {
    fetchDetails().then((_) {
      _filterSearchResults(viewModel.studentList!);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (searchResults.isEmpty) {
      setState(() {
        _filterSearchResults(viewModel.studentList!);
      });
    }

    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = (currentPage * itemsPerPage) < searchResults.length
        ? currentPage * itemsPerPage
        : searchResults.length;
    final currentList = searchResults.sublist(startIndex, endIndex);
    return ChangeNotifierProvider<HeadMasterServices>(
        create: (BuildContext context) => viewModel,
        child: Consumer<HeadMasterServices>(builder: (context, value, _) {
          return LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth <= 800;
            return Scaffold(
              backgroundColor:
                  isMobile ? AppColor.bgLavender : AppColor.panelDark,
              appBar: PreferredSize(
                  preferredSize: const Size(double.infinity, 50),
                  child: isMobile ? MyAppBar("") : const SizedBox()),
              body: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        isMobile ? 10 : 18,
                        isMobile ? 10 : 18,
                        isMobile ? 10 : 18,
                        isMobile ? 6 : 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColor.panelDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColor.lightGrey, width: 1),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 20, right: 20, top: 20),
                            child: Column(
                              children: [
                                searchBox(),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: ListView.builder(
                                itemCount: currentList.length,
                                itemBuilder: (context, index) {
                                  return studentItems(
                                      currentList[index], isMobile);
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(5, 3, 5, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    if (currentPage > 1) {
                                      setState(() {
                                        currentPage--;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.arrow_back,
                                      color: AppColor.text),
                                ),
                                Text(
                                  "$currentPage/${(searchResults.length / itemsPerPage).ceil()}",
                                  style: NotoSansArabicCustomTextStyle.semibold
                                      .copyWith(
                                          color: AppColor.text, fontSize: 16),
                                ),
                                IconButton(
                                  onPressed: () {
                                    if (currentPage <
                                        (searchResults.length / itemsPerPage)
                                            .ceil()) {
                                      setState(() {
                                        currentPage++;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.arrow_forward,
                                      color: AppColor.text),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget studentItems(StudentModel model, bool isMobile) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Container(
          height: isMobile ? null : 98,
          decoration: BoxDecoration(
              color: AppColor.panelDarkSoft,
              boxShadow: const [
                BoxShadow(
                    blurRadius: 5,
                    offset: Offset(0, 5),
                    color: AppColor.greyShadow)
              ],
              borderRadius: BorderRadius.circular(5)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isMobile
                  ? Column(
                      // mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                              top: 15,
                              left: selectedLanguage == 'en' ? 20 : 0,
                              right: selectedLanguage == 'en' ? 0 : 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 30,
                                    width: 30,
                                    decoration: const BoxDecoration(
                                      color: AppColor.lightGrey,
                                      shape: BoxShape.circle,
                                    ),
                                    // child: Image.network(model.phonenumber.toString()),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Text(
                                      "${model.studentName}",
                                      overflow: TextOverflow.ellipsis,
                                      style: NotoSansArabicCustomTextStyle.bold
                                          .copyWith(
                                              fontSize:
                                                  fontSizeProvider.fontSize + 2,
                                              color: AppColor.text),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "${"grade".tr} : ${model.grade}",
                                overflow: TextOverflow.ellipsis,
                                style: NotoSansArabicCustomTextStyle.bold
                                    .copyWith(
                                        fontSize: fontSizeProvider.fontSize,
                                        color: AppColor.text),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                model.classSection.toString(),
                                style: NotoSansArabicCustomTextStyle.bold
                                    .copyWith(
                                        fontSize: fontSizeProvider.fontSize,
                                        color: AppColor.text),
                              ),
                              const SizedBox(height: 5),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: AppFillButton3(
                                    onPressed: () {
                                      viewDetailsAction(model);
                                    },
                                    text: "viewDetails",
                                    color: AppColor.buttonGreen),
                              ),
                            ],
                          ),
                        )
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: EdgeInsets.only(
                                top: 15,
                                left: selectedLanguage == 'en' ? 20 : 0,
                                right: selectedLanguage == 'en' ? 0 : 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 30,
                                  width: 30,
                                  decoration: const BoxDecoration(
                                    color: AppColor.lightGrey,
                                    shape: BoxShape.circle,
                                  ),
                                  // child: Image.network(model.phonenumber.toString()),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    "${model.studentName}",
                                    overflow: TextOverflow.ellipsis,
                                    style: NotoSansArabicCustomTextStyle.bold
                                        .copyWith(
                                            fontSize:
                                                fontSizeProvider.fontSize + 2,
                                            color: AppColor.text),
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
                                    alignment: Alignment.topCenter,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 15),
                                      child: Text(
                                        "${"grade".tr} : ${model.grade}",
                                        overflow: TextOverflow.ellipsis,
                                        style: NotoSansArabicCustomTextStyle
                                            .bold
                                            .copyWith(
                                                fontSize:
                                                    fontSizeProvider.fontSize,
                                                color: AppColor.text),
                                      ),
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 10),
                                    Text(
                                      model.classSection.toString(),
                                      style: NotoSansArabicCustomTextStyle.bold
                                          .copyWith(
                                              fontSize:
                                                  fontSizeProvider.fontSize,
                                              color: AppColor.text),
                                    ),
                                    const SizedBox(height: 5),
                                    AppFillButton3(
                                        onPressed: () {
                                          viewDetailsAction(model);
                                        },
                                        text: "viewDetails",
                                        color: AppColor.buttonGreen)
                                  ],
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
      ),
    );
  }

  Widget searchBox() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
          color: AppColor.panelDarkSoft,
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
                    _filterSearchResults(viewModel.studentList!);
                  });
                },
                style: NotoSansArabicCustomTextStyle.regular.copyWith(
                    color: AppColor.text,
                    fontSize: fontSizeProvider.fontSize + 1),
                decoration: InputDecoration(
                    border: InputBorder.none,
                    hintStyle: NotoSansArabicCustomTextStyle.regular.copyWith(
                        color: AppColor.labelText,
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
