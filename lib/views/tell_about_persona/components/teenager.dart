import 'package:flutter/material.dart';

import '../../../core/design/app_button.dart';
import '../../../core/design/app_expansion_tile.dart';
import '../../../core/design/app_input.dart';
import '../../../core/logic/helper_methods.dart';
import '../../../core/logic/input_validator.dart';
import '../../challenges.dart';
import '../../select_persona.dart';
import '../view.dart';

class TeenagerSection extends StatefulWidget {
  final PersonaType type;

  const TeenagerSection({super.key, required this.type});

  @override
  State<TeenagerSection> createState() => _TeenagerSectionState();
}

class _TeenagerSectionState extends State<TeenagerSection> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _interestsController = TextEditingController();
  final _schoolYearController = TextEditingController();
  String? _gender;
  String? _communicationStyle;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _interestsController.dispose();
    _schoolYearController.dispose();
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
            label: 'Name',
            controller: _nameController,
            validator: InputValidator.personaNameValidator,
            hint: 'Your teenager\'s first name',
          ),
          AppInput(
            prefix: 'age.svg',
            controller: _ageController,
            label: 'Age',
            validator: InputValidator.personaAgeValidator,
            hint: 'e.g. 15',
            keyboardType: TextInputType.number,
          ),
          AppExpansionTile(
            title: 'Select gender',
            label: 'Gender',
            onChange: (value) => _gender = value,
            list: const ['Male', 'Female', 'Non-Binary', 'Prefer not to say'],
            icon: 'gender.svg',
          ),
          AppInput(
            controller: _schoolYearController,
            label: 'School year (optional)',
            hint: 'e.g. Year 10, Junior year',
            prefix: 'age.svg',
          ),
          AppExpansionTile(
            title: 'How do they communicate best?',
            label: 'Communication style',
            onChange: (value) => _communicationStyle = value,
            list: const [
              'Talks openly when calm',
              'Needs space first',
              'Prefers texting or writing',
              'Expresses through behaviour',
              'Opens up one-on-one',
            ],
            icon: 'preferred_communication_method.svg',
          ),
          AppInput(
            controller: _interestsController,
            label: 'Interests and hobbies (optional)',
            hint: 'e.g. Music, gaming, sport, art',
            prefix: 'user_name.svg',
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
                    gender: _gender,
                    communicationStyle: _communicationStyle,
                    interestsHobbies: _interestsController.text.isEmpty
                        ? null
                        : _interestsController.text,
                    currentSchoolYear: _schoolYearController.text.isEmpty
                        ? null
                        : _schoolYearController.text,
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
