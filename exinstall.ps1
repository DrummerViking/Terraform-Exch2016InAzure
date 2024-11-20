Param(
    $Username,
    $Password,
    $NotificationRecipient
)
#region Variables
$folder = New-Item -Name "Ex2016reqs" -Type Directory -Path c:\ -Force
$Ex2016IsoPath = "$($folder.FullName)\ExchangeServer2016-x64-CU22.ISO"
$DotNet48Path = "$($folder.FullName)\net48.exe"
$VS2012Path = "$($folder.FullName)\vs2012.exe"
$VS2013Path = "$($folder.FullName)\vs2013.exe"
$UCM4Path = "$($folder.FullName)\ucma40setup.exe"
$IisUrlRewritePath = "$($folder.FullName)\iisUrlrewrite.msi"
#endregion

#region Register event category and download required PS modules
try {
    Start-Transcript -Path "$($folder.FullName)\$(Get-date -Format "yyyy-MM-dd HH_mm_ss") - transcript.log"
    New-EventLog -LogName Application -Source "ExInstall Script" -ErrorAction SilentlyContinue
    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10665 -Message "Starting Exinstall custom script 'exinstall.ps1'."

    #registering custom view in event viewer
    @"
<ViewerConfig>
    <QueryConfig>
        <QueryParams>
            <Simple>
                <Channel>Application</Channel>
                <RelativeTimeInfo>0</RelativeTimeInfo>
                <Source>ExInstall Script</Source>
                <BySource>True</BySource>
            </Simple>
        </QueryParams>
        <QueryNode>
            <Name>ExInstall events</Name>
            <QueryList>
                <Query Id="0" Path="Application">
                    <Select Path="Application">*[System[Provider[@Name='ExInstall Script']]]</Select>
                </Query>
            </QueryList>
        </QueryNode>
    </QueryConfig>
</ViewerConfig>
"@ | Add-Content "$env:ProgramData\Microsoft\Event Viewer\Views\View_0.xml"
    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10665 -Message "Enabling TLS 1.2 for Powershell session"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10667 -Message "Successfully enabled TLS 1.2"
    Install-PackageProvider -Name "NuGet" -MinimumVersion "2.8.5.201" -Force
    Install-module PSFramework -Force
    Set-PSFConfig -FullName PSFramework.Logging.FileSystem.ModernLog -Value $True -PassThru | Register-PSFConfig
}
catch {
    Write-PSFMessage -Level Error -Message "An error occurred starting up the ExInstall script." -ErrorRecord $_
    Write-EventLog -LogName Application -EntryType Error -Source "ExInstall Script" -EventId 10666 -Message "Failed to start up the ExInstall script. Error message: $_"
    Stop-Transcript
    return
}
#endregion

#region Downloading Required Files
try {
    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10665 -Message "Downloading Exchange required files."
    if ( -not (Test-Path $Ex2016IsoPath) ) {
        Write-PSFMessage -Level Important -Message "Downloading Exchange 2016 CU22 ISO file"
        (New-Object System.Net.WebClient).DownloadFile('https://download.microsoft.com/download/f/0/e/f0e65686-3761-4c9d-b8b2-9fb71a207b8d/ExchangeServer2016-x64-CU22.ISO',$Ex2016IsoPath)
    }
    if ( -not (Test-Path $DotNet48Path) ) {
        Write-PSFMessage -Level Important -Message "Downloading .NET 4.8"
        (New-Object System.Net.WebClient).DownloadFile('https://download.visualstudio.microsoft.com/download/pr/014120d7-d689-4305-befd-3cb711108212/0fd66638cde16859462a6243a4629a50/ndp48-x86-x64-allos-enu.exe',$DotNet48Path)
    }
    if ( -not (Test-Path $VS2012Path) ) {
        Write-PSFMessage -Level Important -Message "Downloading VS 2012"
        (New-Object System.Net.WebClient).DownloadFile('https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe',$VS2012Path)
    }
    if ( -not (Test-Path $VS2013Path) ) {
        Write-PSFMessage -Level Important -Message "Downloading VS 2013"
        (New-Object System.Net.WebClient).DownloadFile('https://download.visualstudio.microsoft.com/download/pr/10912041/cee5d6bca2ddbcd039da727bf4acb48a/vcredist_x64.exe',$VS2013Path)
    }
    if ( -not (Test-Path $UCM4Path) ) {
        Write-PSFMessage -Level Important -Message "Downloading VS UCMA4"
        (New-Object System.Net.WebClient).DownloadFile('https://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe',$UCM4Path)
    }
    if ( -not (Test-Path $IisUrlRewritePath) ) {
        Write-PSFMessage -Level Important -Message "Downloading IIS URL Rewrite Module"
        (New-Object System.Net.WebClient).DownloadFile('https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi',$IisUrlRewritePath)
    }
    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10667 -Message "Successfully downloaded Exchange required files."
}
catch {
    Write-PSFMessage -Level Error -Message "An error occurred downloading required files." -ErrorRecord $_
    Write-EventLog -LogName Application -EntryType Error -Source "ExInstall Script" -EventId 10666 -Message "Failed to download Exchange required files. Error message: $_"
    Stop-Transcript
    return
}
#endregion

