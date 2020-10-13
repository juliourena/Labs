
# To do
# - Clean variable, ask to complete unset variables before execution.
# Change AzureATP $AccessKey 
# Check Lab Content before running (PATH) 
# Install Azure AD on the Domain Controller 
# Change MDATP scripts 

$labName = 'MSRedTeam'
$domain = 'msredteam.xyz'
$domainName = 'MSREDTEAM'
$adminAcct = 'plaintext'
$adminPass = 'PASSWORD123!'
$labsources = "C:\tools\Labs\LabSetup"

$DC='DC-02'
$SRVWEB='SRV-WEB-02'
$WS1='WS-05'
$WS2='WS-06'

New-LabDefinition -Name $labName -DefaultVirtualizationEngine Azure

# Set username and password 
Add-LabDomainDefinition -Name $domain -AdminUser $adminAcct -AdminPassword $adminPass
Set-LabInstallationCredential -Username $adminAcct -Password $adminPass


# Deploying to West Europe for faster speed
$azureDefaultLocation = 'East US'
Add-LabAzureSubscription -DefaultLocationName $azureDefaultLocation

#Role Definition
$role = Get-LabMachineRoleDefinition -Role RootDC @{
    ForestFunctionalLevel = 'WinThreshold'
    DomainFunctionalLevel = 'WinThreshold'
    SiteName = $domainName
	SiteSubnet = '192.168.2.0/24'
}

# Deploying DC and Client machine. (Server has less cost and less services by default)

Add-LabMachineDefinition -Name $DC -OperatingSystem 'Windows Server 2019 Datacenter (Desktop Experience)' -IpAddress '192.168.2.5' -Roles $role -DomainName $domain

Add-LabMachineDefinition -Name $SRVWEB -OperatingSystem 'Windows Server 2019 Datacenter (Desktop Experience)' -IpAddress '192.168.2.10' -DnsServer1 '192.168.2.5' -Roles WebServer -DomainName $domain -Network 'MSRedTeam'

Add-LabMachineDefinition -Name $WS1 -OperatingSystem 'Windows 10 Enterprise' -IpAddress '192.168.2.101' -DnsServer1 '192.168.2.5' -DomainName $domain -Network 'MSRedTeam'

Add-LabMachineDefinition -Name $WS2 -OperatingSystem 'Windows 10 Enterprise' -IpAddress '192.168.2.102' -DnsServer1 '192.168.2.5' -DomainName $domain -Network 'MSRedTeam'

Install-Lab | Add-Content -Path ".\MSRedTeam.log"

# Configure fake accounts, OU and groups
Invoke-LabCommand -ActivityName "Configure Domain Controller" -FilePath C:\tools\Labs\LabSetup\LabSetup.ps1 -ComputerName $DC 

# Configurations 
Invoke-LabCommand -ActivityName "Enable Recycle Bin" -ScriptBlock { Enable-ADOptionalFeature 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target msredteam.xyz -Confirm:$false } -ComputerName $DC

# Restart LabVM to complete the rest of the opperations
Restart-LabVM -ComputerName $DC -Wait -NoDisplay
Restart-LabVM -ComputerName $SRVWEB -Wait -NoDisplay
Restart-LabVM -ComputerName $WS1 -Wait -NoDisplay
Restart-LabVM -ComputerName $WS2 -Wait -NoDisplay

# Create Service Account for Azure ATP (after restart)
Invoke-LabCommand -ActivityName "Configure Group Managed Service Account" -ScriptBlock { Add-KdsRootKey –EffectiveImmediately; Add-KdsRootKey –EffectiveTime ((get-date).addhours(-10));New-ADServiceAccount "azureatpgmsa" -DNSHostName "<FQDN DC>" -PrincipalsAllowedToRetrieveManagedPassword "Domain Controllers";Install-ADServiceAccount -Identity "azureatpgmsa";Test-ADServiceAccount "azureatpgmsa" } -ComputerName $DC

# Azure ATP Sensor 
Copy-LabFileItem -Path "C:\tools\Labs\LabSetup\Azure ATP Sensor Setup.exe" -ComputerName $DC -DestinationFolderPath 'C:\'
Copy-LabFileItem -Path "C:\tools\Labs\LabSetup\SensorInstallationConfiguration.json" -ComputerName $DC -DestinationFolderPath 'C:\'
Invoke-LabCommand -ActivityName "Configure Azure ATP Sensor" -ScriptBlock { cmd /c '"C:\Azure ATP Sensor Setup.exe" /quiet NetFrameworkCommandLineArguments="/q" AccessKey="<ADD YOUR ACCESS KEY HERE>"' } -ComputerName $DC 

