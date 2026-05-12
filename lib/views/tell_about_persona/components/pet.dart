import 'package:flutter/material.dart';

import '../../../core/design/app_button.dart';
import '../../../core/design/app_expansion_tile.dart';
import '../../../core/design/app_input.dart';
import '../../../core/logic/helper_methods.dart';
import '../../../core/logic/input_validator.dart';
import '../../challenges.dart';
import '../../select_persona.dart';
import '../view.dart';

class PetSection extends StatefulWidget {
  final PersonaType type;

  const PetSection({super.key, required this.type});

  @override
  State<PetSection> createState() => _PetSectionState();
}

class _PetSectionState extends State<PetSection> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _breedController = TextEditingController();
  final _healthController = TextEditingController();
  String? _species;
  String? _communicationStyle;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _breedController.dispose();
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
            label: 'Pet\'s name',
            controller: _nameController,
            validator: InputValidator.personaNameValidator,
            hint: 'e.g. Buddy, Luna',
          ),
          AppExpansionTile(
            title: 'What kind of pet?',
            label: 'Species',
            onChange: (value) => _species = value,
            list: const [
              'Dog',
              'Cat',
              'Rabbit',
              'Bird',
              'Guinea pig',
              'Other',
            ],
            icon: 'my_pet.svg',
          ),
          AppInput(
            controller: _breedController,
            label: 'Breed (optional)',
            hint: 'e.g. Golden Retriever, Domestic shorthair',
            prefix: 'user_name.svg',
          ),
          AppInput(
            prefix: 'age.svg',
            controller: _ageController,
            label: 'Age',
            hint: 'e.g. 3 years, 8 months',
            keyboardType: TextInputType.text,
          ),
          AppExpansionTile(
            title: 'How do they usually behave?',
            label: 'General temperament',
            onChange: (value) => _communicationStyle = value,
            list: const [
              'Calm and relaxed',
              'Active and energetic',
              'Anxious or nervous',
              'Aggressive when stressed',
              'Sensitive to change',
            ],
            icon: 'preferred_communication_method.svg',
          ),
          AppInput(
            controller: _healthController,
            label: 'Health or context notes (optional)',
            hint: 'e.g. Rescued, separation anxiety, recent vet visit',
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
                    age: _ageController.text.isEmpty ? null : _ageController.text,
                    species: _species,
                    breed: _breedController.text.isEmpty
                        ? null
                        : _breedController.text,
                    communicationStyle: _communicationStyle,
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
