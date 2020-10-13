
# Into The Breach Lab Deployment guide

This setup describe the process to automate the lab deployement.

This lab included:
* Domain Controller (DC-01)
* Web Server (SRV-WEB-01)
* Workstations (2) (WS-01,WS-02)
* Linux for Command & Control 

**History**: The idea of this lab is to simulate how an attacker from a phishing email can compromise a company using different tactics, techniques and procedures for initial access, lateral movement, credential stealling. 

## Install AutomatedLab

This setup will automate the creation of the windows enviroment we are going to hack, this does not include the Linux Server for command & control. 

It's recommended to run this lab from a VM without any restrictions, if you can create a new VM may avoid some problems. Run powershell as Administrator and install the AutomatedLab package using the following commands:

```
powershell -exec bypass -nop 
```

Install the required modules:
```
Install-Module Az -AllowClobber -Force
Install-PackageProvider Nuget -Force
Install-Module AutomatedLab -AllowClobber -Force
```

Download the [LabSetup](https://github.com/juliourena/Labs/tree/master/LabSetup) directory and copy into C:\tools\.

Go to your [MDATP](https://securitycenter.microsoft.com) tenant and download the onboarding package for *Windows 10* & *Windows Server 2019*, place both files within *C:\tools\LabSetup\ *.

The onboard package for **WS2019** must have the following name: **server-WindowsDefenderATPLocalOnboardingScript.cmd** and the **Windows 10** onboarding package must remain the same. 

Remove the USER_CONSENT section from both onboarding files, for silent install. USER_CONSENT section to be removed: 

```
:USER_CONSENT
set /p shouldContinue= "Press (Y) to confirm and continue or (N) to cancel and exit: "
IF /I "%shouldContinue%"=="N" (
	GOTO CLEANUP
)
IF /I "%shouldContinue%"=="Y" (
	GOTO SCRIPT_START
)
echo.
echo Wrong input. Please try again.
GOTO USER_CONSENT
```

### Install the Lab

**Make sure to change de default credentials!** Go to C:\tools\LabSetup\deploy_lab.ps1 and edit the variables defined: LabName, Domain, DomainName, adminAcct, adminPass, labsources and machines names, also make sure to change C:\tools\LabSetup\ServiceAccount.ps1 variables.

```
Import-Module AutomatedLab
C:\tools\LabSetup\deploy_lab.ps1
```

The setups takes aproximately 1 hour, them you will need to install Office into WS-01 manually, this is to simulate the phishing comming from Outlook. 

To connect to the lab make sure to check which port is using each VM

![MDATP-alert](https://raw.githubusercontent.com/juliourena/Labs/master/img/WS-01-port.png)

## Tenant configuration:
From https://securitycenter.microsoft.com go to Settings > Advanced features and disable:
* Allow or Block file
* Automatically resolve alerts

## Command & Control Configuration with Covenant 

[Covenant](https://github.com/cobbr/Covenant) is a .NET command and control framework that aims to highlight the attack surface of .NET, make the use of offensive .NET tradecraft easier, and serve as a collaborative command and control platform for red teamers.

You can use any Command & Control tool, this example is based on Covenant for simplification. 

In order to install covenant we will use a **Ubuntu Server (Azure Image Ubuntu Server 18.04 LTS)**, the process to install the ubuntu server are not part of this tutorial. 

Once you installed Ubuntu Server make sure to have open ports: (22,80,443,8000) and connect to install dotnet (dotnet is used to build & run Covenant):

### Installation

Covenant use dotnet, in order to install Covenant we need to 1st install dotnet.

```
wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb

sudo add-apt-repository universe
sudo apt-get update
sudo apt-get install apt-transport-https
sudo apt-get update
sudo apt-get install dotnet-sdk-3.1

sudo add-apt-repository universe
sudo apt-get update
sudo apt-get install apt-transport-https
sudo apt-get update
sudo apt-get install aspnetcore-runtime-3.1

sudo add-apt-repository universe
sudo apt-get update
sudo apt-get install apt-transport-https
sudo apt-get update

sudo apt-get install dotnet-runtime-3.1

```

Once you have installed dotnet core, we can build and run Covenant using the dotnet CLI:

```
cd /opt
sudo git clone --recurse-submodules https://github.com/cobbr/Covenant
cd Covenant/Covenant
sudo dotnet build
sudo dotnet run
```

## Hack Them All Step by Steps

Before you move to replicate the attack, you need to:
* Install on WS-01 Office for the 1st step of Initial Access (Phishing received in Outlook/Word). 

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
	
## Creating the CTF

For the CTF platform you can use any platform, I used [CTFd](https://github.com/CTFd/CTFd).

### What is CTFd?
CTFd is a Capture The Flag framework focusing on ease of use and customizability. It comes with everything you need to run a CTF and it's easy to customize with plugins and themes.

[Getting Started Guide](https://github.com/CTFd/CTFd/wiki/Getting-Started)

### How to create the challenges

The challenges tells the history of the attacks, you can to organize the challenges in a way the participants follow the attack. 

#### Example 1 

Let's imagine the attack you did started with phishing, a sample challenge can be: 

1. Looking at Incident #100 the Alert "Network Conection to a Risky Host" identify which computer and user started the attack chain? Example: PC-01,DOMAIN\username

The Example part is really important, that's the way the flag should be entered and it helps the participants to know how to answer correctly. 

#### Example 2

You should enter into the MDATP console and look for challenges, the following alert have different information, you can pick anything as a challenge:

![MDATP-alert](https://raw.githubusercontent.com/juliourena/Labs/master/img/MDATP-alert.png)

1. What's the IP address/DNS of the command and control? 
2. What's the name of the word document? 
3. Which ports connection where stablished to the IP of the command and control server? 

### Other examples:

1. From which computer was the DCSync attack carried out and which account was used for that? *Example:ws-equipo-01,JULIODEMO\jurena*
2. In incident 114 go to Alerts and select the alert "Suspicious WMI process creation" indicate what is the name of the computer and the IP address that was made lateral movement and what was the method. *Example: ws-team-01,2.2.2.2, DCOM*
3. In incident 114, "Sensitive credential memory read on ws-dev-01", check the TimeLine and select the filter "Alert related events", identify What was the account that the attacker compromised after extracting the credentials and what was the Contents of the Command line from the first run of cmd.exe. *Example: JULIODEMO\jurena, "cmd.exe" / c echo test*
4. LOLBins (Living of the Land Binary) allows attackers to create malicious processes using system programs to avoid detection. In Incident 113 and using the alert ** Use of living-of-the-land binary to run malicious code ** say which executable was used to avoid detection. *Example: notepad.exe*
5. MITER ATT & CK (for its acronym in English, Tactics, Techniques and Common Knowledge of Adversaries), is a platform that organizes and categorizes the different types of attacks, threats and procedures carried out by different attackers in the digital world and that allows identifying vulnerabilities in computer systems. In incident 113, the alert ** Suspicious LDAP query on ws-rrhh-01 ** is categorized as ** Collection **. Mention the number of the 3 techniques used according to the MITER Framework. *Example:T3232,T1312,T1435*

**Notes**
* Ask 3 or 4 people to do the challenges before you present, that will help you understand if the are some errors.
* You may ask people that don't know how to use Microsoft Solutions
