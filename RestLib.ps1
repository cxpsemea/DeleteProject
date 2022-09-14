
$serverRestEndpoint = $server + "/cxrestapi/"

################################################
#debug get Headers
function getHeaders($token){
################################################
    return @{
        Authorization = $token
        "Content-Type" = "application/json;v=1.0"
        "Accept" = "application/json"
    }
}


################################################
function getOAuth2Token(){
################################################
    $body = @{
        username = $cxUsername
        password = $cxPassword
        grant_type = "password"
        scope = "sast_rest_api"
        client_id = "resource_owner_client"
        client_secret = "014DF517-39D1-4453-B7B3-9930C563627C"
    }
    
    try {
        $response = Invoke-RestMethod -uri "${serverRestEndpoint}auth/identity/connect/token" -method post -body $body -contenttype 'application/x-www-form-urlencoded'
    } catch {
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
        throw "Could not authenticate"
    }
    
    return $response.token_type + " " + $response.access_token
}

################################################
function getProjects($token){
################################################
    $headers = getHeaders $token
    try {
        Debug "Getting projects"
        $response = Invoke-RestMethod -uri "${serverRestEndpoint}projects" -method get -headers $headers 
        return $response
    } catch {
        Error "StatusCode: $($_.Exception.Response.StatusCode.value__)"
        Log "StatusDescription: $($_.Exception.Response.StatusDescription)"
        Log "Message: $($_.ErrorDetails.Message)"
        throw "Cannot Get Projects"
    }
}


################################################
function getProjectScans($token, $projectId){
################################################    
$headers = getHeaders $token
try {
    $response = Invoke-RestMethod -uri "${serverRestEndpoint}sast/scans?projectId=${projectId}" -method get -headers $headers 
    return $response
    } catch {
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__
    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
    throw "Cannot Get Scans"
    }
}




################################################
function getSourcePathByScanId($token, $scanId){
################################################
    $headers = getHeaders $token
    
   
    try {
        $scan = Invoke-RestMethod -uri "${serverRestEndpoint}sast/scans/${scanId}" -method get -headers $headers
        $cxSourcePath = $cxSourceRoot + "\" + $scan.project.id.ToString() + "_" + $scan.scanState.sourceId
        return $cxSourcePath;
           
    } catch {
        Error "StatusCode: $($_.Exception.Response.StatusCode.value__)"
        Log "StatusDescription: $($_.Exception.Response.StatusDescription)"
        Log "Message: $($_.ErrorDetails.Message)"
        throw "Cannot Get ScanId"
    }
}

################################################
function deleteScan($token, $scanId){
################################################
    
    if ($DryRun) { 
        Log "`tDryRun Mode:: Deleting Scan with ID $scanId"
        return $true
    }
    
    #$body = @{
    #    deleteRunningScans = $true
    #}
    $body = $body | ConvertTo-Json -Depth 99
    #$headers = @{
    #    Authorization = $token
    #}
    $headers = getHeaders $token
    try {
        #$response = Invoke-RestMethod -uri "${serverRestEndpoint}sast/scans/${scanId}" -method Delete -headers $headers -ContentType 'application/json;v=1.0'
        Log "${serverRestEndpoint}sast/scans/${scanId}"
        $response = Invoke-RestMethod -uri "${serverRestEndpoint}sast/scans/${scanId}" -method Delete -headers $headers 
        return $true
    } catch {
        Error "StatusCode: $($_.Exception.Response.StatusCode.value__)"
        Log "StatusDescription: $($_.Exception.Response.StatusDescription)"
        Log "Message: $($_.ErrorDetails.Message)"
        return $false
    }
}



################################################
function deleteProject($token, $projectId){
################################################

    if ($DryRun) { 
        Log "`tDryRun Mode:: Deleting Project with ID $projectId"
        return $true
    }


    $body = @{
        deleteRunningScans = $true
    }
    $body = $body | ConvertTo-Json -Depth 99
    #$headers = @{
    #    Authorization = $token
    #}
    $headers = getHeaders $token
    try {
        $response = Invoke-RestMethod -uri "${serverRestEndpoint}projects/${projectId}" -method Delete -headers $headers -body $body 
        #-ContentType 'application/json'
        return $true
    } catch {
        Error "StatusCode: $($_.Exception.Response.StatusCode.value__)"
        Log "StatusDescription: $($_.Exception.Response.StatusDescription)"
        Log "Message: $($_.ErrorDetails.Message)"
        return $false
    }
}