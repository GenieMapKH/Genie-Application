# Builds the APK with known third-party warnings filtered out of the output.
# Usage: .\scripts\build_apk.ps1 [flutter build apk args...]   e.g. --release
#
# Filtered (none of them affect the build; remove a rule once its cause is gone):
# - "plugins that apply Kotlin Gradle Plugin": firebase_auth, firebase_core,
#   flutter_webrtc, ... still apply KGP themselves. Fixed only by plugin updates.
# - sodium_libs "resolution `workspace`": its published pubspec is malformed.
#   sodium_libs is discontinued (replaced by sodium 4.x).
# - "SDK XML versions up to 3": Android SDK tools newer than the AGP in use.

$blockStarts = @(
    'WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin',
    'WARNING: Your Android app project: '
)
$blockEnds = @('for-plugin-authors', 'for-app-developers')
$singleLines = @(
    'This version only understands SDK XML versions',
    'This can happen if you use versions of Android Studio and the command-line tools',
    'sodium_libs-.*But it has resolution `workspace`',
    '^But found no workspace root including it',
    '^See https://dart.dev/go/pub-workspaces'
)

$skipping = $false
flutter build apk @args 2>&1 | ForEach-Object {
    $line = "$_"
    # PowerShell 5.1 turns blank stderr lines into this text.
    if ($line -eq 'System.Management.Automation.RemoteException') { $line = '' }
    if ($skipping) {
        if ($blockEnds | Where-Object { $line.TrimEnd().EndsWith($_) }) { $skipping = $false }
        return
    }
    if ($blockStarts | Where-Object { $line.StartsWith($_) }) { $skipping = $true; return }
    if ($singleLines | Where-Object { $line -match $_ }) { return }
    Write-Host $line
}
exit $LASTEXITCODE
