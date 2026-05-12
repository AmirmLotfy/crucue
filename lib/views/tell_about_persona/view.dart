import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crucue/core/design/second_app_bar.dart';
import 'package:crucue/core/theme.dart';

import '../select_persona.dart';
import 'components/my_child.dart';
import 'components/my_friend.dart';
import 'components/my_parent.dart';
import 'components/my_partner.dart';
import 'components/sibling.dart';
import 'components/teenager.dart';
import 'components/baby.dart';
import 'components/pet.dart';
import 'components/myself.dart';

class TellAboutPersonaView extends StatefulWidget {
  final PersonaType personaType;

  const TellAboutPersonaView({super.key, required this.personaType});

  @override
  State<TellAboutPersonaView> createState() => _TellAboutPersonaViewState();
}

class _TellAboutPersonaViewState extends State<TellAboutPersonaView> {
  Widget get _form {
    switch (widget.personaType) {
      case PersonaType.child:
        return MyChildSection(type: widget.personaType);
      case PersonaType.teenager:
        return TeenagerSection(type: widget.personaType);
      case PersonaType.baby:
        return BabySection(type: widget.personaType);
      case PersonaType.parent:
        return MyParentSection(type: widget.personaType);
      case PersonaType.partner:
        return MyPartnerSection(type: widget.personaType);
      case PersonaType.sibling:
        return SiblingSection(type: widget.personaType);
      case PersonaType.friend:
        return MyFriendSection(type: widget.personaType);
      case PersonaType.pet:
        return PetSection(type: widget.personaType);
      case PersonaType.myself:
        return MyselfSection(type: widget.personaType);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: SecondAppBar(text: 'About ${widget.personaType.label}'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: widget.personaType.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.personaType.icon,
                    color: AppTheme.primary,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Share a few details so Crucue can create a more helpful care plan.',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Theme.of(context).hintColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            _form,
          ],
        ),
      ),
    );
  }
}

/// Unified care profile data model for AI context.
/// Covers all 9 persona types through optional fields.
class PersonaModelData {
  late final String name;
  late final PersonaType type;
  late final String? age;
  late final String? gender;
  late final String? interestsHobbies;
  late final String? communicationStyle;
  late final String? healthConcerns;
  late final String? relationship;
  late final String? personalityType;
  late final String? loveLanguage;
  late final String? liveSituation;
  late final String? liveTogether;
  late final String? relationStatus;
  late final String? goals;
  late final String? currentFocus;
  late final String? preferredCommunicationMethod;
  late final String? sharedInterests;
  late final String? friendshipDuration;
  late final String? friendshipType;
  late final String? frequencyOfInteraction;
  late final String? birthOrder;
  late final String? occupation;
  late final String? department;
  late final String? position;
  late final String? educationLevel;
  late final String? workRelationship;

  // Pet-specific fields
  late final String? species;
  late final String? breed;
  late final String? petType;

  // Baby-specific fields
  late final String? sleepSchedule;
  late final String? developmentalStage;

  // Teen-specific fields
  late final String? currentSchoolYear;
  late final String? friendGroup;

  // Self-care fields
  late final String? selfCareGoals;
  late final String? stressors;

  PersonaModelData({
    required this.name,
    required this.type,
    this.age,
    this.gender,
    this.interestsHobbies,
    this.communicationStyle,
    this.healthConcerns,
    this.relationship,
    this.personalityType,
    this.loveLanguage,
    this.liveSituation,
    this.liveTogether,
    this.relationStatus,
    this.goals,
    this.currentFocus,
    this.preferredCommunicationMethod,
    this.sharedInterests,
    this.friendshipDuration,
    this.friendshipType,
    this.frequencyOfInteraction,
    this.birthOrder,
    this.occupation,
    this.department,
    this.position,
    this.educationLevel,
    this.workRelationship,
    this.species,
    this.breed,
    this.petType,
    this.sleepSchedule,
    this.developmentalStage,
    this.currentSchoolYear,
    this.friendGroup,
    this.selfCareGoals,
    this.stressors,
  });

