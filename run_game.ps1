$ErrorActionPreference = "Stop"

$ProjectPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$GodotVersion = "4.7.2-stable"
$GodotZipName = "Godot_v4.7.2-stable_win64.exe.zip"
$GodotDownloadUrl = "https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/$GodotZipName"
$GodotZipSha256 = "731980f9608d61333e5baf54a2ef17210acc7a538446c0cb9969f002aca1e953"
$ToolsDir = Join-Path $ProjectPath ".tools\godot\$GodotVersion"

function Find-GodotExecutable {
    $SearchRoots = @(
        $ToolsDir,
        "$env:USERPROFILE\Downloads",
        "$env:USERPROFILE\Desktop",
        "$env:USERPROFILE\Documents"
    ) | Where-Object { Test-Path $_ }

    return Get-ChildItem $SearchRoots -Filter "Godot*.exe" -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notmatch "_console\.exe$" } |
        Sort-Object @{ Expression = { if ($_.FullName.StartsWith($ToolsDir, [System.StringComparison]::OrdinalIgnoreCase)) { 0 } else { 1 } } }, LastWriteTime -Descending |
        Select-Object -First 1
}

function Install-ManagedGodot {
    Write-Host "Baixando Godot $GodotVersion oficial..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $ToolsDir | Out-Null

    $ZipPath = Join-Path $ToolsDir $GodotZipName
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $GodotDownloadUrl -OutFile $ZipPath -UseBasicParsing

    $ActualHash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($ActualHash -ne $GodotZipSha256) {
        Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue
        throw "Falha de seguranca: SHA-256 do Godot baixado nao confere."
    }

    Write-Host "Download validado. Extraindo Godot..." -ForegroundColor Cyan
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $ToolsDir -Force
    Remove-Item $ZipPath -Force
}

$Godot = Find-GodotExecutable

if (-not $Godot) {
    Write-Host "Godot principal nao encontrado." -ForegroundColor Yellow
    Install-ManagedGodot
    $Godot = Find-GodotExecutable
}

if (-not $Godot) {
    Write-Host "Nao foi possivel localizar ou instalar o executavel principal do Godot." -ForegroundColor Red
    exit 1
}

$ConsolePath = Join-Path $Godot.DirectoryName ($Godot.BaseName + "_console.exe")
if (-not (Test-Path -LiteralPath $ConsolePath)) {
    Write-Host "O Godot encontrado nao possui o executavel de console necessario para importacao." -ForegroundColor Yellow
    Write-Host "Instalando uma copia completa e isolada do Godot no projeto..." -ForegroundColor Yellow
    Install-ManagedGodot
    $Godot = Find-GodotExecutable
    $ConsolePath = Join-Path $Godot.DirectoryName ($Godot.BaseName + "_console.exe")
}

if (-not (Test-Path -LiteralPath $ConsolePath)) {
    Write-Host "Nao foi possivel localizar o executavel de console do Godot." -ForegroundColor Red
    exit 1
}

Write-Host "Godot: $($Godot.FullName)" -ForegroundColor Cyan
Write-Host "Importador: $ConsolePath" -ForegroundColor DarkCyan
Write-Host "Projeto: $ProjectPath" -ForegroundColor Cyan
Write-Host "Importando modelos, texturas e cenas..." -ForegroundColor Yellow

& $ConsolePath --headless --path $ProjectPath --import
$ImportExitCode = $LASTEXITCODE

if ($ImportExitCode -ne 0) {
    Write-Host "A importacao falhou com codigo $ImportExitCode. Veja as mensagens acima para identificar o recurso com erro." -ForegroundColor Red
    Write-Host "O jogo nao sera iniciado com assets incompletos." -ForegroundColor Red
    exit $ImportExitCode
}

Write-Host "Importacao concluida. Iniciando Reino da Promessa..." -ForegroundColor Green
Start-Process -FilePath $Godot.FullName -ArgumentList @("--path", $ProjectPath)
