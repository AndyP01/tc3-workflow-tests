Write-Host "Build script."
Write-Host "-------------"
Clear-Host

function AddMessageFilterClass { 
    $source = @'

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
'@
    Add-Type -TypeDefinition $source
}

AddMessageFilterClass('') # Call function
[EnvDteUtils.MessageFilter]::Register() # Call static Register Filter Method

# Search for the solution file of the checked out project and return the full path.
Write-Host "Searching for solution..."
$solutionPath = Get-ChildItem -Path "C:\actions-runner\_work" -Filter *.sln -Recurse | ForEach-Object { $_.FullName }

if ($solutionPath.IsNullOrEmpty) {
    Write-Host " - No solution found."
    exit 1
}

Write-Host " - Found : $($solutionPath)`n"

$dte = new-object -ComObject "TcXaeShell.DTE.15.0"
$dte.SuppressUI = $true
$dte.MainWindow.Visible = $false

$solution = $dte.Solution
$solution.Open($solutionPath)

$projects = $solution.Projects

Write-Host "Checking for projects..."
Write-Host " - $($projects.Count) found.`n"

#if (-not $projects.Count > 0) {
#  Write-Host " - No projects found in Solution.`n"
#  $dte.Quit()
#  exit 1
#}

Write-Host("Searching for test project...")

#$testProject = $projects.Item(1) # how to select this project by name?

$testProject = $null

foreach ($project in $projects) {
    if ($project.Name -like "*test-project") {
        $testProject = $project
        Write-Host " - Using: $($project.Name)`n"
    }
}

#if ($testProject -eq $null) {
#  Write-Host " - Test project not found.`n"
#  $dte.Quit()
#  exit 1
#}

try {
    Write-Host "Configuring TwinCAT..."
    $systemManager = $testProject.Object

    Write-Host " - Set active platform."
    $configManager = $systemManager.ConfigurationManager
    $configManager.ActiveTargetPlatform = "TwinCAT RT (x64)"

    Write-Host " - Set target NetId."
    #$systemManager.SetTargetNetId("UmRT_Default")
    $systemManager.SetTargetNetId("192.168.4.1.1.1")

    Write-Host " - Lookup PLC project."
    $plcProject = $systemManager.LookupTreeItem("TIPC^Main")
    if ($null -eq $plcProject) {
        Write-Host " - Lookup PLC item failed."
    }

    Write-Host " - Set boot project to autostart."
    $plcProject.BootProjectAutostart = $true

    Write-Host " - Generate boot project."
    $plcProject.GenerateBootProject($true)
    
    Write-Host " - Activate and restart TwinCAT."
    $systemManager.ActivateConfiguration()
    $systemManager.StartRestartTwinCAT()
    
    Write-Host "`nDone."
    #$dte.Quit()
}
catch {
    Write-Output "Exception!"
}
finally {
    if ($null -ne $dte) {
        $dte.Quit()
    }
}

[EnvDTEUtils.MessageFilter]::Revoke()

exit 0