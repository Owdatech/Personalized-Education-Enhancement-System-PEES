class ActionModel {
  static var shared = ActionModel();
  bool? isEditAcademicData;
  bool? isExamScript;
  bool? isAddObservation;

  ActionModel(
      {this.isEditAcademicData = false,
      this.isExamScript = false,
      this.isAddObservation = false});
}
