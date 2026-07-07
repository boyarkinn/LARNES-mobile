# mobile_scanner + ML Kit (release / R8)
-keep class dev.steenbakker.mobile_scanner.** { *; }
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.libraries.barhopper.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode_bundled.** { *; }

# CameraX
-keep class androidx.camera.** { *; }

# Flutter plugins (see flutter/flutter#154580)
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
