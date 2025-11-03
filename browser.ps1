<#
    PowerShell Script: Chromium Browser Cleanup Tool (Compact GUI Version)
    Supports: Google Chrome, Microsoft Edge, Brave, Opera, Opera GX

    Features:
    - Compact, clean, centered GUI layout
    - Select specific browsers or apply to all
    - Choose between Standard Cleanup or Complete Reset
    - Automatically closes browsers before cleaning
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to close running browser processes
function Close-BrowserProcesses {
    param([string[]]$processNames)
    foreach ($procName in $processNames) {
        $processes = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $procName }
        if ($processes) {
            Write-Host "Closing all $procName processes..."
            $processes | ForEach-Object { Stop-Process -Id $_.Id -Force }
        }
    }
}

# Function to perform cleanup
function Cleanup-Browser {
    param (
        [string]$BrowserName,
        [string]$DataPath,
        [string]$Mode
    )

    if (-not (Test-Path $DataPath)) {
        Write-Host "[$BrowserName] User data not found: $DataPath"
        return
    }

    if ($Mode -eq 'Aggressive') {
        Write-Host "[$BrowserName] Performing COMPLETE RESET..."
        Remove-Item $DataPath -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "[$BrowserName] Complete reset finished!"
    }
    elseif ($Mode -eq 'Standard') {
        Write-Host "[$BrowserName] Performing STANDARD CLEANUP..."
        $cleanupPaths = @(
            "History",
            "History Provider Cache",
            "Top Sites",
            "Visited Links",
            "Favicons",
            "Cookies",
            "Sessions",
            "Current Tabs",
            "Last Session",
            "Last Tabs",
            "Cache",
            "GPUCache",
            "Code Cache",
            "Service Worker\CacheStorage",
            "Media Cache",
            "Storage\ext"
        )

        $profileDirs = Get-ChildItem -Path $DataPath -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^Default|^Profile' }
        if (-not $profileDirs) {
            $profileDirs = @((Get-Item $DataPath))
        }

        foreach ($profileDir in $profileDirs) {
            foreach ($relPath in $cleanupPaths) {
                $target = Join-Path $profileDir.FullName $relPath
                if (Test-Path $target) {
                    Write-Host "[$BrowserName] Deleting: $target"
                    Remove-Item $target -Force -Recurse -ErrorAction SilentlyContinue
                }
            }
        }
        Write-Host "[$BrowserName] Standard cleanup completed!"
    }
}

# Define browser data locations
$browsers = @{
    'Google Chrome' = "$env:LOCALAPPDATA\Google\Chrome\User Data"
    'Microsoft Edge' = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
    'Brave'          = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
    'Opera'          = "$env:APPDATA\Opera Software\Opera Stable"
    'Opera GX'       = "$env:APPDATA\Opera Software\Opera GX Stable"
}

# Define process names
$processMap = @{
    'Google Chrome' = 'chrome'
    'Microsoft Edge' = 'msedge'
    'Brave'          = 'brave'
    'Opera'          = 'opera'
    'Opera GX'       = 'opera'
}

# --- GUI SETUP ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Browser Cleanup Utility"
$form.Size = New-Object System.Drawing.Size(370, 360)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

# Title label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "🧹 Select browsers and cleanup mode:"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$titleLabel.Location = New-Object System.Drawing.Point(20, 15)
$titleLabel.Size = New-Object System.Drawing.Size(320, 25)
$form.Controls.Add($titleLabel)

# Group box for browser checkboxes
$groupBrowsers = New-Object System.Windows.Forms.GroupBox
$groupBrowsers.Text = "Browsers"
$groupBrowsers.Location = New-Object System.Drawing.Point(20, 45)
$groupBrowsers.Size = New-Object System.Drawing.Size(320, 130)
$form.Controls.Add($groupBrowsers)

# Add browser checkboxes in two columns
$checkBoxes = @{}
$col1 = 20; $col2 = 160; $y = 25; $count = 0
foreach ($browser in $browsers.Keys) {
    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text = $browser
    $chk.Size = New-Object System.Drawing.Size(140, 25)
    if ($count -lt 3) {
        $chk.Location = New-Object System.Drawing.Point($col1, $y)
    } else {
        $chk.Location = New-Object System.Drawing.Point($col2, ($y - (3 * 30)))
    }
    $groupBrowsers.Controls.Add($chk)
    $checkBoxes[$browser] = $chk
    $y += 30
    $count++
}

# Apply to all checkbox
$chkAll = New-Object System.Windows.Forms.CheckBox
$chkAll.Text = "Apply to ALL browsers"
$chkAll.Location = New-Object System.Drawing.Point(30, 185)
$chkAll.Size = New-Object System.Drawing.Size(200, 25)
$chkAll.Add_CheckedChanged({
    $allChecked = $chkAll.Checked
    foreach ($chk in $checkBoxes.Values) {
        $chk.Checked = $allChecked
        $chk.Enabled = -not $allChecked
    }
})
$form.Controls.Add($chkAll)

# Mode selection
$lblMode = New-Object System.Windows.Forms.Label
$lblMode.Text = "Cleanup mode:"
$lblMode.Location = New-Object System.Drawing.Point(30, 215)
$form.Controls.Add($lblMode)

$radioStandard = New-Object System.Windows.Forms.RadioButton
$radioStandard.Text = "Standard Cleanup"
$radioStandard.Location = New-Object System.Drawing.Point(50, 240)
$radioStandard.Checked = $true
$form.Controls.Add($radioStandard)

$radioAggressive = New-Object System.Windows.Forms.RadioButton
$radioAggressive.Text = "Complete Reset"
$radioAggressive.Location = New-Object System.Drawing.Point(180, 240)
$form.Controls.Add($radioAggressive)

# Run button
$buttonRun = New-Object System.Windows.Forms.Button
$buttonRun.Text = "Run Cleanup"
$buttonRun.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$buttonRun.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$buttonRun.ForeColor = "White"
$buttonRun.FlatStyle = 'Flat'
$buttonRun.Size = New-Object System.Drawing.Size(120, 35)
$buttonRun.Location = New-Object System.Drawing.Point(120, 280)
$buttonRun.Add_Click({
    $selectedBrowsers = @()
    foreach ($browser in $browsers.Keys) {
        if ($checkBoxes[$browser].Checked) {
            $selectedBrowsers += $browser
        }
    }

    if ($selectedBrowsers.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please select at least one browser or 'Apply to All'.", "No Browser Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    $mode = if ($radioAggressive.Checked) { 'Aggressive' } else { 'Standard' }

    # Close processes
    $processesToClose = $selectedBrowsers | ForEach-Object { $processMap[$_] }
    Close-BrowserProcesses -processNames ($processesToClose | Select-Object -Unique)

    # Run cleanup
    foreach ($browser in $selectedBrowsers) {
        $path = $browsers[$browser]
        Cleanup-Browser -BrowserName $browser -DataPath $path -Mode $mode
    }

    [System.Windows.Forms.MessageBox]::Show("Cleanup completed successfully!", "Done", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    $form.Close()
})
$form.Controls.Add($buttonRun)

# Show form
$form.Topmost = $true
$form.ShowDialog()
