<#
    Script Name: cleanup.ps1
    Author: Anthony Cotales
    Email: ton.cotales@gmail.com
    Date: 2025-10-04
    Description: This script cleans temp files, clears recycle bin, DNS cache, and improves basic system performance.
#>

# Restart the windows explorer (fix UI lag)
#Stop-Process -Name explorer -Force; Start-Process explorer.exe

# Clear DNS Cache (if network is slow)
#Clear-DnsClientCache -ErrorAction SilentlyContinue;

# Clear the system clipboard history
Restart-Service cbdhsvc_* -Force -ErrorAction SilentlyContinue;

# Clear the file explorer address bar history
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths" -Name "*" -ErrorAction SilentlyContinue;

# Clear the recent files
Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations\*" -Recurse -Force -ErrorAction SilentlyContinue;
Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations\*" -Recurse -Force -ErrorAction SilentlyContinue;
Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Recent\*" -Recurse -Force -ErrorAction SilentlyContinue;

# Empty the recycle bin
Clear-RecycleBin -Force -ErrorAction SilentlyContinue;

# Delete user's temporary files
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue;

# Delete system's temporary files
Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue;


# Showing messagebox of the complete procedure
[System.Windows.Forms.MessageBox]::Show(
    "System Cleanup COMPLETE!",
    "cleanup.exe",
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information)

