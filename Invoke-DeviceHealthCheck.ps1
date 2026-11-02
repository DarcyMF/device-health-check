# quick health check for a windows pc
# checks the stuff i end up looking at on most "my laptop is slow" tickets
# run it with: .\Invoke-DeviceHealthCheck.ps1

# get the OS info once at the start - it has the boot time and memory numbers we need later
$os = Get-CimInstance Win32_OperatingSystem

# prints one line of the report, coloured by status
# e.g. Show WARN 'Disk C:' '12 GB free'  ->  [WARN] Disk C:   12 GB free  (in yellow)
function Show($status, $check, $detail) {
    # pick a colour for the status
    $colour = @{ OK = 'Green'; WARN = 'Yellow'; FAIL = 'Red' }[$status]

    # {0,-4} and {1,-15} pad the text so everything lines up in columns
    Write-Host ("[{0,-4}] {1,-15} {2}" -f $status, $check, $detail) -ForegroundColor $colour
}

# heading with the computer name and windows version
Write-Host "`n$env:COMPUTERNAME - $($os.Caption)`n"


# --- uptime ---
# how long since the pc was last restarted
# a lot of slowness and stuck updates go away after a restart, so flag anything over 2 weeks
$days = ((Get-Date) - $os.LastBootUpTime).Days
if ($days -ge 14) { Show WARN 'Uptime' "$days days since last restart" }
else { Show OK 'Uptime' "$days days" }


# --- disk space ---
# DriveType 3 means local hard drives only (skips USBs, DVD drives and network drives)
foreach ($d in Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3') {
    # work out free space as a percentage and in GB
    $pct = [math]::Round($d.FreeSpace / $d.Size * 100)
    $gb = [math]::Round($d.FreeSpace / 1GB, 1)

    # under 10% free is bad (updates can fail), under 20% is worth a warning
    if ($pct -lt 10) { Show FAIL "Disk $($d.DeviceID)" "$gb GB free ($pct%)" }
    elseif ($pct -lt 20) { Show WARN "Disk $($d.DeviceID)" "$gb GB free ($pct%)" }
    else { Show OK "Disk $($d.DeviceID)" "$gb GB free ($pct%)" }
}


# --- memory ---
# windows gives free and total memory in KB, so work out the % used from those
$used = [math]::Round((1 - $os.FreePhysicalMemory / $os.TotalVisibleMemorySize) * 100)

# over 90% used usually means something is hogging RAM and the pc will feel slow
if ($used -ge 90) { Show WARN 'Memory' "$used% used" }
else { Show OK 'Memory' "$used% used" }


# --- pending reboot ---
# windows update creates this registry key when it has installed something and needs a restart
# if it's there, the updates won't finish until the pc is restarted
if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') {
    Show WARN 'Reboot' 'restart needed to finish updates'
} else { Show OK 'Reboot' 'none pending' }


# --- network ---
# ping google's public DNS server to see access to internet is working.
# -Quiet makes it return just true/false instead of the full ping output
if (Test-Connection 8.8.8.8 -Count 1 -Quiet) { Show OK 'Internet' 'can reach 8.8.8.8' }
else { Show FAIL 'Internet' 'no response from 8.8.8.8' }

# check DNS separately - if ping works but this fails, the internet is fine but DNS is broken
try {
    [System.Net.Dns]::GetHostAddresses('google.com') | Out-Null
    Show OK 'DNS' 'google.com resolves'
} catch { Show FAIL 'DNS' "can't resolve google.com" }

# blank line at the end so the output doesn't run into the prompt
Write-Host ''
