import 'package:get/get_navigation/src/root/internacionalization.dart';

class LocaleString extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          //Login Screen
          'appName': "Personalized Education\nEnhancement System",
          'emailAddressTitle': "Email Address",
          'passwordTitle': "Password",
          'emailHint': "Email Address*",
          'passwordHint': "Password*",
          'rememberMe': "Remember me",
          'forgotPassword': "Forgot Password",
          'login': "Login",
          'english': "English",
          'arabic': "Arabic",
          'copyrightInformation': "Copyright information",
          'termsandPrivacyPolicy': "Terms and Privacy Policy",
          'loginHeroSubtitle': "Smart platform for schools",
          'loginHeroBadge': "Unified admin, teacher and parent experience",
          'loginFormSubtitle': "Enter your email and password to continue",
          // Forgot password screen
          'forgotPasswordTitle': "Forgot Password ?",
          'forgotPassowordSubTitle':
              "No worries, we’ll sent you the reset instructions.",
          'resetPassword': "Reset Password",
          'backToLogin': "Back to log in",
          // OTP Screen
          'resetPasswordsubTitle': "We sent a code to abc123@ gmail.com",
          'continue': "Continue",
          'didntemail': "Didn.t receive the email ?",
          'resendIt': "Resend it",
          // Reset Password
          'setPasswordTitle': "Set a new Password",
          'setPasswordSubTitle': "Must be at least 8 characters",
          'newPasswordTitle': "New Password",
          'newPasswordHint': "New Password*",
          'confirmPasswordTitle': "Confirm New Password",
          'confirmPasswordHint': "Confirm New Password*",
          // Headmaster Dashboard
          'dashboard': "DASHBOARD",
          'students': 'STUDENTS',
          'settings': 'SETTINGS',
          'welcome': "Welcome",
          'schoolperfo': "School Performance Metrics",
          'schoolPerformanceWindow30Days':
              "Showing results from the last 30 days",
          'noSchoolPerformanceDataLast30Days':
              "No school performance data in the last 30 days",
          'performanceByGrade': "Performance by Grade",
          'subjectsByGrade': "Subjects by Grade",
          'absenceByGrade': "Absence by Grade",
          'absentStudentsCount': "Absent students",
          'noAbsenceDataAvailable': "No absence data available yet",
          'noAbsenceDataForSelectedMonth':
              "No absences recorded for the selected month",
          'noSubjectMarksForSelectedGrade':
              "No subject marks available for selected grade",
          'schoolHint':
              "Key indicators (e.g., average grades,\nattendance rates).",
          'userManagement': "User Management",
          'userManagesubList': "Link or button to manage users.",
          'reports': "Reports",
          'reportssubList': "Quick links to recent or important reports.",
          'alerts&Noti': "Alerts and Notifications",
          'subAlert': "Section for critical messages requiring attention.",
          // User management list
          'searchSubject': "Search by subject",
          'recentUpdates': "Recent Updates",
          'username': "Username",
          'userRole': "User Role",
          'status': "Status",
          'edit': "Edit",
          'deactivate': "Deactivate",
          'addNewUser': "Add New User",
          'name': "Name : ",
          'contactNumber': "Contact Number : ",
          'email': "Email : ",
          'roleAssignment': "Role Assigment : ",
          'viewDetails': "View Details",
          'checkboxtext': "Checkboxes or toggles for specific access rights",
          'cancel': "Cancel",
          'save': "Save",
          // Profile Screen
          'nameTitle': "Name",
          'fName': "First Name",
          'emailTitle': "Email",
          'emailHintTitle': "abc123gmail.com",
          'userId': "User ID",
          'userIdHint': "abc123personal",
          'role': "Role",
          'parent': "Parent",
          'deleteUser': "Delete User",
          'deactiveUser': "Deactive User",
          'saveChanges': "Save Changes",
          // Student List(Headmaster)
          'grade': "Grade",
          'gradee': "Grade",
          'studentId': "Student ID",
          'contactInformation': "Contact Information : ",
          'phoneNumber': "Phone Number",
          'address': "Address",
          'editDetails': "Edit Details",
          //tab
          'academicData': "Academic Data",
          'teachingPlans': "Teaching Plans",
          'observation': "Observations",
          'progress': "Progress",
          // academic
          'subject': "Subject",
          'marks': "Marks",
          'attendance': "Attendance",
          'reportCard': "Report Card", //
          'totalMarks': "Total Marks",
          'obtainedMarks': "Obtained\nMarks",
          'activity': "Activity",
          'totalWorkingDay': "Total no. of working Days",
          'presentDays': "Present Days",
          'absentDays': "Absent Days",
          'halfDays ': "Half Days",
          'examName': "Exam Name : ",
          'examNameTitle': "Exam Name",
          'date': "Date : ",
          'selectedDateLabel': "Selected Date",
          'selectDate': "Select Date",
          'curriculumCoverage': "Curriculum Coverage",
          'multiselectdropdown': "Multiselect dropdown",
          'uploadFiles': "Upload Files",
          'dragandDropFiles': "Drag and Drop Files",
          'supportedFileTypesPDF,JPG': "Supported File Types PDF,JPG",
          'upload': "Upload",
          'notesandObservations': "Notes and Observations",
          'notesHint': "Text area for teachers to add comments.",
          'submit': "Submit",
          'addObservation': "Add Observation",
          'absentAutoNote': "Student marked absent.",
          'examScipts': "Exam Scipts",
          // Teaching plan
          'currentPlans': "Current Plans",
          'pastPlans': "Past Plans",
          'objectives': "Objectives :",
          'objList': "List of SMART goals.",
          'strategies': "Strategies :",
          'methodHint': "Recommended teaching methods.",
          'resources': "Resources :",
          'resoHint': "Links or references to materials.",
          'assessmentMethods': "Assessment Methods :",
          'teachMethod': "Recommended teaching methods",
          // Observation
          'selectSubject': "Select Subject",
          'selectGrade': "Select Grade",
          'selectStudentName': "Select Student",
          'observationTitle': "Observation : ",
          'attachFiles': "Attach Files : ",
          'teachersNotes': "Teacher’s Notes :", //
          'listStudent': "List of Notes for student",
          'feedback': "Feedback :",
          'providedFeedback': "Provided Feedback", //
          'behaviorInClass': "Behaviour in Class",
          'selectBehaviorInClass': "Select behaviour (optional)",
          'behaviorExcellentInteraction': "Excellent interaction in class",
          'behaviorVeryGoodInteraction': "Good interaction in class",
          'behaviorAcceptableInteraction': "Acceptable interaction in class",
          'behaviorWeakInteraction': "Weak interaction in class",
          'behaviorNoInteraction': "No interaction in class",
          'behaviorDisruptive': "Disruptive behavior in class",
          'behaviorLackOfFocus': "Lack of focus in class",
          'behaviorHomeworkNotDone': "Homework not completed",
          'subjectPerformance': "Subject Performance",
          // setting screen
          'profileSettings': "Profile Settings",
          'personalInformation': "Personal Information",
          'contactNo': "Contact No. :",
          'updateInformation': "Update Information",
          'changePassword': "Change Password",
          'oldPassword': "Old Password :",
          'newPassword': "New Password :",
          'confirmPassword': "Confirm Password :",
          'languagePreferences': "Language Preferences",
          'notificationSettings': "Notification Settings",
          'alertTypes': "Alert Types",
          'specificAlerts': "Specific Alerts",
          'deliveryMethods': "Delivery Methods",
          'sms': "SMS",
          'byOtherAPP': "By Other APP",
          'accessibilityOptions': "Accessibility Options",
          'fontSize': "Font Size",
          'contrastMode': "Contrast Mode",
          'disable': "Disable",
          'enable': "Enable",
          // Notification list
          'actions': "Actions",
          // teacher sections
          'teachingPlan': "TEACHING PLANS",
          'observationHeading': "OBSERVATIONS",
          'className': "Class Name",
          'numberofStudents': "Number of Students",
          'examScript': "Exam Script",
          'searchHint': "Student Name or Student ID",
          'noSubject':
              "No subject has been added here, so please \nadd the subject and save the report card.",
          'subjectName': "Subject Name :",
          'subjecthint': "Enter subject name",
          'addSubject': "Add Subject",
          'evaluate': "Evaluate",
          'timeline': "TimeLine :",
          'download': "Download",
          'feedbackButton': "Feedback",
          'saveChnages': "Save Chnages",
          'subjectTitle': "Subject : ",
          'subjectFeedback': "Subject of the Feedback", //
          'feedbackHint': "Input on the plan’s effectiveness.", //
          'send': "Send",
          'hideDetails': "Hide Details",
          'viewObservation': "View Observation",
          'addNewObservation': "Add New Observation",
          'observationSavedSuccessfully': "Observation saved successfully",
          'pleaseSelectGrade': "Please select a grade",
          'pleaseSelectStudent': "Please select a student",
          'filters': "Filters",
          'export': "Export",
          'upcomingActions': "Upcoming Actions",
          'recentsAlerts': "Recents Alerts",
          'viewall': "View all",
          'fromDate': "Date from",
          'toDate': "Date to",
          'present': "Present",
          'absent': "Absent",
          'halfDay': "Half day",
          'logOut': "Logout",
          'discard': "Discard",
          'teachers': "Teachers",
          'parents': "Parents",
          'all': "All",
          'student': "Students",
          'assignedteacher': "Assigned Teacher",
          'sara': "Sara",
          'parentsub': "Visual representation (e.g., progress bar or grade).",
          'overallPerformance': "Overall Performance", //
          'resourcesTitle': "Resources",
          'resounceList': "Links to support materials or guides.",
          'alertsSub': "Section for important messages.",
          'lowMarksAlertsTitle': "Students With Marks Below 6/10",
          'noLowMarksAlerts': "No students currently below 6/10.",
          'marksOutOfTen': "Mark (out of 10)",
          'averageMarks': "Average Marks",
          'averageGrade': "Average Grade",
          'assList': "List of recent assessments, feedback, or observations.",
          'inApp': "In-app",

          'dateTitle': "Date",
          'curriculum': "Curriculum",
          'showLess': "Show Less", //
          'showMore': "Show More", //
          'analyzeReport': "View Analyze Report", //

          'selectCurriculumn': "Select Curriculum",
          'errorCurriculum': "Please select curriculum",
          'errorSubject': "Please select subject",
          'showHistory': "Show History",

          'examHistoryTitle': "Exam Scripts History",
          'examDate': "Exam Date",
          'showEvaluatedText': "Show Evaluated Text",
          'curriculumName': "Curriculum Name",
          'noExamHistory': "No exam history found",
          'erroExamHistory': "Error fetching data",

          'analyzeReport': "Analyze Report",
          'areasforImprovement': "Areas for Improvement",
          'interventions': "Interventions",
          'recommendations': "Recommendations",
          'strengths': "Strengths",
          'weaknesses': "Weaknesses",

          'exportWithExcel': "Export with Excel",
          'exportWithPdf': "Export with PDF",
          'ok': "OK",
          'viewExamScripts': "View Exam Scripts",
          'startDate': "Start Date",
          'endDate': "End Date",

          'changeProfile': "Change Profile Photo",
          'clicktochange': "Click to change",
          'phone': "Phone No.",
          'section': "Section",
          'class/section': "class / section",
          'reportTitle': "REPORTS",
          'viewAllPlans': "View All Plans",
          'noTeachingPlan': "No Teaching Plan",
          'userMange': "User Manage",
          'viewAllFeedback': "View All Feedback",
          'feedbacks': "Feedback",
          'feedbackMessage': "Feedback Message",
          'noFeedbakcs': "No Feedbacks",
          'norecordYet': "No record yet",
          'loadingPleaseWait': "Loading... Please wait",
          'description': "Description",
          'childInformation': "Child's Information",
          'nostudentsfound': "No students found",
          'message': "Message",

          // all snackbar text
          'email/passAlert': "Email and password are required",
          'loginFailed': "Login failed",
          'emailEmpty': "Email can not be empty",
          'validEmail': "Enter a valid email address",
          'passwordEmpty': "Password can not be empty",
          'otpSuccess': "OTP send successfully",
          'otpEmpty': "OTP can't be empty",
          'otpVerifySuccess': "OTP verify successfully",
          'newPasswordEmpty': "New Password can't be empty.",
          'passwordLength':
              "Password length must be greater than eight character.",
          'confirmPasswordEmpty': "Confirm Password can't be empty.",
          'passwordMismatch': "Passwords do not match.",
          'newPasswordLength':
              "New Password length must be greater than eight character.",
          'successResetPassword': "Your Passsowrd is successfully reset.",
          'passwordChange': "Your Password Successfully Changed.",
          'nameEmpty': "Name can't be empty",
          'contactEmpty': "Contact Number can't be empty",
          'successInfo': "Your Personal Infornamtion Successfully updated.",
          'logoutSuccess': "Logout Successfully",
          'userCreate': "User Created Successfully.",
          'roleEmpty': "Role can't be empty",
          'examEmpty': "Exam Name can't be empty",
          'dateEmpty': "Date can't be empty",
          'noteEmpty': "Notes can't be empty",
          'uploadFile': "Please Upload File",
          'successExamScripts': "Your Exam Script Uploaded Successfully",
          'assignMarks': "Please assign marks",
          'assignGrade': "Please assign grade",
          'assignTotalMark': "Please assign Total Mark",
          'selectSubjectAndCurriculumHint':
              "Select a subject and curriculum to enter marks.",
          'noMarksHistoryYet': "No marks history available yet.",
          'editMarksTitle': "Edit Marks",
          'deleteMarksTitle': "Delete Marks",
          'deleteMarksConfirm':
              "Are you sure you want to delete this marks entry?",
          'validNumericMarks': "Please enter valid numeric marks",
          'marksUpdatedSuccess': "Marks updated successfully",
          'updateMarksEndpointUnavailable':
              "Update endpoint not available on server",
          'updateMarksFailed': "Failed to update marks",
          'markEntryEditIdMissing':
              "This mark entry cannot be edited because no entry ID was returned by server.",
          'markEntryDeleteIdMissing':
              "This mark entry cannot be deleted because no entry ID was returned by server.",
          'marksDeletedSuccess': "Marks deleted successfully",
          'deleteMarksEndpointUnavailable':
              "Delete endpoint not available on server",
          'deleteMarksFailed': "Failed to delete marks",
          'action': "Action",
          'updateSuccessReportCard': "Your Report Card Successfully Updated",
          'successTeachingPlan': "Teaching Plan Successfully Updated.",
          'downloadPlan': "Teaching Plans Successfully Downloaded.",
          'feedbackEmpty': "Feedback can't be empty.",
          'successFeedback': "Your Feedback Successfully Send.",
          'observationEmpty': "Observation can't be empty",
          'emptySubject': "Subject not selected, so select a subject.",
          'attachFile': "Please Attach a file",
          'successObservation': "Observation Succesfully Created.",
          'bothSuccess': "Student Details & Image Successfully Updated.",
          'successStudentDetails': "Student Details Successfully Updated",
          'successUserUpdated': "Your User Successfully Updated.",
          'successDeactive': "Your user is successfully deactivate",
          'accept': "Accept",
          'reject': "Reject",
          'reset': "Reset",
          'noImprovement': "No areas for improvement available.",
          'improvement': "Improvement",
          'delete': "Delete",
          'deleteEvaluationTitle':
              "Are you sure want to delete evaluation report",
          'successDelete': "Your evaluation report successfully deleted",
          'yes': "Yes",
          'no': "No",
          "analysisDeleted": "Analysis deleted successfully",
          "generateTeachingPlan": "Generate teaching plan",
          "class": "Class",
          "assignedTeacherName": "Assigned Teacher Name",
          "recentUpdates": "Recent Updates",
          "length8greater":
              "The length of the contact number should not be greater than 8",
          "length8less":
              "The length of the contact number should not be less than 8",
          "sendFeedback": "Send Feedback",
          "teacherClassReportTitle": "Teacher Class Report",
          "selectTeacherHint": "Select teacher",
          "noTeachersFound": "No teachers found.",
          "selectTeacherToViewReport": "Select a teacher to view report.",
          "noClassReportDataForSelectedTeacher":
              "No class report data for selected teacher.",
          "averageMarkLabel": "Average mark:",
          "studentsBelowSixLastEntry": "Students below 6 (last entry):",
          "noneLabel": "None",
          "failedToLoadTeachers": "Failed to load teachers",
          "unableToLoadTeachers": "Unable to load teachers.",
          "teacherNotFound": "Teacher not found.",
          "failedToLoadStudents": "Failed to load students",
          "unableToBuildTeacherReport": "Unable to build teacher report.",
          "teacherActivitiesLast7DaysTitle": "Teacher Activities (Last 7 Days)",
          "noTeacherActivitiesLast7Days":
              "No teacher activities in the last 7 days.",
          "activityMarksAdded": "Marks Added",
          "activityObservationAdded": "Observation Added",
          "loadedClassesLabel": "Loaded classes",
          //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        },
        'ar': {
          //Login Screen
          'appName': "نظام تعزيز التعليم المخصص",
          'emailAddressTitle': "عنوان البريد الإلكتروني",
          'passwordTitle': "كلمة المرور",
          'emailHint': "عنوان البريد الإلكتروني*",
          'passwordHint': "كلمة المرور*",
          'rememberMe': "تذكرني",
          'forgotPassword': "هل نسيت كلمة المرور؟",
          'login': "تسجيل الدخول",
          'english': "الإنجليزية",
          'arabic': "العربية",
          'copyrightInformation': "معلومات حقوق النشر",
          'termsandPrivacyPolicy': "الشروط وسياسة الخصوصية",
          'loginHeroSubtitle': "منصة ذكية للمدارس",
          'loginHeroBadge': "تجربة موحدة للإدارة والمعلمين وأولياء الأمور",
          'loginFormSubtitle': "أدخل بريدك الإلكتروني وكلمة المرور للمتابعة",
          // Forgot password Screen
          'forgotPasswordTitle': "نسيت كلمة المرور؟",
          'forgotPassowordSubTitle': "لا تقلق، سنرسل لك تعليمات إعادة التعيين.",
          'resetPassword': "إعادة تعيين كلمة المرور",
          'backToLogin': "العودة لتسجيل الدخول",
          // OTP Screen
          'resetPasswordsubTitle': "يمكننا إرسال رمز إلى abc123@gmail.com",
          'continue': "متابعة",
          'didntemail': "لم تستلم البريد الإلكتروني؟",
          'resendIt': "إعادة الإرسال",
          // Reset Password
          'setPasswordTitle': "قم بتعيين كلمة مرور جديدة",
          'setPasswordSubTitle': "يجب أن تكون 8 أحرف على الأقل",
          'newPasswordTitle': "كلمة المرور الجديدة",
          'newPasswordHint': "كلمة المرور الجديدة*",
          'confirmPasswordTitle': "تأكيد كلمة المرور الجديدة",
          'confirmPasswordHint': "تأكيد كلمة المرور الجديدة*",
          // Headmaster Dashboard
          'dashboard': 'لوحة التحكم',
          'students': 'الطلاب',
          'settings': 'الإعدادات',
          'welcome': "مرحباً،",
          'schoolperfo': "مقاييس أداء المدرسة",
          'schoolPerformanceWindow30Days': "عرض النتائج لآخر 30 يومًا",
          'noSchoolPerformanceDataLast30Days':
              "لا توجد بيانات أداء للمدرسة خلال آخر 30 يومًا",
          'performanceByGrade': "الأداء حسب الصف",
          'subjectsByGrade': "المواد حسب الصف",
          'absenceByGrade': "الغياب حسب الصف",
          'absentStudentsCount': "عدد الطلاب الغائبين",
          'noAbsenceDataAvailable': "لا توجد بيانات غياب متاحة بعد",
          'noAbsenceDataForSelectedMonth':
              "لا توجد حالات غياب مسجلة للشهر المحدد",
          'noSubjectMarksForSelectedGrade':
              "لا توجد درجات مواد متاحة للصف المحدد",
          'schoolHint':
              "المؤشرات الرئيسية (مثل: متوسط الدرجات، معدلات الحضور).",
          'userManagement': "إدارة المستخدمين",
          'userManagesubList': "رابط أو زر لإدارة المستخدمين.", //
          'reports': "التقارير",
          'reportssubList': "روابط سريعة للتقارير الأخيرة أو الهامة.",
          'alerts&Noti': "التنبيهات والإشعارات",
          'subAlert': "قسم للرسائل الهامة التي تتطلب الاهتمام.", //
          // User management list
          'searchHint': "اسم الطالب أو رقم الهوية",
          'searchSubject': "البحث حسب الموضوع",
          'recentUpdates': "آخر التحديثات",
          'username': "اسم المستخدم", //
          'userRole': "دور المستخدم", //
          'status': "الحالة", //
          'edit': "تعديل",
          'deactivate': "تعطيل المستخدم",
          'addNewUser': "إضافة مستخدم جديد",
          'name': "الاسم : ",
          'contactNumber': "رقم الهاتف : ",
          'email': "البريد الإلكتروني : ",
          'roleAssignment': "تعيين الدور : ",
          'viewDetails': "عرض التفاصيل",
          'checkboxtext': "مربعات الاختيار أو التبديل لحقوق وصول محددة",
          'cancel': "إلغاء",
          'save': "حفظ",
          // Profile Screen
          'nameTitle': "الاسم",
          'fName': "الاسم",
          'emailTitle': "البريد الإلكتروني",
          'emailHintTitle': "abc123gmail.com",
          'userId': "معرف المستخدم",
          'userIdHint': "abc123personal",
          'role': "الدور",
          'parent': "الوالد", //
          'deleteUser': "حذف المستخدم",
          'deactiveUser': "تعطيل المستخدم",
          'saveChanges': "حفظ التغييرات",
          // Student List(Headmaster)
          'grade': "الصف",
          'gradee': "الرمز",
          'studentId': "رقم الطالب",
          'contactInformation': "معلومات الاتصال",
          'phoneNumber': "رقم الهاتف",
          'address': "العنوان",
          'editDetails': "تحرير التفاصيل",
          //tab
          'assignedteacher': "المعلم المعيّن",
          'academicData': "البيانات الأكاديمية",
          'teachingPlans': "خطط التدريس",
          'observation': "الملاحظات",
          'progress': "التقدم", //التقدم
          // academic
          'subject': "المادة",
          'marks': "الدرجة", //
          'attendance': "حضور", //
          'reportCard': "بطاقة التقرير",
          'totalMarks': "مجموع الدرجات",
          'obtainedMarks': "الدرجات المحصلة",
          'activity': "نشاط", //
          'totalWorkingDay': "المجموع لا. من أيام العمل", //
          'presentDays': "الأيام الحالية", //
          'absentDays': "أيام الغياب", //
          'halfDays ': "نصف أيام", //
          'examName': "اسم الامتحان :",
          'examNameTitle': "اسم الامتحان",
          'date': "التاريخ :",
          'selectedDateLabel': "التاريخ المحدد",
          'selectDate': "التاريخ",
          'curriculumCoverage': "تغطية المنهج",
          'multiselectdropdown': "القائمة المنسدلة متعددة التحديد", //
          'uploadFiles': "تحميل الملفات",
          'dragandDropFiles': "سحب وإسقاط الملفات", //
          'supportedFileTypesPDF,JPG': "الملفات المدعومة PDF، JPG",
          'upload': "تحميل",
          'notesandObservations': "ملاحظات وملاحظات", //
          'notesHint': "مساحة نصية للمعلمين لإضافة تعليقات.",
          'submit': "إرسال",
          'addObservation': "إضافة ملاحظة",
          'absentAutoNote': "تم تسجيل الطالب كغائب.",
          'examScipts': "أوراق الامتحانات",
          // Teaching plan
          'currentPlans': "الخطط الحالية", //
          'pastPlans': "الخطط الماضية", //
          'objectives': "الأهداف :",
          'objList': "قائمة الأهداف الذكية.", //
          'strategies': "الاستراتيجيات :",
          'methodHint': "طرق التدريس الموصى بها.", //
          'resources': "الموارد :",
          'resoHint': "روابط أو مراجع للمواد.", //
          'assessmentMethods': "طريقة التقييم :",
          'teachMethod': "طرق التدريس الموصى بها", //
          // Observation
          'selectSubject': "اختر المادة",
          'selectGrade': "اختر الصف",
          'selectStudentName': "اختر الطالب",
          'observationTitle': "الملاحظة :",
          'attachFiles': "إرفاق الملفات :",
          'teachersNotes': "ملاحظات المعلم :", //
          'listStudent': "قائمة الملاحظات للطالب", //
          'feedback': "ملاحظات :",
          'providedFeedback': "ردود الفعل المقدمة", //
          'behaviorInClass': "سلوك الطالب في الصف",
          'selectBehaviorInClass': "اختر السلوك (اختياري)",
          'behaviorExcellentInteraction': "تفاعل ممتاز في الصف",
          'behaviorVeryGoodInteraction': "تفاعل جيد في الصف",
          'behaviorAcceptableInteraction': "تفاعل مقبول في الصف",
          'behaviorWeakInteraction': "تفاعل ضعيف في الصف",
          'behaviorNoInteraction': "لا يوجد أي تفاعل في الصف",
          'behaviorDisruptive': "شغب في الصف",
          'behaviorLackOfFocus': "عدم تركيز في الصف",
          'behaviorHomeworkNotDone': "لم يتم حل الواجب",
          'subjectPerformance': "أداء المادة",
          // setting screen
          'profileSettings': "إعدادات الملف الشخصي",
          'personalInformation': "المعلومات الشخصية",
          'contactNo': "رقم التواصل :",
          'updateInformation': "تحديث المعلومات",
          'changePassword': "تغيير كلمة المرور",
          'oldPassword': "كلمة المرور القديمة :",
          'newPassword': "كلمة المرور الجديدة :",
          'confirmPassword': "تأكيد كلمة المرور :",
          'languagePreferences': "إعدادات اللغة",
          'notificationSettings': "إعدادات الإشعارات",
          'alertTypes': "أنواع التنبيه", //
          'specificAlerts': "تنبيهات محددة", //
          'deliveryMethods': "طرق التسليم",
          'sms': "رسالة نصية",
          'byOtherAPP': "بواسطة تطبيق آخر", //
          'accessibilityOptions': "خيارات الوصول",
          'fontSize': "حجم الخط",
          'contrastMode': "وضع التباين",
          'disable': "تعطيل",
          'enable': "تمكين",
          // Notification list
          'actions': "Actions", //
          // teacher sections
          'teachingPlan': "خطط التدريس",
          'observationHeading': "الملاحظات",
          'className': "اسم الصف",
          'numberofStudents': "عدد الطلاب",
          'examScript': "أوراق الامتحانات",
          'noSubject':
              "لم تتم إضافة أي موضوع هنا، لذا يرجى \nإضافة الموضوع وحفظ بطاقة التقرير.", //
          'subjectName': "المادة :",
          'subjecthint': "المادة",
          'addSubject': "أضف الموضوع", //
          'evaluate': "يقيم", //
          'timeline': "الجدول الزمني :",
          'download': "تحميل",
          'feedbackButton': "ملاحظات",
          'saveChnages': "حفظ التغييرات",
          'subjectTitle': "المادة :",
          'subjectFeedback': "موضوع ردود الفعل", //
          'feedbackHint': "المدخلات على فعالية الخطة.", //
          'send': "يرسل", //
          'hideDetails': "إخفاء التفاصيل",
          'viewObservation': "عرض الملاحظة",
          'addNewObservation': "إضافة ملاحظة جديدة",
          'observationSavedSuccessfully': "تم حفظ الملاحظة بنجاح",
          'pleaseSelectGrade': "يرجى اختيار الصف",
          'pleaseSelectStudent': "يرجى اختيار الطالب",
          'filters': "الفلاتر",
          'export': "تصدير",
          'upcomingActions': "الإجراءات القادمة",
          'recentsAlerts': "التنبيهات الأخيرة",
          'viewall': "عرض الكل", //
          'fromDate': "التاريخ من",
          'toDate': "التاريخ إلى",
          'present': "حاضر", //
          'absent': "غائب", //
          'halfDay': "نصف يوم", //
          'logOut': "تسجيل الخروج",
          'discard': "ينبذ", //
          'teachers': "المعلمون",
          'parents': "أولياء الأمور",
          'all': "الكل",
          'student': "الطلاب",
          'sara': "سارة", //
          'parentsub':
              "التمثيل المرئي (على سبيل المثال، شريط التقدم أو الدرجة).", //
          'overallPerformance': "الأداء العام", //
          'resourcesTitle': "الموارد",
          'resounceList': "روابط لمواد الدعم أو الأدلة.", //
          'alertsSub': "قسم للرسائل الهامة.", //
          'lowMarksAlertsTitle': "الطلاب ذوو الدرجات الأقل من 6/10",
          'noLowMarksAlerts': "لا يوجد طلاب بدرجات أقل من 6/10 حالياً.",
          'marksOutOfTen': "الدرجة (من 10)",
          'averageMarks': "متوسط الدرجات",
          'averageGrade': "متوسط التقدير",
          'assList': "قائمة التقييمات أو التعليقات أو الملاحظات الأخيرة.", //
          'inApp': "داخل التطبيق",

          'dateTitle': "التاريخ",
          'curriculum': "المنهج",
          'showLess': "عرض أقل", //
          'showMore': "عرض المزيد", //
          'analyzeReport': "تحليل التقرير", //

          'selectCurriculumn': "اختر المنهج",
          'errorCurriculum': "يرجى اختيار المنهج",
          'errorSubject': "يرجى اختيار المادة",
          'showHistory': "عرض السجل",
          'examHistoryTitle': "سجل أوراق الامتحان",
          'examDate': "تاريخ الامتحان",
          'showEvaluatedText': "إظهار النص المقيّم", //
          'curriculumName': "اسم المنهج",
          'noExamHistory': "لم يتم العثور على سجل الامتحان",
          'erroExamHistory': "خطأ في جلب البيانات", //

          'analyzeReport': "تحليل التقرير", //
          'areasforImprovement': "مجالات التحسين", //
          'interventions': "التدخلات", //
          'recommendations': "توصيات", //
          'strengths': "نقاط القوة", //
          'weaknesses': "نقاط الضعف", //

          'exportWithExcel': "تصدير بصيغة Excel",
          'exportWithPdf': "تصدير بصيغة PDF",
          'ok': "موافق",
          'viewExamScripts': "عرض نصوص الامتحان", //
          'noTeachingPlan': "لم يتم إنشاء خطة تدريس",
          'viewPlan': "عرض الخطة",
          'learningObjectives': "أهداف التعلم",
          'instructionalStrategies': "استراتيجيات التدريس",
          'recommendedResources': "الموارد الموصى بها",
          'startDate': "تاريخ البدء",
          'endDate': "تاريخ الانتهاء",

          'changeProfile': "تغيير صورة الملف الشخصي",
          'clicktochange': "انقر للتغيير",
          'phone': "رقم الهاتف",
          'section': "القسم",
          'class/section': "الطبقة / القسم", //
          'reportTitle': "التقارير",
          'viewAllPlans': "عرض جميع الخطط",
          'userMange': "إدارة المستخدم",
          'viewAllFeedback': "عرض جميع التعليقات",
          'feedbacks': "تعليقات",
          'feedbackMessage': "رسالة التعليق",
          'noFeedbakcs': "لا توجد تعليقات",
          'norecordYet': "لا يوجد سجل بعد",
          'loadingPleaseWait': "جارٍ التحميل... يرجى الانتظار",
          'description': "الوصف",
          'childInformation': "معلومات الطفل",
          'nostudentsfound': "لم يتم العثور على أي طلاب", //
          'message': "رسالة", //

          // all snackbar text
          'email/passAlert': "البريد الإلكتروني وكلمة المرور مطلوبة",
          'loginFailed': "فشل تسجيل الدخول",
          'emailEmpty': "لا يمكن أن يكون البريد الإلكتروني فارغًا",
          'validEmail': "يرجى إدخال عنوان بريد إلكتروني صالح",
          'passwordEmpty': "لا يمكن أن تكون كلمة المرور فارغة",
          'otpSuccess': "تم إرسال رمز التحقق بنجاح",
          'otpEmpty': "لا يمكن أن يكون رمز التحقق فارغًا",
          'otpVerifySuccess': "تم التحقق من الرمز بنجاح",
          'newPasswordEmpty': "لا يمكن أن تكون كلمة المرور الجديدة فارغة",
          'passwordLength': "يجب أن تكون كلمة المرور أطول من ثمانية أحرف",
          'confirmPasswordEmpty': "تأكيد كلمة المرور لا يمكن أن يكون فارغًا",
          'passwordMismatch': "كلمتا المرور غير متطابقتين",
          'newPasswordLength':
              "يجب أن تكون كلمة المرور الجديدة أطول من ثمانية أحرف",
          'successResetPassword': "تمت إعادة تعيين كلمة المرور بنجاح",
          'passwordChange': "تم تغيير كلمة المرور بنجاح",
          'nameEmpty': "لا يمكن أن يكون الاسم فارغًا",
          'contactEmpty': "لا يمكن أن يكون رقم الاتصال فارغًا",
          'successInfo': "تم تحديث معلوماتك الشخصية بنجاح",
          'logoutSuccess': "تم تسجيل الخروج بنجاح",
          'userCreate': "تم إنشاء المستخدم بنجاح",
          'roleEmpty': "لا يمكن أن يكون الدور فارغًا",
          'examEmpty': "لا يمكن أن يكون اسم الامتحان فارغًا",
          'dateEmpty': "لا يمكن أن يكون التاريخ فارغًا",
          'noteEmpty': "لا يمكن أن تكون الملاحظات فارغة",
          'uploadFile': "يرجى تحميل الملف",
          'successExamScripts': "تم تحميل أوراق الامتحان بنجاح",
          'assignMarks': "يرجى تخصيص الدرجات",
          'assignGrade': "يرجى تخصيص التقدير",
          'assignTotalMark': "يرجى تخصيص الدرجة الكلية",
          'selectSubjectAndCurriculumHint':
              "اختر المادة والمنهج لإدخال الدرجات.",
          'noMarksHistoryYet': "لا يوجد سجل درجات حتى الآن.",
          'editMarksTitle': "تعديل الدرجات",
          'deleteMarksTitle': "حذف الدرجات",
          'deleteMarksConfirm': "هل أنت متأكد أنك تريد حذف سجل الدرجات هذا؟",
          'validNumericMarks': "يرجى إدخال درجات رقمية صحيحة",
          'marksUpdatedSuccess': "تم تحديث الدرجات بنجاح",
          'updateMarksEndpointUnavailable':
              "نقطة نهاية تحديث الدرجات غير متاحة على الخادم",
          'updateMarksFailed': "فشل تحديث الدرجات",
          'markEntryEditIdMissing':
              "لا يمكن تعديل سجل الدرجات هذا لأنه لم يتم إرجاع معرف السجل من الخادم.",
          'markEntryDeleteIdMissing':
              "لا يمكن حذف سجل الدرجات هذا لأنه لم يتم إرجاع معرف السجل من الخادم.",
          'marksDeletedSuccess': "تم حذف الدرجات بنجاح",
          'deleteMarksEndpointUnavailable':
              "نقطة نهاية حذف الدرجات غير متاحة على الخادم",
          'deleteMarksFailed': "فشل حذف الدرجات",
          'action': "الإجراءات",
          'updateSuccessReportCard': "تم تحديث بطاقة التقرير بنجاح",
          'successTeachingPlan': "تم تحديث خطة التدريس بنجاح",
          'downloadPlan': "تم تحميل خطة التدريس بنجاح",
          'feedbackEmpty': "Feedback can't be empty.", //
          'successFeedback': "Your Feedback Successfully Send.", //
          'observationEmpty': "لا يمكن أن تكون الملاحظة فارغة",
          'emptySubject': "لم يتم تحديد مادة، يرجى اختيار مادة",
          'attachFile': "يرجى إرفاق ملف",
          'successObservation': "تم إنشاء الملاحظة بنجاح",
          'bothSuccess': "تم تحديث تفاصيل وصورة الطالب بنجاح",
          'successStudentDetails': "تم تحديث تفاصيل الطالب بنجاح",
          'successUserUpdated': "تم تحديث المستخدم بنجاح",
          'successDeactive': "تم تعطيل المستخدم بنجاح",
          'accept': "يقبل",
          'reject': "يرفض",
          'reset': "إعادة ضبط",
          'noImprovement': "لا توجد مجالات متاحة للتحسين.",
          'improvement': "تحسين",
          "delete": "حذف",
          "deleteEvaluationTitle": "هل أنت متأكد أنك تريد حذف تقرير التقييم؟",
          "successDelete": "تم حذف تقرير التقييم بنجاح",
          "yes": "نعم",
          "no": "لا",
          "analysisDeleted": "تم حذف التحليل بنجاح",
          "generateTeachingPlan": "إنشاء خطة تعليمية",
          "class": "الصف",
          "assignedTeacherName": "اسم المعلم المعين",
          "recentUpdates": "آخر التحديثات",
          "length8greater": "يجب ألا يزيد طول رقم الاتصال عن 8",
          "length8less": "يجب ألا يقل طول رقم الاتصال عن 8",
          "sendFeedback": "إرسال ملاحظات",
          "teacherClassReportTitle": "تقرير صفوف المعلم",
          "selectTeacherHint": "اختر المعلم",
          "noTeachersFound": "لم يتم العثور على معلمين.",
          "selectTeacherToViewReport": "اختر معلمًا لعرض التقرير.",
          "noClassReportDataForSelectedTeacher":
              "لا توجد بيانات تقرير صف للمعلم المحدد.",
          "averageMarkLabel": "متوسط الدرجة:",
          "studentsBelowSixLastEntry": "الطلاب الأقل من 6 (آخر إدخال):",
          "noneLabel": "لا يوجد",
          "failedToLoadTeachers": "فشل تحميل المعلمين",
          "unableToLoadTeachers": "تعذر تحميل المعلمين.",
          "teacherNotFound": "المعلم غير موجود.",
          "failedToLoadStudents": "فشل تحميل الطلاب",
          "unableToBuildTeacherReport": "تعذر إنشاء تقرير المعلم.",
          "teacherActivitiesLast7DaysTitle": "أنشطة المعلم (آخر 7 أيام)",
          "noTeacherActivitiesLast7Days":
              "لا توجد أنشطة للمعلم خلال آخر 7 أيام.",
          "activityMarksAdded": "تمت إضافة درجات",
          "activityObservationAdded": "تمت إضافة ملاحظة",
          "loadedClassesLabel": "الفصول المحملة"
        },
      };
}
