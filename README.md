# borg-cygwin

Based on the work of Billy Charlton and digidream

This creates a standard Windows installer for Borg Backup on 64bit (propably also 32bit) Windows 7 and above.

* The only prerequisite is NSIS installed, available at http://nsis.sourceforge.net/Download
* About 3 GB free disk space required to build installer
* Borg install itself will only be ~85MB and require about 300MB on disk
* Tested on Windows 8.1 64-bit

---
Create the build environment by using bootstrap.bat
You then may proceed to run build_installer_64.bat and/or build_installer_32.bat, to create the run environment and the corresponding installer.

Updating verisons is not tested yet.

A backup script is included in the installation.
I highly recommend to run the backup job as SYSTEM user, as permissions should not be an issue.

Then use borg like this, noting that all file paths are in Cygwin notation e.g. /cygdrive/c/path/to/my/files

```
borg init /cygdrive/D/Borg
borg create -C lz4 /cygdrive/D/Borg::Test /cygdrive/C/Photos/
```

The install script first builds borg inside temporary CygWin subfolder, then installs a much smaller release version into the Borg-installer subfolder. Built packages are copied over, unnecessary files removed, and then NSIS is run.

Tested with CygWin 2.4.1, borgbackup 1.0.0 on Windows 7 64-bit.
