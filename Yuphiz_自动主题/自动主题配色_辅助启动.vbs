' ����
' �ű����ƣ�Yuphiz_�Զ����⸨��������
' �汾�ţ�v1.1.1
' ���ߣ�Yuphiz
' ���ű���Yuphiz_�Զ�����ű��ĸ�������
' ���ô˽ű����·��ɲ����������ģ����뱾�����޹�
' �˽ű���ɲ��� GPL-3.0-later Э��

Pathcurrentfile = createobject("Scripting.FileSystemObject").GetFile(Wscript.ScriptFullName).ParentFolder.Path

set Shell=CreateObject("WScript.Shell")


select case wscript.arguments.count 
      case 0
            call ScriptLauncherUi()
            ' call IsHaveWallpaperScript(Pathcurrentfile  & "\��չ")
      case 1
            select case wscript.arguments(0)
                  case "--RunByTaskWithoutUpdateTime"
                        call runmain("RunByTaskWithoutUpdateTime",1)
                  case "--UpdateSchtasksTime"
                        call runmain("UpdateSchtasksTime",1)
                  case "--StayInBackgroundWithoutTips"
                        call runmain("RunStayInBackgroundWithoutTips",1)
                  case "--Wallpaper"
                        call RunWallpaperOrNot()
            end select
end select


sub ScriptLauncherUi()
      ask=inputbox( vbcrlf& _
            "�� ��ʱ�棺�ճ������Զ��л���ɫ (�Ƽ�)" &vbcrlf&vbcrlf& _
            "     1     �� �� �� ʱ ��" &vbcrlf&vbcrlf& _
            "     1.2   �� �� �� ʱ ��"&vbcrlf&vbcrlf&vbcrlf&vbcrlf& _
            "�� ��̨�棺��ϵͳ������ɫ����" &vbcrlf&vbcrlf& _
            "     2     �� �� �� ̨ ��" &vbcrlf&vbcrlf& _
            "     2.1   �� �� (ˢ��������)" &vbcrlf&vbcrlf&vbcrlf& _
            "     2.2   �� �� �� ̨ �� (��ȡ����̨��������)" &vbcrlf&vbcrlf& _
            "     2.3   �� ͣ ֹ �� ̨  (�´ο�����������)" &vbcrlf&vbcrlf&vbcrlf&vbcrlf& _
            "��   3 ��������ѡ�� ( �޸� ж�� ��ݷ�ʽ ��)" &vbcrlf&vbcrlf, _
            "�Զ�������ɫ   v1.1.1   -- By @Yuphiz",_
            "�������Ӧ����ţ����� 1")

      select case True
            case Ask=""
                  Wscript.quit
            case Ask="1"
                  call runmain("RunChangeByTask",1)
            case Ask="1.2"
                  call runmain("DisableSchtasks",1)
            case Ask="2"
                  call runmain("RunStayInBackground",01)
            case Ask="2.1"
                  call runmain("RestartTheBackground",01)
            case Ask="2.2"
                  call runmain("KillTheBackgroundAndDisable",1)
            case Ask="2.3"
                  call runmain("KillTheBackground",1)
            case Ask="3"
                  call ScriptLauncherUi2()
                  Wscript.quit
            case else
                  call ScriptLauncherUi()
                  Wscript.quit
      end select
end sub

sub ScriptLauncherUi2()
      ask2=inputbox( vbcrlf& _
            "     1     �� �� �� �� �� �� (��һ��������)"&vbcrlf&vbcrlf& _
            "     2     �� �� �� �� �� (��ʱ����ѡ)" &vbcrlf&vbcrlf&vbcrlf& _
            "     3     �� �� �� ��" &vbcrlf&vbcrlf& _
            "     4     ж �� �� ��" &vbcrlf&vbcrlf&vbcrlf& _
            "     5     �� �� �� �� �� ʽ" &vbcrlf&vbcrlf& _
            "     6     �� �� �� �� �� ʽ �� �� ��" &vbcrlf&vbcrlf, _
            "�Զ�������ɫ   v1.1.1   -- By @Yuphiz",_
            "�������Ӧ����ţ����� 1")    

      select case True
            case Ask2=""
                  Wscript.quit
            case Ask2="1"
                  call runmain("DefaultConfig",1)
            case Ask2="2"
                  ' call runmain("Repair",1)
                  call ScriptLauncherUi2()
                  Wscript.quit
            case Ask2="3"
                  call runmain("DisableAllSchtasks",1)
            case Ask2="4"
                  call runmain("RemoveAllSchtasks",1)
            case Ask2="5"
                  call SendLinkTo(Pathcurrentfile)
            case Ask2="6"
                  DesktopPath = Shell.SpecialFolders("Desktop")
                  call SendLinkTo(DesktopPath)
            case else
                  call ScriptLauncherUi2()
                  Wscript.quit
      end select
end sub


sub runmain(arguments,ishidden)
     Shell.run("powershell -ExecutionPolicy Bypass -File """&Pathcurrentfile &"\�Զ�������ɫ.ps1"" "& arguments ),ishidden
end sub



'����ֲ���ֽ֧��
function IsHaveWallpaperScript(PathFolder)
      set FSO = CreateObject("Scripting.FileSystemObject")
      set Folders=FSO.GetFolder(PathFolder)
      set SubFolders=Folders.SubFolders
      set Files = Folders.Files

      for each Oneof in SubFolders
            FolderArray = split(Oneof,"\")
            FolderName = FolderArray(Ubound(FolderArray))
      ' msgbox FolderName &vbcrlf& Instr(1,FolderName,"__",1)
            if Instr(1,FolderName,"__",1) <> 1 then
                  name = IsHaveWallpaperScript(Oneof)
            ' exit function
            end if
      next
      
      for each Oneof in Files
            if Oneof.Name = "��ֽ�߼���_Yuphiz.ps1" then
            message= _
                "�ļ��У�" & Folders &vbcrlf&_
                "�ļ���" & Oneof.Name &vbcrlf&_
                "�ļ�·����" & Oneof
                name = Oneof
            end if
            ' msgBox name
            '     exit function
      next
IsHaveWallpaperScript = name
end function



sub RunWallpaperOrNot()
      UserName=CreateObject("WScript.Network").UserName
      Set Shell = CreateObject("Wscript.Shell")
      set FSO = CreateObject("Scripting.FileSystemObject")
      WallpaperScriptPath = IsHaveWallpaperScript(Pathcurrentfile & "\��չ")
      ' msgbox IsHaveWallpaperScriptPath
      if WallpaperScriptPath <> "" then
            ' msgbox 2
            call RandomWallpaper(WallpaperScriptPath,Null,1)
      else
            wscript.quit
      end if
end sub


sub RandomWallpaper(Path,arguments,ishidden)
      Set Shell = CreateObject("Wscript.Shell")
      Shell.run("powershell -ExecutionPolicy Bypass -File """&Path &""" "& arguments ),ishidden
end sub

sub SendLinkTo(Path)
      set LinkObj = Shell.CreateShortcut(Path & "\�Զ�������ɫ.lnk")
      LinkObj.TargetPath = "explorer"
      LinkObj.Arguments = Wscript.ScriptFullName
      LinkObj.IconLocation = "%SystemRoot%\System32\shell32.dll,174"
      LinkObj.Save
      Shell.popup "�������" &vbcrlf&vbcrlf&_
      Path &vbcrlf&vbcrlf&_
      "�����˿�ݷ�ʽ",2
end sub