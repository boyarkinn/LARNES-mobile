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
  });

  factory ParentChildDetail.fromJson(Map<String, dynamic> json) {
    return ParentChildDetail(
      child: ParentChild.fromJson(json['child'] as Map<String, dynamic>),
      homeworkCount: json['homeworkCount'] as int? ?? 0,
    );
  }

  final ParentChild child;
  final int homeworkCount;
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