#region Installing Exchange required Windows features
try {
    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10665 -Message "Installing Exchange required Windows features."
    Write-PSFMessage -Level Important -Message "Installing Exchange required Windows features."
    
    Install-WindowsFeature NET-Framework-45-Features, Server-Media-Foundation, RPC-over-HTTP-proxy, RSAT-Clustering, RSAT-Clustering-CmdInterface, RSAT-Clustering-Mgmt, RSAT-Clustering-PowerShell, WAS-Process-Model, Web-Asp-Net45, Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, Web-Dyn-Compression, Web-Http-Errors, Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Lgcy-Mgmt-Console, Web-Metabase, Web-Mgmt-Console, Web-Mgmt-Service, Web-Net-Ext45, Web-Request-Monitor, Web-Server, Web-Stat-Compression, Web-Static-Content, Web-Windows-Auth, Web-WMI, Windows-Identity-Foundation, RSAT-ADDS;
    
    Write-PSFMessage -Level Important -Message "Successfully installed Exchange requiredWindows features."
    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10667 -Message "Successfully installed Exchange requiredWindows features."
}
catch {
    Write-PSFMessage -Level Error -Message "An error occurred installing Windows Features." -ErrorRecord $_
    Write-EventLog -LogName Application -EntryType Error -Source "ExInstall Script" -EventId 10666 -Message "Failed to install Exchange required Windows features. Error message: $_"
    Stop-Transcript
    return
}
#endregion

#region Visual C++ Redistributable Package for Visual Studio 2012
try {
    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10665 -Message "Installing Visual C++ Redistributable Package for Visual Studio 2012."
    Write-PSFMessage -Level Important -Message "Installing Visual C++ Redistributable Package for Visual Studio 2012."
    
    Start-Process $VS2012Path -ArgumentList "/quiet /norestart /log $($folder.FullName)\vs2012.log" -Wait
    
    Write-PSFMessage -Level Important -Message "Successfully installed Visual C++ Redistributable Package for Visual Studio 2012."
    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10667 -Message "Successfully installed Visual C++ Redistributable Package for Visual Studio 2012."
}
catch {
    Write-PSFMessage -Level Error -Message "An error occurred installing Visual C++ Redistributable Package for Visual Studio 2012." -ErrorRecord $_
    Write-EventLog -LogName Application -EntryType Error -Source "ExInstall Script" -EventId 10666 -Message "Failed to install Visual C++ Redistributable Package for Visual Studio 2012. Error message: $_"
    Stop-Transcript
    return
}
#endregion

#region Visual C++ Redistributable Package for Visual Studio 2013
try {
    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10665 -Message "Installing Visual C++ Redistributable Package for Visual Studio 2013."
    Write-PSFMessage -Level Important -Message "Installing Visual C++ Redistributable Package for Visual Studio 2013."
    
    Start-Process $VS2013Path -ArgumentList "/quiet /norestart /log $($folder.FullName)\vs2013.log" -Wait
    
    Write-PSFMessage -Level Important -Message "Successfully installed Visual C++ Redistributable Package for Visual Studio 2013."
    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10667 -Message "Successfully installed Visual C++ Redistributable Package for Visual Studio 2013."
}
catch {
    Write-PSFMessage -Level Error -Message "An error occurred installing Visual C++ Redistributable Package for Visual Studio 2013." -ErrorRecord $_
    Write-EventLog -LogName Application -EntryType Error -Source "ExInstall Script" -EventId 10666 -Message "Failed to install Visual C++ Redistributable Package for Visual Studio 2013. Error message: $_"
    Stop-Transcript
    return
}
#endregion

#region Microsoft Unified Communications Managed API 4.0
try {
    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10665 -Message "Installing Microsoft Unified Communications Managed API 4.0."
    Write-PSFMessage -Level Important -Message "Installing Microsoft Unified Communications Managed API 4.0."
    
    Start-Process $UCM4Path -ArgumentList "/quiet /log $($folder.FullName)\ucma4.log" -Wait
    
    Write-PSFMessage -Level Important -Message "Successfully installed Microsoft Unified Communications Managed API 4.0."
    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10667 -Message "Successfully installed Microsoft Unified Communications Managed API 4.0."
}
catch {
    Write-PSFMessage -Level Error -Message "An error occurred installing Microsoft Unified Communications Managed API 4.0." -ErrorRecord $_
    Write-EventLog -LogName Application -EntryType Error -Source "ExInstall Script" -EventId 10666 -Message "Failed to install Microsoft Unified Communications Managed API 4.0. Error message: $_"
    Stop-Transcript
    return
}
#endregion

