# Builds the APK with known third-party warnings filtered out of the output.
# Usage: .\scripts\build_apk.ps1 [-Env production|staging] [flutter build apk args...]
#   .\scripts\build_apk.ps1 -Env production   -> build\app\outputs\flutter-apk\tilomnov-production.apk
#   .\scripts\build_apk.ps1 -Env staging      -> build\app\outputs\flutter-apk\tilomnov-staging.apk
# -Env builds an ARM64-v8a release APK from .env.<Env> (backend URL, Sentry, app id) and
# copies it to a name of its own, so the two builds don't overwrite each other.
# Without -Env the arguments go to `flutter build apk` unchanged.
#
# Filtered (none of them affect the build; remove a rule once its cause is gone):
# - "plugins that apply Kotlin Gradle Plugin": firebase_auth, firebase_core,
#   flutter_webrtc, ... still apply KGP themselves. Fixed only by plugin updates.
# - sodium_libs "resolution `workspace`": its published pubspec is malformed.
#   sodium_libs is discontinued (replaced by sodium 4.x).
# - "SDK XML versions up to 3": Android SDK tools newer than the AGP in use.

param(
    [ValidateSet('production', 'staging')]
    [string]$Env,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArgs
)

$buildArgs = @($FlutterArgs | Where-Object { $_ })
if ($Env) {
    $envFile = Join-Path $PSScriptRoot "..\.env.$Env"
    if (-not (Test-Path $envFile)) {
        Write-Error "$envFile is missing (it is git-ignored: create it from the other .env.* file)."
        exit 1
    }
    # Split packaging also removes other ABIs bundled by native plugins.
    $buildArgs = @('--release', '--target-platform=android-arm64', '--split-per-abi', "--dart-define-from-file=.env.$Env") + $buildArgs
}

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
flutter build apk @buildArgs 2>&1 | ForEach-Object {
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
$buildExitCode = $LASTEXITCODE
if ($buildExitCode -eq 0 -and $Env) {
    $apkDir = Join-Path $PSScriptRoot '..\build\app\outputs\flutter-apk'
    $named = Join-Path $apkDir "tilomnov-$Env.apk"
    Copy-Item (Join-Path $apkDir 'app-arm64-v8a-release.apk') $named -Force
    Write-Host "APK for $Env`: $((Resolve-Path $named).Path)"

    # Gradle exports before the named copy exists, so copy it to APK_EXPORT_DIR here.
    $localProps = Join-Path $PSScriptRoot '..\android\local.properties'
    $exportLine = if (Test-Path $localProps) { Select-String -Path $localProps -Pattern '^APK_EXPORT_DIR=(.+)$' | Select-Object -First 1 }
    if ($exportLine) {
        $exportDir = $exportLine.Matches[0].Groups[1].Value.Trim()
        Copy-Item $named $exportDir -Force
        Write-Host "Copied to $exportDir"
    }
}
exit $buildExitCode
