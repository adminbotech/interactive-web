# Converts amazon.csv into a compact data.js used by dashboard.html
# Usage:  powershell -ExecutionPolicy Bypass -File build_data.ps1
$ErrorActionPreference = 'Stop'
$src = Join-Path $PSScriptRoot 'amazon.csv'
$out = Join-Path $PSScriptRoot 'data.js'

function Num($s) {
    if ($null -eq $s) { return $null }
    $c = ($s -replace '[^0-9.]', '')
    if ($c -eq '' -or $c -eq '.') { return $null }
    return [double]$c
}

$rows = Import-Csv -Path $src -Encoding UTF8
$seen = @{}
$list = New-Object System.Collections.Generic.List[object]
foreach ($r in $rows) {
    if ($seen.ContainsKey($r.product_id)) { continue }
    $seen[$r.product_id] = $true
    $cats = $r.category -split '\|'
    $list.Add([ordered]@{
        id    = $r.product_id
        name  = $r.product_name
        cat   = $cats[0]
        sub   = $(if ($cats.Count -gt 1) { $cats[1] } else { $cats[0] })
        leaf  = $cats[-1]
        price = Num $r.discounted_price
        mrp   = Num $r.actual_price
        disc  = Num $r.discount_percentage
        rating = Num $r.rating
        rcount = $(if ((Num $r.rating_count) -ne $null) { Num $r.rating_count } else { 0 })
        img   = $r.img_link
        link  = $r.product_link
    })
}
$json = $list | ConvertTo-Json -Compress -Depth 3
[System.IO.File]::WriteAllText($out, "window.PRODUCTS = $json;", (New-Object System.Text.UTF8Encoding $false))
Write-Host "Wrote $($list.Count) unique products (from $($rows.Count) rows) to $out"
