# Consumer rules for Linkzly Flutter SDK host applications.

# Tink (pulled in transitively via the Linkzly Android SDK ->
# androidx.security:security-crypto) references compile-only error_prone annotations
# that are erased at runtime and never bundled. They are harmless, but R8 full-mode
# fails the host app's release build on the resulting "Missing class" reports unless
# they are suppressed here. Shipping this rule in the plugin guarantees coverage even
# when the resolved Android SDK artifact predates the same fix in its own consumer rules.
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn com.google.crypto.tink.**