# Onboarding MDATP
# Send Onboarding package to machines 
Copy-LabFileItem -Path C:\tools\Labs\LabSetup\server-WindowsDefenderATPLocalOnboardingScript.cmd -ComputerName $DC -DestinationFolderPath 'C:\'
Copy-LabFileItem -Path C:\tools\Labs\LabSetup\server-WindowsDefenderATPLocalOnboardingScript.cmd -ComputerName $SRVWEB -DestinationFolderPath 'C:\'
Copy-LabFileItem -Path C:\tools\Labs\LabSetup\WindowsDefenderATPLocalOnboardingScript.cmd -ComputerName $WS1 -DestinationFolderPath 'C:\'
Copy-LabFileItem -Path C:\tools\Labs\LabSetup\WindowsDefenderATPLocalOnboardingScript.cmd -ComputerName $WS2 -DestinationFolderPath 'C:\'

# Run Onboarding package 
Invoke-LabCommand -ActivityName "MDATP Onboarding" -ScriptBlock { C:\server-WindowsDefenderATPLocalOnboardingScript.cmd } -ComputerName $DC
Invoke-LabCommand -ActivityName "MDATP Onboarding" -ScriptBlock { C:\server-WindowsDefenderATPLocalOnboardingScript.cmd } -ComputerName $SRVWEB
Invoke-LabCommand -ActivityName "MDATP Onboarding" -ScriptBlock { C:\WindowsDefenderATPLocalOnboardingScript.cmd } -ComputerName $WS1
Invoke-LabCommand -ActivityName "MDATP Onboarding" -ScriptBlock { C:\WindowsDefenderATPLocalOnboardingScript.cmd } -ComputerName $WS2

# Configure VPN Server 
#Invoke-LabCommand -ActivityName "Configure VPN Server Groups" -ScriptBlock { New-ADGroup -GroupCategory Security -GroupScope Global -Name "sec-server-vpn"; Add-ADGroupMember -Identity "sec-server-vpn" -Members "SRV-VPN-01$"; } -ComputerName $DC

#Invoke-LabCommand -ActivityName "Configure VPN Server Groups" -ScriptBlock { New-ADGroup -GroupCategory Security -GroupScope Global -Name "sec-vpn-users"; Add-ADGroupMember -Identity "sec-vpn-users" -Members "VPNUsers"; Add-ADGroupMember -Identity "sec-vpn-users" -Members "VPNComputers" } -ComputerName $DC

# Local Admins
Invoke-LabCommand -ActivityName "Setting up Local Admin" -ScriptBlock { Add-LocalGroupMember -Group 'Administrators' -Member ('SrvAdmins','kkreps') } -ComputerName $SRVWEB
Invoke-LabCommand -ActivityName "Setting up Local Admin" -ScriptBlock { Add-LocalGroupMember -Group 'Administrators' -Member ('DesktopAdmins','lewen') } -ComputerName $WS1
Invoke-LabCommand -ActivityName "Setting up Local Admin" -ScriptBlock { Add-LocalGroupMember -Group 'Administrators' -Member ('DesktopAdmins', 'kkreps') } -ComputerName $WS2

# Configure sqlservice account to run the service SNMPTraps
Invoke-LabCommand -ActivityName "Configuring sqlservice account" -FilePath C:\tools\Labs\LabSetup\SNMPTRAP.ps1 -ComputerName $SRVWEB

# Copy GPO
Copy-LabFileItem -Path C:\tools\Labs\LabSetup\GPO -ComputerName $DC -DestinationFolderPath 'C:\'

# Configure GPO 
Invoke-LabCommand -ActivityName "Configure GPO to disable Defender" -FilePath C:\tools\Labs\LabSetup\GPO_Setup.ps1 -ComputerName $DC 

Show-LabDeploymentSummary -Detailed 

# Stop VM
$DcVm = Get-AzVM -ResourceGroupName $labName -name $DC
$SRVWEBVm = Get-AzVM -ResourceGroupName $labName -name $SRVWEB
$WS1Vm = Get-AzVM -ResourceGroupName $labName -name $WS1
$WS2Vm = Get-AzVM -ResourceGroupName $labName -name $WS2
#$WS3Vm = Get-AzVM -ResourceGroupName $labName -name $WS3
$DcVm | Stop-AzVM -ResourceGroupName $labName -force
$SRVWEBVm | Stop-AzVM -ResourceGroupName $labName -force
$WS1Vm | Stop-AzVM -ResourceGroupName $labName -force
$WS2Vm | Stop-AzVM -ResourceGroupName $labName -force
#$WS3Vm | Stop-AzVM -ResourceGroupName $labName -force

# Resize VM to a lower cost image.
$DcVm.HardwareProfile.VmSize = "Standard_B2ms"
$SRVWEBVm.HardwareProfile.VmSize = "Standard_B2ms"
$WS1Vm.HardwareProfile.VmSize = "Standard_B2ms"
$WS2Vm.HardwareProfile.VmSize = "Standard_B2ms"

Update-AzVM -VM $DcVm -ResourceGroupName $labName -Verbose
Update-AzVM -VM $SRVWEBVm -ResourceGroupName $labName -Verbose
Update-AzVM -VM $WS1Vm -ResourceGroupName $labName -Verbose
Update-AzVM -VM $WS2Vm -ResourceGroupName $labName -Verbose
