// ignore_for_file: use_build_context_synchronously
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/HeadMaster_Dashboard/Model/student_profile.dart';
import 'package:pees/HeadMaster_Dashboard/Services/headMaster_services.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/AppTextField.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/Widgets/utils.dart';
import 'dart:html' as html;
import 'package:provider/provider.dart';

class UpdateStudentDetails extends StatefulWidget {
  String? studentId;
  UpdateStudentDetails(this.studentId, {super.key});

  @override
  State<UpdateStudentDetails> createState() => _UpdateStudentDetailsState();
}

class _UpdateStudentDetailsState extends State<UpdateStudentDetails> {
  HeadMasterServices masterViewModel = HeadMasterServices();
  String selectedLanguage = Get.locale?.languageCode ?? 'en';
  StudentProfileModel? studModel;
  TextEditingController studentNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController gradeController = TextEditingController();
  TextEditingController classController = TextEditingController();
  Uint8List? imageData;
  Uint8List? showImage;

  saveStudentDetails() async {
    String name = studentNameController.text;
    String address = addressController.text;
    String studId = widget.studentId ?? "";
    String email = emailController.text;
    String phone = phoneController.text;
    String grade = gradeController.text;
    String section = classController.text;

    int? code = await masterViewModel.updateStudentDetails(
        studId, name, address, email, phone, grade, section);

    print("Student Id: $studId");

    if (code == 200) {
      if (imageData != null) {
        int? imageCode =
            await masterViewModel.uploadStudentImage(studId, imageData!);
        if (context.mounted) {
          if (imageCode == 200) {
            Utils.snackBar("bothSuccess".tr, context);
            print("Returning TRUE to refresh list");
            Navigator.of(context)
              ..pop(true)
              ..pop(true); // ✅ Returning true after update
            // fetchDetails();
          } else {
            print("Image Upload Error: ${masterViewModel.apiError}");
            Utils.snackBar(masterViewModel.apiError!, context);
          }
        }
      } else {
        if (context.mounted) {
          Utils.snackBar("successStudentDetails".tr, context);
          print("Returning TRUE to refresh list");
          Navigator.of(context)
            ..pop(true)
            ..pop(true);
          // fetchDetails();
          // ✅ Returning true after update
        }
      }
    } else {
      if (context.mounted) {
        print("Details Update Error: ${masterViewModel.apiError}");
        Utils.snackBar(masterViewModel.apiError!, context);
      }
    }
  }

  setStudentDetails() async {
    StudentProfileModel? model = await masterViewModel
        .fetchStudentProfileDetails(widget.studentId ?? "");
    if (model != null) {
      studModel = model;
    }
    setState(() {
      print("Student ID : ${studModel?.studentId}");
      print("Image URL : ${studModel?.photoUrl}");
      studentNameController.text = studModel?.studentName ?? "";
      phoneController.text = studModel?.phoneNumber ?? "";
      emailController.text = studModel?.email ?? "";
      addressController.text = studModel?.address ?? "";
      gradeController.text = studModel?.grade ?? "";
      classController.text = studModel?.classSection ?? "";
    });
  }

  // void pickImage() {
  //   html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
  //   uploadInput.accept = 'image/*';
  //   uploadInput.click();

  //   uploadInput.onChange.listen((event) {
  //     final files = uploadInput.files;
  //     if (files != null && files.isNotEmpty) {
  //       final file = files[0];
  //       final reader = html.FileReader();
  //       reader.readAsArrayBuffer(file);
  //       setState(() {
  //         reader.onLoadEnd.listen((e) {
  //           imageData = reader.result as Uint8List?;
  //         });
  //       });
  //     }
  //   });
  // }

  void pickImage() {
    html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);

        reader.onLoadEnd.listen((e) {
          setState(() {
            imageData = reader.result as Uint8List?;
            print(
                "Image Loaded: ${imageData?.length} bytes"); // Debugging print
          });
        });

