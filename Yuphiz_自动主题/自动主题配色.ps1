<#
.����
      �ű����ƣ�Yuphiz_�Զ�����
      �汾�ţ�v1.1.1
      ���ߣ�Yuphiz
      ���ű����԰��� Windows10 �Զ��л���ǳɫ����
      ���ô˽ű����·��ɲ����������ģ����뱾�����޹�
      �˽ű���ɲ��� GPL-3.0-later Э��
#>


param (
      [Parameter(Mandatory=$false)]$RunWith
)

# $time1 = get-date
# ��������
#�ű�����·�������Ϊ����ѡ��ǰ����·��
$PathScriptWork = $PSScriptRoot;if ($PathScriptWork -eq "") {$PathScriptWork=(get-location).path}
$title="�Զ�������ɫ"

$popup=new-object -comobject wscript.shell


function set-MulTrigger-TaskService {
      param (
            [Parameter(Mandatory=$true)]$TaskName,
            [Parameter(Mandatory=$true)]$TriggersArray,
            [Parameter(Mandatory=$true)]$ActionPath,
            [Parameter(Mandatory=$true)]$ActionArguments,
            [Parameter(Mandatory=$true)]$Description,
            [Parameter(Mandatory=$true)]$WhatToDoTask,
            $RootPath = "\"
      )
      $service = new-object -com("Schedule.Service")
      $service.connect()
      $rootFolder = $service.Getfolder($RootPath)

      $taskDefinition = $service.NewTask(0)

      $Settings = $taskDefinition.Settings
      $Settings.StartWhenAvailable = $True
      $Settings.DisallowStartIfOnBatteries = $false
      $Settings.ExecutionTimeLimit= "PT5M"

      $triggers = $taskDefinition.Triggers

      $TriggerHashTable = @{}
      For ($i=0; $i -lt $TriggersArray.count;$i++) {
            switch ($TriggersArray[$i].Type) {
                  "Logon" {
                        $TypeLogon = 9
                        ($TriggerHashTable.$i) = $triggers.Create($typeLogon)
                        ($TriggerHashTable.$i).UserId = $env:username
                        ($TriggerHashTable.$i).Enabled = $TriggersArray[$i].Enable
                        ($TriggerHashTable.$i).delay = $TriggersArray[$i].delay
                        ($TriggerHashTable.$i).Repetition.Interval = $TriggersArray[$i].Interval
                        ($TriggerHashTable.$i).Repetition.Duration = $TriggersArray[$i].Duration
                        break
                  }
                  "Daily" {
                        $TypeDaily = 2
                        ($TriggerHashTable.$i) = $triggers.Create($TypeDaily)
                        ($TriggerHashTable.$i).StartBoundary = $TriggersArray[$i].StartTime
                        ($TriggerHashTable.$i).DaysInterval = $TriggersArray[$i].DaysInterval
                        ($TriggerHashTable.$i).Repetition.Interval = $TriggersArray[$i].Interval
                        ($TriggerHashTable.$i).Repetition.Duration = $TriggersArray[$i].Duration
                        ($TriggerHashTable.$i).Enabled = $TriggersArray[$i].Enable
                        break
                    }
                  "Event" { 
                        $TypeEvent = 9
                        ($TriggerHashTable.$i) = $triggers.Create($TypeEvent)
                        ($TriggerHashTable.$i).Subscription = $TriggersArray[$i].XML
                        ($TriggerHashTable.$i).Enabled = $TriggersArray[$i].Enable
                        break
                   }
            }
      }

      $InfoTask = $taskDefinition.RegistrationInfo
      $InfoTask.Description = $Description

      $Actions = $taskDefinition.Actions
      $Action = $Actions.Create(0)
      $Action.Path = $ActionPath
      $Action.Arguments= $ActionArguments
            
      $WhatToDo = switch ($WhatToDoTask) {
            "Update" { 4 }
            "CreateOrUpdate" { 6 }
      }
      $null=$rootFolder.RegisterTaskDefinition( $TaskName,$taskDefinition,$WhatToDo,$null,$null, 3)
}

