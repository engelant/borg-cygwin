@echo off
set CYGSETUP=setup-x86.exe
set BASEDIR=%~dp0
cd /d %BASEDIR%

set POWERSHELL=%windir%\System32\WindowsPowerShell\v1.0\powershell.exe
mkdir cache

echo Fetch Cygwin setup from internet using powershell

"%POWERSHELL%" -Command "(New-Object Net.WebClient).DownloadFile('https://cygwin.com/setup-x86.exe', 'cache\\setup-x86.exe')"


set CYGBUILD64=%BASEDIR%\build\x86_64
set CYGBUILD32=%BASEDIR%\build\x86
set CYGMIRROR=http://mirrors.kernel.org/sourceware/cygwin/
set BUILDPKGS=python3,python3-devel,python3-setuptools,binutils,gcc-g++,libopenssl,openssl-devel,git,make,openssh,liblz4-devel,liblz4_1

cd cache
IF "%1"=="" (
echo.
echo Installing x86_64 Build version of Cygwin
echo.
%CYGSETUP% -a x86_64 -q -B -o -n -R %CYGBUILD64% -s %CYGMIRROR% -P %BUILDPKGS%
echo.
echo Installing x86 Build version of Cygwin
echo.
%CYGSETUP% -a x86 -q -B -o -n -R %CYGBUILD32% -s %CYGMIRROR% -P %BUILDPKGS%
)
IF "%1"=="x86" (
echo.
echo Installing x86 Build version of Cygwin
echo.
%CYGSETUP% -a x86 -q -B -o -n -R %CYGBUILD64% -s %CYGMIRROR% -P %BUILDPKGS%
)
IF "%1"=="x86_64" (
echo.
echo Installing x86_64 Build version of Cygwin
echo.
%CYGSETUP% -a x86_64 -q -B -o -n -R %CYGBUILD32% -s %CYGMIRROR% -P %BUILDPKGS%
)




REM --- Build borgbackup

IF "%1"=="" (
cd %CYGBUILD64%
copy /Y ..\..\fstab etc\
echo.
echo Installing Borg Backup into x86_64 Build version of Cygwin
echo.

bin\bash --login -c 'easy_install-3.6 pip; pip install borgbackup'
cd %CYGBUILD32%
copy /Y ..\..\fstab etc\
echo.
echo Installing Borg Backup into x86 Build version of Cygwin
echo.
bin\bash --login -c 'easy_install-3.6 pip; pip install borgbackup'
)
IF "%1"=="x86" (
echo.
echo Installing Borg Backup into x86 Build version of Cygwin
echo.
cd %CYGBUILD32%
copy /Y ..\..\fstab etc\
bin\bash --login -c 'easy_install-3.6 pip; pip install borgbackup'
)
IF "%1"=="x86_64" (
cd %CYGBUILD64%
copy /Y ..\..\fstab etc\
echo.
echo Installing Borg Backup into x86_64 Build version of Cygwin
echo.
bin\bash --login -c 'easy_install-3.6 pip; pip install borgbackup'
)

echo.
echo.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo Don't forget to install NSIS, available at http://nsis.sourceforge.net/Download
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!




