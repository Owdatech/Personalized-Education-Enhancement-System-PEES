class ApiEndPoint {
  //api list
  static var login = "api/auth/login";
  static var createAccount = "api/auth/createaccount";
  static var logout = "api/auth/logout";
  static var resetPassword = "";
  static var notificationAlertApi = "api/alerts";
  static var changePassword = "api/auth/changepassword";

  static var pdfOcrApi = "file_ocr";
  static var pdfEvaluate = "evaluate";

  static var studentlist = "students/list";
  static var updateStudentDetail = "api/student/update";
  static var uploadStudentPhoto = "api/student/upload-photo1";

  static var getProfile = "api/auth/getprofile?userId=";
  static var updateProfile = "api/auth/updateprofile";

  static var addUser = "api/headmaster/add-users";
  static var updateUser = "api/headmaster/users1/";
  static var getUserList = "api/headmaster/users";
  static var deactiveUser = "api/headmaster/deactivate";
  
  
  static var getObservation = "students/{studId}/observations";
  static var addObservation = "students/{studId}/observations";

  static var updateTeachingPlan = "teaching-plan/";
  static var exportTeachingPlan = "api/teaching-plan/export";
  
  static var getReportCard = "api/student/report-card/";// add userId
  static var updateReportCard = "api/student/update-report-card";
  static var addReportCard = "api/student/report-card";
  static var examScriptUpload = "upload_exam_script";
  
  static var sendOTP = "generate-otp1";
  static var verifyOTP = "verify-otp";
}
