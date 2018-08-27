; Borg Backup Installer
; Billy Charlton <sfbilly@gmail.com>
; Anton Engelhardt <anton@neednow.de>
; --------------------------

!include LogicLib.nsh

;!define VERSION "1.1.16"
!define VERSION_LONG "${VERSION}.0"

!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\BorgBackupUnofficial"

; ------------
; use "Modern" UI
;!define MUI_ICON "console.ico"
!include "MUI2.nsh"
!insertmacro MUI_LANGUAGE "English"
!define MUI_PAGE_HEADER_TEXT "Borg Backup"

!addincludedir "."
!addplugindir "."

; The name of the installer
Name "Borg Backup ${VERSION} ${ARCH}"

; The file to write
OutFile "Borg Backup Installer v${VERSION} ${ARCH}.exe"


InstallDir "C:\Program Files${PRGM_SUFFIX}\Borg"


; Registry key to check for directory (so if you install again, it will
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\BorgBackupUnofficial" "InstallPath"

; Request application privileges for Windows Vista
RequestExecutionLevel admin

VIProductVersion "${VERSION_LONG}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "BorgBackupUnofficial"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "${VERSION_LONG}"

;--------------------------------

; Pages

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES


;--------------------------------
; Main installer tasks
Section "Borg Backup (required)"

  SectionIn RO
  SetOutPath $INSTDIR

  ; Unzip everything
  File /nonfatal /a /r "${ARCH}\"

  ; Write the installation path into the registry
  WriteRegStr HKLM "Software\BorgBackupUnofficial" "InstallPath" "$INSTDIR"

  ; Write the uninstall keys
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "DisplayName" "Borg Backup ${ARCH}"
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${VERSION_LONG}"
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "Publisher" "BorgBackup Unofficial"
  WriteRegDWORD HKLM "${PRODUCT_UNINST_KEY}" "EstimatedSize" "200000"
  WriteRegDWORD HKLM "${PRODUCT_UNINST_KEY}" "NoModify" 1
  WriteRegDWORD HKLM "${PRODUCT_UNINST_KEY}" "NoRepair" 1
  WriteUninstaller "uninstall.exe"

  ; ------------------------------
  ; create borg.bat in install dir
  FileOpen $4 "$INSTDIR\borg.bat" w
  FileWrite $4 `@"$INSTDIR\bin\bash" --login -c "cd \"$$(cygpath '%cd%')\"; /bin/borg %*"`
  FileClose $4

  ; ------------------------
  ; Create Shortcuts
  SetOutPath "$INSTDIR"
  CreateShortCut "$DESKTOP\Borg Console.lnk" \
                 "$INSTDIR\bin\mintty.exe" "-i /Cygwin.ico -" \
                 "$INSTDIR\bin\mintty.exe"
  CreateShortCut "$INSTDIR\Borg Console.lnk" \
                 "$INSTDIR\bin\mintty.exe" "-i /Cygwin.ico -" \
                 "$INSTDIR\bin\mintty.exe"

  ; ----------------
  ; Start Menu Shortcuts
  CreateDirectory "$SMPROGRAMS\Borg Backup"
  CreateShortCut "$SMPROGRAMS\Borg Backup\Borg Console.lnk" \
                 "$INSTDIR\bin\mintty.exe" "-i /Cygwin.ico -" \
                 "$INSTDIR\bin\mintty.exe"
  CreateShortCut "$SMPROGRAMS\Borg Backup\Uninstall.lnk" \
                 "$INSTDIR\uninstall.exe" "" \
                 "$INSTDIR\uninstall.exe" 0

  ; --------
  ; Add to PATH
  Push "$INSTDIR"
  Call AddToPath

SectionEnd


Section "Uninstall"
  ; Remove from PATH
  Push "$INSTDIR"
  Call un.RemoveFromPath

  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\BorgBackupUnofficial"
  DeleteRegKey HKLM "Software\BorgBackupUnofficial"

  ; Remove shortcuts
  Delete "$SMPROGRAMS\Borg Backup\*.*"
  Delete "$DESKTOP\Borg Console.lnk"
  RMDir "$SMPROGRAMS\Borg Backup"

  ; Remove files and uninstaller
  Delete "$INSTDIR\borg.bat"
  Delete "$INSTDIR\Borg Console.lnk"
  Delete "$INSTDIR\Cygwin.bat"
  Delete "$INSTDIR\Cygwin.ico"
  Delete "$INSTDIR\Cygwin-Terminal.ico"
  Delete "$INSTDIR\uninstall.exe"
  RMDir /r "$INSTDIR\bin"
  RMDir /r "$INSTDIR\dev"
  RMDir /r "$INSTDIR\etc"
  RMDir /r "$INSTDIR\lib"
  RMDir /r "$INSTDIR\tmp"
  RMDir /r "$INSTDIR\usr"
  RMDir /r "$INSTDIR\var"
  RMDir "$INSTDIR"

SectionEnd

;--------------------------------------------------------------------
; Path functions
;
; Based on example from:
; http://nsis.sourceforge.net/Path_Manipulation
;


!include "WinMessages.nsh"

; Registry Entry for environment (NT4,2000,XP)
; All users:
;!define Environ 'HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'
; Current user only:
!define Environ 'HKCU "Environment"'


; AddToPath - Appends dir to PATH
;   (does not work on Win9x/ME)
;
; Usage:
;   Push "dir"
;   Call AddToPath

Function AddToPath
  Exch $0
  Push $1
  Push $2
  Push $3
  Push $4

  ; NSIS ReadRegStr returns empty string on string overflow
  ; Native calls are used here to check actual length of PATH

  ; $4 = RegOpenKey(HKEY_CURRENT_USER, "Environment", &$3)
  System::Call "advapi32::RegOpenKey(i 0x80000001, t'Environment', *i.r3) i.r4"
  IntCmp $4 0 0 done done
  ; $4 = RegQueryValueEx($3, "PATH", (DWORD*)0, (DWORD*)0, &$1, ($2=NSIS_MAX_STRLEN, &$2))
  ; RegCloseKey($3)
  System::Call "advapi32::RegQueryValueEx(i $3, t'PATH', i 0, i 0, t.r1, *i ${NSIS_MAX_STRLEN} r2) i.r4"
  System::Call "advapi32::RegCloseKey(i $3)"

  IntCmp $4 234 0 +4 +4 ; $4 == ERROR_MORE_DATA
    DetailPrint "AddToPath: original length $2 > ${NSIS_MAX_STRLEN}"
    MessageBox MB_OK "PATH not updated, original length $2 > ${NSIS_MAX_STRLEN}"
    Goto done

  IntCmp $4 0 +5 ; $4 != NO_ERROR
    IntCmp $4 2 +3 ; $4 != ERROR_FILE_NOT_FOUND
      DetailPrint "AddToPath: unexpected error code $4"
      Goto done
    StrCpy $1 ""

  ; Check if already in PATH
  Push "$1;"
  Push "$0;"
  Call StrStr
  Pop $2
  StrCmp $2 "" 0 done
  Push "$1;"
  Push "$0\;"
  Call StrStr
  Pop $2
  StrCmp $2 "" 0 done

  ; Prevent NSIS string overflow
  StrLen $2 $0
  StrLen $3 $1
  IntOp $2 $2 + $3
  IntOp $2 $2 + 2 ; $2 = strlen(dir) + strlen(PATH) + sizeof(";")
  IntCmp $2 ${NSIS_MAX_STRLEN} +4 +4 0
    DetailPrint "AddToPath: new length $2 > ${NSIS_MAX_STRLEN}"
    MessageBox MB_OK "PATH not updated, new length $2 > ${NSIS_MAX_STRLEN}."
    Goto done

  ; Append dir to PATH
  DetailPrint "Add to PATH: $0"
  StrCpy $2 $1 1 -1
  StrCmp $2 ";" 0 +2
    StrCpy $1 $1 -1 ; remove trailing ';'
  StrCmp $1 "" +2   ; no leading ';'
    StrCpy $0 "$1;$0"
  WriteRegExpandStr ${Environ} "PATH" $0
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000

done:
  Pop $4
  Pop $3
  Pop $2
  Pop $1
  Pop $0
FunctionEnd


; RemoveFromPath - Removes dir from PATH
;
; Usage:
;   Push "dir"
;   Call RemoveFromPath

Function un.RemoveFromPath
  Exch $0
  Push $1
  Push $2
  Push $3
  Push $4
  Push $5
  Push $6

  ReadRegStr $1 ${Environ} "PATH"
  StrCpy $5 $1 1 -1
  StrCmp $5 ";" +2
    StrCpy $1 "$1;" ; ensure trailing ';'
  Push $1
  Push "$0;"
  Call un.StrStr
  Pop $2 ; pos of our dir
  StrCmp $2 "" done

  DetailPrint "Remove from PATH: $0"
  StrLen $3 "$0;"
  StrLen $4 $2
  StrCpy $5 $1 -$4 ; $5 is now the part before the path to remove
  StrCpy $6 $2 "" $3 ; $6 is now the part after the path to remove
  StrCpy $3 "$5$6"
  StrCpy $5 $3 1 -1
  StrCmp $5 ";" 0 +2
    StrCpy $3 $3 -1 ; remove trailing ';'
  WriteRegExpandStr ${Environ} "PATH" $3
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000

done:
  Pop $6
  Pop $5
  Pop $4
  Pop $3
  Pop $2
  Pop $1
  Pop $0
FunctionEnd


; StrStr - find substring in a string
;
; Usage:
;   Push "this is some string"
;   Push "some"
;   Call StrStr
;   Pop $0 ; "some string"

!macro StrStr un
Function ${un}StrStr
  Exch $R1 ; $R1=substring, stack=[old$R1,string,...]
  Exch     ;                stack=[string,old$R1,...]
  Exch $R2 ; $R2=string,    stack=[old$R2,old$R1,...]
  Push $R3
  Push $R4
  Push $R5
  StrLen $R3 $R1
  StrCpy $R4 0
  ; $R1=substring, $R2=string, $R3=strlen(substring)
  ; $R4=count, $R5=tmp
  loop:
    StrCpy $R5 $R2 $R3 $R4
    StrCmp $R5 $R1 done
    StrCmp $R5 "" done
    IntOp $R4 $R4 + 1
    Goto loop
done:
  StrCpy $R1 $R2 "" $R4
  Pop $R5
  Pop $R4
  Pop $R3
  Pop $R2
  Exch $R1 ; $R1=old$R1, stack=[result,...]
FunctionEnd
!macroend
!insertmacro StrStr ""
!insertmacro StrStr "un."
