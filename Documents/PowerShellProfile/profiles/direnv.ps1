# direnv requires PowerShell 7.2+. Skip on Windows PowerShell 5.1.
if ($PSVersionTable.PSVersion.Major -lt 7) {
  return
}

Invoke-Expression "$(direnv hook pwsh)"
