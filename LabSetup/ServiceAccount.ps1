$UserName = 'zerotrustws\sqlservice'
$Service = 'ALG'
$Password = 'Supersecure!'

$svcD=gwmi win32_service -filter "name='$service'"
$svcD | Invoke-WmiMethod -Name ChangeStartMode -ArgumentList "Automatic"
$svcD.StopService() 
$svcD.change($null,$null,$null,$null,$null,$null,$UserName,$Password,$null,$null,$null) 
$svcD.StartService()
