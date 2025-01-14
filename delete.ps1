
param ( 
    [string]$sourceFile,
    [string]$destinationFolder = "02"
)

# Erstelle den Zielordner, falls er nicht existiert
if (-Not (Test-Path $destinationFolder)) {
    Write-Host "Error - destination folder does not exists"
    exit 1
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
        
    # Vergleiche die Dauer
    if (($sourceDuration -ge ($destinationDuration - 1)) -and ($sourceDuration -le ($destinationDuration + 1)) ) {
        Write-Host "deleting file: $($sourceFile)"
        Remove-Item -Path $sourceFile
        continue
    } 
    else {
        Write-Host "duration of files does not match: $($sourceDuration) vs $($destinationDuration)"
    }
} 
