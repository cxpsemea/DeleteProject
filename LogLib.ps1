################################################
# Get timestamp for Logs
function getTime() {
################################################
    return "[{0:MM/dd/yyyy} {0:HH:mm:ss.fff K}]" -f (Get-Date)
}
        
#Get current location of script
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$logFile = Join-Path $scriptPath $logFilename
    
    
################################################
#log message to Console and log File
function log($message, $warning = $false) {
################################################
    $formattedMessage = "$(getTime) ${message}"
       
    if(!$warning){
        Write-Host $formattedMessage
        Write-Output $formattedMessage | Out-file $logFile -append
    } else{
        Write-Warning $formattedMessage
        Write-Output "WARNING: ${formattedMessage}" | Out-file $logFile -append
    }
}
        
################################################
#debug message to Console and log File
function debug($message) {
################################################
    if ( $CxDebug ) {
        log( "$message" )
    }
}
    
################################################
#error message to Console and log File
function error($message, $warning = $false) {
################################################
    $formattedMessage = "$(getTime) ${message}"
          
    Write-Error $formattedMessage
    Write-Output "ERROR: ${formattedMessage}" | Out-file $logFile -append
}

