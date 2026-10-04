Add-Type -AssemblyName System.Drawing
Get-ChildItem -File | Where-Object { $_.Extension -match "png|jpeg|jpg" } | ForEach-Object {
    $img = [System.Drawing.Image]::FromFile($_.FullName)
    Write-Host "$($_.Name): $($img.Width) x $($img.Height)"
    $img.Dispose()
}
