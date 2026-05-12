import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crucue/core/logic/helper_methods.dart';
import 'package:crucue/core/theme.dart';
import 'package:crucue/views/tell_about_persona/view.dart';

import '../core/design/second_app_bar.dart';

/// The 9 care relationship types supported in Crucue MVP.
/// colleague, customer, neighbor, teacher are deprioritized and hidden.
enum PersonaType {
  child,
  teenager,
  baby,
  parent,
  partner,
  sibling,
  friend,
  pet,
  myself,
}

extension PersonaTypeExtension on PersonaType {
  String get label {
    switch (this) {
      case PersonaType.child:
        return 'Child';
      case PersonaType.teenager:
        return 'Teenager';
      case PersonaType.baby:
        return 'Baby';
      case PersonaType.parent:
        return 'Parent';
      case PersonaType.partner:
        return 'Partner';
      case PersonaType.sibling:
        return 'Sibling';
      case PersonaType.friend:
        return 'Family Member';
      case PersonaType.pet:
        return 'Pet Companion';
      case PersonaType.myself:
        return 'Self-Care';
    }
  }

  String get description {
    switch (this) {
      case PersonaType.child:
        return 'Support your child through daily challenges';
      case PersonaType.teenager:
        return 'Connect and guide your teenager';
      case PersonaType.baby:
        return 'Care for your baby with confidence';
      case PersonaType.parent:
        return 'Support an aging or unwell parent';
      case PersonaType.partner:
        return 'Strengthen your partnership';
      case PersonaType.sibling:
        return 'Improve your sibling relationship';
      case PersonaType.friend:
        return 'Support a family member or close friend';
      case PersonaType.pet:
        return 'Help your pet through a difficult moment';
      case PersonaType.myself:
        return 'Take care of your own wellbeing';
    }
  }

  IconData get icon {
    switch (this) {
      case PersonaType.child:
        return Icons.child_care_rounded;
      case PersonaType.teenager:
        return Icons.face_rounded;
      case PersonaType.baby:
        return Icons.baby_changing_station_rounded;
      case PersonaType.parent:
        return Icons.elderly_rounded;
      case PersonaType.partner:
        return Icons.favorite_rounded;
      case PersonaType.sibling:
        return Icons.group_rounded;
      case PersonaType.friend:
        return Icons.people_rounded;
      case PersonaType.pet:
        return Icons.pets_rounded;
      case PersonaType.myself:
        return Icons.self_improvement_rounded;
    }
  }

  Color get color {
    switch (this) {
      case PersonaType.child:
        return CrucueTokens.personaChild;
      case PersonaType.teenager:
        return CrucueTokens.personaTeenager;
      case PersonaType.baby:
        return CrucueTokens.personaBaby;
      case PersonaType.parent:
        return CrucueTokens.personaParent;
      case PersonaType.partner:
        return CrucueTokens.personaPartner;
      case PersonaType.sibling:
        return CrucueTokens.personaSibling;
      case PersonaType.friend:
        return CrucueTokens.personaFriend;
      case PersonaType.pet:
        return CrucueTokens.personaPet;
      case PersonaType.myself:
        return CrucueTokens.personaMyself;
    }
  }

  /// Returns the persona type name for use in AI policy lookups.
  String get policyKey => name;
}

class SelectPersonaView extends StatelessWidget {
  const SelectPersonaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const SecondAppBar(text: 'Who are you supporting?'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 8.h),
            child: Column(
              children: [
                Text(
                  'Choose a care profile',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: AppTheme.fontFamily2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Select the person you want to better support today.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).hintColor,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
              itemCount: PersonaType.values.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (context, i) {
                final type = PersonaType.values[i];
                return _RelationshipCard(type: type);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 32.h),
            child: Text(
              'Crucue keeps all care profiles private and encrypted.',
              style: TextStyle(fontSize: 12.sp, color: Theme.of(context).hintColor),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _RelationshipCard extends StatelessWidget {
  final PersonaType type;

  const _RelationshipCard({required this.type});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => navigateTo(TellAboutPersonaView(personaType: type)),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: type.color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: type.color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 46.h,
              height: 46.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: Icon(type.icon, color: Theme.of(context).colorScheme.onSurface, size: 22.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    type.description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Theme.of(context).hintColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14.sp,
              color: Theme.of(context).hintColor,
            ),
          ],
        ),
      ),
    );
  }
}
