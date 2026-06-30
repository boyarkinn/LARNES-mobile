class ParentChild {  const ParentChild({
    required this.id,
    required this.firstName,
    this.lastName,
    this.patronymic,
    this.dateOfBirth,
    this.gender,
    this.ageYears,
  });

  factory ParentChild.fromJson(Map<String, dynamic> json) {
    return ParentChild(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String?,
      patronymic: json['patronymic'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      gender: json['gender'] as String?,
      ageYears: (json['ageYears'] as num?)?.toInt(),
    );
  }

  final String id;
  final String firstName;
  final String? lastName;
  final String? patronymic;
  final String? dateOfBirth;
  final String? gender;
  final int? ageYears;
}

class ParentChildDetail {
  const ParentChildDetail({
    required this.child,
    required this.homeworkCount,
    required this.education,
  });

  factory ParentChildDetail.fromJson(Map<String, dynamic> json) {
    return ParentChildDetail(
      child: ParentChild.fromJson(json['child'] as Map<String, dynamic>),
      homeworkCount: json['homeworkCount'] as int? ?? 0,
      education: ChildEducationContext.fromJson(
        json['education'] as Map<String, dynamic>?,
      ),
    );
  }

  final ParentChild child;
  final int homeworkCount;
  final ChildEducationContext education;
}

class ChildEducationContext {
  const ChildEducationContext({
    required this.tutors,
    required this.networks,
  });

  factory ChildEducationContext.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ChildEducationContext(tutors: [], networks: []);
    }

    final tutors = (json['tutors'] as List<dynamic>? ?? const [])
        .map((item) => ChildTutorContext.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    final networks = (json['networks'] as List<dynamic>? ?? const [])
        .map((item) => ChildNetworkContext.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();

    return ChildEducationContext(tutors: tutors, networks: networks);
  }

  final List<ChildTutorContext> tutors;
  final List<ChildNetworkContext> networks;

  bool get hasEducation =>
      tutors.isNotEmpty ||
      networks.isNotEmpty ||
      networks.any((network) => network.groups.isNotEmpty);
}

class ChildTutorContext {
  const ChildTutorContext({
    required this.teacherId,
    required this.teacherName,
    required this.groups,
  });

  factory ChildTutorContext.fromJson(Map<String, dynamic> json) {
    return ChildTutorContext(
      teacherId: json['teacherId'] as String,
      teacherName: json['teacherName'] as String,
      groups: (json['groups'] as List<dynamic>? ?? const [])
          .map((item) => ChildTutorGroup.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  final String teacherId;
  final String teacherName;
  final List<ChildTutorGroup> groups;
}

class ChildTutorGroup {
  const ChildTutorGroup({required this.id, required this.name});

  factory ChildTutorGroup.fromJson(Map<String, dynamic> json) {
    return ChildTutorGroup(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  final String id;
  final String name;
}

class ChildNetworkContext {
  const ChildNetworkContext({
    required this.ownerUserId,
    required this.networkName,
    required this.groups,
  });

  factory ChildNetworkContext.fromJson(Map<String, dynamic> json) {
    return ChildNetworkContext(
      ownerUserId: json['ownerUserId'] as String,
      networkName: json['networkName'] as String,
      groups: (json['groups'] as List<dynamic>? ?? const [])
          .map((item) => ChildNetworkGroup.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  final String ownerUserId;
  final String networkName;
  final List<ChildNetworkGroup> groups;
}

class ChildNetworkGroup {
  const ChildNetworkGroup({
    required this.groupId,
    required this.groupName,
    required this.centerLabel,
    this.teacherName,
  });

  factory ChildNetworkGroup.fromJson(Map<String, dynamic> json) {
    return ChildNetworkGroup(
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      centerLabel: json['centerLabel'] as String,
      teacherName: json['teacherName'] as String?,
    );
  }

  final String groupId;
  final String groupName;
  final String centerLabel;
  final String? teacherName;
}

class CreateChildPayload {
  const CreateChildPayload({
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    this.patronymic,
  });

  final String firstName;
  final String lastName;
  final String dateOfBirth;
  final String gender;
  final String? patronymic;

  Map<String, dynamic> toJson(String locale) => {
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'locale': locale,
        if (patronymic != null && patronymic!.isNotEmpty) 'patronymic': patronymic,
      };
}
