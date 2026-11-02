# device-health-check

Small PowerShell script that checks a few basic things on a Windows PC:

- uptime
- free disk space
- memory usage
- if a restart is pending for updates
- internet + DNS

I made it because I check these on most "my laptop is slow" tickets at work.

## Run

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\Invoke-DeviceHealthCheck.ps1
```

## Todo

- save results to a file
- check if Defender is on
- run it on more than one computer
