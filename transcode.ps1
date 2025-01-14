
param ( 
    [string]$sourceFile,
    [string]$destinationFolder = "02", 
    [int]$threads = (Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors,
    [string]$ffmpegPath = "ffmpeg.exe",
    $priority = [System.Diagnostics.ProcessPriorityClass]::Normal
)

# Erstelle den Zielordner, falls er nicht existiert
if (-Not (Test-Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder
}

# Funktion zum Ermitteln der Videodauer
function Get-VideoDuration {
    param (
        [string]$filePath
    )
    $time = & ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $filePath 
    $integerValue = [int]$time
    
    return $integerValue
}

# Konvertiere jede Videodatei im Ordner
$destinationFile = Join-Path -Path $destinationFolder -ChildPath "$($file.BaseName).mp4"

# Überprüfe, ob die datei bereits existiert
if (Test-Path $destinationFile) {
    # Hol die Dauer der Quelldatei und der Zieldatei
    $sourceDuration = Get-VideoDuration -filePath $sourceFile
    $destinationDuration = Get-VideoDuration -filePath $destinationFile
	
    Write-Host "Input duration: $($sourceDuration)"
    Write-Host "Output duration: $($destinationDuration)"

        
    # Vergleiche die Dauer
    if (($sourceDuration -ge ($destinationDuration - 1)) -and ($sourceDuration -le ($destinationDuration + 1)) ) {
        Write-Host "output datei existiert bereits: $($file.Name)"
        Remove-Item -Path $sourceFile
        continue
    } 
} 


    
# Führe die ffmpeg-Konvertierung aus
#& $ffmpegPath -hwaccel auto -i $sourceFile -threads $numOfCores -c:v libvvenc -preset fast -c:a copy $destinationFile
$process = Start-Process -FilePath "$($ffmpegPath)" -ArgumentList "-y -hide_banner -hwaccel auto -i ""$($sourceFile)"" -threads 1 -c:v libvvenc -preset slower -c:a copy ""$($destinationFile)""" -WindowStyle Maximize -PassThru 
#-WhatIf
$process.PriorityClass = $priority
$process.WaitForExit()	
	
    
# Überprüfe, ob die Konvertierung erfolgreich war
if (Test-Path $destinationFile) {
    # Hol die Dauer der Quelldatei und der Zieldatei
    $sourceDuration = Get-VideoDuration -filePath $sourceFile
    $destinationDuration = Get-VideoDuration -filePath $destinationFile
        
    # Vergleiche die Dauer
    if (($sourceDuration -ge ($destinationDuration - 1)) -and ($sourceDuration -le ($destinationDuration + 1)) ) {
        Write-Host "Konvertierung erfolgreich und Längen stimmen überein: $($file.Name)"
        Remove-Item -Path $sourceFile
    }
    else {
        Write-Host "Konvertierung erfolgreich, aber Längen stimmen nicht überein: $($file.Name)"
    }
}
else {
    Write-Host "Konvertierung fehlgeschlagen: $($file.Name)"
}
