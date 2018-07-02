# borg-cygwin
Borg: v1.1.6
Cygwin: latest online

##WARNING - This is a WIP, which technically works, but not fully documented.
As said, working on it.

Based on the work of Billy Charlton and digidream, scripting mostly done in bash, for obvious reasons.

This creates a standard Windows installer for Borg Backup on 64bit (and untested 32bit) Windows 7 and above.

* The only prerequisite is NSIS installed, available at http://nsis.sourceforge.net/Download
* About 3 GB free disk space required to build installer
* Borg install itself will only be ~85MB and require about 300MB on disk
* Tested on Windows 8.1 64-bit

---
Create the build environment by using bootstrap.bat
You then may proceed to run build_installer_64.bat and/or build_installer_32.bat, to create the run environment and the corresponding installer.

Updating verisons is not tested yet.

A backup script is included in the installation.
You can run this as SYSTEM user to avoid permission issues. ACL is not tested, as for my kind of backup it's irrelevant.

Then use borg like this, noting that all file paths are in Cygwin notation e.g. /cygdrive/c/path/to/my/files

```
borg init /cygdrive/D/Borg
borg create -C lz4 /cygdrive/D/Borg::Test /cygdrive/C/Photos/
```

The install script first builds borg inside temporary build/ARCH subfolder, then installs a much smaller release version into the run/ARCH subfolder. Built packages are copied over, unnecessary files removed (still room for improvement), and then NSIS is run and put into dist folder.

Tested with CygWin 2.10.0, borgbackup 1.1.6 on Windows 8.1 64-bit.
