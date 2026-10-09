# Mobile Scanner & ML Kit rules to prevent R8 from stripping necessary native code
-keep class dev.steenbakker.mobile_scanner.** { *; }
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }

# Ignore warnings for missing Play Core classes referenced by Flutter's deferred components
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn com.google.android.play.core.**
