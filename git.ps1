$status = git status --porcelain
$changed = @($status | Where-Object { $_ -match '^.[AMDR]' }).Count
$staged = @($status | Where-Object { $_ -match '^[AMDR]' }).Count

# حساب الـ commits الجاهزة للرفع بشكل آمن في PowerShell
$ahead = (git rev-list '@{u}..HEAD' 2>$null).Count
if (-not $ahead) { $ahead = 0 }

Write-Host "Changed files : $changed"
Write-Host "Added files : $staged"
Write-Host "Commited files : $ahead"

if ($changed -gt 0) {
    Write-Host "Changed and waiting for add" -ForegroundColor Red
} elseif ($staged -gt 0) {
    Write-Host "Added and waiting for commit" -ForegroundColor DarkYellow
} elseif ($ahead -gt 0) {
    Write-Host "Commited and waiting for push" -ForegroundColor Blue
} else {
    Write-Host "Everything up to date" -ForegroundColor Green
}