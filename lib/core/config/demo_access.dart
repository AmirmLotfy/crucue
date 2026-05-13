import 'package:flutter/foundation.dart';

/// Whether Settings shows the seeded demo profile ("Mom") and related helpers.
///
/// - [kDebugMode]: always on (local development).
/// - Release / profile: pass `--dart-define=SHOW_DEMO_SEED=true` when building
///   the hackathon or reviewer APK so judges can load demo data without a debug build.
const bool _demoSeedFromDefine = bool.fromEnvironment(
  'SHOW_DEMO_SEED',
  defaultValue: false,
);

bool get showDemoProfileSeeding => kDebugMode || _demoSeedFromDefine;
