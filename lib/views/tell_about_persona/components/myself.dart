import 'package:flutter/material.dart';

import '../../../core/design/app_button.dart';
import '../../../core/design/app_expansion_tile.dart';
import '../../../core/design/app_input.dart';
import '../../../core/logic/helper_methods.dart';
import '../../../core/logic/input_validator.dart';
import '../../challenges.dart';
import '../../select_persona.dart';
import '../view.dart';

class MyselfSection extends StatefulWidget {
  final PersonaType type;

  const MyselfSection({super.key, required this.type});

  @override
  State<MyselfSection> createState() => _MyselfSectionState();
}

class _MyselfSectionState extends State<MyselfSection> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _goalsController = TextEditingController();
  final _stressorsController = TextEditingController();
  String? _currentFocus;
  String? _communicationStyle;

  @override
  void dispose() {
    _nameController.dispose();
    _goalsController.dispose();
    _stressorsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInput(
            prefix: 'user_name.svg',
            label: 'Your first name',
            controller: _nameController,
            validator: InputValidator.personaNameValidator,
            hint: 'e.g. Alex',
          ),
          AppExpansionTile(
            title: 'What area would you like to focus on?',
            label: 'Current focus',
            onChange: (value) => _currentFocus = value,
            list: const [
              'Managing stress',
              'Better sleep and rest',
              'Emotional regulation',
              'Setting boundaries',
              'Building healthy habits',
              'Caregiver burnout recovery',
              'Overall wellbeing',
            ],
            icon: 'profile.svg',
          ),
          AppExpansionTile(
            title: 'How do you tend to handle stress?',
            label: 'Stress response style',
            onChange: (value) => _communicationStyle = value,
            list: const [
              'Withdraw and go quiet',
              'Get frustrated or irritable',
              'Overthink and worry',
              'Stay busy to avoid it',
              'Reach out for support',
            ],
            icon: 'preferred_communication_method.svg',
          ),
          AppInput(
            controller: _goalsController,
            label: 'What would you like to feel differently? (optional)',
            hint: 'e.g. Less anxious, more patient, better rested',
            prefix: 'arrow_up.svg',
            maxLines: 2,
          ),
          AppInput(
            controller: _stressorsController,
            label: 'Main stressors right now (optional)',
            hint: 'e.g. Work, caregiving responsibilities, sleep',
            prefix: 'warning.svg',
            maxLines: 2,
          ),
          AppButton(
            text: 'Next',
            onPress: () {
              if (_formKey.currentState!.validate()) {
                navigateTo(ChallengesView(
                  personaName: _nameController.text,
                  type: widget.type,
                  personaModelData: PersonaModelData(
                    name: _nameController.text,
                    type: widget.type,
                    currentFocus: _currentFocus,
                    communicationStyle: _communicationStyle,
                    selfCareGoals: _goalsController.text.isEmpty
                        ? null
                        : _goalsController.text,
                    stressors: _stressorsController.text.isEmpty
                        ? null
                        : _stressorsController.text,
                    goals: _goalsController.text.isEmpty
                        ? null
                        : _goalsController.text,
                  ),
                ));
              }
            },
          ),
        ],
      ),
    );
  }
}
