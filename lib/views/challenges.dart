import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:crucue/core/design/app_button.dart';
import 'package:crucue/core/design/app_input.dart';
import 'package:crucue/core/logic/helper_methods.dart';
import 'package:crucue/views/results.dart';
import 'package:crucue/views/select_persona.dart';

import '../core/design/second_app_bar.dart';
import '../core/theme.dart';
import 'tell_about_persona/view.dart';

class ChallengesView extends StatefulWidget {
  final String personaName;
  final PersonaType type;
  final PersonaModelData personaModelData;

  const ChallengesView({
    super.key,
    required this.personaName,
    required this.type,
    required this.personaModelData,
  });

  @override
  State<ChallengesView> createState() => _ChallengesViewState();
}

class _ChallengesViewState extends State<ChallengesView> {
  List<String> selectedList = [];
  final _otherController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  List<_Category> get _challengeList {
    switch (widget.type) {
      case PersonaType.child:
        return _childChallenges;
      case PersonaType.teenager:
        return _teenagerChallenges;
      case PersonaType.baby:
        return _babyChallenges;
      case PersonaType.parent:
        return _parentChallenges;
      case PersonaType.partner:
        return _partnerChallenges;
      case PersonaType.sibling:
        return _siblingChallenges;
      case PersonaType.friend:
        return _familyMemberChallenges;
      case PersonaType.pet:
        return _petChallenges;
      case PersonaType.myself:
        return _myselfChallenges;
    }
  }

  static const _childChallenges = [
    _Category(
      title: 'Behavior',
      list: [
        'Meltdowns or tantrums',
        'Refusing to follow routines',
        'Aggression or hitting',
        'Difficulty transitioning',
      ],
    ),
    _Category(
      title: 'Communication',
      list: [
        'Not expressing feelings',
        'Difficulty understanding instructions',
        'Social struggles',
        'Selective mutism',
      ],
    ),
    _Category(
      title: 'Emotions',
      list: [
        'Anxiety or worry',
        'Big emotional reactions',
        'Low mood or withdrawal',
        'Sleep difficulties',
      ],
    ),
    _Category(
      title: 'Learning',
      list: [
        'Attention and focus',
        'School refusal',
        'Learning differences',
        'Homework struggles',
      ],
    ),
  ];

  static const _parentChallenges = [
    _Category(
      title: 'Day-to-Day Care',
      list: [
        'Managing daily routines',
        'Medical appointment coordination',
        'Medication management',
        'Safety at home',
      ],
    ),
    _Category(
      title: 'Communication',
      list: [
        'Expressing needs and feelings',
        'Cognitive or memory changes',
        'Misunderstandings',
        'Resistance to help',
      ],
    ),
    _Category(
      title: 'Emotional Support',
      list: [
        'Loneliness or isolation',
        'Grief or loss',
        'Anxiety or fear',
        'Dignity and independence',
      ],
    ),
    _Category(
      title: 'Caregiver Wellbeing',
      list: [
        'Caregiver fatigue',
        'Setting boundaries',
        'Balancing responsibilities',
        'Getting support',
      ],
    ),
  ];

  static const _partnerChallenges = [
    _Category(
      title: 'Communication',
      list: [
        'Not feeling heard',
        'Recurring arguments',
        'Emotional distance',
        'Difficulty expressing needs',
      ],
    ),
    _Category(
      title: 'Connection',
      list: [
        'Less quality time together',
        'Feeling disconnected',
        'Different stress responses',
        'Loss of intimacy',
      ],
    ),
    _Category(
      title: 'Life Pressures',
      list: [
        'Financial stress',
        'Parenting disagreements',
        'Work-life balance',
        'Big life transitions',
      ],
    ),
  ];

  static const _familyMemberChallenges = [
    _Category(
      title: 'Providing Support',
      list: [
        'Not knowing how to help',
        'Feeling shut out',
        'Supporting through crisis',
        'Long-distance care',
      ],
    ),
    _Category(
      title: 'Communication',
      list: [
        'Difficult conversations',
        'Avoiding the subject',
        'Feeling dismissed',
        'Misunderstandings',
      ],
    ),
    _Category(
      title: 'Boundaries',
      list: [
        'Over-involvement',
        'Setting limits',
        'Protecting your own wellbeing',
        'Asking for help',
      ],
    ),
  ];

  static const _siblingChallenges = [
    _Category(
      title: 'Conflict',
      list: [
        'Recurring arguments',
        'Old resentments',
        'Competition for attention',
        'Feeling unequal',
      ],
    ),
    _Category(
      title: 'Communication',
      list: [
        'Difficulty talking openly',
        'Misunderstandings',
        'Feeling dismissed',
        'Different values',
      ],
    ),
    _Category(
      title: 'Shared Responsibility',
      list: [
        'Caregiving for parents',
        'Family decisions',
        'Financial matters',
        'Distance and time',
      ],
    ),
  ];

