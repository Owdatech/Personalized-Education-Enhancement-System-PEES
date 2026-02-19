class TeachingPlan {
  final String assessmentMethods;
  final String instructionalStrategies;
  final String learningObjectives;
  final String recommendedResources;
  final String timeline;

  TeachingPlan({
    required this.assessmentMethods,
    required this.instructionalStrategies,
    required this.learningObjectives,
    required this.recommendedResources,
    required this.timeline,
  });

  factory TeachingPlan.fromJson(Map<String, dynamic> json) {
    return TeachingPlan(
      assessmentMethods: json["teaching_plan"]["actionPlan"]["assessmentMethods"].toString(),
      instructionalStrategies: json["teaching_plan"]["actionPlan"]["instructionalStrategies"].toString(),
      learningObjectives: json["teaching_plan"]["learningObjectives"].toString(),
      recommendedResources: json["teaching_plan"]["recommendedResources"].toString(),
      timeline: json["teaching_plan"]["timeline"].toString(),
    );
  }
}