        reader.onError.listen((error) {
          print("Error reading file: $error");
        });
      }
    });
  }

  @override
  void initState() {
    setStudentDetails();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HeadMasterServices>(
        create: (BuildContext context) => masterViewModel,
        child: Consumer<HeadMasterServices>(builder: (context, value, _) {
          return LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth <= 800;
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  isMobile ? const SizedBox() : const BackButtonWidget(),
                  Padding(
                    padding: EdgeInsets.only(
                        left: isMobile ? 12 : 100,
                        right: isMobile ? 12 : 100,
                        top: isMobile ? 12 : 30),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          isMobile
                              ? const BackButtonWidget()
                              : const SizedBox(),
                          isMobile
                              ? const SizedBox(height: 5)
                              : const SizedBox(),
                          studentDetailsForm(isMobile)
                        ],
                      ),
                    ),
                  ),
                  value.loading ? const LoaderView() : Container()
                ],
              ),
            );
          });
        }));
  }

  Widget studentDetailsForm(bool isMobile) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return SizedBox(
      child: Column(
        children: [
          Container(
            height: 82,
            decoration: const BoxDecoration(
                color: AppColor.buttonGreen,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5), topRight: Radius.circular(5))),
            child: Padding(
              padding: EdgeInsets.only(
                  left: selectedLanguage == "en"
                      ? isMobile
                          ? 10
                          : 30
                      : 0,
                  right: selectedLanguage == "en"
                      ? isMobile
                          ? 10
                          : 0
                      : 30),
              child: Align(
                alignment: selectedLanguage == "en"
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Text(
                  studModel?.studentName.toString() ?? "",
                  style: PoppinsCustomTextStyle.bold.copyWith(
                      fontSize: fontSizeProvider.fontSize + 2,
                      color: AppColor.white),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: isMobile ? MediaQuery.of(context).size.height : 580,
            decoration: BoxDecoration(
                color: AppColor.panelDarkSoft,
                boxShadow: [
                  const BoxShadow(
                      color: AppColor.greyShadow,
                      blurRadius: 15,
                      offset: Offset(0, 10)),
                ],
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(5),
                    bottomRight: Radius.circular(5))),
            child: Padding(
              padding: EdgeInsets.only(
                  top: 20,
                  left: selectedLanguage == "en"
                      ? isMobile
                          ? 10
                          : 30
                      : 0,
                  right: selectedLanguage == "en"
                      ? isMobile
                          ? 10
                          : 0
                      : 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("changeProfile".tr,
                      style: PoppinsCustomTextStyle.semibold.copyWith(
                          color: AppColor.black,
                          fontSize: fontSizeProvider.fontSize)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 50),
                      Container(
                          width: 79,
                          height: 79,
                          decoration: const BoxDecoration(
                              // color: AppColor.lightGrren,
                              shape: BoxShape.circle),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: CircleAvatar(
                                radius: 50,
                                backgroundImage: imageData != null
                                    ? MemoryImage(
                                        imageData!) // Show newly uploaded image
                                    : NetworkImage(studModel?.photoUrl ??
                                        "") // Show stored profile image

                                ),
                          )),
                      const SizedBox(width: 50),
                      isMobile
                          ? const SizedBox()
                          : InkWell(
                              onTap: () {
                                pickImage();
                              },
                              child: Container(
                                height: 40,
                                width: 160,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                        color: AppColor.buttonGreen, width: 2)),
                                child: Center(
                                  child: Text(
                                    "clicktochange".tr,
                                    style: PoppinsCustomTextStyle.medium
                                        .copyWith(
                                            fontSize: fontSizeProvider.fontSize,
                                            color: AppColor.buttonGreen),
                                  ),
                                ),
                              ),
                            )
                    ],
                  ),
                  isMobile ? const SizedBox(height: 10) : const SizedBox(),
                  isMobile
                      ? InkWell(
                          onTap: () {
                            pickImage();
                          },
                          child: Container(
                            height: 40,
                            width: 160,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                    color: AppColor.buttonGreen, width: 2)),
                            child: Center(
                              child: Text(
                                "clicktochange".tr,
                                style: PoppinsCustomTextStyle.medium.copyWith(
                                    fontSize: fontSizeProvider.fontSize,
                                    color: AppColor.buttonGreen),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(),
                  const SizedBox(height: 15),
                  isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "nameTitle".tr,
                              style: PoppinsCustomTextStyle.semibold.copyWith(
                                  color: AppColor.black,
                                  fontSize: fontSizeProvider.fontSize),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              height: 35,
                              // width: 650,
                              child: AppTextFieldBlank(
                                  textController: studentNameController,
                                  hintText: "fName".tr,
                                  icon: null),
                            ),
                            const SizedBox(height: 10),
                            Text("emailTitle".tr,
                                style: PoppinsCustomTextStyle.semibold.copyWith(
                                    color: AppColor.black,
                                    fontSize: fontSizeProvider.fontSize)),
                            const SizedBox(height: 5),
                            SizedBox(
                              height: 35,
                              // width: 650,
                              child: AppTextFieldBlank(
                                  textController: emailController,
                                  hintText: "emailHintTitle".tr,
                                  icon: null),
                            ),
                            const SizedBox(height: 10),
                            Text("phone".tr,
                                style: PoppinsCustomTextStyle.semibold.copyWith(
                                    color: AppColor.black,
                                    fontSize: fontSizeProvider.fontSize)),
                            const SizedBox(height: 5),
                            SizedBox(
                              height: 35,
                              width: 650,
                              child: AppTextFieldBlank(
                                  inputType: TextInputType.number,
                                  textController: phoneController,
                                  hintText: "1234567890",
                                  icon: null),
                            ),
                            const SizedBox(height: 10),
                            Text("address".tr,
                                style: PoppinsCustomTextStyle.semibold.copyWith(
                                    color: AppColor.black,
                                    fontSize: fontSizeProvider.fontSize)),
                            const SizedBox(height: 5),
                            SizedBox(
                              height: 35,
                              width: 650,
                              child: AppTextFieldBlank(
                                  textController: addressController,
                                  hintText: "address".tr,
                                  icon: null),
                            ),
                            Text("grade".tr,
                                style: PoppinsCustomTextStyle.semibold.copyWith(
                                    color: AppColor.black,
                                    fontSize: fontSizeProvider.fontSize)),
                            const SizedBox(width: 42),
                            SizedBox(
                              height: 35,
                              width: 650,
                              child: AppTextFieldBlank(
                                  textController: gradeController,
                                  hintText: "grade".tr,
                                  icon: null),
                            ),
                            const SizedBox(height: 10),
                            Text("section".tr,
                                style: PoppinsCustomTextStyle.semibold.copyWith(
                                    color: AppColor.black,
                                    fontSize: fontSizeProvider.fontSize)),
                            const SizedBox(height: 5),
                            SizedBox(
                              height: 35,
                              width: 650,
                              child: AppTextFieldBlank(
                                  textController: classController,
                                  hintText: "class/section".tr,
                                  icon: null),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  "nameTitle".tr,
                                  style: PoppinsCustomTextStyle.semibold
                                      .copyWith(
                                          color: AppColor.black,
                                          fontSize: fontSizeProvider.fontSize),
                                ),
                                const SizedBox(width: 45),
                                SizedBox(
                                  height: 35,
                                  width: 650,
                                  child: AppTextFieldBlank(
                                      textController: studentNameController,
                                      hintText: "fName".tr,
                                      icon: null),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Text("emailTitle".tr,
                                    style: PoppinsCustomTextStyle.semibold
                                        .copyWith(
                                            color: AppColor.black,
                                            fontSize:
                                                fontSizeProvider.fontSize)),
                                const SizedBox(width: 49),
                                SizedBox(
                                  height: 35,
                                  width: 650,
                                  child: AppTextFieldBlank(
                                      textController: emailController,
                                      hintText: "emailHintTitle".tr,
                                      icon: null),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Text("phone".tr,
                                    style: PoppinsCustomTextStyle.semibold
                                        .copyWith(
                                            color: AppColor.black,
                                            fontSize:
                                                fontSizeProvider.fontSize)),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 35,
                                  width: 650,
                                  child: AppTextFieldBlank(
                                      textController: phoneController,
                                      hintText: "1234567890",
                                      icon: null),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Text("address".tr,
                                    style: PoppinsCustomTextStyle.semibold
                                        .copyWith(
                                            color: AppColor.black,
                                            fontSize:
                                                fontSizeProvider.fontSize)),
                                const SizedBox(width: 23),
                                SizedBox(
                                  height: 35,
                                  width: 650,
                                  child: AppTextFieldBlank(
                                      textController: addressController,
                                      hintText: "address".tr,
                                      icon: null),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Text("grade".tr,
                                    style: PoppinsCustomTextStyle.semibold
                                        .copyWith(
                                            color: AppColor.black,
                                            fontSize:
                                                fontSizeProvider.fontSize)),
                                const SizedBox(width: 42),
                                SizedBox(
                                  height: 35,
                                  width: 650,
                                  child: AppTextFieldBlank(
                                      textController: gradeController,
                                      hintText: "grade".tr,
                                      icon: null),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Text("section".tr,
                                    style: PoppinsCustomTextStyle.semibold
                                        .copyWith(
                                            color: AppColor.black,
                                            fontSize:
                                                fontSizeProvider.fontSize)),
                                const SizedBox(width: 29),
                                SizedBox(
                                  height: 35,
                                  width: 650,
                                  child: AppTextFieldBlank(
                                      textController: classController,
                                      hintText: "class/section".tr,
                                      icon: null),
                                ),
                              ],
                            ),
                          ],
                        ),
                  const SizedBox(height: 25),
                  Padding(
                    padding: EdgeInsets.only(
                        right: selectedLanguage == "en"
                            ? isMobile
                                ? 10
                                : 60
                            : 0,
                        left: selectedLanguage == "en" ? 0 : 60),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 150,
                            height: 40,
                            decoration: BoxDecoration(
                                color: AppColor.lightBrown,
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColor.buttonShadow,
                                    blurRadius: 5,
                                    offset: Offset(0, 5),
                                  )
                                ]),
                            child: Center(
                              child: Text(
                                "cancel".tr,
                                style: PoppinsCustomTextStyle.medium.copyWith(
                                    fontSize: fontSizeProvider.fontSize,
                                    color: AppColor.brown),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        InkWell(
                          onTap: () {
                            saveStudentDetails();
                            // uploadImageAction();
                          },
                          child: Container(
                            width: 120,
                            height: 40,
                            decoration: BoxDecoration(
                                color: AppColor.buttonGreen,
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColor.buttonShadow,
                                    blurRadius: 5,
                                    offset: Offset(0, 5),
                                  )
                                ]),
                            child: Center(
                              child: Text(
                                "save".tr,
                                style: PoppinsCustomTextStyle.medium.copyWith(
                                    fontSize: fontSizeProvider.fontSize,
                                    color: AppColor.white),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
