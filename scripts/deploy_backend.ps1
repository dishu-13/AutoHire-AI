param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectId
)

firebase use $ProjectId
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

firebase deploy --only firestore:rules,firestore:indexes
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Firestore rules and indexes deployed for $ProjectId."
