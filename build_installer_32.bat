@echo off
set BASEDIR=%~dp0%
cd build\x86
bin\bash --login -c 'BASE=`cygpath %BASEDIR:\=\\\\\\\\%`; INST=${BASE}/build_installer; chmod +x $INST; $INST $BASE x86'