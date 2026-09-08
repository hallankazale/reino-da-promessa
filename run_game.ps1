$ErrorActionPreference = "Stop"

$ProjectPath = Split-Path -Parent $MyInvocation.MyCommand.Path

$GodotCandidates = @(
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Documents"
)

$Godot = Get-ChildItem $GodotCandidates -Filter "Godot*.exe" -File -Recurse -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $Godot) {
    Write-Host "Godot nao encontrado. Coloque o executavel em Downloads, Desktop ou Documents." -ForegroundColor Red
    exit 1
}

Write-Host "Godot: $($Godot.FullName)" -ForegroundColor Cyan
Write-Host "Projeto: $ProjectPath" -ForegroundColor Cyan
Write-Host "Importando modelos, texturas e cenas..." -ForegroundColor Yellow

& $Godot.FullName --headless --path $ProjectPath --import
if ($LASTEXITCODE -ne 0) {
    Write-Host "A importacao falhou. O jogo nao sera iniciado com assets incompletos." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "Importacao concluida. Iniciando Reino da Promessa..." -ForegroundColor Green
& $Godot.FullName --path $ProjectPath
