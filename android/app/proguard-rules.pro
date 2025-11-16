## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

## Google Error Prone and Crypto Tink annotations
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn javax.annotation.concurrent.**

-keep class com.google.crypto.tink.** { *; }
-keepclassmembers class * {
    @com.google.crypto.tink.annotations.** *;
}

## Google Play Core (for deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

## Google API Client (HTTP)
-dontwarn com.google.api.client.http.**
-dontwarn org.joda.time.**

## Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
