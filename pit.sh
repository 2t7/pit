#!/bin/bash
#pit - A (single file) archive wrapper around git
#Copyright (C) 2014  Martin Spiessl
#
#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.

if [ $# -lt 1 ] || [ $1 == "-h" ]; then
  echo -en "\
Usage:\n\
pit name [gitargv]\n\
	execute 'git gitargsv' on pit archive with name 'name'\n\
pit name -init\n\
	create a pit archive with name 'name' (optionally based on a file with same name)\n\
pit name -unpack [path]\n
	unpack pit archive to location at 'path' or if not specified the current directory\n
pit name -pack [path]\n\
	pack git folder at 'path' (or current directory if not specified) into pit archive with name 'name'\n\
pit name -add file\n\
	add file named 'file' to pit archive 'name'\n\
pit name -clone gitlocation\n\
	generates a pit archive from sources at gitlocation\n\
"
  exit 0
fi
TDIR=`mktemp -d`
WD=`pwd`
function repack() {
    tar cf $ARCHIVE . 2>/dev/null
    cd $WD
    TMPFILE1=`mktemp`
    TMPFILE2=`mktemp`
    tar tvf $TDIR/$ARCHIVE --full-time | grep -v "./\$"| sort > $TMPFILE1
    tar tvf $WD/$ARCHIVE --full-time | grep -v "./\$" | sort > $TMPFILE2
    cmp $TMPFILE1 $TMPFILE2 >/dev/null 2>&1
    CMP=$?
    if [ $CMP -ne 0 ]
    then
      cp -p $TDIR/$ARCHIVE . 
    fi
    rm $TMPFILE1 $TMPFILE2
    TLIST=`tar tf $TDIR/$ARCHIVE | grep -v "^./.git" | grep -v "./\$"`
    for F in $TLIST
    do
        F="${F#./}"
        cmp $F $TDIR/$F >/dev/null 2>&1
        CMP=$?
        if [ ! -z $F ] && [ $CMP -ne 0 ] 
        then
             echo "pit: git call changed $F => updating $WD/$F"
             cd $TDIR
             cp -ip --parents $F $WD/ 
             #cp -pv $F $WD/
             cd $WD
        fi
    done
}
#--------------------------------------------------
if [ $2 == "init" ]
then
    ABORT="false"
    if [ ! -f $1 ]
    then
        ABORT="true"
        echo -en "File does not exist. Create it?(y/n/A)"
        read ANSWER
        if [ -z "$ANSWER" ]
        then
            ANSWER="a"
        fi
        if [ $ANSWER == "y" ]
        then
            touch $1
            ABORT="false"
        elif [ $ANSWER == "n" ]
        then
            ABORT="false"
        fi
    fi
    OK="y"
    if [ -f .$1.pit ] && [ $ABORT != "true" ]
    then
        echo -en "\
pit archive aready existing.\n\
Are you sure you want to init a NEW pit archive?\n\
(This will overwrite the existing one!!!) (y/N)"
        read  OK
        if [ -z "$OK" ]
        then
            OK="n"
        fi
    fi
    if [ $OK == "y" ] && [ $ABORT != "true" ]
    then 
        FILE=$1
        ARCHIVE=.$FILE.pit
        cp -p  $FILE $TDIR
        cd $TDIR
        git init
        git add $FILE
        tar cf $ARCHIVE . 2>/dev/null
        cd $WD
        cp -p $TDIR/$ARCHIVE .
    fi
#--------------------------------------------------
elif [ $2 == "unpack" ]
then
    ARCHIVE=.$1.pit
    if [ $# -lt 2 ]
    then
        echo "wrong number of arguments. try 'pit name unpack [path]'"
    elif [ ! -f $ARCHIVE ]
    then
        echo "pit archive $ARCHIVE not found!"
    else
        if [ -z "$3" ]
        then
            tar -xf $ARCHIVE -C .
        else
            tar -xf $ARCHIVE -C $3
        fi
    fi
#--------------------------------------------------
elif [ $2 == "pack" ]
then
    ARCHIVE=.$1.pit
    cd $TDIR
    if [ $# -lt 3 ]; then
        git clone $WD .
    else
        git clone $3 . 
    fi
    tar cf $ARCHIVE . 2>/dev/null
    cd $WD
    cp -p $TDIR/$ARCHIVE .
#--------------------------------------------------
elif [ $2 == "add" ]
then
    ARCHIVE=.$1.pit
    FILE=$3
    tar xf $ARCHIVE -C $TDIR/
    cp -p $FILE $TDIR/
    cd $TDIR
    git add $FILE
    repack
#--------------------------------------------------
elif [ $2 == "clone" ]
then
    if [ $# -lt 3 ] || [ $# -gt 3 ]
    then
        echo -en "Wrong number of parameters, try \n pit name clone repository"
    else
        ARCHIVE=.$2.pit
        NAME=$2
        REPO=$3
        cd $TDIR
        git clone $REPO .
        pit pack $NAME $TDIR
        cp $TDIR/$ARCHIVE $WD
    fi
#--------------------------------------------------
elif [ $2 == "git" ]
then
    if [ -f .$1.pit ]
    then
        FILE=$1
        ARCHIVE=.$1.pit
        tar xf $ARCHIVE -C $TDIR/
        #TODO also copy all other modified files
        FLIST=`tar tf $ARCHIVE | grep -v "^./.git"  |grep -v "./\$"| sort`
        for F in $FLIST
        do
            if [ ! -e $F ]
            then
                rm -rf $TDIR/$F
            else
                cmp $F $TDIR/$F
                CMP=$?
                if [ $CMP -ne 0 ]
                then
                    cp -p --parents $F $TDIR/
                fi
            fi
        done
        #TODO-ende-
        #cp -p $FILE $TDIR/
        cd $TDIR
        git "${@:3}"
        repack 
    else
        echo "Corresponding pit archive not found. You might create an archive by pit init $1 init"
    fi
fi
rm -rf $TDIR
