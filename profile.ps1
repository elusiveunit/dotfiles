# PowerShell profile

function Prompt {
	# ---------- Line 1 ----------
	Write-Host "" # Newline
	Write-Host -NoNewline ([char]::ConvertFromUtf32(9484)) # ┌
	Write-Host -NoNewline ([char]::ConvertFromUtf32(9472)) # ─
	Write-Host -NoNewline $env:UserName -ForegroundColor Magenta
	# Write-Host -NoNewline " at "
	# Write-Host -NoNewline $env:ComputerName -ForegroundColor Yellow
	Write-Host -NoNewline " in "
	Write-Host -NoNewline "$(Get-Location)" -ForegroundColor Green

	# Git info
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

	# Execution time
	if ($hist = Get-History) {
		$time = ($hist[-1].EndExecutionTime - $hist[-1].StartExecutionTime).Totalmilliseconds
		$ms = [math]::Round($time % 1000)
		$s = [math]::Round(($time / 1000) % 60)
		$m = [math]::Round(($time / 60000) % 60)
		$h = [math]::Round($time / 3600000)

		$executionTime = ''
		if ($h -gt 0) {
			$executionTime = "${h}h${m}m"
		}
		elseif ($m -gt 0) {
			$executionTime = "${m}m${s}s"
		}
		elseif ($s -gt 0) {
			if ($ms -ge 100) {
				$executionTime = "${s}.${ms}s"
			}
			else {
				$executionTime = "${s}s"
			}
		}
		# elseif ($ms -gt 0) {
		# 	$executionTime = "${ms}ms"
		# }

		if ($executionTime) {
			Write-Host " $executionTime" -NoNewline -ForegroundColor DarkGray
		}
	}

	# ---------- Line 2 ----------
	Write-Host "" # Newline
	Write-Host -NoNewline ([char]::ConvertFromUtf32(9492)) # └
	Write-Host -NoNewline ([char]::ConvertFromUtf32(9472)) # ─
	$dateTime = Get-Date -Format 'HH:mm'
	Write-Host -NoNewline "[$dateTime]" # time in [HH:MM]
	Write-Host -NoNewline ([char]::ConvertFromUtf32(8594)) # →

	return " "
}

# Navigation shortcuts
function _upOne { Set-Location .. }
function _upTwo { Set-Location ../.. }
function _upThree { Set-Location ../../.. }
function _upFour { Set-Location ../../../.. }
Set-Alias -Name '..' _upOne
Set-Alias -Name '...' _upTwo
Set-Alias -Name '....' _upThree
Set-Alias -Name '.....' _upFour

Set-Alias -Name 'c' cls
Set-Alias -Name 'g' git
Set-Alias -Name 'lsa' dir
Set-Alias -Name 'cd..' _upOne

function dev { Set-Location 'C:\_\dev' }

function color_list() {
	foreach ($color in [Enum]::GetValues([ConsoleColor])) {
		Write-Host "$color" -Foreground $color
	}
}

# Up and Down arrows go back through history
Set-PSReadlineKeyHandler -Key UpArrow -ScriptBlock {
	[Microsoft.PowerShell.PSConsoleReadLine]::HistorySearchBackward()
	[Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
}
Set-PSReadlineKeyHandler -Key DownArrow -ScriptBlock {
	[Microsoft.PowerShell.PSConsoleReadLine]::HistorySearchForward()
	[Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
}

# Bind keys to fzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
