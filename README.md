# DeleteProject
Powershell script to delete a project in CxSAST and all it's related data.

Previous to delete a project, find all the scans, delete every scan in CxSAST and removes the stored source code (in the files system) for every removed scan.
After that, the project itself is removed from CxSAST.

## Usage 

   ```shell
   .\DeleteProject.ps1 -CxServer "http://localhost:80" -CxUser "user" -CxPass "password" -projectName "CxSAST project name" [-CxSourceRoot "C:\CxSrc"] [-CxDelSrcDir] [-ContinueOnDelSrcDirError] [-DryRun] [-logFilename "mylogfile.txt"] [-CxDebug]
   ```
### Mandatory parameters

#### -CxServer
URL of your CxSAST instance (e.g. "http://localhost:80" )

#### -CxUser
CxSAST username (with permissions to manage scans and projects)

#### -CxPass
Password of CxSAST user

### Additional optional parameters

#### -CxSourceRoot
Root directory of scans's source code (defaults to D:\CxSrc)

#### -CxDelSrcDir
By default, `the script WILL NOT delete the scans` source code directory.

If set, scans' source code directory will be removed.

#### -ContinueOnDelSrcDirError
By default, the script will stop in case of an error deleting the scan surce code directory.

If set, the script will continue processing the scans of the project (deleting every scan in CxSAST and removing the source code from the filesystem)

#### -DryRun
If set, print the out the actions to do, but do not execute them. 

#### -logFilename
Defaults to DeleteProject.log

#### -CxDebug
If set, verbose debug. Defaults to info.

   
