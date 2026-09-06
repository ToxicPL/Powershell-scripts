Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Ping Checker"
$form.Size = New-Object System.Drawing.Size(700, 540)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

$label = New-Object System.Windows.Forms.Label
$label.Text = "Host list (one per line):"
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.Size = New-Object System.Drawing.Size(220, 20)
$form.Controls.Add($label)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Multiline = $true
$textBox.Location = New-Object System.Drawing.Point(20, 50)
$textBox.Size = New-Object System.Drawing.Size(560, 180)
$textBox.ScrollBars = "Vertical"
$textBox.Text = @"
"@
$form.Controls.Add($textBox)

$checkButton = New-Object System.Windows.Forms.Button
$checkButton.Text = "Check"
$checkButton.Location = New-Object System.Drawing.Point(20, 250)
$checkButton.Size = New-Object System.Drawing.Size(120, 30)
$form.Controls.Add($checkButton)

$loadButton = New-Object System.Windows.Forms.Button
$loadButton.Text = "Load from file"
$loadButton.Location = New-Object System.Drawing.Point(155, 250)
$loadButton.Size = New-Object System.Drawing.Size(140, 30)
$form.Controls.Add($loadButton)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(20, 300)
$listBox.Size = New-Object System.Drawing.Size(560, 160)
$listBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$listBox.DrawMode = [System.Windows.Forms.DrawMode]::OwnerDrawFixed
$listBox.ItemHeight = 22
$listBox.Add_DrawItem({
    param($listSender, $drawInfo)

    if ($drawInfo.Index -lt 0) { return }

    $itemText = $listSender.Items[$drawInfo.Index].ToString()
    $drawInfo.DrawBackground()

    if ($itemText -match '^\[OK\]') {
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Green)
    }
    elseif ($itemText -match '^\[FAIL\]|^\[ERROR\]') {
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Red)
    }
    else {
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
    }

    $drawInfo.Graphics.DrawString($itemText, $drawInfo.Font, $brush, $drawInfo.Bounds.X + 2, $drawInfo.Bounds.Y + 3)
    $drawInfo.DrawFocusRectangle()
})
$form.Controls.Add($listBox)

$loadButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $fileHosts = Get-Content -Path $dialog.FileName
        $filteredHosts = $fileHosts | Where-Object { $_.Trim() }

        if ($filteredHosts) {
            $textBox.Text = ($filteredHosts | ForEach-Object { $_.Trim() }) -join [Environment]::NewLine
            $listBox.Items.Add("[INFO] Loaded hosts from: $($dialog.FileName)")
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("No valid hosts found in the selected file.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        }
    }
})

$checkButton.Add_Click({
    $listBox.Items.Clear()
    $hosts = $textBox.Text -split "`r?`n" | Where-Object { $_.Trim() }

    foreach ($machine in $hosts) {
        $machine = $machine.Trim()
        if (-not $machine) { continue }

        try {
            $ping = Test-NetConnection -ComputerName $machine -InformationLevel Quiet -WarningAction SilentlyContinue
            if ($ping) {
                $listBox.Items.Add("[OK] $machine is reachable")
            } else {
                $listBox.Items.Add("[FAIL] $machine is not reachable")
            }
        }
        catch {
            $listBox.Items.Add("[ERROR] $machine - $($_.Exception.Message)")
        }
    }
})

$form.ShowDialog()