# borg-cygwin
Borg: v1.1.6
Cygwin: latest online
Based on the work of Billy Charlton and digidream, scripting mostly done in bash, for obvious reasons.

This creates a standard Windows installer for Borg Backup on 64bit (and untested 32bit) Windows 7 and above.

* Borg install itself will only be ~85MB and require about 300MB on disk
* Tested on Windows 8.1 64-bit


## WARNING - This is a WIP, which technically works, but not fully documented.
As said, working on it.

## Bugs
* The x86 insatller will suggest "C:\Program Files\" instead of "C:\Program Files (x86)". You should switch that on installation till it gets fixed.
* ACL is not tested, as for my kind of backup it’s irrelevant.
* Updating verisons is not tested yet.

---
## Running Borg
I can't state how **important** it is to install and run the proper bitness for your system. While **64bit** on 32bit systems won't run I presume, **32bit** on 64bit will just run fine until you want to utilize something like vssadmin or shadowcopies, as in a 32bit bash environment the required libraries/services are unavailible!

After Installation of the release pachage you should find a cygwin small environment in the Borg installation folder. There is also a backupscript.example file, you can use as a start point.
I suggest to use the SYSTEM user to perform local backups, as there should not be any permission issues.

To get a shell as SYSTEM user utilize psexec from [PsTools](https://docs.microsoft.com/en-us/sysinternals/downloads/psexec) on Microsoft Systinternals. They come in **32bit** and **64bit** versions, use the proper one for _your windows version_ and run
```CMD
psexec64 -i -s "C:\Program Files\Borg\bin\mintty.exe" -e "C:\Program Files\Borg\bin\bash.exe" --login
```
To get a nice little bash shell as SYSTEM user. Be careful, this is the point where you can do pretty much everything, including breaking your machine. This covers 
``` bash
# generate keys for borg backup (no passphrase)
ssh-keygen -t ed25519
# get your public key to insert into the remote machine
cat .ssh/id_ed25519.pub
# connect to your target machine to get its key to the known_hosts
ssh borgbackup@example.com -p 2022 echo
# create your borg repo
# you may want to read the borg doc
export BORG_REPO=ssh://username@example.com:2022/~/backup/main
export BORG_PASSPHRASE='XYZl0ngandsecurepa_55_phrasea&&123'
borg init --encryption=repokey-blake2

# copy the example backupscript as SYSTEM user
cp -rf /backupscript.example /backupscript
# just to be sure
chmod 700 /backupscript
# /backupscript is now SYSTEM owned, to edit it with e.g. Notepad++.
# You may have to close Notepad++, if it's already running as non SYSTEM user
"`cygpath 'C:\Program Files\Notepad++'`/Notepad++" "`cygpath -w /backupscript`"
```
You want to edit (use an editor with linux line endings support like Notepad++) the backupscript to stop your services (if any) and add your directories you want to backup. This script contains code to create and mount (or link in the windows world) a shadow copy to a given directory, perform the backup and destroy the shadow. I reccomend using ``SHADOWC_PATH=`cygpath "C:\\ShadowC"` `` and then e.g. `${SHADOWC_PATH/Users}` as a backup path in _borg create_ command.

**backupscript**:
``` bash
#!/bin/bash
PS=`cygpath -S`"/WindowsPowerShell/v1.0/powershell.exe"
NET=`cygpath -S`"/net.exe"
CMD=`cygpath -S`"/cmd.exe"

# Setting this, so the repo does not need to be given on the commandline:
export BORG_REPO=ssh://username@example.com:2022/~/backup/main

# Setting this, so you won't be asked for your repository passphrase:
export BORG_PASSPHRASE='XYZl0ngandsecurepa_55_phrasea&&123'

#Stop / Start Services 
function services_stop {
	$NET stop mysql
}
function services_start {
	$NET start mysql
}

function vss_create {
	SHADOWID1=$(vss_create_shadow "C:\\")
	vss_mount_shadow $SHADOWID1 "C:\\ShadowC"
}
function vss_delete {
	vss_remove_shadow $SHADOWID1 "C:\\ShadowC"
}

function borg_backup {
SHADOWC_PATH=`cygpath C:\\ShadowC`
borg create                         \
    --verbose                       \
    --filter AME                    \
    --list                          \
    --stats                         \
    --show-rc                       \
    --compression lz4               \
                                    \
    ::'{hostname}-{now}'            \
    ${SHADOWC_PATH}/Users                            \
	
}

function borg_prune {
}

#Helper Functions
vss_create_shadow () {
	PSC="\$s1 = (Get-WmiObject -List Win32_ShadowCopy).Create(\"$1\", \"ClientAccessible\"); Write-Host \$s1.ShadowID -NoNewLine"
	$PS -Command "$PSC"
}

vss_mount_shadow () {
	PSC="\$s2 = Get-WmiObject Win32_ShadowCopy | Where-Object { \$_.ID -eq \"$1\" }; \$d  = \$s2.DeviceObject + '\'; Write-Host \$d -NoNewLine"
	DEVICEOBJECT=`$PS -Command "$PSC"`
	cmd /c mklink /d $2 "$DEVICEOBJECT"
}

vss_remove_shadow () {
	cmd /c rmdir /q $2
	PSC="\$s2 = Get-WmiObject Win32_ShadowCopy | Where-Object { \$_.ID -eq \"$1\" }; \$s2.Delete()"
	$PS -Command "$PSC"
}

#Execute Backup
services_stop
trap 'services_start' INT TERM
vss_create
trap 'services_start; vss_delete' INT TERM
services_start
trap 'vss_delete' INT TERM
borg_backup
vss_delete
trap - INT TERM
borg_prune
```

Try the initial backup by executing `/backupscript`, and if it works out you may create a windows planned task executing the `backupscript.bat` as SYSTEM user. This will call `/backupscript` in the user environement.

---
## Build Borg Installer
* The only prerequisite is NSIS installed, available at http://nsis.sourceforge.net/Download
* About 3 GB free disk space required to build installer
Create the build environment by using bootstrap.bat
You then may proceed to run build_installer_64.bat and/or build_installer_32.bat, to create the run environment and the corresponding installer.

The install script first builds borg inside temporary build/ARCH subfolder, then installs a much smaller release version into the run/ARCH subfolder. Built packages are copied over, unnecessary files removed (still room for improvement), and then NSIS is run and put into dist folder.

Tested with CygWin 2.10.0, borgbackup 1.1.6 on Windows 8.1 64-bit.