#region IIS URL Rewrite Module
try {
    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10665 -Message "Installing IIS URL Rewrite Module."
    Write-PSFMessage -Level Important -Message "Installing IIS URL Rewrite Module"
    
    Start-Process $IisUrlRewritePath -ArgumentList "/quiet /log $($folder.FullName)\IisurlRewrite.log" -Wait
    
    Write-PSFMessage -Level Important -Message "Successfully installed IIS URL Rewrite Module."
    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10667 -Message "Successfully installed IIS URL Rewrite Module."
}
catch {
    Write-PSFMessage -Level Error -Message "An error occurred installing IIS URL Rewrite Module." -ErrorRecord $_
    Write-EventLog -LogName Application -EntryType Error -Source "ExInstall Script" -EventId 10666 -Message "Failed to install IIS URL Rewrite Module. Error message: $_"
    Stop-Transcript
    return
}
#endregion

#region .NET 4.8
try {
    $regkey = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' | Select-Object Release 
    Switch($regkey.Release){
        378389 {$NETversion = ".NET Framework 4.5"}
        378675 {$NETversion = ".NET Framework 4.5.1 installed with Windows 8.1 or Windows Server 2012 R2"}
        378758 {$NETversion = ".NET Framework 4.5.1 installed on Windows 8, Windows 7 SP1, or Windows Vista SP2"}
        379893 {$NETversion = ".NET Framework 4.5.2"}
        393295 {$NETversion = ".NET Framework 4.6"}
        393297 {$NETversion = ".NET Framework 4.6"}
        394254 {$NETversion = ".NET Framework 4.6.1"}
        394271 {$NETversion = ".NET Framework 4.6.1"}
        394802 {$NETversion = ".NET Framework 4.6.2"}
        394806 {$NETversion = ".NET Framework 4.6.2"}
        460798 {$NETversion = ".NET Framework 4.7"}
        460805 {$NETversion = ".NET Framework 4.7"}
        461308 {$NETversion = ".NET Framework 4.7.1"}
        461310 {$NETversion = ".NET Framework 4.7.1"}
        461808 {$NETversion = ".NET Framework 4.7.2"} 
        461814 {$NETversion = ".NET Framework 4.7.2"}
        528040 {$NETversion = ".NET Framework 4.8"}
        528049 {$NETversion = ".NET Framework 4.8"}
        528209 {$NETversion = ".NET Framework 4.8"}
        528372 {$NETversion = ".NET Framework 4.8"}
    }
    if ( $NETversion -ne ".NET Framework 4.8" ) {
        Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10665 -Message "Installing .NET 4.8."
        Write-PSFMessage -Level Important -Message "Installing .NET 4.8."
        
        Start-Process $DotNet48Path -ArgumentList "/q /norestart /log $($folder.FullName)\dotnet48.log" -Wait
        
        Write-PSFMessage -Level Important -Message "Successfully installed .NET 4.8."
        Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10667 -Message "Successfully installed .NET 4.8."
    }
}
catch {
    Write-PSFMessage -Level Error -Message "An error occurred installing .NET 4.8" -ErrorRecord $_
    Write-EventLog -LogName Application -EntryType Error -Source "ExInstall Script" -EventId 10666 -Message "Failed to install .NET 4.8. Error message: $_"
    Stop-Transcript
    return
}
#endregion

#region Create Post reboot file
'
Param(
    $Username,
    $Password,
    $NotificationRecipient
)
# Variables
$folder = New-Item -Name "Ex2016reqs" -Type Directory -Path c:\ -Force
$Ex2016IsoPath = "$($folder.FullName)\ExchangeServer2016-x64-CU22.ISO"
$OrganizationName = "FirstOrg"

# Start script
Start-Transcript -Path "$($folder.FullName)\$(Get-date -Format "yyyy-MM-dd HH_mm_ss") - post reboot transcript.log"
Import-Module PSFramework
Import-Module ActiveDirectory

# Increase Domain and Forest functional Levels to W2016
$PDC = Get-ADDomainController -Discover -Service PrimaryDC
Set-ADDomainMode -Identity $PDC.Domain -DomainMode 7 -Confirm:$False -ErrorAction SilentlyContinue
Set-ADForestMode -Identity $PDC.Domain -ForestMode 7 -Confirm:$false -ErrorAction SilentlyContinue