  static const _teenagerChallenges = [
    _Category(
      title: 'Connection',
      list: [
        'Feeling shut out',
        'Won\'t talk to me',
        'Pushing me away',
        'Spending all time in room',
      ],
    ),
    _Category(
      title: 'Emotions',
      list: [
        'Intense mood swings',
        'Anxiety or panic',
        'Low mood or withdrawal',
        'Anger that escalates quickly',
      ],
    ),
    _Category(
      title: 'Behaviour',
      list: [
        'Risky choices',
        'Peer pressure concerns',
        'Refusing basic responsibilities',
        'Screen time conflict',
      ],
    ),
    _Category(
      title: 'School and future',
      list: [
        'Refusing school',
        'Academic stress',
        'Conflict about the future',
        'Friendship difficulties',
      ],
    ),
  ];

  static const _babyChallenges = [
    _Category(
      title: 'Sleep',
      list: [
        'Won\'t settle to sleep',
        'Waking frequently at night',
        'Short naps',
        'Changing sleep pattern',
      ],
    ),
    _Category(
      title: 'Feeding',
      list: [
        'Feeding difficulties',
        'Refusing feeds',
        'Wind and discomfort',
        'Starting solids',
      ],
    ),
    _Category(
      title: 'Crying and soothing',
      list: [
        'Inconsolable crying',
        'Colic or reflux',
        'Hard to soothe',
        'Overstimulation',
      ],
    ),
    _Category(
      title: 'Development',
      list: [
        'Milestone concerns',
        'Sensory sensitivities',
        'Not reaching expected stage',
        'Health concerns',
      ],
    ),
  ];

  static const _petChallenges = [
    _Category(
      title: 'Behaviour',
      list: [
        'Aggression or snapping',
        'Destructive behaviour',
        'Excessive barking or vocalising',
        'Refusing commands',
      ],
    ),
    _Category(
      title: 'Anxiety',
      list: [
        'Separation anxiety',
        'Fear of loud noises',
        'Fearful around strangers',
        'Hypervigilance',
      ],
    ),
    _Category(
      title: 'Routine',
      list: [
        'Disrupted eating or sleeping',
        'Toileting issues',
        'Reluctance to exercise',
        'Change in normal behaviour',
      ],
    ),
    _Category(
      title: 'Health and care',
      list: [
        'Refusing medication',
        'Post-vet stress',
        'New home adjustment',
        'Ageing and slowing down',
      ],
    ),
  ];

  static const _myselfChallenges = [
    _Category(
      title: 'Stress and overwhelm',
      list: [
        'Feeling constantly overwhelmed',
        'Caregiver burnout',
        'Too much on my plate',
        'Can\'t switch off',
      ],
    ),
    _Category(
      title: 'Emotions',
      list: [
        'Anxiety or constant worry',
        'Low mood',
        'Irritability or short temper',
        'Emotional exhaustion',
      ],
    ),
    _Category(
      title: 'Rest and wellbeing',
      list: [
        'Not sleeping well',
        'No time for myself',
        'Neglecting my own needs',
        'Physical tension or fatigue',
      ],
    ),
    _Category(
      title: 'Relationships and boundaries',
      list: [
        'Difficulty saying no',
        'Feeling unsupported',
        'Isolation',
        'Resentment building',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: SecondAppBar(
        text: "Today's challenge",
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 0),
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTheme.fontFamily2,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                children: [
                  const TextSpan(text: 'What are you'),
                  TextSpan(
                    text: ' facing with ${widget.personaName}?',
                    style: const TextStyle(color: AppTheme.primary),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 6.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              'Select what fits, or describe it in your own words below.',
              style: TextStyle(
                fontSize: 13.sp,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._challengeList.map((cat) => _ChallengeCategory(
                        category: cat,
                        selectedList: selectedList,
                        onToggle: (item) {
                          setState(() {
                            if (selectedList.contains(item)) {
                              selectedList.remove(item);
                            } else {
                              selectedList.add(item);
                            }
                          });
                        },
                      )),
                  SizedBox(height: 16.h),
                  AppInput(
                    controller: _otherController,
                    label: 'Describe in your own words (optional)',
                    hint: "What's happening today?",
                    maxLines: 3,
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppButton(
        text: 'Get Support Plan',
        type: ButtonType.bottomNav,
        isLoading: isLoading,
        onPress: () {
          final extras = _otherController.text.trim();
          final challenges = [
            ...selectedList,
            if (extras.isNotEmpty) extras,
          ];
          navigateTo(ResultsView(
            title: widget.personaName,
            personaType: widget.type,
            challengesList: challenges,
            personaModelData: widget.personaModelData,
          ));
        },
      ),
    );
  }
}

class _ChallengeCategory extends StatelessWidget {
  final _Category category;
  final List<String> selectedList;
  final ValueChanged<String> onToggle;

  const _ChallengeCategory({
    required this.category,
    required this.selectedList,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: category.list.map((item) {
              final selected = selectedList.contains(item);
              return GestureDetector(
                onTap: () => onToggle(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary
                        : Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: selected ? AppTheme.primary : Theme.of(context).dividerColor,
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : Theme.of(context).hintColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _Category {
  final String title;
  final List<String> list;

  const _Category({required this.title, required this.list});
}
