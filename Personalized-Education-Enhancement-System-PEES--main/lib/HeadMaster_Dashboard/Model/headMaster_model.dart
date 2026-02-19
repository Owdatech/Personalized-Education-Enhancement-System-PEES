enum HeadMasterListType { dashBoard, students, userManagement, settings }

class HeadMasterModel {
  String title;
  String fillImage;
  String colorImage;
  HeadMasterListType type;

  HeadMasterModel(
      {required this.title,
      required this.fillImage,
      required this.colorImage,
      required this.type});
}
class ApiResponse {
  final int statusCode;
  final String? message;

  ApiResponse({required this.statusCode, this.message});
}
