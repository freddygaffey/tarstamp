# tarstamp - timestamped tar snapshots (PowerShell)
# https://github.com/freddygaffey/tarstamp

function tarstamp {
    [CmdletBinding()]
    param(
        [Alias('n')]
        [string]$Name,
        [Alias('h','?')]
        [switch]$Help,
        [Parameter(Position=0, ValueFromRemainingArguments=$true)]
        [string[]]$Path
    )
    $usage = @"
usage: tarstamp [-Name NAME] <path> [<path> ...]
       tarstamp -Help

  -n, -Name NAME   archive name (required when passing multiple paths or a glob)
  -h, -Help        show this help

examples:
  tarstamp src\                          # -> src_<timestamp>.tar
  tarstamp -n pyfiles *.py               # -> pyfiles_<timestamp>.tar
  tarstamp -Name configs `$HOME\.gitconfig `$HOME\.vimrc
"@
    if ($Help) { Write-Host $usage; return }
    if (-not $Path -or $Path.Count -eq 0) { Write-Host $usage; return }
    # Expand wildcards (PowerShell does not auto-glob like POSIX shells).
    $resolved = @()
    foreach ($p in $Path) {
        $items = Get-Item -Path $p -ErrorAction SilentlyContinue
        if (-not $items) { Write-Error "tarstamp: '$p' does not exist"; return }
        foreach ($i in $items) { $resolved += $i.FullName }
    }
    if ($resolved.Count -gt 1 -and -not $Name) {
        Write-Error "tarstamp: multiple paths require -Name (or -n) NAME"
        return
    }
    if (-not $Name) {
        $Name = (Get-Item -LiteralPath $resolved[0]).Name
    }
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $archive = "${Name}_${stamp}.tar"
    $elapsed = Measure-Command { tar cf $archive @resolved }
    if ($LASTEXITCODE -ne 0) { Write-Error "tarstamp: tar failed"; return }
    $bytes = (Get-Item -LiteralPath $archive).Length
    $size = switch ($bytes) {
        { $_ -ge 1GB } { "{0:N1}G" -f ($bytes / 1GB); break }
        { $_ -ge 1MB } { "{0:N1}M" -f ($bytes / 1MB); break }
        { $_ -ge 1KB } { "{0:N1}K" -f ($bytes / 1KB); break }
        default        { "${bytes}B" }
    }
    $secs = "{0:N1}" -f $elapsed.TotalSeconds
    Write-Host "-> $archive | ${secs}s | $size"
}

function untarstamp {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Archive
    )
    if (-not (Test-Path -LiteralPath $Archive)) {
        Write-Error "untarstamp: '$Archive' not found"
        return
    }
    $base = [System.IO.Path]::GetFileNameWithoutExtension($Archive)
    $dest = Join-Path (Split-Path -Parent (Resolve-Path $Archive)) "$base.extracted"
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    tar xf $Archive -C $dest
    if ($LASTEXITCODE -eq 0) { Write-Host "-> $dest" }
}
