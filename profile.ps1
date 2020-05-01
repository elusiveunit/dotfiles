# PowerShell profile

function Prompt {
	Write-Host "" # Newline
	Write-Host -NoNewline ([char]::ConvertFromUtf32(9484)) # ┌
	Write-Host -NoNewline ([char]::ConvertFromUtf32(9472)) # ─
	Write-Host -NoNewline $env:UserName -ForegroundColor Magenta
	# Write-Host -NoNewline " at "
	# Write-Host -NoNewline $env:ComputerName -ForegroundColor Yellow
	Write-Host -NoNewline " in "
	Write-Host -NoNewline "$(Get-Location)" -ForegroundColor Green

	$gitStatus = Get-GitStatus
	if ($gitStatus) {
		Write-Host -NoNewline " on "
		Write-Host -NoNewline "$($gitStatus.Branch)" -ForegroundColor Cyan

		$statusFlags = ""
		if ($gitStatus.HasWorking) {
			$statusFlags += "+"
		}
		if ($gitStatus.HasIndex) {
			$statusFlags += "!"
		}
		if ($gitStatus.HasUntracked) {
			$statusFlags += "?"
		}
		if ($gitStatus.StashCount -gt 0) {
			$statusFlags += "$"
		}

		$branchFlags = ""
		if ($gitStatus.AheadBy -gt 0) {
			$branchFlags += [char]::ConvertFromUtf32(8593) # ↑
			$branchFlags += $gitStatus.AheadBy
		}
		if ($gitStatus.BehindBy -gt 0) {
			$branchFlags += [char]::ConvertFromUtf32(8595) # ↓
			$branchFlags += $gitStatus.BehindBy
		}

		if ($branchFlags.Length -gt 0) {
			if ($statusFlags.Length -gt 0) {
				$statusFlags += " "
			}
			$statusFlags += $branchFlags
		}
		if ($statusFlags.Length -gt 0) {
			Write-Host " [$statusFlags]" -NoNewline -ForegroundColor Red
		}
	}

	Write-Host "" # Newline
	Write-Host -NoNewline ([char]::ConvertFromUtf32(9492)) # └
	Write-Host -NoNewline ([char]::ConvertFromUtf32(9472)) # ─
	$dateTime = Get-Date -Format 'HH:mm'
	Write-Host -NoNewline "[$dateTime]" # time in [HH:MM]
	Write-Host -NoNewline ([char]::ConvertFromUtf32(8594)) # →

	return " "
}

# Navigation shortcuts
function upOneDir { Set-Location .. }
function upTwoDir { Set-Location ../.. }
function upThreeDir { Set-Location ../../.. }
function upFourDir { Set-Location ../../../.. }
Set-Alias -Name '..' upOneDir
Set-Alias -Name '...' upTwoDir
Set-Alias -Name '....' upThreeDir
Set-Alias -Name '.....' upFourDir
function dev { Set-Location 'C:\_\dev' }

Set-Alias -Name 'c' cls
Set-Alias -Name 'g' git
Set-Alias -Name 'lsa' dir
Set-Alias -Name 'cd..' upOneDir

# Up and Down arrows go back through history
Set-PSReadlineKeyHandler -Key UpArrow -ScriptBlock {
	[Microsoft.PowerShell.PSConsoleReadLine]::HistorySearchBackward()
	[Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
}
Set-PSReadlineKeyHandler -Key DownArrow -ScriptBlock {
	[Microsoft.PowerShell.PSConsoleReadLine]::HistorySearchForward()
	[Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
}
