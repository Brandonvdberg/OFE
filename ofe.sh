#!/bin/bash

## Objection File Extractor ##
## Its super hacky but it works.... most of the time :D

################################## Change me ##################################
# Package identifier
ID="com.mobile.appName"
# App directory path on device - must end with a slash /
PATH="/data/user/0/com.mobile.appName/"

# Local binary location - update it
OBJECTION="/home/kali/.local/bin/objection"
FRIDAPS="/home/kali/.local/bin/frida-ps"

# Exclude Files
# Some files break/crash Objection when you try download them. Add the full path to the exclude file, example: 
# /var/mobile/Containers/Data/Application/442124AD-57CD-43C1-12D4-10119999/Documents/brokenfile.txt
EXCLUDE="$(pwd)/exclude.txt"
###############################################################################

# Binaries
MKDIR="/usr/bin/mkdir"
GREP="/usr/bin/grep"
AWK="/usr/bin/awk"
CAT="/usr/bin/cat"
SED="/usr/bin/sed"
RM="/usr/bin/rm"
FIND="/usr/bin/find"
WC="/usr/bin/wc"

PID=$($FRIDAPS -Uai | $GREP $ID | $AWK '{print $1}')
BASE=$(pwd)

function fileDownload() {
  while IFS= read -r FILE
  do
    echo $FILE | $GREP -E '[[:alpha:]] [[:alpha:]]' &>/dev/null && FILE=$(echo $FILE | $SED 's/\([[:alpha:]]\) \([[:alpha:]]\)/\1\\ \2/g')
    $GREP -Fxq "$1/$FILE" $EXCLUDE &>/dev/null && echo "$FILE excluded, SKIPPING!" || $OBJECTION -g $PID run file download "$1/$FILE" "$FILE"; [[ $(echo $?) == 1 ]] && echo "Unable to download: $1/$FILE" >> ${BASE}/error-log.txt
    echo "$1/$FILE" >> ${BASE}/download-log.txt
  done < OBJECTIONFILES.txt
}

function dirLoop() {
  while IFS= read -r SUBDIR
  do	
    echo "$SUBDIR"
    $MKDIR "$SUBDIR"
    pushd "$SUBDIR"

    LWORKDIR=$(pwd | $AWK -F "$MAINDIR" '{print $2}')
    RWORKDIR="$PATH$MAINDIR$LWORKDIR"

    $OBJECTION -g $PID run ls $RWORKDIR > OBJECTIONDIRROOT.txt
    $GREP -E "^Directory" OBJECTIONDIRROOT.txt | $AWK -v awkVar="$DIRNUM" '{print substr($0, index($0, $awkVar))}' > OBJECTIONDIR.txt
    $GREP -E "^Regular" OBJECTIONDIRROOT.txt | $AWK -v awkVar="$DIRNUM" '{print substr($0, index($0, $awkVar))}' > OBJECTIONFILES.txt
    $GREP -E "^File" OBJECTIONDIRROOT.txt | $AWK -v awkVar="$DIRNUM" '{print substr($0, index($0, $awkVar))}' >> OBJECTIONFILES.txt

    fileDownload "$RWORKDIR"

    if [[ -s OBJECTIONDIR.txt ]]
    then
      echo "Currently: $LWORKDIR"
      echo ""
      dirLoop
      popd
    else
      popd
    fi
  done < OBJECTIONDIR.txt
}

function main() {
  $OBJECTION -g $PID run ls $PATH > OBJECTIONDIRROOT.txt
  $GREP -E "^Directory" OBJECTIONDIRROOT.txt | $AWK -v awkVar="$DIRNUM" '{print substr($0, index($0, $awkVar))}' > OBJECTIONDIR.txt
  $GREP -E "^Regular" OBJECTIONDIRROOT.txt | $AWK -v awkVar="$DIRNUM" '{print substr($0, index($0, $awkVar))}' > OBJECTIONFILES.txt
  $GREP -E "^File" OBJECTIONDIRROOT.txt | $AWK -v awkVar="$DIRNUM" '{print substr($0, index($0, $awkVar))}' >> OBJECTIONFILES.txt
    
  for MAINDIR in $($CAT OBJECTIONDIR.txt)
  do	
    $MKDIR -p $MAINDIR
    cd $MAINDIR
    $OBJECTION -g $PID run ls $PATH$MAINDIR > OBJECTIONDIRROOT.txt
    $GREP -E "^Directory" OBJECTIONDIRROOT.txt | $AWK -v awkVar="$DIRNUM" '{print substr($0, index($0, $awkVar))}' > OBJECTIONDIR.txt
    $GREP -E "^Regular" OBJECTIONDIRROOT.txt | $AWK -v awkVar="$DIRNUM" '{print substr($0, index($0, $awkVar))}' > OBJECTIONFILES.txt
    $GREP -E "^File" OBJECTIONDIRROOT.txt | $AWK -v awkVar="$DIRNUM" '{print substr($0, index($0, $awkVar))}' >> OBJECTIONFILES.txt
    LWORKDIR=$(pwd | $AWK -F "$MAINDIR" '{print $2}')
    RWORKDIR="$PATH$MAINDIR$LWORKDIR"
        
    fileDownload "$RWORKDIR"
    dirLoop
    cd $BASE
    
    #Clear popd stack
    while [ "$(dirs | $WC -l)" -gt 1 ]; do
    popd > /dev/null
    done
  done
    
  # Clean up
  $FIND . -iname "OBJECTIONDIR.txt" -exec $RM {} \;
  $FIND . -iname "OBJECTIONDIRROOT.txt" -exec $RM {} \;
  $FIND . -iname "OBJECTIONFILES.txt" -exec $RM {} \;
}

echo ""
read -p "Android or iOS? [a/i]?" PLATFORM
echo ""
case $PLATFORM in
  A|a)
    DIRNUM=10
    main
  ;;
  I|i)
    DIRNUM=15
    main
  ;;
  *)
    echo "No valid input given, computer says no..."
    exit 1
  ;;
esac