#region Install Exchange 2016 Binaries
try {
    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10665 -Message "Installing Exchange 2016 Binaries."
    Write-PSFMessage -Level Important -Message "Installing Exchange 2016 Binaries."
    $null = Mount-DiskImage -ImagePath "$Ex2016IsoPath"
    Set-Location (Get-PSDrive | Where-Object description -eq "EXCHANGESERVER2016-X64-CU22").Root
    
    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10665 -Message "Preparing Exchange 2016 Schema."
    Write-PSFMessage -Level Important -Message "Preparing Exchange 2016 Schema."
    Start-Process -filePath .\Setup.EXE -ArgumentList "/prepareschema /IAcceptExchangeServerLicenseTerms_DiagnosticDataON" -Wait
    
    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10665 -Message "Preparing Exchange 2016 AD."
    Write-PSFMessage -Level Important -Message "Preparing Exchange 2016 AD."
    $arg = "/prepareAD /OrganizationName:{0} /IAcceptExchangeServerLicenseTerms_DiagnosticDataON" -f "$OrganizationName"
    Start-Process -filePath .\Setup.EXE -ArgumentList $arg -Wait

    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10665 -Message "Performing Exchange 2016 roles installation."
    Write-PSFMessage -Level Important -Message "Performing Exchange 2016 roles installation."
    Start-Process -filePath .\Setup.EXE -ArgumentList "/Mode:Install /Roles:mb,mt /InstallWindowsComponents /IAcceptExchangeServerLicenseTerms_DiagnosticDataON" -Wait
    
    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10667 -Message "Successfully installed Exchange 2016 Binaries."
    Write-PSFMessage -Level Important -Message "Finished installing Exchange 2016 server."

    # Remove Scheduled Task
    Unregister-ScheduledTask -TaskName "Run postinstall exinstall scripts"
    Stop-Transcript
    exit 0
}
catch {
    Write-PSFMessage -Level Error -Message "An error occurred installing Exchange 2016 Binaries." -ErrorRecord $_
    Write-EventLog -LogName Application -EntryType Error -Source "ExInstall Script" -EventId 10666 -Message "Failed to install Exchange 2016 Binaries. Error message: $_"
    Stop-Transcript
    return
    exit 0
}
try {
    # Sending post installation notification email
    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10665 -Message "Sending post installation notification email."
    Write-PSFMessage -Level Important -Message "Sending post installation notification email."
    add-PSsnapin *exchange*
    $fromAddress = "test1@$((Get-AcceptedDomain).domainname)"
    $null = New-SendConnector -Internet -Name "Internet" -AddressSpaces *
    [securestring]$secStringPassword = ConvertTo-SecureString $Password -AsPlainText -Force
    New-Mailbox -name "test1" -DisplayName "test1" -Password $secStringPassword -UserPrincipalName $fromAddress
    [String]$body = @"
Hello $Username,

Exchange setup has finished successfully. Please connect to the virtual machine, and verify all services are running.

Thanks,
"@
    [pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($fromAddress, $secStringPassword)
    Send-MailMessage -From $fromAddress -To $NotificationRecipient -Body $body -SmtpServer (Get-ExchangeServer).fqdn -UseSsl -Port 587 -Subject "Exchange Deployment with ExInstall" -Credential $credObject -ErrorAction Stop
    
    Write-EventLog -LogName Application -EntryType Information -Source "ExInstall Script" -EventId 10667 -Message "Successfully sent post installation notification email."
    Write-PSFMessage -Level Important -Message "Successfully sent post installation notification email."
}
catch {
    Write-PSFMessage -Level Error -Message "An error occurred sending post installation notification email." -ErrorRecord $_
    Write-EventLog -LogName Application -EntryType Error -Source "ExInstall Script" -EventId 10666 -Message "An error occurred sending post installation notification email. Error message: $_"
    Stop-Transcript
    return
    exit 0
}
#endregion
' | Add-Content "$($folder.FullName)\postreboot.ps1"
#endregion

#region Register scheduleTask
Write-PSFMessage -Level Important -Message "Registering Scheduled task to run post reboot script"
$taskname = "Run postreboot exinstall scripts"
$taskdescription = "Run postreboot exinstall scripts"
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' `
  -Argument '-NoProfile -WindowStyle Hidden -command "C:\Ex2016reqs\postreboot.ps1 -username $Username -Password $Password -NotificationRecipient $NotificationRecipient"'
$trigger =  New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskname -Description $taskdescription -Settings $settings -User $Username -Password $Password
Write-PSFMessage -Level Important -Message "Sucessfully registered Scheduled task to run post reboot script"
#endregion

#reboot
Write-PSFMessage -Level Important -Message "Rebooting system"
Stop-transcript
shutdown.exe -r -t 0