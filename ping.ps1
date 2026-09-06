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
    param($sender, $e)

    if ($e.Index -lt 0) { return }

    $itemText = $sender.Items[$e.Index].ToString()
    $e.DrawBackground()

    if ($itemText -match '^\[OK\]') {
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Green)
    }
    elseif ($itemText -match '^\[FAIL\]|^\[ERROR\]') {
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Red)
    }
    else {
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
    }

    $e.Graphics.DrawString($itemText, $e.Font, $brush, $e.Bounds.X + 2, $e.Bounds.Y + 3)
    $e.DrawFocusRectangle()
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

    foreach ($host in $hosts) {
        $host = $host.Trim()
        if (-not $host) { continue }

        try {
            $ping = Test-NetConnection -ComputerName $host -InformationLevel Quiet -WarningAction SilentlyContinue
            if ($ping) {
                $listBox.Items.Add("[OK] $host is reachable")
            } else {
                $listBox.Items.Add("[FAIL] $host is not reachable")
            }
        }
        catch {
            $listBox.Items.Add("[ERROR] $host - $($_.Exception.Message)")
        }
    }
})

$form.ShowDialog()