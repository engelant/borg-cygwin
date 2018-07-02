@echo off
set BASEDIR=%~dp0%
cd build\x86_64
bin\bash --login -c 'BASE=`cygpath %BASEDIR:\=\\\\\\\\%`; INST=${BASE}/build_installer; chmod +x $INST; $INST $BASE x86_64'