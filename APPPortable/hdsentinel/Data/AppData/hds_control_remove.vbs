on error resume next
Err.clear
Set service = CreateObject("Schedule.Service")
service.Connect
Set rootFolder = service.GetFolder("\HardDiskSentinel")
if Err.Number<>0 then
	Wscript.Echo "Already REMOVED"
	Wscript.Quit
	end if
rootFolder.DeleteTask "Hard Disk Sentinel",0
if (rootFolder.GetTasks(0).Count=0) then
	Set rootFolder = service.GetFolder("\")
	rootFolder.DeleteFolder "HardDiskSentinel",0
  end if
Wscript.Echo "REMOVED"
