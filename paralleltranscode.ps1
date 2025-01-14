param ( 
    [int]$processCount = 1,
    [string]$sourceFolder = "done"
)
$cores =(Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors
$threads = $cores
if($processCount -lt $cores){
    $threads = [math]::Ceiling($cores / $processCount)
}
else {
    $threads = 1
}

$fileQueue = [System.Collections.Queue]::new()


# Definiere die Liste der Video-Dateierweiterungen
$videoExtensions = @(".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".webm")

# Hole alle Videodateien im Quellordner
$files = Get-ChildItem -Path $sourceFolder | Where-Object { $videoExtensions -contains $_.Extension.ToLower() }
# Add files to the queue
foreach ($file in $files) {
    $fileQueue.Enqueue($file.FullName)
}

$jobs = @()

function Start-Task {
    param(
        [string]$sourceFile,
        [int]$threads
    )
    Write-Host "Starting job for $sourceFile with threads $threads"
    $task = Start-Job -ScriptBlock { param ($filePath, $thr) .\transcode.ps1 -sourceFile $filePath  -threads $thr} -ArgumentList($sourceFile,$threads)
    return $task
}


# Start the initial batch of processes
for ($i = 1; $i -le $processCount; $i++) {
    if ($fileQueue.Count -gt 0) {
        $sourceFile = $fileQueue.Dequeue()
        #$jobs += Start-Job -ScriptBlock { param ($filePath) .\transcode.ps1 -sourceFile $filePath  -threads 1} -ArgumentList($sourceFile)
        $jobs += Start-Task -sourceFile $sourceFile -threads $threads
    }
}

# Monitor and start new processes as jobs complete
$IsStillJobsRunning = $true
while ($IsStillJobsRunning) {
    $IsStillJobsRunning = $false
    for ($i = 0; $i -lt $jobs.Count; $i++) { 
        $job = $jobs[$i]
        if ($job.State -eq 'Running') {
            $IsStillJobsRunning = $true
        }
        elseif ($job.State -eq 'Completed' -or $job.State -eq 'Failed') {
            $output = Receive-Job -Job $job 
            Write-Host "Job $($job.Name) $($job.State) with output: $output | reason: $($job.JobStateInfo.Reason)"
            Remove-Job -Job $job
            $jobs[$i] = $null
            if ($fileQueue.Count -gt 0) {
                $sourceFile = $fileQueue.Dequeue()
                $jobs[$i] = Start-Task -sourceFile $sourceFile -threads $threads
            }
        }
    }
    #Start-Sleep -Seconds 5
    Get-Job | Wait-Job -Any > $null
}

Write-Host "All files have been processed."
