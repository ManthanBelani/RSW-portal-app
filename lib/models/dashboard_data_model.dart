class DashboardData {
  final int project;
  final int billableTask;
  final int nonbillableTask;
  final int client;
  final int user;
  final int projectByClient;

  // Labels for each data point
  final String? projectLabel;
  final String? billableTaskLabel;
  final String? nonbillableTaskLabel;
  final String? clientLabel;
  final String? userLabel;
  final String? projectByClientLabel;

  DashboardData({
    required this.project,
    required this.billableTask,
    required this.nonbillableTask,
    required this.client,
    required this.user,
    required this.projectByClient,
    this.projectLabel,
    this.billableTaskLabel,
    this.nonbillableTaskLabel,
    this.clientLabel,
    this.userLabel,
    this.projectByClientLabel,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    // Extract data section from the response
    final data = json['data'] ?? json;
    
    return DashboardData(
      project: data['project']?.toInt() ?? 0,
      billableTask: data['billableTask']?.toInt() ?? 0,
      nonbillableTask: data['nonbillableTask']?.toInt() ?? 0,
      client: data['client']?.toInt() ?? 0,
      user: data['user']?.toInt() ?? 0,
      projectByClient: data['projectByClient']?.toInt() ?? 0,
      projectLabel: data['projectLabel'] as String?,
      billableTaskLabel: data['billableTaskLabel'] as String?,
      nonbillableTaskLabel: data['nonbillableTaskLabel'] as String?,
      clientLabel: data['clientLabel'] as String?,
      userLabel: data['userLabel'] as String?,
      projectByClientLabel: data['projectByClientLabel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project': project,
      'billableTask': billableTask,
      'nonbillableTask': nonbillableTask,
      'client': client,
      'user': user,
      'projectByClient': projectByClient,
      'projectLabel': projectLabel,
      'billableTaskLabel': billableTaskLabel,
      'nonbillableTaskLabel': nonbillableTaskLabel,
      'clientLabel': clientLabel,
      'userLabel': userLabel,
      'projectByClientLabel': projectByClientLabel,
    };
  }
}

extension ToInt on dynamic {
  int toInt() {
    if (this is int) return this;
    if (this is double) return this.toInt();
    if (this is String) {
      final parsed = int.tryParse(this);
      return parsed ?? 0;
    }
    return 0;
  }
}