function get-TaskService {
      Param (
            [Parameter(Mandatory=$true)]$TaskName,
            $RootPath = "\"
      )
      $Results = @()
      $service = new-object -com("Schedule.Service")
      $service.connect()
      $rootFolder = $service.Getfolder($RootPath)
      
      $taskDefinition = $service.NewTask(0)

      Foreach ($Oneof in $TaskName) {
            try{
                  $Result = $rootFolder.gettask($Oneof)
            }catch{
                  $Result = "����ƻ�������"
            }
            $Results += @{
                  (split-path $Oneof -leaf) = $Result
            }
      }
return $Results
}



function get-ConfigFromJson {
      $FileConfig="$PathScriptWork\$($title)_$($env:userdomain)_$($env:username).json"

      if (! (Test-Path $FileConfig)) {
            @"
{
"��λѡ��":{
      "�����Զ���λ":"��"
,     "�ֶ���λ����":0
,     "�ֶ���λγ��":0
      
,     "�ճ�ʱ��ƫ��_ʱ":0
,     "����ʱ��ƫ��_ʱ":0
       
}

,"������ɫѡ��":{
      "�л�ϵͳ��ɫ":"��"
,     "�л�Ӧ����ɫ":"��"
}

,"��չѡ��":{
      "������չ":"��"
,     "�Զ��ر�":"��,�˹�����ʱ����ѡ"
,     "��չ����":{
            "�� ��":"bbb ccc"
      }
,     "�첽��������߳���":"8,�˹�����ʱ����ѡ"
,     "�ӳ���չ":[
            "UWP����ҳ��ɫ"
      ]
,     "�ӳ�ʱ��_����":4000
,     "�ӳ���չ�첽����":"��,�˹�����ʱ����ѡ"
}
,"����ѡ��":{
      "����ƻ�ƫ��ʱ��_ʱ":0.05
}
}
"@ | set-content $FileConfig
}

      try {
            $Config=get-content $FileConfig | ConvertFrom-Json
      }catch{
            $null = $popup.popup("      $FileConfig `n`r
      $($error[0])",0,"�����ļ�����",16);exit
      }
return $Config
}

if ($RunWith -eq "DefaultCongif") {exit}
# ��ȡ����
$Config=get-ConfigFromJson



# ��ȡ��չ
function Get-Extensions {
      param (
            $PathOfFolder,
            $Extensions=@(),
            $FormatSupported =@( ".ps1")
      )
      $Filter=(ls $PathOfFolder -File -Depth 2 | ?{$FormatSupported -contains $_.Extension}) 
            foreach ($Oneof in $Filter) {
                  $path = ($Oneof.FullName.split("\"))[-1,-2,-3] | ?{ $_.indexof("__") -eq 0}
                  if ($path.count -eq 0) {
                        $Extensions += $Oneof
                  }
            }

return $Extensions
}


# �����ӳٵ���չ
function Run_Delay_Extension {
      param (
            $Delay_extensions
      )
      # $RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, 2)
      # $RunspacePool.Open()

      foreach ($oneof in $Delay_extensions){
            Invoke-Command -ScriptBlock $oneof
      }
      # Read-Host
}



# ������չ
function RunExtension {
      # $time1=get-date

      $extensions=Get-Extensions "$PathScriptWork\��չ"

      if ($extensions.count -gt 0){
      $Delay_extensionsWithArgument = @()
      $Delay_extensionsWithoutArgument = @()
      
      $RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, 8)
      $RunspacePool.Open()
      $jobObject=@()
      for ($i=0;$i -lt $extensions.count;$i++) {
            $name=$extensions[$i].BaseName
            Start-Sleep -Milliseconds 200
            if ($config.��չѡ��.��չ����.$name -ne $null) {
                  if ($config.��չѡ��.�ӳ���չ -contains $name) {
                        $Argument=$config.��չѡ��.��չ����.$name
                        $Delay_extensionsWithArgument += [scriptblock]::Create("powershell -ExecutionPolicy Bypass -File '$($extensions[$i].fullname)' $Argument")
                  }else{
                        $Argument=$config.��չѡ��.��չ����.$name
                        $file = [scriptblock]::Create("powershell -ExecutionPolicy Bypass -File '$($extensions[$i].fullname)' $Argument")
                        $PowerShell =[powershell]::Create()
                        $PowerShell.Runspacepool = $Runspacepool
                        [void]$PowerShell.AddScript($file)
                        $jobObject += $PowerShell.BeginInvoke()
                  }
                  
            }else {
                  if ($config.��չѡ��.�ӳ���չ -contains $name) {
                        $Delay_extensionsWithoutArgument += [scriptblock]::Create("powershell -ExecutionPolicy Bypass -File '$($extensions[$i].fullname)' ")
                  }else{
                        $file = [scriptblock]::Create("powershell -ExecutionPolicy Bypass -File '$($extensions[$i].fullname)' ")
                        $PowerShell =[powershell]::Create()
                        $PowerShell.Runspacepool = $Runspacepool
                        [void]$PowerShell.AddScript($file)
                        $jobObject += $PowerShell.BeginInvoke()
                  }
            }
      }
      # ($(get-date)-$time1).TotalSeconds
      # $time1=get-date
      
      foreach ($Oneof in $jobObject) {
            # ($jobObject | ?{$_.Result.IsCompleted -ne $true}).count
            $null=$Oneof.AsyncWaitHandle.WaitOne()
      }
      $PowerShell.RunspacePool.close()
      $PowerShell.Dispose()
      $RunspacePool.close()
      $RunspacePool.Dispose()
      #     write-host "Handles: $($(Get-Process -Id $PID).HandleCount) Memory: $($(Get-Process -Id $PID).PrivateMemorySize64 / 1mb) mb"
      [System.GC]::Collect()
      # ($(get-date)-$time1).TotalSeconds
      $DelayTime = $config.��չѡ��.�ӳ�ʱ��_����
      if ($DelayTime -lt 2000){
            $DelayTime = 5000
      }
      Start-Sleep -Milliseconds $DelayTime
      $Delay_extensionsWithArgument += $Delay_extensionsWithoutArgument
      Run_Delay_Extension $Delay_extensionsWithArgument
}
      # read-host
}


#��̨������ƻ�����idд����¡�����id��ȡ
#�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T ���¼ƻ�����(��̨����) ��ʼ �T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T
function TaskService {
      param (
            $UpdateOrRead
      )
      $service = new-object -com("Schedule.Service")
      $service.connect()
      $rootFolder = $service.Getfolder("\YuphizScript")
      
      $taskDefinition = $service.NewTask(0)

      if ($UpdateOrRead -eq "Update"){
            $Settings = $taskDefinition.Settings
            $Settings.StartWhenAvailable = $True
            $Settings.DisallowStartIfOnBatteries = $false
            $Settings.ExecutionTimeLimit= "PT5M"

            $triggers = $taskDefinition.Triggers
            $trigger = $triggers.Create(9)
            $trigger.UserId = $env:username

            $InfoTask = $taskDefinition.RegistrationInfo
            $InfoTask.Description=$pid

            $Action = $taskDefinition.Actions.Create(0)
            $Action.Path = "wscript"
            $Action.Arguments= `
                  "`"$PathScriptWork\$($title)_��������.vbs`" --StayInBackgroundWithoutTips"
            
            $UpdateTask = 4
            $null=$rootFolder.RegisterTaskDefinition( `
                  "$env:username\$title\��̨������¼",`
                  $taskDefinition,$UpdateTask,$null,$null, 3)


      }elseif($UpdateOrRead -eq "Read"){
            if (schtasks /query /tn YuphizScript\$env:username\$title\��̨������¼ 2>$null){
            $XmlTasks= `
                  [xml]($rootFolder.gettask("$env:username\$title\��̨������¼").xml)
            $DescriptionTasks=$XmlTasks.Task.RegistrationInfo.Description
            return $DescriptionTasks
            }
      }
      
}




#�жϺ�̨���Ƿ������в����½���id
function GetOrUpdate-BackgroundProcessId{
      param (
            $GetOrUpdate,
            $IsTips
      )
      $ProcessID=TaskService "Read"
      if ($GetOrUpdate -eq "Get" -and $ProcessID -ne $null){
            if ((get-process -id $ProcessID -erroraction Ignore).ProcessName -eq "powershell"){
                        return $True
                  }else{
                        return $false
                  }
      }elseif ($GetOrUpdate -eq "Get" -and $ProcessID -eq $null){
            return $false
      }elseif ($GetOrUpdate -eq "Update" -and $ProcessID -ne $null){
            if ((get-process -id $ProcessID -erroraction Ignore).ProcessName -eq "powershell"){
                  $null=$Popup.popup("$title �Ѿ����У�����������",0,$null,4096)
                  exit
            }else{
                  TaskService "Update"
                  if ($IsTips -ne "NoTips") {
                        Write-Host "�������� ����"
                        $null=$Popup.popup("������$title",1,$null,4096)
                  }
            }
      }elseif($GetOrUpdate -eq "Update" -and $ProcessID -eq $null){
            TaskService "Update"
            if ($IsTips -ne "NoTips") {
                  Write-Host "�������� ����"
                  $null=$Popup.popup("������$title",1,$null,4096)
            }
      }
}





# ���л�ɫ
function changeTheme{
      param (
            $WindowsThemeValue,
            $AppThemeValue
      )
#�������� ��Windowsģʽ��ɫ����ʼ�˵���
      if ($config.������ɫѡ��.�л�ϵͳ��ɫ -eq "��") {
            # $null=$popup.Popup("��ϵͳ��ɫ",1,$null,4096)
            $null = reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d $WindowsThemeValue /f
      }
#�������� ��Ӧ����ɫ
      if ($config.������ɫѡ��.�л�Ӧ����ɫ -eq "��") {
            # $null=$popup.Popup("��Ӧ����ɫ",1,$null,4096)
            $null = reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d $AppThemeValue /f
      }

#�������� ��չ
      if (($config.��չѡ��.������չ -eq "��") -and ((GetOrUpdate-BackgroundProcessId "get") -eq $false)) {
            # $null=$popup.Popup("��̨û�п�����������չ",1,$null,4096)
            RunExtension
      }
}




# $time1=get-date

function Get-SunRiseSet {
      param (
            $Longitude,
            $Latitude,
            $SunRiseValue=1,
            $dayCount =(New-TimeSpan -Start '2000-01-01 12:00:00').TotalDays,
            $h=[math]::sin(-0.833/180*[math]::PI),
            $ut0=180,
            $ut=0
      )
$LatitudeRadian=$Latitude/180*[math]::PI   #�Ƕ�ת��Ϊ����

$t= ($dayCount + $ut0 / 360d) / 36525.64 #������
$L = 280.460 + 36000.777 * $t #̫��ƽ���ƾ�
$G = (357.528 + 35999.050 * $t)/180*[math]::PI #̫��ƽ�����
$lamda = ($L + 1.915 * [Math]::sin($G) + 0.020 * [Math]::sin(2 * $G))/180*[math]::PI #̫���Ƶ�����
$epc = (23.4393- 0.0130 * $t)/180*[math]::PI #�������
$sigam = [Math]::asin([Math]::sin($epc) * [Math]::sin($lamda)) #̫����ƫ��

$gha = $ut0 - 180 - 1.915 * [Math]::sin($G) - 0.020 * [Math]::sin(2 * $G)+ 2.466 * [Math]::sin(2 * $lamda) - 0.053 * [Math]::sin(4 * $lamda);  # ��������ʱ��̫��ʱ���

$e =([Math]::acos(($h - [Math]::tan($LatitudeRadian) * [Math]::tan($sigam))))*180/[math]::PI  # ����ֵe

if ($SunRiseValue -eq 1){
      $ut = $ut0 - $gha - $Longitude - $e
      if ([math]::abs($ut - $ut0) -ge 0.1) {
            $zone=[int][System.TimeZoneInfo]::local.BaseUtcOffset.TotalHours
            $SunRise=($ut / 15 + $zone) + $Config.��λѡ��.�ճ�ʱ��ƫ��_ʱ
            Get-SunRiseSet $Longitude $Latitude 1 $dayCount $h $ut $ut
      }else{
            Get-SunRiseSet $Longitude $Latitude 0 $dayCount $h
            return 
      }

}elseif($SunRiseValue -eq 0){
      $ut = $ut0 - $gha - $Longitude + $e
      if ([math]::abs($ut - $ut0) -ge 0.1) {
            Get-SunRiseSet $Longitude $Latitude 0 $dayCount $h $ut $ut
      }else{
            $Sunset=($ut / 15 + $zone) + $Config.��λѡ��.����ʱ��ƫ��_ʱ
            return $SunRise,$SunSet
      }
}
}



# Сʱ��ʽ��
Function ConvertHourTo($h,$hm){
      $hh=[math]::floor($h) |
            % { if("$_".length -lt 2) {"0"+$_}else{$_}}
      $mm=[math]::floor(($h-$hh)*60) |
            % { if("$_".length -lt 2) {"0"+$_}else{$_}}
      $ss=[math]::floor((($h-$hh)*60-$mm)*60) |
            % { if("$_".length -lt 2) {"0"+$_}else{$_}}
      if ($hm -eq "hm") {
            return "$hh"+":"+"$mm"
      }else{
            return "$hh"+":"+"$mm"+":"+"$ss"
      }
}



#ʱ��ת������
Function ConvertTimeTo {
      param (
            $TimeDat,
            $What="h"
      )
      $timesplit=$TimeDat.split(":",3)
      if ($What -eq "h"){
            return $timesplit[0]/1+$timesplit[1]/60+$timesplit[2]/3600
      }elseif ($What -eq "m"){
            return $timesplit[0]*60+$timesplit[1]/1+$timesplit[2]/60
      }elseif ($What -eq "s"){
            return $timesplit[0]*3600+$timesplit[1]*60+$timesplit[2]/1
      }
}




#�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T �������ƻ� ģ�鿪ʼ �T�T�T�T�T�T�T�T�T�T�T�T�T�T�T�T
function TimeSchtasks{
      param (
            $EnableOrDisable,
            $SunRise,
            $SunSet,
            $OnlyUpdate  
      )

      $hms_SunRise=ConvertHourTo ($SunRise)
      $hms_SunSet=ConvertHourTo ($SunSet)
# "`n�ճ�ʱ����"
# $hms_SunRise
# "`n����ʱ����"
# $hms_SunSet

####���ű� ��Ȼ�ŵ���һ�𣬵��Ǵ����������ӳ�����
$TaskName="\YuphizScript\$env:username\$title\�Զ�������ɫ"
if ((! (schtasks /query /tn $TaskName  2>$null)) -and $EnableOrDisable -eq "Enable" ){
      $TriggerClass = cimclass MSFT_TaskEventTrigger root/Microsoft/Windows/TaskScheduler
      $triggerXML = $TriggerClass | New-CimInstance -ClientOnly
      $triggerXML.Enabled = $true
      $triggerXML.Subscription="<QueryList><Query Id='0' Path='System'><Select Path='System'>*[System[Provider[@Name='Microsoft-Windows-Power-Troubleshooter'] and (Level=4 or Level=0) and (EventID=1)]]</Select></Query></QueryList>"
      $Triggers = @(
            $(New-ScheduledTaskTrigger -daily -at $hms_SunRise),
            $(New-ScheduledTaskTrigger -daily -at $hms_SunSet),
            $(New-ScheduledTaskTrigger -atlogon -user "$env:username"),
            $triggerXML
      )
      $null = Register-ScheduledTask -taskname $TaskName -Action (New-ScheduledTaskAction -Execute "wscript" -Argument """$PathScriptWork\$($title)_��������.vbs"" --RunByTaskWithoutUpdateTime") -Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit 00:05 -AllowStartIfOnBatteries)  -Trigger  $Triggers
}else{
      if ($OnlyUpdate -ne "OnlyUpdate") {
      $null = SCHTASKS /change /$EnableOrDisable /tn $TaskName
      }
}


####�����ճ�����ʱ��
      $TaskName5="\YuphizScript\$env:username\$title\�����ճ�����ʱ��"
      if ((! (schtasks /query /tn $TaskName5  2>$null)) -and $EnableOrDisable -eq "Enable" ){
            $null = schtasks /Create /TN $TaskName5 /TR "wscript '$PathScriptWork\$($title)_��������.vbs' --UpdateSchtasksTime" /SC DAILY /mo 2 /ST 02:00:00 /f
            $null = Set-ScheduledTask -taskname YuphizScript\$env:username\$title\�����ճ�����ʱ�� -Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit 00:05 -AllowStartIfOnBatteries)
      }else{
            if ($OnlyUpdate -ne "OnlyUpdate") {
                  $null = SCHTASKS /change /$EnableOrDisable /tn $TaskName5
                  }
      }


      if ( $EnableOrDisable -eq "Enable" -and $RunWith -ne "RunByTaskWithoutUpdateTime") {
            $TriggerClass = cimclass MSFT_TaskEventTrigger root/Microsoft/Windows/TaskScheduler
            $triggerXML = $TriggerClass | New-CimInstance -ClientOnly
            $triggerXML.Enabled = $true
            $triggerXML.Subscription="<QueryList><Query Id='0' Path='System'><Select Path='System'>*[System[Provider[@Name='Microsoft-Windows-Power-Troubleshooter'] and (Level=4 or Level=0) and (EventID=1)]]</Select></Query></QueryList>"
            $Triggers = @(
                  $(New-ScheduledTaskTrigger -daily -at $hms_SunRise),
                  $(New-ScheduledTaskTrigger -daily -at $hms_SunSet),
                  $(New-ScheduledTaskTrigger -atlogon -user "$env:username"),
                  $triggerXML
            )
            $null = Set-ScheduledTask -taskname YuphizScript\$env:username\$title\�Զ�������ɫ -Trigger  $Triggers
      }
}





function ChangeThemeBySchtasks{
      param (
            $SunRise,
            $SunSet,
            $IsTips
      )
      
      $TimeNowh=ConvertTimeTo (Get-Date -Format 'HH:mm:ss')
      
#����
# $debugtime="19:40"
# $TimeNowh=ConvertTimeTo $debugtime

            
# �ж�����ʱ�� ��������
      $OffsetSchtask=$Config.����ѡ��.����ƻ�ƫ��ʱ��_ʱ
      if ((($SunRise-$OffsetSchtask) -le $timenowH) -and ($timenowH  -le  ($SunSet-$OffsetSchtask))) {
            $WindowsThemeValue = "1" #ϵͳǳɫ���⣨��ʼ�˵�����������
            $AppThemeValue = "1" #Ӧ��ǳɫ����
      }else{
            $WindowsThemeValue = "0" #ϵͳ��ɫ���⣨��ʼ�˵�����������
            $AppThemeValue = "0" #Ӧ����ɫ����
      }
      if ($IsTips -ne "Notips"){
            Write-Host "�������� ����"
            $null = $popup.popup("�����ö�ʱ��",1,$null,4096)
      }
      changeTheme $WindowsThemeValue $AppThemeValue
}




function BackgroundSchtasks {
      param (
            $EnableOrDisable="Enable"
      )
      $TaskName6="\YuphizScript\$env:username\$title\��̨������¼"
      if ((!(schtasks /query /tn $TaskName6  2>$null)) -and $EnableOrDisable -eq "Enable"){
            $null = Register-ScheduledTask -taskname $TaskName6 -Action (New-ScheduledTaskAction -Execute "wscript" -Argument """$PathScriptWork\$($title)_��������.vbs"" --StayInBackgroundWithoutTips") -Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit 00:05 -AllowStartIfOnBatteries)  -Trigger  (New-ScheduledTaskTrigger -atlogon -user "$env:username") 
      }else{
            $null = SCHTASKS /change /$EnableOrDisable /tn $TaskName6
      }
}



function StayInBackground {
      for () {
            Start-sleep -m 700
            $NewSystemTheme=(Get-ItemProperty -path "registry::HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize").SystemUsesLightTheme
            Start-Sleep -m 700
            $NewAppTheme=(Get-ItemProperty -path "registry::HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize").AppsUseLightTheme

            if ($NewAppTheme -ne $LastAppTheme -or $NewSystemTheme -ne $LastSystemTheme) {
                  # $null=$popup.popup("NewAppTheme: $NewAppTheme `n`r
# NewSystemTheme: $NewSystemTheme" ,1,$null,4096)
                  if ($NewAppTheme -ne $LastAppTheme ) {
                        $LastAppTheme = $NewAppTheme
                        RunExtension
                        Start-Sleep -m 700
                        $LastSystemTheme = (Get-ItemProperty -path "registry::HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize").SystemUsesLightTheme
                  }elseif($NewSystemTheme -ne $LastSystemTheme) {
                        $LastSystemTheme = $NewSystemTheme
                        RunExtension
                        Start-Sleep -m 700
                        $LastAppTheme = (Get-ItemProperty -path "registry::HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize").AppsUseLightTheme
                  }
                  Start-sleep -m 1000
                  
            }

      }
}

function KillOrRestartBackground {
      param (
            $KillOrRestart
      )
      $ProcessID=TaskService "Read"
      if ($ProcessID -ne $null) {
            if ((get-process -id $ProcessID -erroraction Ignore).ProcessName -eq "powershell"){
                  taskkill /im $ProcessID /f
                  if ($KillOrRestart -eq "AndDisableSchtasks"){
                        BackgroundSchtasks "Disable"
                  }
            }
      }
      if ($KillOrRestart -eq "Restart"){
            BackgroundSchtasks
            GetOrUpdate-BackgroundProcessId "Update"
            StayInBackground
      }
}


function DisableAllSchtasks{
      KillOrRestartBackground "Kill"
      $AllSchTasks=@(
            "\YuphizScript\$env:username\$title\�ճ�ǳɫ",
            "\YuphizScript\$env:username\$title\������ɫ",
            "\YuphizScript\$env:username\$title\��¼",
            "\YuphizScript\$env:username\$title\����",
            "\YuphizScript\$env:username\$title\�����ճ�����ʱ��",
            "\YuphizScript\$env:username\$title\��̨������¼"
            "\YuphizScript\$env:username\$title\��ֽ�ֲ�"
      )
      foreach ($Oneof in $AllSchTasks){
            if (schtasks /query /tn $Oneof 2>$null) {
                 $null = schtasks /change /disable /tn $Oneof
            }
      }
      $null = $popup.popup("�������",1,$null,4096)
}


function RemoveAllSchtasks{
      $Ask=$popup.popup(
      "������������Ҫɾ����$title����",
      0, 
      "�������������ȷ��",
      1+48+256+4096 
  )
  if ($Ask -eq 1) {
      KillOrRestartBackground "Kill"
      $AllSchTasks=@(
            "\YuphizScript\$env:username\$title\�ճ�ǳɫ",
            "\YuphizScript\$env:username\$title\������ɫ",
            "\YuphizScript\$env:username\$title\��¼",
            "\YuphizScript\$env:username\$title\����",
            "\YuphizScript\$env:username\$title\�����ճ�����ʱ��",
            "\YuphizScript\$env:username\$title\��̨������¼",
            "\YuphizScript\$env:username\$title\��ֽ�ֲ�",
            "\YuphizScript\$env:username\$title\�Զ�������ɫ"
      )
      foreach ($Oneof in $AllSchTasks){
            if (schtasks /query /tn $Oneof 2>$null) {
                 schtasks /delete /tn $Oneof /f
            }
      }

      $service = new-object -com("Schedule.Service")
      $service.connect()
      $rootFolder = $service.Getfolder("\YuphizScript\$env:username")
      $taskDefinition=$service.NewTask(0)
      try{$rootFolder.deleteFolder($title,0)}catch{}
      $null = $popup.popup("�������",1,$null,4096)

}else{
      exit
}
}


if ($Config.��λѡ��.�����Զ���λ -eq "��"){ 
      $UrlLocation = "https://api.map.baidu.com/location/ip?ak=HQi0eHpVOLlRuIFlsTZNGlYvqLO56un3&coor=bd09ll"
      try {
            $Location=invoke-restmethod -uri $UrlLocation -UseBasicParsing
      }catch{
         switch ($error[0].FullyQualifiedErrorId) {
             "WebCmdletWebResponseException,Microsoft.PowerShell.Commands.InvokeRestMethodCommand" {
            $null = $popup.popup("    ������󣬶�λʧ�ܡ�`
    ������������ֶ���λ`
    ��ȷ���˳�����",0,"�Զ�������ɫ",4096)
            exit
        }
      }
      }
      $Longitude=$Location.Content.Point.x
      $Latitude=$Location.Content.Point.y
}elseif ($Config.��λѡ��.�����Զ���λ -eq "��" -or $Longitude -eq $null -or $Latitude -eq $null) {
      $Longitude=$Config.��λѡ��.�ֶ���λ����
      $Latitude=$Config.��λѡ��.�ֶ���λγ��
}


$SunRiseSet = (Get-SunRiseSet $Longitude $Latitude)
$SunRise = $SunRiseSet[0]
$SunSet = $SunRiseSet[1]

# $SunRise
# $SunSet


switch ($RunWith) {
      "RunByTaskWithoutUpdateTime" {
            ChangeThemeBySchtasks $SunRise $SunSet "Notips"
      }
      "RunChangeByTask" {
            TimeSchtasks "Enable" $SunRise $SunSet
            ChangeThemeBySchtasks $SunRise $SunSet
      }
      "UpdateSchtasksTime" {
            TimeSchtasks "Enable" $SunRise $SunSet "OnlyUpdate"
      }
      "DisableSchtasks" {TimeSchtasks "disable"}
      "RunStayInBackground" {
            BackgroundSchtasks
            GetOrUpdate-BackgroundProcessId "Update"
            StayInBackground
      }
      "RunStayInBackgroundWithoutTips" {
            # BackgroundSchtasks
            GetOrUpdate-BackgroundProcessId "Update" "Notips"
            StayInBackground
      }
      "RestartTheBackground" {
            KillOrRestartBackground "restart"
      }
      "KillTheBackground" {
            KillOrRestartBackground "Kill"
      }
      "KillTheBackgroundAndDisable" {
            KillOrRestartBackground "Kill"
            BackgroundSchtasks "Disable"
      }
      "DisableAllSchtasks" {
            DisableAllSchtasks
      }
      "RemoveAllSchtasks" {
            RemoveAllSchtasks
      }
}