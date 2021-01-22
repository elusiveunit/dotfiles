# Init script for PowerShell
#Requires -RunAsAdministrator

$confirmation = Read-Host "Install PowerShell packages? [y/N] "
if ($confirmation -eq 'y') {
	Install-PackageProvider -Name NuGet -Force
	Install-Module -Name PowerShellGet -Force
	Install-Module PSReadLine
	Install-Module PSFzf
	Install-Module posh-git
}
else {
	Write-Host "Skipped packages" -ForegroundColor Yellow
}

$symlinks = @{
	"$PSScriptRoot\.bashrc"                         = "$HOME\.bashrc"
	"$PSScriptRoot\.bash_profile"                   = "$HOME\.bash_profile"
	"$PSScriptRoot\.inputrc"                        = "$HOME\.inputrc"
	"$PSScriptRoot\.ackrc"                          = "$HOME\.ackrc"
	"$PSScriptRoot\.npmrc"                          = "$HOME\.npmrc"
	"$PSScriptRoot\profile.ps1"                     = "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
	"$PSScriptRoot\windows-terminal-settings.jsonc" = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
}

$targets = @()
foreach ($src in $symlinks.keys) {
	$targets += $symlinks[$src]
}
$targets = $targets -join ', '
$confirmation = Read-Host "Symlink files? This will remove any existing ones (affects $targets). [y/N] "
if ($confirmation -eq 'y') {
	foreach ($src in $symlinks.keys) {
		$dest = $symlinks[$src]
		if (Test-Path $dest) {
			Remove-Item $dest
		}
		[void](New-Item -ItemType SymbolicLink -Path "$dest" -Target "$src" -ErrorAction SilentlyContinue -ErrorVariable linkErrors)
		if ($linkErrors) {
			Write-Host "Linking $src failed" -ForegroundColor Red
			Write-Output $linkErrors
		}
		else {
			Write-Host "Linked $src -> $dest" -ForegroundColor Green
		}
	}
}
else {
	Write-Host "Skipped symlinks" -ForegroundColor Yellow
}

$confirmation = Read-Host "Add include to global .gitconfig? [y/N] "
if ($confirmation -eq 'y') {
	git config --global include.path "$PSScriptRoot\.gitconfig"
	Write-Host "Added git config include" -ForegroundColor Green
}
else {
	Write-Host "Skipped git config include" -ForegroundColor Yellow
}
