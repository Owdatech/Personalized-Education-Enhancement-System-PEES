class TeachingPlanModel {
  TeachingPlan? teachingPlan;

  TeachingPlanModel({this.teachingPlan});

  TeachingPlanModel.fromJson(Map<String, dynamic> json) {
    teachingPlan = json['teaching_plan'] != null
        ? TeachingPlan.fromJson(json['teaching_plan'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (teachingPlan != null) {
      data['teaching_plan'] = teachingPlan!.toJson();
    }
    return data;
  }
}

class TeachingPlan {
  String? actionPlan;
  String? createdAt;
  String? planId;
  int? version;

  TeachingPlan({this.actionPlan, this.createdAt, this.planId, this.version});

  TeachingPlan.fromJson(Map<String, dynamic> json) {
    actionPlan = json['actionPlan'];
    createdAt = json['createdAt'];
    planId = json['planId'];
    version = json['version'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['actionPlan'] = actionPlan;
    data['createdAt'] = createdAt;
    data['planId'] = planId;
    data['version'] = version;
    return data;
  }
}