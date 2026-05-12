/// Default on-device Gemma weights for Crucue (hybrid / offline-capable tier).
///
/// **Not** the same as cloud `gemma-4-26b-a4b-it`: phones use **Gemma 4 E2B/E4B**
/// LiteRT-LM builds (see [flutter_gemma](https://pub.dev/packages/flutter_gemma) and
/// [litert-community on Hugging Face](https://huggingface.co/litert-community)).
///
/// ## Formats ([flutter_gemma](https://pub.dev/packages/flutter_gemma) README)
/// - Android: `.litertlm` or `.task` with [ModelFileType.task].
/// - iOS: `.litertlm` is **text-only** (no vision/audio) per plugin docs; `.task` for older flows.
/// - Default download: **Gemma 4 E2B IT** `.litertlm` (~2.6 GB).
library;

import 'package:flutter_gemma/flutter_gemma.dart';

/// Hugging Face resolve URL for the default Crucue on-device model (public, no gate).
const String kCrucueOnDeviceGemma4E2bLitertLmUrl =
    'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm?download=true';

/// Filename segment used by [FlutterGemma.isModelInstalled] / uninstall (matches URL path).
const String kCrucueOnDeviceDefaultModelFileName = 'gemma-4-E2B-it.litertlm';

/// Optional larger variant (higher-RAM devices); same repo family.
const String kCrucueOnDeviceGemma4E4bLitertLmUrl =
    'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.litertlm?download=true';

const ModelType kCrucueOnDeviceModelType = ModelType.gemmaIt;

/// `.litertlm` uses the same [ModelFileType.task] path as `.task` in flutter_gemma.
const ModelFileType kCrucueOnDeviceModelFileType = ModelFileType.task;
