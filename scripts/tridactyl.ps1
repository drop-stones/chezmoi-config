. "$PSScriptRoot/utils.ps1"

##############################################
# tridactyl-native
##############################################

function Install-TridactylNative() {
  $tempFile = Join-Path $env:TEMP "tridactyl_installnative.ps1"

  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
  (New-Object System.Net.WebClient).DownloadFile('https://raw.githubusercontent.com/tridactyl/native_messenger/master/installers/windows.ps1', $tempFile)

  & $tempFile -Tag 1.24.4

  if (Test-Path $tempFile) {
    Remove-Item $tempFile
  }
 
  Write-LogMessage -b "Tridactyl Native Messenger has been installed/updated."
}
