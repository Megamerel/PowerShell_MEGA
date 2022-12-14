#!/bin/env powershell

# PowerShell -- Start OIS Proxies

function Proxy-Start {
    param (
        [int]$Port,
        [int]$RemotePort = 443,
        [int]$Timeout = 180,
        [string]$HostName,
        [string]$Name,
        [string]$Headers
    )

    # exit running instance 
    Try {
      curl -TimeoutSec 1 http://localhost:$Port/exit | Out-Null
      Write-Host $("killed $Port")
    }
    Catch {
      Write-Host "not killed $Port"
    }
    
    # create a log dir
    $Env:LOGTREE = $("$Env:LOCALAPPDATA/proxy")
    if (-not(Test-Path -Path $Env:LOGTREE)) { 
      md $Env:LOGTREE | Out-Null
    }
    $Env:LOGDIR = $("$Env:LOGTREE/$Port")
    if (-not(Test-Path -Path $Env:LOGDIR)) { 
      md $Env:LOGDIR | Out-Null
    }

    $Env:WRITE_BODIES="20M"
    $Env:HEADERS="$Headers"
    
    Start-Process                   "http2https-logging-proxy.exe" `
      -ArgumentList                 $Port, $HostName, $Timeout, $RemotePort `
      -WorkingDirectory             $Env:LOGDIR `
      -RedirectStandardOutput       "$Env:LOGDIR/stdout.log" `
      -RedirectStandardError        "$Env:LOGDIR/stderr.log" `
      -NoNewWindow

    return "Started $Name listener on port $Port"
}

# SLCM for basic authentication
Proxy-Start `
  -Name 'SLCM' `
  -Port 8004 `
  -HostName frontend.erp.accept.vu.nl `
  -Headers "Authorization:Basic T01BREFVU0VSOj5sUWZLbXlycVRoYUN5c1hFeHJ1NkxuTFd0QVVkTVp5amZ4cE1qc0Q='
  
# SAP SAC -- adding the x-sap-sac-custom-auth header
Proxy-Start `
  -Name 'SAP SAC' `
  -Port 8006 `
  -HostName stichting-vu-q.eu10.hcs.cloud.sap `
  -Headers "x-sap-sac-custom-auth:true,content-type:application/soap+xml; charset=utf-8"
  
# Broker outbound -- add API Key
Proxy-Start `
  -Name 'Broker outbound' `
  -Port 8012 `
  -RemotePort 5755 `
  -HostName "integration.accept.vu.nl" `
  -Headers "x-Gateway-APIKey:03ce95e0-4307-437e-a02a-c54c4088387e"
  
