# Flutter QNN Chat - ProGuard Rules
# Required for release builds with MediaPipe and Protocol Buffers

# MediaPipe
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

# Protocol Buffers
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# Flutter Gemma native libraries
-keep class io.flutter.plugins.** { *; }
