package com.crucue.app.ai

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Android native adapter for on-device Gemma 4 inference.
 *
 * Strategy:
 * 1. Android AICore (preferred) — uses the system-managed Gemini Nano 4 model
 *    via the Google AI Edge SDK. Available on Pixel 8+ and select OEM devices.
 * 2. LiteRT-LM fallback — runs Gemma 4 E2B/E4B GGUF weights bundled via
 *    Play Asset Delivery through the LiteRT-LM inference engine.
 *
 * ## Channel
 * `com.crucue.app/on_device_ai`
 *
 * ## Methods
 * - `isAvailable` → Boolean: device capability check
 * - `initialize`  → void: load model into memory (throws if weights missing)
 * - `generate`    → String: run inference with prompt
 * - `dispose`     → void: release model from memory
 *
 * ## Status
 * STUB — returns "not available" until model weights are integrated.
 * See docs/on_device_strategy.md for the full integration path.
 *
 * **Hackathon / LiteRT demo:** See docs/edge_demo_path.md for how to validate Gemma 4
 * on-device (Google AI Edge Gallery, LiteRT-LM roadmap) without claiming this
 * plugin is production-ready yet.
 */
class OnDeviceAiPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private var isModelLoaded = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        releaseModel()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isAvailable" -> handleIsAvailable(result)
            "initialize"  -> handleInitialize(call, result)
            "generate"    -> handleGenerate(call, result)
            "dispose"     -> handleDispose(result)
            else          -> result.notImplemented()
        }
    }

    // ─── Method handlers ─────────────────────────────────────────────────────

    /**
     * Returns true if the device meets on-device AI requirements:
     * - Android 10+
     * - 4+ GB RAM (approximate check via ActivityManager)
     * - AICore or LiteRT-LM support (checked at runtime)
     *
     * STUB: always returns false until native integration is complete.
     */
    private fun handleIsAvailable(result: Result) {
        // TODO: Check AICore availability via com.google.android.gms.aicore
        //       or LiteRT-LM via ai.onnxruntime / tflite bindings.
        // Stub: report unavailable until model weights are configured.
        result.success(false)
    }

    /**
     * Loads the specified Gemma 4 model variant into memory.
     *
     * Expected [call.arguments] map:
     * - `modelVariant` (String): "gemma-4-e2b-it" or "gemma-4-e4b-it"
     *
     * STUB: throws MODEL_NOT_FOUND until weights are delivered.
     */
    private fun handleInitialize(call: MethodCall, result: Result) {
        val modelVariant = call.argument<String>("modelVariant") ?: "gemma-4-e2b-it"

        // TODO: Resolve modelVariant to Play Asset Delivery asset path.
        //       Initialize AICore or LiteRT-LM session with the resolved weights.
        // Example AICore path:
        //   val session = LlmInference.createFromOptions(context, options)
        //   where options.setModelPath(resolveAssetPath(modelVariant))

        result.error(
            "MODEL_NOT_FOUND",
            "On-device model '$modelVariant' weights not available. " +
            "Configure Play Asset Delivery and retry.",
            null
        )
    }

    /**
     * Runs inference with the loaded model.
     *
     * Expected [call.arguments] map:
     * - `prompt` (String): full prompt text
     * - `maxTokens` (Int): maximum tokens to generate (default 512)
     * - `temperature` (Double): sampling temperature (default 0.4)
     *
     * Returns the generated String response.
     *
     * STUB: throws NOT_INITIALIZED until model is loaded.
     */
    private fun handleGenerate(call: MethodCall, result: Result) {
        if (!isModelLoaded) {
            result.error(
                "NOT_INITIALIZED",
                "Model not initialized. Call 'initialize' first.",
                null
            )
            return
        }

        // TODO: Invoke AICore / LiteRT-LM session with the prompt.
        //   val response = session.generateResponse(prompt)
        //   result.success(response)
        result.error("NOT_INITIALIZED", "Model not loaded.", null)
    }

    /**
     * Releases the model from memory.
     */
    private fun handleDispose(result: Result) {
        releaseModel()
        result.success(null)
    }

    // ─── Private helpers ─────────────────────────────────────────────────────

    private fun releaseModel() {
        // TODO: Close AICore / LiteRT-LM session.
        isModelLoaded = false
    }

    companion object {
        const val CHANNEL_NAME = "com.crucue.app/on_device_ai"
    }
}
