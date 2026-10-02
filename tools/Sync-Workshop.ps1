# Local staging only. This script never uploads/publishes to Steam.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$baoSource = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$baoConfig = Get-Content -LiteralPath (Join-Path $baoSource 'settings2.json') -Raw | ConvertFrom-Json
$baoRoot = [IO.Path]::GetFullPath($baoConfig.workshopRoot).TrimEnd('\')
$baoAllowed = [IO.Path]::GetFullPath((Join-Path $env:USERPROFILE 'Zomboid\Workshop\BanditsAIOverhaul')).TrimEnd('\')
if ($baoRoot -ne $baoAllowed -or $baoConfig.modFolder -ne 'BanditsAIOverhaul') {
    throw 'Unexpected Workshop destination. Refusing to copy.'
}
function Assert-NoLink([string]$Path) {
    $baoCursor = $Path
    while ($baoCursor) {
        if (Test-Path -LiteralPath $baoCursor) {
            $baoItem = Get-Item -LiteralPath $baoCursor -Force
            if ($baoItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Reparse point is not allowed in deployment path: $baoCursor"
            }
        }
        $baoCursor = [IO.Path]::GetDirectoryName($baoCursor)
    }
}
Assert-NoLink $baoRoot
$baoTarget = Join-Path $baoRoot 'Contents\mods\BanditsAIOverhaul'
Assert-NoLink $baoTarget
[IO.Directory]::CreateDirectory($baoRoot) | Out-Null
$baoLock = $null
$baoDeadline = [DateTime]::UtcNow.AddSeconds(20)
while (-not $baoLock) {
    try { $baoLock = [IO.File]::Open((Join-Path $baoRoot '.bao-sync.lock'), 'OpenOrCreate', 'ReadWrite', 'None') }
    catch [IO.IOException] {
        if ([DateTime]::UtcNow -gt $baoDeadline) { throw 'Another Workshop copy is still running. Save again.' }
        Start-Sleep -Milliseconds 100
    }
}
try {
    [IO.Directory]::CreateDirectory($baoTarget) | Out-Null
    $baoManifestPath = Join-Path $baoRoot '.bao-sync-files.json'
    $baoPrevious = @()
    if (Test-Path -LiteralPath $baoManifestPath) {
        $baoPrevious = Get-Content -LiteralPath $baoManifestPath -Raw | ConvertFrom-Json
    }
    $baoFiles = @()
    foreach ($baoPart in $baoConfig.include) {
        if ($baoPart -notin @('42', 'common')) { throw "Unsupported mod directory: $baoPart" }
        $baoFrom = Join-Path $baoSource $baoPart
        if (-not (Test-Path -LiteralPath $baoFrom)) { continue }
        Assert-NoLink $baoFrom
        foreach ($baoEntry in Get-ChildItem -LiteralPath $baoFrom -Recurse -Force) {
            if ($baoEntry.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Source mod contains a reparse point.' }
            if (-not $baoEntry.PSIsContainer) { $baoFiles += $baoEntry }
        }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $baoSource '42\mod.info'))) { throw '42/mod.info is missing.' }
    $baoCurrent = @()
    foreach ($baoFile in $baoFiles) {
        $baoRelative = $baoFile.FullName.Substring($baoSource.Length + 1)
        $baoDestination = [IO.Path]::GetFullPath((Join-Path $baoTarget $baoRelative))
        if (-not $baoDestination.StartsWith($baoTarget + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid destination.' }
        Assert-NoLink $baoDestination
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($baoDestination)) | Out-Null
        Copy-Item -LiteralPath $baoFile.FullName -Destination $baoDestination -Force
        $baoCurrent += $baoRelative
    }
    # Remove only files deployed by an earlier successful run, never metadata or unrelated files.
    foreach ($baoRelative in $baoPrevious) {
        if ($baoRelative -in $baoCurrent) { continue }
        if ($baoRelative -notmatch '^(42|common)[\\/]') { throw 'Invalid manifest entry.' }
        $baoStale = [IO.Path]::GetFullPath((Join-Path $baoTarget $baoRelative))
        if (-not $baoStale.StartsWith($baoTarget + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid stale path.' }
        Assert-NoLink $baoStale
        if (Test-Path -LiteralPath $baoStale -PathType Leaf) { Remove-Item -LiteralPath $baoStale -Force }
    }
    $baoCurrent | ConvertTo-Json | Set-Content -LiteralPath $baoManifestPath -Encoding UTF8
    $baoWorkshopInfo = Join-Path $baoRoot 'workshop.txt'
    if (-not (Test-Path -LiteralPath $baoWorkshopInfo)) {
        @('version=1', 'title=Bandits AI Overhaul', 'description=Independent NPC AI mod. Development build.',
            'tags=', 'visibility=private') | Set-Content -LiteralPath $baoWorkshopInfo -Encoding UTF8
    }
    $baoPreview = Join-Path $baoRoot 'preview.png'
    $baoSourcePreview = Join-Path $baoSource 'preview.png'
    Assert-NoLink $baoSourcePreview
    Assert-NoLink $baoPreview
    Copy-Item -LiteralPath $baoSourcePreview -Destination $baoPreview -Force
    Write-Output "BAO Workshop copy OK: $($baoCurrent.Count) files -> $baoTarget"
    Write-Output 'Project preview copied; existing workshop.txt / Steam item ID preserved. No upload performed.'
}
finally { if ($baoLock) { $baoLock.Dispose() } }
