#!/bin/bash
if [ $# -lt 1 ] || [ $1 == "-h" ]; then
  echo -en "\
Usage:\n\
pit [name] [gitargs]\n\
	execute 'git gitargs' on pit archive with name 'name'\n\
pit -init name\n\
	create a pit archive with name 'name' (optionally based on a file with same name)\n\
pit -pack name [path]\n\
	pack git folder at 'path' into pit archive with name 'name'\n\
pit -add name file\n\
	add file named 'file' to pit archive 'name'\n\
"
  exit 0
fi
TDIR=`mktemp -d`
WD=`pwd`
function repack() {
  tar cf $ARCHIVE . 2>/dev/null
  cd $WD
  cp -p $TDIR/$ARCHIVE .
  if  [ ! cmp $FILE $TDIR/$FILE >/dev/null 2>&1 ]  ||  [ $FILE -nt $TDIR/$FILE ] || [ $FILE -ot $TDIR/$FILE ]
  then
    echo "pit: git call changed file => updating  $WD/$FILE" 
    cp -p $TDIR/$FILE 
  fi  
}
#--------------------------------------------------
if [ $1 == "init" ]
then
  ABORT="false"
  if [ ! -f $2 ]
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
      touch $2
      ABORT="false"
    elif [ $ANSWER == "n" ]
    then
      ABORT="false"
    fi
  fi
  OK="y"
  if [ -f .$2.pit ] && [ $ABORT != "true" ]
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
    FILE=$2
    ARCHIVE=.$FILE.pit
    cp -p  $FILE $TDIR
    cd $TDIR
    git init
    git add $FILE
    git commit -am "inital commit"
    tar cf $ARCHIVE . 2>/dev/null
    cd $WD
    cp -p $TDIR/$ARCHIVE .
  fi
#--------------------------------------------------
elif [ $1 == "pack" ]
then
  ARCHIVE=.$2.pit
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
elif [ $1 == "add" ]
then
  ARCHIVE=.$2.pit
  FILE=$3
  tar xf $ARCHIVE -C $TDIR/
  cp -p $FILE $TDIR/
  cd $TDIR
  git add $FILE
  git commit -am "added file $FILE"
  repack
  
#--------------------------------------------------
else
  if [ -f $1 ]
  then 
    if [ -f .$1.pit ]
    then
      FILE=$1
      ARCHIVE=.$1.pit
      tar xf $ARCHIVE -C $TDIR/
      cp -p $FILE $TDIR/
      cd $TDIR
      echo ${@:2}
      git ${@:2}
      repack 
      #tar cf $ARCHIVE . 2>/dev/null
      #cd $WD
      #cp -p $TDIR/$ARCHIVE .
      #if  [ ! cmp $FILE $TDIR/$FILE >/dev/null 2>&1 ]  ||  [ $FILE -nt $TDIR/$FILE ] || [ $FILE -ot $TDIR/$FILE ]
      #then
      #  echo "pit: git call changed file => updating  $WD/$FILE" 
      #  cp -p $TDIR/$FILE .
      #fi
    else
      echo "Corresponding pit archive not found. You might create an archive by pit -init $1"
    fi
  else
    echo "$1 is not a existing file. You need to create it first!"
  fi
fi
rm -rf $TDIR
