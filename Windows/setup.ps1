<#
.SYNOPSIS
    Sets up a Windows machine from the YAML files in ..\config.

.DESCRIPTION
    Installs packages with Scoop (per user), Chocolatey and winget (administrator),
    then the cross-platform tools (npm, pipx, cargo, VS Code extensions) and the
    git identity. It is safe to run again: anything already installed is skipped.

    Run it from a normal (not elevated) PowerShell window. It asks for
    administrator rights only for the Chocolatey and winget part, because Scoop
    refuses to install as administrator.

.PARAMETER InstallProfile
    work     installs the "base" lists only.
    personal installs "base" plus the "personal" lists.
    Defaults to the profile in config\config.local.yml (or config.example.yml).
    Can also be written -Profile.

.PARAMETER DryRun
    Show what would be installed and change nothing.

.PARAMETER Section
    All (default), User (Scoop and the cross-platform tools) or Machine
    (Chocolatey and winget, needs administrator rights).

.EXAMPLE
    .\setup.ps1 -DryRun
.EXAMPLE
    .\setup.ps1 -Profile personal
#>
[CmdletBinding()]
param(
    [Alias('Profile')]
    [ValidateSet('work', 'personal')]
    [string]$InstallProfile,

    [switch]$DryRun,

    [ValidateSet('All', 'User', 'Machine')]
    [string]$Section = 'All',

    [string]$ConfigDir = (Join-Path (Split-Path -Parent $PSScriptRoot) 'config'),

    [string]$LogPath = (Join-Path $HOME ("setup-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date)))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Failures = [System.Collections.Generic.List[string]]::new()
$script:OnWindows = [System.Environment]::OSVersion.Platform -eq 'Win32NT'
$PlaceholderEmail = 'you@example.com'

# ---------------------------------------------------------------- helpers

function Write-Step([string]$Message) {
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Test-IsAdmin {
    if (-not $script:OnWindows) { return $false }
    $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-Command([string]$Name) {
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# Pick up programs installed earlier in this run.
function Update-SessionPath {
    if (-not $script:OnWindows) { return }
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user"
}

function Merge-Config($Base, $Override) {
    $result = @{}
    foreach ($key in $Base.Keys) { $result[$key] = $Base[$key] }
    foreach ($key in $Override.Keys) {
        if ($result.ContainsKey($key) -and
            $result[$key] -is [System.Collections.IDictionary] -and
            $Override[$key] -is [System.Collections.IDictionary]) {
            $result[$key] = Merge-Config $result[$key] $Override[$key]
        }
        else {
            $result[$key] = $Override[$key]
        }
    }
    return $result
}

function Import-YamlFile([string]$Path) {
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Yaml
}

# The packages wanted from one group of a packages file, for the chosen profile.
function Get-Wanted($Packages, [string]$Group) {
    if (-not $Packages.Contains($Group)) { return @() }
    $items = @($Packages[$Group]['base'])
    if ($InstallProfile -eq 'personal') { $items += @($Packages[$Group]['personal']) }
    return @($items | Where-Object { $_ })
}

# Run one install. A failure is recorded and the run carries on.
function Invoke-Install([string]$Label, [scriptblock]$Action) {
    if ($DryRun) {
        Write-Host "[dry-run] would install $Label"
        return
    }
    Write-Host "Installing $Label"
    try {
        $global:LASTEXITCODE = 0
        & $Action
        if ($global:LASTEXITCODE -ne 0) { throw "exit code $global:LASTEXITCODE" }
    }
    catch {
        $script:Failures.Add("$Label -- $($_.Exception.Message)")
        Write-Warning "Failed to install ${Label}: $($_.Exception.Message)"
    }
}

# Download an installer to a file first, then run it. Never piped into a shell.
function Invoke-RemoteInstaller([string]$Name, [string]$Url) {
    $file = Join-Path ([System.IO.Path]::GetTempPath()) "$Name-install.ps1"
    Invoke-WebRequest -Uri $Url -OutFile $file -UseBasicParsing
    $shell = (Get-Process -Id $PID).Path
    & $shell -NoProfile -ExecutionPolicy Bypass -File $file
    Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue
}

function Install-Missing([string]$Manager, [string[]]$Wanted, [string[]]$Installed, [scriptblock]$Install) {
    $have = @($Installed | ForEach-Object { $_.ToLowerInvariant() })
    $missing = @($Wanted | Where-Object { $have -notcontains $_.ToLowerInvariant() })
    Write-Step "${Manager}: $($Wanted.Count) wanted, $($missing.Count) to install"
    foreach ($name in $missing) {
        $action = { & $Install $name }.GetNewClosure()
        Invoke-Install "$Manager package $name" $action
    }
}

# --------------------------------------------------------------- sections

function Install-ScoopPackages($Wanted) {
    if ($Wanted.Count -eq 0) { return }
    if (-not (Test-Command 'scoop')) {
        if (Test-IsAdmin) {
            $script:Failures.Add('Scoop -- not installed, and it cannot be installed from an administrator window. Run setup.ps1 again without elevation.')
            Write-Warning 'Skipping Scoop: it cannot be installed from an administrator window.'
            return
        }
        Invoke-Install 'Scoop' {
            if ($script:OnWindows -and (Get-ExecutionPolicy -Scope CurrentUser) -eq 'Undefined') {
                Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            }
            Invoke-RemoteInstaller 'scoop' 'https://get.scoop.sh'
        }
        Update-SessionPath
    }
    $installed = @()
    if (Test-Command 'scoop') {
        $export = scoop export 2>$null | Out-String | ConvertFrom-Json
        $installed = @($export.apps | ForEach-Object { $_.Name })
    }
    Install-Missing 'scoop' $Wanted $installed { param($n) scoop install $n }
}

function Install-ChocolateyPackages($Wanted) {
    if ($Wanted.Count -eq 0) { return }
    if (-not (Test-Command 'choco')) {
        Invoke-Install 'Chocolatey' { Invoke-RemoteInstaller 'chocolatey' 'https://community.chocolatey.org/install.ps1' }
        Update-SessionPath
    }
    $installed = @()
    if (Test-Command 'choco') {
        $installed = @(choco list --local-only --limit-output | ForEach-Object { ($_ -split '\|')[0] })
    }
    Install-Missing 'choco' $Wanted $installed { param($n) choco install -y --no-progress $n }
}

function Install-WingetPackages($Wanted) {
    if ($Wanted.Count -eq 0) { return }
    if (-not (Test-Command 'winget')) {
        $script:Failures.Add('winget -- not found. Install "App Installer" from the Microsoft Store.')
        Write-Warning 'Skipping winget: it is not installed.'
        return
    }
    $installed = @()
    foreach ($id in $Wanted) {
        winget list --id $id --exact --accept-source-agreements *> $null
        if ($LASTEXITCODE -eq 0) { $installed += $id }
    }
    Install-Missing 'winget' $Wanted $installed {
        param($n) winget install --id $n --exact --silent --accept-package-agreements --accept-source-agreements
    }
}

function Install-WithTool([string]$Tool, [string]$Manager, [string[]]$Wanted, [scriptblock]$List, [scriptblock]$Install) {
    if ($Wanted.Count -eq 0) { return }
    if (-not (Test-Command $Tool)) {
        Write-Warning "Skipping ${Manager}: '$Tool' is not installed (yet)."
        return
    }
    Install-Missing $Manager $Wanted @(& $List) $Install
}

function Set-GitIdentity($Config) {
    if ($Config.user.git_email -eq $PlaceholderEmail) {
        Write-Warning 'user.git_email is still the example value, so git is not configured. Copy config\config.example.yml to config\config.local.yml and edit it.'
        return
    }
    if (-not (Test-Command 'git')) {
        Write-Warning "Skipping git identity: 'git' is not installed (yet)."
        return
    }
    Write-Step 'git identity'
    Invoke-Install 'git user.name and user.email' {
        git config --global user.name $Config.user.git_name
        git config --global user.email $Config.user.git_email
    }
}

function Copy-WslConfig {
    $target = Join-Path $HOME '.wslconfig'
    $source = Join-Path $PSScriptRoot 'config\.wslconfig'
    if (Test-Path -LiteralPath $target) {
        Write-Host "Keeping your existing $target"
        return
    }
    Write-Step 'WSL settings'
    Invoke-Install ".wslconfig to $target" { Copy-Item -LiteralPath $source -Destination $target }
}

function Invoke-MachineSection($Windows) {
    Write-Step 'Machine-wide packages (Chocolatey, winget)'
    Install-ChocolateyPackages (Get-Wanted $Windows 'choco')
    Install-WingetPackages (Get-Wanted $Windows 'winget')
}

function Invoke-UserSection($Windows, $Common, $Config) {
    Write-Step 'Per-user packages (Scoop and cross-platform tools)'
    Install-ScoopPackages (Get-Wanted $Windows 'scoop')
    Update-SessionPath

    Install-WithTool 'npm' 'npm' (Get-Wanted $Common 'npm') {
        npm ls -g --depth=0 --parseable 2>$null | Select-Object -Skip 1 | ForEach-Object { ($_ -replace '\\', '/') -replace '.*/node_modules/', '' }
    } { param($n) npm install -g $n }

    Install-WithTool 'pipx' 'pipx' (Get-Wanted $Common 'pipx') {
        pipx list --short | ForEach-Object { ($_ -split ' ')[0] }
    } { param($n) pipx install $n }

    Install-WithTool 'cargo' 'cargo' (Get-Wanted $Common 'cargo') {
        cargo install --list | Where-Object { $_ -match '^\S' } | ForEach-Object { ($_ -split ' ')[0] }
    } { param($n) cargo install --locked $n }

    Install-WithTool 'code' 'VS Code extension' (Get-Wanted $Common 'vscode_extensions') {
        code --list-extensions
    } { param($n) code --install-extension $n }

    Set-GitIdentity $Config
    Copy-WslConfig
}

# ------------------------------------------------------------------- main

if (-not $DryRun) {
    try { Start-Transcript -Path $LogPath | Out-Null; Write-Host "Logging to $LogPath" } catch { Write-Warning "No log file: $($_.Exception.Message)" }
}

if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Step 'Installing the powershell-yaml module (current user)'
    Install-Module -Name powershell-yaml -Scope CurrentUser -Force -Repository PSGallery
}
Import-Module powershell-yaml

$config = Import-YamlFile (Join-Path $ConfigDir 'config.example.yml')
$localConfig = Join-Path $ConfigDir 'config.local.yml'
if (Test-Path -LiteralPath $localConfig) {
    $config = Merge-Config $config (Import-YamlFile $localConfig)
}
if (-not $InstallProfile) { $InstallProfile = $config.profile }
if ($InstallProfile -notin 'work', 'personal') {
    throw "profile must be 'work' or 'personal', found '$InstallProfile'."
}

$windowsPackages = Import-YamlFile (Join-Path $ConfigDir 'packages\windows.yml')
$commonPackages = Import-YamlFile (Join-Path $ConfigDir 'packages\common.yml')

Write-Host "Profile: $InstallProfile$(if ($DryRun) { ' (dry run, nothing will change)' })"

switch ($Section) {
    'Machine' {
        if (-not $DryRun -and -not (Test-IsAdmin)) { throw 'The Machine section needs an administrator window.' }
        Invoke-MachineSection $windowsPackages
    }
    'User' {
        Invoke-UserSection $windowsPackages $commonPackages $config
    }
    'All' {
        if ($DryRun -or (Test-IsAdmin)) {
            Invoke-MachineSection $windowsPackages
        }
        else {
            Write-Step 'Asking for administrator rights for the Chocolatey and winget part'
            $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"",
                '-Section', 'Machine', '-InstallProfile', $InstallProfile, '-ConfigDir', "`"$ConfigDir`"")
            $child = Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList $arguments -Verb RunAs -Wait -PassThru
            if ($child.ExitCode -ne 0) {
                $script:Failures.Add("Machine section (Chocolatey, winget) -- exit code $($child.ExitCode), see its window or log")
            }
            Update-SessionPath
        }
        Invoke-UserSection $windowsPackages $commonPackages $config
    }
}

Write-Host ''
if ($script:Failures.Count -gt 0) {
    Write-Host "$($script:Failures.Count) step(s) failed:" -ForegroundColor Red
    $script:Failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}
else {
    Write-Host 'Done. No failures.' -ForegroundColor Green
}
if (-not $DryRun) { try { Stop-Transcript | Out-Null } catch { $null = $_ } }
exit ([int]($script:Failures.Count -gt 0))
