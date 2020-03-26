
# Into The Breach Lab Deployment guide

This setup describe the process to automate the lab deployement.

This lab included:
* Domain Controller (DC-01)
* Web Server (SRV-WEB-01)
* Workstations (2) (WS-01,WS-02)

**History**: The idea of this lab is to simulate how an attacker from a phishing email can compromise a company using different tactics, techniques and procedures for initial access, lateral movement, credential stealling. 

## Install AutomatedLab

It's recommended to run this lab from a VM without any restrictions, if you can create a new VM may avoid some problems. Run powershell as Administrator and install the AutomatedLab package using the following commands:

```
powershell -exec bypass -nop 
Install-Module Az -AllowClobber -Force
Install-PackageProvider Nuget -Force
Install-Module AutomatedLab -AllowClobber -Force
```

Download the instalation package <link> to the directory C:\tools\LabSetup, from the powershell session run the following command:

```
Import-Module AutomatedLab
C:\tools\LabSetup\deploy_lab.ps1
```

The setups takes aproximately 1 hour, them you will need to install Office into WS-01 manually, this is to simulate the phishing comming from Outlook. 

## Tenant configuration:
From https://securitycenter.microsoft.com go to Settings > Advanced features and disable:
* Allow or Block file
* Automatically resolve alerts

## Command & Control Configuration with Covenant 

[Covenant](https://github.com/cobbr/Covenant) is a .NET command and control framework that aims to highlight the attack surface of .NET, make the use of offensive .NET tradecraft easier, and serve as a collaborative command and control platform for red teamers.

You can use any Command & Control tool, this example is based on Covenant for simplification. 

In order to install covenant we will use a Ubuntu Server (Azure Image Ubuntu Server 18.04 LTS), the process to install the ubuntu server are not part of this tutorial. 

Once you installed Ubuntu Server make sure to have open ports: (22,80,443,8000) and connect to install dotnet (dotnet is used to build & run Covenant):

### Installation

Be sure to install the dotnet core version 2.2 SDK! Covenant does not yet support dotnet core 3.0, and the SDK is necessary to build the project (not just the runtime).

```
wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb

sudo add-apt-repository universe
sudo apt-get update
sudo apt-get install apt-transport-https
sudo apt-get update
sudo apt-get install dotnet-sdk-2.2

sudo add-apt-repository universe
sudo apt-get update
sudo apt-get install apt-transport-https
sudo apt-get update
sudo apt-get install aspnetcore-runtime-2.2

sudo add-apt-repository universe
sudo apt-get update
sudo apt-get install apt-transport-https
sudo apt-get update

sudo apt-get install dotnet-runtime-2.2

```

Once you have installed dotnet core, we can build and run Covenant using the dotnet CLI:

```
cd /opt
git clone --recurse-submodules https://github.com/cobbr/Covenant
cd Covenant/Covenant
/opt/Covenant/Covenant > dotnet build
/opt/Covenant/Covenant > dotnet run
```

## Hack Them All Step by Steps

To complete the lab setup you will need to complete 2 manual process:
* Install on WS-01 Office for the 1st step of Initial Access (Phishing received in Outlook). 

### History:
	1. Initial Access - lewen get phished and the attacker get command and control over WS-01 PC.
	2. Enumeration - The attacker started enumerating and discover all workstations, users and group from the domain using PowerView.
	3. Privilege Escalation - Since lewen was local admin on his workstation the attacker used UAC Bypass technique to get a high integrity process (aka admin privileges).
	4. Credential Stealing - The attacker execute mimikatz to steal credentials from the local computer and also get the credentials from a recently logged user (rjames), with the previous enumeration identified that rjames was member of the DesktopAdmin group.
	5. Lateral Movement - He used his new gained credentials to compromise one of the discovered workstations (WS-02) using WMI.
	6. Credential Stealing - he repeated the process on the new workstation (WS-02) and get the credentials of kkreps, a developer.
	7. Lateral Movement - with kkreps credentials the attacker access a WebServer (SRV-WEB-01) using PSEXEC.
	8. Credential Stealing - within SRV-WEB-01 the attacker was able to get the hash of a sqladmin user which ended up being part of the Domain Admin group.
	9. DCSync - with the new obtained credentials the attacker execute DCSync to get all users hashes.  