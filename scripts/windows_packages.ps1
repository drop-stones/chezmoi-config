. "$PSScriptRoot/utils.ps1"

##############################################
# scoop
##############################################

function Add-ScoopBucket([string] $Bucket, [string] $Url) {
  if (-not (scoop bucket list | Select-String -Quiet $Bucket)) {
    Write-LogMessage -b "[add] " "add $Bucket bucket"
    scoop bucket add $Bucket $Url
  } else {
    Write-LogMessage -y "[skip] " "$Bucket bucket is already added"
  }
}

function Test-IsPackageInstalled([string] $Package) {
  # skip header by `Select-Object -Skip 1`
  scoop list $Package 6>&1 | Select-Object -Skip 1 | Where-Object { $_.Name -eq $Package } | ForEach-Object { return $True }
  return $False
}

function Test-IsPackageAvailable([string] $Package) {
  scoop search $Package 6>&1 | Select-Object -Skip 1 | Where-Object { $_.Name -eq $Package } | ForEach-Object { return $True }
  return $False
}

function Install-Package([string[]] $Packages) {
  scoop install $Packages
}

function Install-PackageList([string] $PackageList) {
  Install-Packages $PackageList (Get-Command Test-IsPackageInstalled).ScriptBlock (Get-Command Test-IsPackageAvailable).ScriptBlock (Get-Command Install-Package).ScriptBlock
}

##############################################
# winget
##############################################

function Test-IsWingetPackageInstalled([string] $Package) {
  (winget list) -match 'winget$' | Select-String -Quiet $Package
}

function Test-IsWingetPackageAvailable([string] $Package) {
  winget search $Package | Out-Null
  $LASTEXITCODE -eq 0
}

function Install-WingetPackage([string[]] $Packages) {
  winget install $Packages
}

function Install-WingetPackageList([string] $PackageList) {
  Install-Packages $PackageList (Get-Command Test-IsWingetPackageInstalled).ScriptBlock (Get-Command Test-IsWingetPackageAvailable).ScriptBlock (Get-Command Install-WingetPackage).ScriptBlock
}

##############################################
# msys2
##############################################

function Test-IsMsys2PackageInstalled([string] $Package) {
  msys2 -lc "pacman -Qi $Package &>/dev/null"
  return $LASTEXITCODE -eq 0
}

function Test-IsMsys2PackageAvailable([string] $Package) {
  msys2 -lc "pacman -Si $Package &>/dev/null"
  return $LASTEXITCODE -eq 0
}

function Install-Msys2Package([string] $Package) {
  msys2 -lc "pacman -S --noconfirm $Package"
}

function Install-Msys2PackageList([string] $PackageList) {
  msys2 -lc "pacman -Sy" # Update package databases information
  Install-Packages $PackageList (Get-Command Test-IsMsys2PackageInstalled).ScriptBlock (Get-Command Test-IsMsys2PackageAvailable).ScriptBlock (Get-Command Install-Msys2Package).ScriptBlock
}

# Patch msys2_shell.cmd to inject env vars (symlink mode, POSIX-form XDG paths)
# before any shell starts inside msys2. The block is bracketed by markers so
# the rewrite is idempotent. scoop overwrites this file on msys2 update, so
# this must run before any msys2 invocation in the same session.
function Update-Msys2Shell {
  $Msys2Cmd = "$env:USERPROFILE\scoop\apps\msys2\current\msys2_shell.cmd"
  if (-not (Test-Path $Msys2Cmd)) {
    return
  }

  # C:\Users\foo -> /c/Users/foo
  $Drive     = $env:USERPROFILE.Substring(0, 1).ToLower()
  $Rest      = $env:USERPROFILE.Substring(2) -replace '\\', '/'
  $HomePosix = "/$Drive$Rest"

  $MarkerBegin = "rem >>> chezmoi-env-begin"
  $MarkerEnd   = "rem <<< chezmoi-env-end"
  $Banner      = "rem " + ("=" * 74)

  $Block = @"

$Banner
$MarkerBegin
$Banner

rem Native Windows symlinks (instead of msys2's copy fallback).
set MSYS=winsymlinks:nativestrict

rem XDG paths in POSIX form. Windows user env holds them as C:\... which
rem breaks fish's conf.d glob; override to POSIX form for msys2 only.
set XDG_CONFIG_HOME=$HomePosix/.config
set XDG_DATA_HOME=$HomePosix/.local/share
set XDG_CACHE_HOME=$HomePosix/.cache

$Banner
$MarkerEnd
$Banner

"@

  $Content = [System.IO.File]::ReadAllText($Msys2Cmd)

  # Strip any previous block, including the banner lines surrounding it.
  $Content = [regex]::Replace(
    $Content,
    "(?ms)\r?\n?rem ={3,}\r?\n$MarkerBegin\r?\n.*?$MarkerEnd\r?\nrem ={3,}\r?\n",
    ""
  )

  # Insert right after `setlocal EnableDelayedExpansion`.
  $Content = [regex]::Replace(
    $Content,
    "(?m)^(setlocal EnableDelayedExpansion\r?\n)",
    "`$1$Block",
    1
  )

  [System.IO.File]::WriteAllText($Msys2Cmd, $Content)
}
