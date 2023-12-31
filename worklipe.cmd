echo Edge2 prepearing
echo Note: may take some time for diskpart to start, please wait...

:: pnputil.exe /add-driver "X:\driverpackage\dwcsdhc\dwcsdhc.inf" /install

(
echo list disk
) | diskpart

echo ==========
ping 127.0.0.1 -n 5 1>nul

(
echo select disk 0
echo select partition 1
echo assign letter=A
exit
)  | diskpart

(
echo select disk 0
echo select partition 2
echo assign letter=B
exit
)  | diskpart

echo;
echo Creating proper boot entries and BCD...
echo;

rmdir /S /Q A:\EFI
rmdir /S /Q B:\EFI

bcdboot B:\Windows /s A: /f UEFI

echo;
echo Creating msr partition...
echo;

(
echo select disk 0
echo create partition msr size=16
exit
)  | diskpart

echo;
echo Coverting boot partition to an ESP one...
echo;

(
echo select disk 0
echo select partition 1
echo set id=C12A7328-F81F-11D2-BA4B-00A0C93EC93B override
exit
)  | diskpart

echo Inject eMMC driver...
Dism /Image:B: /Add-Driver /Driver:"X:\driverpackage\dwcsdhc\dwcsdhc.inf"

:: https://www.elevenforum.com/t/what-is-oobe-bypassnro.5011/
:: https://www.tenforums.com/tutorials/95002-dism-edit-registry-offline-image.html
:: reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f
:: shutdown /r /t 0

echo;
echo Restoring old winre...
echo;

del B:\Windows\System32\Recovery\winre.wim
copy B:\Windows\System32\Recovery\backup-winre.wim B:\Windows\System32\Recovery\winre.wim

echo;
echo Configuring finnished, rebooting after 5 sec...
echo;


echo ==========
ping 127.0.0.1 -n 5 1>nul

:end
