param(
    [string]$OwnerAndRepo
)

Write-Output "Build script."
Write-Output "-------------"

function AddMessageFilterClass 
{ 
$source = @‘ 
namespace EnvDteUtils
{
using System; 
using System.Runtime.InteropServices; 

public class MessageFilter : IOleMessageFilter 
{ 
public static void Register() 
{ 
IOleMessageFilter newFilter = new MessageFilter(); 
IOleMessageFilter oldFilter = null; 
CoRegisterMessageFilter(newFilter, out oldFilter); 
} 

public static void Revoke() 
{ 
IOleMessageFilter oldFilter = null; 
CoRegisterMessageFilter(null, out oldFilter); 
} 

int IOleMessageFilter.HandleInComingCall(int dwCallType, System.IntPtr hTaskCaller, int dwTickCount, System.IntPtr lpInterfaceInfo)
{ 
return 0; 
} 

int IOleMessageFilter.RetryRejectedCall(System.IntPtr hTaskCallee, int dwTickCount, int dwRejectType) 
{ 
if (dwRejectType == 2) 
{ 
return 99; 
} 
return -1; 
} 

int IOleMessageFilter.MessagePending(System.IntPtr hTaskCallee, int dwTickCount, int dwPendingType) 
{ 
return 2; 
} 

[DllImport("Ole32.dll")] 
private static extern int CoRegisterMessageFilter(IOleMessageFilter newFilter, out IOleMessageFilter oldFilter); 
} 

[ComImport(), Guid("00000016-0000-0000-C000-000000000046"), InterfaceTypeAttribute(ComInterfaceType.InterfaceIsIUnknown)] 
interface IOleMessageFilter 
{ 
[PreserveSig] 
int HandleInComingCall(int dwCallType, IntPtr hTaskCaller, int dwTickCount, IntPtr lpInterfaceInfo);

[PreserveSig]
int RetryRejectedCall(IntPtr hTaskCallee, int dwTickCount, int dwRejectType);

[PreserveSig]
int MessagePending(IntPtr hTaskCallee, int dwTickCount, int dwPendingType);
}
}
‘@
 Add-Type -TypeDefinition $source
}

AddMessageFilterClass('') # Call function
[EnvDteUtils.MessageFilter]::Register() # Call static Register Filter Method

$stringArray = $OwnerAndRepo.Split('/');

$owner = $stringArray[0]
$repo = $stringArray[1]

Write-Output 'Owner : ' + $owner
Write-Output 'Repo : ' + $repo


#$solutionDir = "C:\dev\mobject-disposable\src\mobject-disposable-library\"
#$solutionName = "mobject-disposable.sln"
#$solutionPath = $solutionDir += $solutionName 

#$dte = new-object -com TcXaeShell.DTE.15.0
#$dte.SuppressUI = $false
#$dte.MainWindow.Visible = $true

#$solution = $dte.Solution
#$solution.Open($solutionPath)

#$projects = $solution.Projects

#Write-Host("Checking for projects...")
#if (-not $projects.Count > 0) {
#  Write-Host(" - No projects found in Solution.")
#  $dte.Quit()
#  exit 1
#}

#Write-Host(" - " + $projects.Count + " found.")

#$testProject = $null
#
#foreach ($project in $projects){
# "NAME: " + $project.Name
#  
#  if ($project.Name -eq "mobject-disposable-test-project") {
#    $testProject = $projects.Item($project)
#    break
#  }
#}

#$testProject = $projects.Item(1) # how to select this project by name?

#if ($testProject -eq $null) {
#  Write-Host(" - Test project not found.")
#  $dte.Quit()
#  exit 1
#}

#$systemManager = $testProject.Object

#$configManager = $systemManager.ConfigurationManager
#$configManager.ActiveTargetPlatform = "TwinCAT RT (x64)"

##$systemManager.SetTargetNetId("UmRT_Default")
#$systemManager.SetTargetNetId("192.168.4.1.1.1")


#$plcProject = $systemManager.LookupTreeItem("TIPC^Main")
#$plcProject.BootProjectAutostart = $true
#$plcProject.GenerateBootProject($true)

#$systemManager.ActivateConfiguration()
#$systemManager.StartRestartTwinCAT() 

#$dte.Quit()

[EnvDTEUtils.MessageFilter]::Revoke()

exit 0
