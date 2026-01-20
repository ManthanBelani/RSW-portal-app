class UserDesignationPermission {
  final int id;
  final int designationId;
  final int? teamId;
  final List<bool> notes;
  final List<bool> projects;
  final List<bool> tasks;
  final List<bool> users;
  final List<bool> interviews;
  final List<bool> leads;
  final List<bool> banks;
  final List<bool> leaveRequest;
  final List<bool> generateFixInvoice;
  final List<bool> holiday;
  final List<bool> roles;
  final List<bool> works;
  final List<bool> clients;
  final List<bool> capture;
  final List<bool> codingStandard;
  final List<bool> attendance;
  final List<bool> resourceManagement;
  final List<bool> socialMediaContents;
  final String? createdAt;
  final String updatedAt;
  final List<bool> userComputerInfos;
  final List<bool> generateDocument;
  final List<bool> campaigns;
  final List<bool> userDocuments;
  final List<bool> payrollSection;
  final List<bool> proposalSystem;
  final List<bool> designations;
  final List<bool> rulebook;

  UserDesignationPermission({
    required this.id,
    required this.designationId,
    this.teamId,
    required this.notes,
    required this.projects,
    required this.tasks,
    required this.users,
    required this.interviews,
    required this.leads,
    required this.banks,
    required this.leaveRequest,
    required this.generateFixInvoice,
    required this.holiday,
    required this.roles,
    required this.works,
    required this.clients,
    required this.capture,
    required this.codingStandard,
    required this.attendance,
    required this.resourceManagement,
    required this.socialMediaContents,
    this.createdAt,
    required this.updatedAt,
    required this.userComputerInfos,
    required this.generateDocument,
    required this.campaigns,
    required this.userDocuments,
    required this.payrollSection,
    required this.proposalSystem,
    required this.designations,
    required this.rulebook,
  });

  factory UserDesignationPermission.fromJson(Map<String, dynamic> json) {
    List<bool> _parsePerm(String? value, {int expectedLength = 4}) {
      if (value == null || value.isEmpty) {
        return List.generate(expectedLength, (_) => false);
      }

      final parts = value.split(',');
      final result = <bool>[];
      for (int i = 0; i < expectedLength; i++) {
        if (i < parts.length) {
          result.add(parts[i].trim() == '1');
        } else {
          result.add(false);
        }
      }
      return result;
    }

    return UserDesignationPermission(
      id: json['id'] as int,
      designationId: json['designation_id'] as int,
      teamId: json['team_id'] as int?,
      notes: _parsePerm(json['notes']),
      projects: _parsePerm(json['projects']),
      tasks: _parsePerm(json['tasks']),
      users: _parsePerm(json['users']),
      interviews: _parsePerm(json['interviews']),
      leads: _parsePerm(json['leads']),
      banks: _parsePerm(json['banks']),
      leaveRequest: _parsePerm(json['leave_request']),
      generateFixInvoice: _parsePerm(json['generate_fix_invoice']),
      holiday: _parsePerm(json['holiday']),
      roles: _parsePerm(json['roles']),
      works: _parsePerm(json['works']),
      clients: _parsePerm(json['clients']),
      capture: _parsePerm(json['capture']),
      codingStandard: _parsePerm(json['coding_standard']),
      attendance: _parsePerm(json['attendance']),
      resourceManagement: _parsePerm(json['resource_management'], expectedLength: 2), // only 2 values
      socialMediaContents: _parsePerm(json['social_media_contents']),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String,
      userComputerInfos: _parsePerm(json['user_computer_infos']),
      generateDocument: _parsePerm(json['generate_document']),
      campaigns: _parsePerm(json['campaigns']),
      userDocuments: _parsePerm(json['user_documents']),
      payrollSection: _parsePerm(json['payroll_section']),
      proposalSystem: _parsePerm(json['proposal_system']),
      designations: _parsePerm(json['designations']),
      rulebook: _parsePerm(json['rulebook']),
    );
  }
}