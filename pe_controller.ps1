param(
    [string]$o,
    [switch]$h
)

# PID della PowerShell che esegue lo script (auto-esclusione)
$SelfPid = $PID

function Show-Help {
    Write-Host @"
Usage:
  .\netstat-ipinfo.ps1 [-o output.txt] [-h]

Description:
  Analyzes active network connections (netstat -ano),
  extracts only PUBLIC remote IP addresses,
  maps each connection to its PID and Process Name,
  and queries ipinfo.io to retrieve:
    - org
    - hostname
    - country

Options:
  -o <file>   Save the output to a file
  -h          Show this help message

Note:
  Private IP addresses (10.x.x.x, 172.16–31.x.x, 192.168.x.x),
  loopback addresses, and 0.0.0.0 are ignored.
  If suspicious activity is suspected, these connections must be reviewed manually.
"@
    exit
}

if ($h) { Show-Help }

function Is-PublicIP($ip) {
    if ($ip -match '^10\.') { return $false }
    if ($ip -match '^192\.168\.') { return $false }
    if ($ip -match '^172\.(1[6-9]|2[0-9]|3[0-1])\.') { return $false }
    if ($ip -match '^127\.') { return $false }
    if ($ip -eq '0.0.0.0') { return $false }
    return $true
}

$results = @()

netstat -ano | Select-String '^ *TCP' | ForEach-Object {

    $parts = ($_ -replace '\s+', ' ').Trim().Split(' ')

    if ($parts.Count -lt 5) { return }

    $remote  = $parts[2]
    $connPid = $parts[4]

    # Esclude la PowerShell che esegue lo script
    if ($connPid -eq $SelfPid) { return }

    if ($remote -notmatch ':') { return }

    $ip = $remote.Split(':')[0]

    if (-not (Is-PublicIP $ip)) { return }

    try {
        $proc = Get-Process -Id $connPid -ErrorAction Stop
        $procName = $proc.ProcessName
    } catch {
        $procName = 'N/A'
    }

    try {
        $ipinfo = Invoke-RestMethod -Uri "https://ipinfo.io/$ip/json" -Method Get -TimeoutSec 5
        $org = $ipinfo.org
        $hostname_ipinfo = $ipinfo.hostname
        $country = $ipinfo.country
    } catch {
        $org = $hostname_ipinfo = $country = 'N/A'
    }

    $results += [PSCustomObject]@{
        PID      = $connPid
        Process  = $procName
        RemoteIP = $ip
        Country  = $country
        Org      = $org
        Hostname = $hostname_ipinfo
    }
}

# Pulizia finale dell'output
$results = $results | Where-Object {
    $_.PID -ne 0 -and
    $_.RemoteIP -match '^\d{1,3}(\.\d{1,3}){3}$' -and
    $_.Process -ne 'Idle' -and
    $_.Org -ne 'N/A'
}

$results = $results | Sort-Object PID, RemoteIP -Unique

if ($o) {
    $results | Format-Table -AutoSize | Out-String | Set-Content $o
    Write-Host "Output saved in $o"
} else {
    $results | Format-Table -AutoSize
}
