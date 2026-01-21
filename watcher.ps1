# VECTIS LEGACY BRIDGE - PowerShell v2.0 Compatible
# No Python. No dependencies. 4KB footprint.

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "C:\LegacyApp\Exports"
$watcher.Filter = "*.csv"
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true  

# The Destination (Your Cloud)
$url = "http://ingest.vectis.io/upload"
$apiKey = "YOUR_SECURE_TOKEN"

Write-Host "Vectis Agent Active. Watching $($watcher.Path)..."

# Define the action block
$action = { $path = $Event.SourceEventArgs.FullPath
            $changeType = $Event.SourceEventArgs.ChangeType
            
            Write-Host "Detected $changeType on $path"
            
            # WAIT for the legacy app to release the file handle
            Start-Sleep -s 3
            
            # NATIVE UPLOAD (.NET WebClient)
            # This bypasses needing external tools like curl or ftp
            try {
                $webClient = New-Object System.Net.WebClient
                $webClient.Headers.Add("X-Auth", $apiKey)
                
                Write-Host "Uploading..."
                $response = $webClient.UploadFile($url, "POST", $path)
                
                Write-Host "Success."
                
                # Optional: Move to 'Processed' folder to signal user it's done
                # Move-Item $path "C:\LegacyApp\Exports\Processed" -Force
            }
            catch {
                Write-Host "Upload Failed: $_"
            }
          }

# Register the event (This keeps it running in background)
Register-ObjectEvent $watcher "Created" -Action $action
Register-ObjectEvent $watcher "Changed" -Action $action

# Keep the script alive without burning CPU
while ($true) { Start-Sleep -s 5 }