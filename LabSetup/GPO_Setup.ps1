
$DomainDN = ([adsi]'').distinguishedName

# Lab GPO add Disable Defender Realtime Monitoring
Write-Host -Object "Creating Windows Defender Excusion GPO" -ForegroundColor Cyan
$Path = "C:\GPO"
$ID = Get-ChildItem -Path $Path
$GPO = New-GPO -Name 'Disable Defender Realtime Monitoring' -Comment 'Disable Defender Realtime Monitoring'
Import-GPO -TargetName $GPO.DisplayName -Path $Path -BackupId $ID.Name
Write-Host -Object "GPO with GUID $($GPO.Id) created." -ForegroundColor Green
Write-Host -Object "Linking Windows Defender GPO to Domain" -ForegroundColor Cyan
New-GPLink -Guid $GPO.Id -Target "$($DomainDN)" -LinkEnabled Yes