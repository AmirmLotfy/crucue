class InputValidator {
  InputValidator._();

  static final _emailReg = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? emailValidator(String value) {
    if (value.trim().isEmpty) return 'Email is required';
    if (!_emailReg.hasMatch(value.trim())) return 'Please enter a valid email';
    return null;
  }

  static String? passwordLoginValidator(String value) {
    if (value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? passwordValidator(
    String value, {
    bool lengthRequired = false,
  }) {
    if (value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? confirmPasswordValidator(String password, String confirm) {
    if (confirm.isEmpty) return 'Please confirm your password';
    if (password != confirm) return 'Passwords do not match';
    return null;
  }

  static String? requiredValidator(
    String? value, {
    required String fieldName,
    int minLength = 1,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  static String? nameValidator(String? value) {
    return requiredValidator(value, fieldName: 'Name', minLength: 2);
  }

  static String? profileFieldValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) return null; // Optional fields
    return null;
  }

  static String? phoneValidator(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    if (value.length < 7) return 'Please enter a valid phone number';
    return null;
  }

  // ─── Legacy persona form validators ───────────────────────────────
  static String? personaNameValidator(String? value) => nameValidator(value);

  static String? personaAgeValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Age is required';
    return null;
  }

  static String? personaSharedInterestsValidator(String? value) => null;
  static String? personaInterestsHobbiesValidator(String? value) => null;
  static String? personaHealthConditionsValidator(String? value) => null;
  static String? personaGoalsValidator(String? value) => null;
  static String? personaEducationLevelValidator(String? value) => null;
  static String? personaLoveLanguageValidator(String? value) => null;
  static String? personaWorkRelationshipValidator(String? value) => null;
}
