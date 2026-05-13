$source    = $PSScriptRoot
$addonName = "ProjEP_RUF_Farmer"
$target    = "C:\Ascension\Launcher\resources\epoch-live\Interface\AddOns\$addonName"

$extensions = @("*.lua", "*.toc", "*.xml")

New-Item -ItemType Directory -Path $target -Force | Out-Null

$files = $extensions | ForEach-Object { Get-ChildItem -Path $source -Filter $_ }

foreach ($file in $files) {
    Copy-Item -Path $file.FullName -Destination $target -Force
}

$count = ($files | Measure-Object).Count
Write-Host "[$addonName] $count Dateien nach '$target' deployt." -ForegroundColor Green