  PersonaModelData.fromJson(Map<String, dynamic> json) {
    name = json['name'] as String? ?? '';
    age = json['age'] as String?;
    gender = json['gender'] as String?;
    communicationStyle = json['communicationStyle'] as String?;
    interestsHobbies = json['interestsHobbies'] as String?;
    healthConcerns = json['healthConcerns'] as String?;
    relationship = json['relationship'] as String?;
    personalityType = json['personalityType'] as String?;
    loveLanguage = json['loveLanguage'] as String?;
    liveSituation = json['liveSituation'] as String?;
    liveTogether = json['liveTogether'] as String?;
    relationStatus = json['relationStatus'] as String?;
    goals = json['goals'] as String?;
    currentFocus = json['currentFocus'] as String?;
    preferredCommunicationMethod =
        json['preferredCommunicationMethod'] as String?;
    sharedInterests = json['sharedInterests'] as String?;
    friendshipDuration = json['friendshipDuration'] as String?;
    friendshipType = json['friendshipType'] as String?;
    frequencyOfInteraction = json['frequencyOfInteraction'] as String?;
    birthOrder = json['birthOrder'] as String?;
    occupation = json['occupation'] as String?;
    department = json['department'] as String?;
    position = json['position'] as String?;
    educationLevel = json['educationLevel'] as String?;
    workRelationship = json['workRelationship'] as String?;
    species = json['species'] as String?;
    breed = json['breed'] as String?;
    petType = json['petType'] as String?;
    sleepSchedule = json['sleepSchedule'] as String?;
    developmentalStage = json['developmentalStage'] as String?;
    currentSchoolYear = json['currentSchoolYear'] as String?;
    friendGroup = json['friendGroup'] as String?;
    selfCareGoals = json['selfCareGoals'] as String?;
    stressors = json['stressors'] as String?;
    final typeStr = json['personaType'] as String? ?? 'child';
    type = PersonaType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => PersonaType.child,
    );
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'name': name,
      'personaType': type.name,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (interestsHobbies != null) 'interestsHobbies': interestsHobbies,
      if (communicationStyle != null) 'communicationStyle': communicationStyle,
      if (healthConcerns != null) 'healthConcerns': healthConcerns,
      if (relationship != null) 'relationship': relationship,
      if (personalityType != null) 'personalityType': personalityType,
      if (loveLanguage != null) 'loveLanguage': loveLanguage,
      if (liveSituation != null) 'liveSituation': liveSituation,
      if (goals != null) 'goals': goals,
      if (currentFocus != null) 'currentFocus': currentFocus,
      if (preferredCommunicationMethod != null)
        'preferredCommunicationMethod': preferredCommunicationMethod,
      if (sharedInterests != null) 'sharedInterests': sharedInterests,
      if (friendshipDuration != null) 'friendshipDuration': friendshipDuration,
      if (friendshipType != null) 'friendshipType': friendshipType,
      if (frequencyOfInteraction != null)
        'frequencyOfInteraction': frequencyOfInteraction,
      if (birthOrder != null) 'birthOrder': birthOrder,
      if (occupation != null) 'occupation': occupation,
      if (department != null) 'department': department,
      if (position != null) 'position': position,
      if (educationLevel != null) 'educationLevel': educationLevel,
      if (workRelationship != null) 'workRelationship': workRelationship,
      if (liveTogether != null) 'liveTogether': liveTogether,
      if (relationStatus != null) 'relationStatus': relationStatus,
      if (species != null) 'species': species,
      if (breed != null) 'breed': breed,
      if (petType != null) 'petType': petType,
      if (sleepSchedule != null) 'sleepSchedule': sleepSchedule,
      if (developmentalStage != null) 'developmentalStage': developmentalStage,
      if (currentSchoolYear != null) 'currentSchoolYear': currentSchoolYear,
      if (friendGroup != null) 'friendGroup': friendGroup,
      if (selfCareGoals != null) 'selfCareGoals': selfCareGoals,
      if (stressors != null) 'stressors': stressors,
    };
    return data;
  }
}
