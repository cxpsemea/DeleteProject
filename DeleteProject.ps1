Param(
    [Parameter(Mandatory = $true)][string]$CxServer,
    [Parameter(Mandatory = $true)][string]$CxUser,
    [Parameter(Mandatory = $true)][string]$CxPass,
    [Parameter(Mandatory = $true)][string]$projectName,
    [Parameter()][string]$cxSourceRoot = "D:\CxSrc",
    [Parameter()][string]$logFilename = "DeleteProject.log",
    [Switch]$CxDebug = $false,
    [Switch]$CxDelSrcDir = $false,
    [Switch]$ContinueOnDelSrcDirError = $false,
    [Switch]$DryRun = $false
)


if ($ContinueOnDelSrcDirError) {
    $errorAction = "Continue"
} else {
    $errorAction = "Stop"
}

$server = $CxServer
$cxUsername = $CxUser
$cxPassword = $CxPass



$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$logLib = Join-Path $scriptPath "LogLib.ps1"
$RestLib = Join-Path $scriptPath "RestLib.ps1"


. $logLib
. $RestLib


################################################
function deleteScanDirectory($scanDirectory){ 
################################################

    If (!(Test-path $scanDirectory) -And !$DryRun ) {
        Log "The specified scan directory [$scanDirectory] doesn't exist."
    }

    if (!$DryRun -And $CxDelSrcDir) {
        Remove-Item -Recurse -Force $scanDirectory -ErrorAction $errorAction
    } else {
        Log "`tDryRun Mode or not CxDelSrcDir :: Deleting directory $scanDirectory"
    }
}




function Main {
    $mainSw = [Diagnostics.Stopwatch]::StartNew()
    
    $disk = (Get-Item $cxSourceRoot).PSDrive.Name
    $initialSize = Get-PSDrive $disk
    $totalDriveSize = $initialSize.free + $initialSize.used


    Log "Processing projectName [$projectName]"

    Debug "disk: $disk"
    Debug "initialSize: $initialSize"
    Debug "totalDriveSize: $totalDriveSize"

    Debug "Getting token.."
    $token = getOAuth2Token
    #Debug $token


    Debug "Getting Projects.."
    $projects = getProjects $token
    $found = $false
    foreach($project in $projects){
        #Debug "$project"
        $prjId = $project.id
        #Debug "projectId: $prjId"
        $prjName = $project.name
        #Debug "projectName: $prjName"

        if ( $projectName -eq $prjName)  {
            Log "Project with name [$projectName] and id [$prjId] found !!"
            $found = $true
        }

        if ( !$found ) {
            Log "Not Found yet [$prjName]"
            continue
        }

        Log "Getting scans for project [$projectName]"
        $scans = @(getProjectScans $token $prjId)
        if($scans.Count -eq 0){
            Log "projectName [$projectName] without scans. Deleting project.."
            $projectDeleted = deleteProject $token $prjId
            if($projectDeleted){
                Log "Project '${prjName}' was deleted !"
            } else {
                Log "Project '${prjName}' was NOT deleted !"
            }
            break
        } 
        

        Log "projectName [$projectName] has [$($scans.Count)] scans"

        $deleted=0
        foreach($scan in $scans){
            $scanId = $scan.id
            Log "Processing scanid [$scanId] getting SourcePath..."
            $srcPath = getSourcePathByScanId $token $scanId
            Log "`tScan id [$scanId] with SourcePath [$srcPath]"
            Log "`tDeleting scanId [$scanId].."
            $scanDeleted = deleteScan $token $scanId
            if($scanDeleted) {
                Log "`tscanId [$scanId] Deleted"
                try {
                    Log "`tDeleting directory [$srcPath].."
                    deleteScanDirectory $srcPath
                }
                catch {
                    Error "$($_.Exception.Message)"
                    Log "`directory [$srcPath] NOT deleted !!"
                    Log "Exiting ...."
                    exit 1
                }
                Log "`tDirectory [$srcPath] deleted"
                $deleted++

            } else {
                Log "`tscanId [$scanId] NOT deleted !!"
                if ($ContinueOnError) {
                    Log "`ContinueOnError [$ContinueOnError] continuing.."
                } else {
                    Log "`ContinueOnError [$ContinueOnError] Exiting.."
                    exit 1
                }
            }

        }
        Log "Deleted [$deleted] scans out of [$($scans.Count)] from Project [$prjName]: "

        Log "Checking scans for project [$prjName]"
        $tscans = @(getProjectScans $token $prjId)
        if($tscans.Count -eq 0){
            Log "projectName [$prjName] without scans. About to delete project [$prjName] [$prjId].."

            $projectDeleted = deleteProject $token $prjId
            if($projectDeleted){
                Log "Project '${prjName}' was deleted !"
            } else {
                Log "Project '${prjName}' was NOT deleted !"
            }
        } else {
            Log "Project '${projectName}' has still [$($tscans.Count)] scans !!!"
            if ($ContinueOnError) {
                Log "`ContinueOnError [$ContinueOnError] continuing.."
                Log "projectName [$prjName] still with scans. About to delete project [$prjName] [$prjId].."
                $projectDeleted = deleteProject $token $prjId
                if($projectDeleted){
                    Log "Project '${prjName}' was deleted !"
                } else {
                    Log "Project '${prjName}' was NOT deleted !"
                }
            } else {
                Log "`ContinueOnError [$ContinueOnError] Exiting.."
                exit 1
            }

        }

        Debug "Exiting from projects loop"
        break
 
    }


    $mainSw.Stop()

    if (!$found) {
        Log "projectName [$projectName] does not exist !!"
    }


    Log("Finished deleting project(s) in $($mainSw.Elapsed.TotalSeconds) secs")
}


try {
    If (!(Test-path $cxSourceRoot)) {
        throw "The specified path [$cxSourceRoot] doesn't exist."
    }
      
    Main
}
catch {
    Write-Error "$($_.Exception.Message)"
}