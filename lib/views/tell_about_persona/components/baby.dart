import 'package:flutter/material.dart';

import '../../../core/design/app_button.dart';
import '../../../core/design/app_expansion_tile.dart';
import '../../../core/design/app_input.dart';
import '../../../core/logic/helper_methods.dart';
import '../../../core/logic/input_validator.dart';
import '../../challenges.dart';
import '../../select_persona.dart';
import '../view.dart';

class BabySection extends StatefulWidget {
  final PersonaType type;

  const BabySection({super.key, required this.type});

  @override
  State<BabySection> createState() => _BabySectionState();
}

class _BabySectionState extends State<BabySection> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _healthController = TextEditingController();
  String? _developmentalStage;
  String? _sleepSchedule;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _healthController.dispose();
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
            label: 'Name or nickname',
            controller: _nameController,
            validator: InputValidator.personaNameValidator,
            hint: 'e.g. Baby Mia, Little one',
          ),
          AppInput(
            prefix: 'age.svg',
            controller: _ageController,
            label: 'Age in months',
            validator: InputValidator.personaAgeValidator,
            hint: 'e.g. 6 months, 14 months',
            keyboardType: TextInputType.number,
          ),
          AppExpansionTile(
            title: 'Developmental stage',
            label: 'Developmental stage',
            onChange: (value) => _developmentalStage = value,
            list: const [
              'Newborn (0-3 months)',
              'Early infant (3-6 months)',
              'Sitting and exploring (6-9 months)',
              'Crawler (9-12 months)',
              'Early toddler (12-18 months)',
            ],
            icon: 'age.svg',
          ),
          AppExpansionTile(
            title: 'Sleep pattern',
            label: 'Sleep schedule',
            onChange: (value) => _sleepSchedule = value,
            list: const [
              'Sleeping well through night',
              'Waking 1-2 times',
              'Waking frequently (3+)',
              'Irregular — hard to predict',
              'Short napper',
            ],
            icon: 'notification.svg',
          ),
          AppInput(
            controller: _healthController,
            label: 'Health notes (optional)',
            hint: 'e.g. Reflux, eczema, premature birth',
            prefix: 'blood_type.svg',
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
                    age: _ageController.text,
                    developmentalStage: _developmentalStage,
                    sleepSchedule: _sleepSchedule,
                    healthConcerns: _healthController.text.isEmpty
                        ? null
                        : _healthController.text,
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
