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
  String? _userRole;
  String _selectedGradeFilter = 'all';
  String _selectedSubjectFilter = 'all';

  bool get _isHeadmasterRole {
    final role =
        (_userRole ?? '').toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    return role == 'headmaster' ||
        role == 'headmasters' ||
        role == 'admin' ||
        role == 'administrator' ||
        role.contains('headmaster');
  }

  bool get _shouldShowLowMarksSection {
    final hasRole = (_userRole ?? '').trim().isNotEmpty;
    return _isHeadmasterRole || (!hasRole && widget.isAlerts != true);
  }

  fetchNotification() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    _userRole = prefs.getString('role');
    print("Alerts screen role: $_userRole");

    int? code = await viewModel.fetchAlertsNotification(userId ?? "");
    if (code == 200) {
      print("Fetch success notification list");
    } else {
      print("Notification List Error : ${viewModel.apiError}");
    }

    if (_shouldShowLowMarksSection) {
      final lowMarksCode = await viewModel.fetchLowMarksAlertsForHeadmaster();
      if (lowMarksCode == 200) {
        print("Fetch success low marks alerts");
      } else {
        print("Low marks alerts fetch error: ${viewModel.apiError}");
      }
    }
  }

  String formatDate(String dateString) {
    try {
      final parsedDate =
          DateTime.parse(dateString); // Parse the string into DateTime
      return DateFormat('dd-MM-yyyy')
          .format(parsedDate); // Format it as dd-MM-yyyy
    } catch (_) {
      return dateString;
    }
  }

  String _formatOutOfTen(double value) => value.toStringAsFixed(2);

  int? _extractKgOrder(String gradeText) {
    final normalized = gradeText
        .toUpperCase()
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (RegExp(r'\bKG\s*1\b').hasMatch(normalized) ||
        RegExp(r'\bKINDERGARTEN\s*1\b').hasMatch(normalized)) {
      return 1;
    }
    if (RegExp(r'\bKG\s*2\b').hasMatch(normalized) ||
        RegExp(r'\bKINDERGARTEN\s*2\b').hasMatch(normalized)) {
      return 2;
    }
    return null;
  }

  int _extractGradeOrder(String gradeText) {
    final kgOrder = _extractKgOrder(gradeText);
    if (kgOrder != null) return kgOrder - 1;
    final normalized = gradeText.toUpperCase().replaceAll('_', ' ');
    final match = RegExp(r'\b(\d{1,2})\b').firstMatch(normalized);
    if (match == null) return 999;
    final gradeNumber = int.tryParse(match.group(1)!);
    return gradeNumber == null ? 999 : gradeNumber + 1;
  }

  int _extractTrackOrder(String gradeText) {
    final normalized = gradeText.toUpperCase();
    if (normalized.contains('SCIENCE') || normalized.contains('(SC)')) return 0;
    if (normalized.contains('LITERATURE') || normalized.contains('(LI)')) {
      return 1;
    }
    return 2;
  }

  String _canonicalGrade(String gradeText) {
    final raw = gradeText.trim();
    if (raw.isEmpty) return raw;
    final normalized = raw
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toUpperCase();
    final kgOrder = _extractKgOrder(normalized);
    if (kgOrder != null) return 'KG$kgOrder';
    final match = RegExp(r'\b(\d{1,2})\b').firstMatch(normalized);
    if (match == null) return normalized;
    final n = match.group(1)!;
    final hasScience = RegExp(r'\bSCIENCE\b').hasMatch(normalized);
    final hasLiterature = RegExp(r'\bLITERATURE\b').hasMatch(normalized);
    if (hasScience) return 'GRADE $n(SCIENCE)';
    if (hasLiterature) return 'GRADE $n(LITERATURE)';
    return 'GRADE $n';
  }

  String _displayGradeLabel(String gradeValue) {
    if (gradeValue == 'all') return "all".tr;
    final canonical = _canonicalGrade(gradeValue);
    if (canonical == 'KG1' || canonical == 'KG2') {
      final isArabic = (Get.locale?.languageCode ?? 'en').startsWith('ar');
      final kgOrder = canonical == 'KG1' ? 1 : 2;
      return isArabic ? 'الروضة $kgOrder' : 'KG$kgOrder';
    }
    final gradeNo = _extractGradeOrder(canonical);
    final isArabic = (Get.locale?.languageCode ?? 'en').startsWith('ar');

    if (isArabic && gradeNo >= 1 && gradeNo <= 12) {
      if (canonical.contains('(SCIENCE)')) return 'الصف $gradeNo (علمي)';
      if (canonical.contains('(LITERATURE)')) return 'الصف $gradeNo (أدبي)';
      return 'الصف $gradeNo';
    }
    return canonical;
  }

  List<String> _availableGrades() {
    final baseGrades = <String>[
      'KG1',
      'KG2',
      ...List<String>.generate(10, (i) => 'GRADE ${i + 1}'),
      'GRADE 11(SCIENCE)',
      'GRADE 11(LITERATURE)',
      'GRADE 12(SCIENCE)',
      'GRADE 12(LITERATURE)',
    ];
    final gradesFromData = viewModel.lowMarkAlerts
        .map((e) => _canonicalGrade(e.grade))
        .where((g) => g.isNotEmpty)
        .where((g) => g != 'GRADE 11' && g != 'GRADE 12')
        .toSet()
        .toList();
    final grades = <String>{...baseGrades, ...gradesFromData}.toList()
      ..sort((a, b) {
        final aOrder = _extractGradeOrder(a);
        final bOrder = _extractGradeOrder(b);
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        final aTrackOrder = _extractTrackOrder(a);
        final bTrackOrder = _extractTrackOrder(b);
        if (aTrackOrder != bTrackOrder) {
          return aTrackOrder.compareTo(bTrackOrder);
        }
        return a.compareTo(b);
      });
    return ['all', ...grades];
  }

  List<String> _availableSubjectsForSelectedGrade() {
    final source = _selectedGradeFilter == 'all'
        ? viewModel.lowMarkAlerts
        : viewModel.lowMarkAlerts
            .where((e) => _canonicalGrade(e.grade) == _selectedGradeFilter)
            .toList();
    final subjects = source
        .map((e) => e.subject.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['all', ...subjects];
  }

  List<LowMarkAlertItem> _filteredLowMarkAlerts() {
    return viewModel.lowMarkAlerts.where((e) {
      final gradeOk = _selectedGradeFilter == 'all' ||
          _canonicalGrade(e.grade) == _selectedGradeFilter;
      final subjectOk = _selectedSubjectFilter == 'all' ||
          e.subject.trim() == _selectedSubjectFilter;
      return gradeOk && subjectOk;
    }).toList();
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
              backgroundColor: AppColor.bgLavender,
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
                                fontSize: 18, color: AppColor.panelDark),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            child: _shouldShowLowMarksSection
                                ? Column(
                                    children: [
                                      lowMarksAlertsSection(themeManager),
                                      const SizedBox(height: 50),
                                    ],
                                  )
                                : _buildAlertsAndNotifications(themeManager),
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

  Widget _buildAlertsAndNotifications(ThemeManager themeManager) {
    return Column(
      children: [
        viewModel.alertsList.isEmpty
            ? Center(
                child: Text("norecordYet".tr),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                primary: false,
                itemCount: viewModel.alertsList.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      decoration: BoxDecoration(
                          color: AppColor.panelDarkSoft,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                                color: AppColor.greyShadow,
                                blurRadius: 5,
                                offset: Offset(0, 5))
                          ]),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text("date".tr,
                                    style: NotoSansArabicCustomTextStyle.bold
                                        .copyWith(
                                            fontSize: 15,
                                            color: AppColor.white)),
                                Text(
                                    formatDate(
                                        "${viewModel.alertsList[index].date}"),
                                    style: NotoSansArabicCustomTextStyle.regular
                                        .copyWith(
                                            fontSize: 14,
                                            color: AppColor.white))
                              ],
                            ),
                            const SizedBox(height: 7),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${"message".tr} : ",
                                    style: NotoSansArabicCustomTextStyle.bold
                                        .copyWith(
                                            fontSize: 15,
                                            color: AppColor.white)),
                                Expanded(
                                  child: Text(
                                      "${viewModel.alertsList[index].aiGeneratedMessage}",
                                      style: NotoSansArabicCustomTextStyle
                                          .regular
                                          .copyWith(
                                              fontSize: 14,
                                              color: AppColor.white)),
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
        const SizedBox(height: 5),
        widget.isAlerts == true
            ? const SizedBox()
            : viewModel.notificationsList.isEmpty
                ? Center(
                    child: Text("norecordYet".tr),
                  )
                : ListView.builder(
                    itemCount: viewModel.notificationsList.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    primary: false,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Container(
                          decoration: BoxDecoration(
                              color: AppColor.panelDarkSoft,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                    color: AppColor.greyShadow,
                                    blurRadius: 5,
                                    offset: Offset(0, 5))
                              ]),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text("date".tr,
                                        style: NotoSansArabicCustomTextStyle
                                            .bold
                                            .copyWith(
                                                fontSize: 15,
                                                color: AppColor.white)),
                                    Text(
                                        formatDate(
                                            "${viewModel.notificationsList[index].createdAt}"),
                                        style: NotoSansArabicCustomTextStyle
                                            .regular
                                            .copyWith(
                                                fontSize: 14,
                                                color: AppColor.white))
                                  ],
                                ),
                                const SizedBox(height: 7),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("${"message".tr} : ",
                                        style: NotoSansArabicCustomTextStyle
                                            .bold
                                            .copyWith(
                                                fontSize: 15,
                                                color: AppColor.white)),
                                    Expanded(
                                      child: Text(
                                          "${viewModel.notificationsList[index].title}",
                                          style: NotoSansArabicCustomTextStyle
                                              .regular
                                              .copyWith(
                                                  fontSize: 14,
                                                  color: AppColor.white)),
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
        const SizedBox(height: 50),
      ],
    );
  }

  Widget lowMarksAlertsSection(ThemeManager themeManager) {
    final gradeOptions = _availableGrades();
    if (!gradeOptions.contains(_selectedGradeFilter)) {
      _selectedGradeFilter = 'all';
    }
    final subjectOptions = _availableSubjectsForSelectedGrade();
    if (!subjectOptions.contains(_selectedSubjectFilter)) {
      _selectedSubjectFilter = 'all';
    }
    final filteredItems = _filteredLowMarkAlerts();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: AppColor.panelDarkSoft,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
                color: AppColor.greyShadow, blurRadius: 5, offset: Offset(0, 5))
          ]),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "lowMarksAlertsTitle".tr,
              style: NotoSansArabicCustomTextStyle.bold
                  .copyWith(fontSize: 16, color: AppColor.white),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGradeFilter,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: "grade".tr,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      filled: true,
                      fillColor: AppColor.textField,
                      labelStyle: const TextStyle(color: AppColor.textGrey),
                    ),
                    dropdownColor: AppColor.panelDark,
                    style: const TextStyle(color: AppColor.white),
                    items: gradeOptions
                        .map((g) => DropdownMenuItem<String>(
                              value: g,
                              child: Text(
                                _displayGradeLabel(g),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedGradeFilter = value;
                        _selectedSubjectFilter = 'all';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSubjectFilter,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: "subject".tr,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      filled: true,
                      fillColor: AppColor.textField,
                      labelStyle: const TextStyle(color: AppColor.textGrey),
                    ),
                    dropdownColor: AppColor.panelDark,
                    style: const TextStyle(color: AppColor.white),
                    items: subjectOptions
                        .map((s) => DropdownMenuItem<String>(
                              value: s,
                              child: Text(
                                s == 'all' ? "all".tr : s,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedSubjectFilter = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            filteredItems.isEmpty
                ? Text(
                    "noLowMarksAlerts".tr,
                    style: NotoSansArabicCustomTextStyle.regular
                        .copyWith(fontSize: 14, color: AppColor.white),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColor.lightGrey),
                          color: AppColor.panelDarkSoft,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.studentName,
                                style: NotoSansArabicCustomTextStyle.bold
                                    .copyWith(
                                        fontSize: 15, color: AppColor.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${"email".tr} ${item.studentEmail}",
                                style: NotoSansArabicCustomTextStyle.regular
                                    .copyWith(
                                        fontSize: 13, color: AppColor.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${"grade".tr} : ${_displayGradeLabel(item.grade)}",
                                style: NotoSansArabicCustomTextStyle.regular
                                    .copyWith(
                                        fontSize: 13, color: AppColor.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${"subject".tr} : ${item.subject}",
                                style: NotoSansArabicCustomTextStyle.regular
                                    .copyWith(
                                        fontSize: 13, color: AppColor.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${"assignedteacher".tr} : ${item.teacherName}",
                                style: NotoSansArabicCustomTextStyle.regular
                                    .copyWith(
                                        fontSize: 13, color: AppColor.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${"marksOutOfTen".tr} : ${_formatOutOfTen(item.normalizedMarkOutOfTen)} / 10",
                                style: NotoSansArabicCustomTextStyle.semibold
                                    .copyWith(
                                        fontSize: 13,
                                        color: Colors.red.shade700),
                              ),
                              if (item.timestamp != null &&
                                  item.timestamp!.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    "${"date".tr} ${formatDate(item.timestamp!)}",
                                    style: NotoSansArabicCustomTextStyle.regular
                                        .copyWith(
                                            fontSize: 12,
                                            color: AppColor.textGrey),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
