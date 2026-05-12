import Flutter
import UIKit

/**
 * iOS native adapter for on-device Gemma 4 inference via LiteRT-LM.
 *
 * Strategy:
 * LiteRT-LM (formerly TensorFlow Lite, now part of Google AI Edge) runs
 * Gemma 4 E2B/E4B model weights that are bundled via on-demand resources
 * or downloaded to the app's Documents directory.
 *
 * Requirements:
 * - iPhone 12+ recommended (A14 Bionic or later for acceptable speed)
 * - iPhone 15+ recommended for 4B model (A16 Bionic, 8 GB RAM)
 * - iOS 16.0+
 *
 * ## Channel
 * `com.crucue.app/on_device_ai`
 *
 * ## Methods
 * - `isAvailable` → Bool: device capability check
 * - `initialize`  → void: load model into memory
 * - `generate`    → String: run inference with prompt
 * - `dispose`     → void: release model from memory
 *
 * ## Status
 * STUB — returns "not available" until LiteRT-LM integration is complete.
 * See docs/on_device_strategy.md for the full integration path.
 */
class OnDeviceAiPlugin: NSObject, FlutterPlugin {

    private static let channelName = "com.crucue.app/on_device_ai"
    private var isModelLoaded = false

    // MARK: - FlutterPlugin registration

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = OnDeviceAiPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // MARK: - Method call handling

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAvailable":
            handleIsAvailable(result: result)
        case "initialize":
            handleInitialize(call: call, result: result)
        case "generate":
            handleGenerate(call: call, result: result)
        case "dispose":
            handleDispose(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Handlers

    /**
     * Returns true if the device supports on-device Gemma 4 inference.
     *
     * Checks:
     * - iOS 16.0+
     * - Physical device (not simulator)
     * - Sufficient RAM (> 3 GB for E2B, > 6 GB for E4B)
     *
     * STUB: always returns false until LiteRT-LM is integrated.
     */
    private func handleIsAvailable(result: @escaping FlutterResult) {
        // TODO: Check ProcessInfo.processInfo.physicalMemory >= 3 * 1024 * 1024 * 1024
        //       and that we're on a physical device (TARGET_OS_SIMULATOR == 0).
        //       Return true when LiteRT-LM session can be created.
        result(false)
    }

    /**
     * Loads the specified Gemma 4 model variant.
     *
     * Expected arguments dictionary:
     * - `modelVariant` (String): "gemma-4-e2b-it" or "gemma-4-e4b-it"
     *
     * STUB: returns MODEL_NOT_FOUND until weights are configured.
     */
    private func handleInitialize(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let modelVariant = args["modelVariant"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "modelVariant required", details: nil))
            return
        }

        // TODO: Resolve modelVariant to the bundled / downloaded model path.
        //   let modelPath = resolveModelPath(modelVariant)
        //   let options = LlmInference.Options(modelPath: modelPath)
        //   session = try LlmInference(options: options)
        //   isModelLoaded = true

        result(FlutterError(
            code: "MODEL_NOT_FOUND",
            message: "On-device model '\(modelVariant)' weights not available. " +
                     "Bundle via on-demand resources or background download.",
            details: nil
        ))
    }

    /**
     * Runs inference with the loaded model.
     *
     * Expected arguments dictionary:
     * - `prompt` (String): full prompt text
     * - `maxTokens` (Int): maximum tokens (default 512)
     * - `temperature` (Double): sampling temperature (default 0.4)
     *
     * STUB: returns NOT_INITIALIZED until model is loaded.
     */
    private func handleGenerate(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isModelLoaded else {
            result(FlutterError(
                code: "NOT_INITIALIZED",
                message: "Model not initialized. Call 'initialize' first.",
                details: nil
            ))
            return
        }

        // TODO: Extract prompt/maxTokens/temperature from args.
        //   let response = try session?.generateResponse(inputText: prompt)
        //   result(response)
        result(FlutterError(code: "NOT_INITIALIZED", message: "Model not loaded.", details: nil))
    }

    /**
     * Releases the model from memory.
     */
    private func handleDispose(result: @escaping FlutterResult) {
        // TODO: session = nil
        isModelLoaded = false
        result(nil)
    }
}
