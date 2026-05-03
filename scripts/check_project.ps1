param(
  [string]$FlutterPath = "C:\Users\dishu\Downloads\flutter_windows_3.41.8-stable\flutter\bin\flutter.bat"
)

Write-Host "Checking Flutter project..."
& $FlutterPath analyze --no-pub
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $FlutterPath test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "All checks passed."
