#!/bin/sh
TDIR=`mktemp -d`
WD=`pwd`
if [ $1 ==  "-init" ]
then
  if [ -f $2 ]
  then
    OK="y"
    if [ -f .$2.pit ]
    then
      echo -en "\
pit archive aready existing.\n\
Are you sure you want to init a NEW pit archive?\n\
(This will overwrite the existing one!!!) (y/N)"
      read  OK
    fi
    if [ $OK == "y" ]
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
  fi 
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
      #now we have to update the archive and our script file if git changed it:
      tar cf $ARCHIVE . 2>/dev/null
      cd $WD
      #TODO check for a way to avoid archive copy if it is up to date
      #maybe second answer to http://stackoverflow.com/questions/1030545/how-to-compare-two-tarballs-content
      cp -p $TDIR/$ARCHIVE .
      if  [ ! cmp $FILE $TDIR/$FILE >/dev/null 2>&1 ]  ||  [ $FILE -nt $TDIR/$FILE ] || [ $FILE -ot $TDIR/$FILE ]
      then
        echo "pit: git call changed file => updating  $WD/$FILE" 
        cp -p $TDIR/$FILE .
      fi
    else
      echo "Corresponding pit archive not found. You might create an archive by pit -init $1"
    fi
  else
    echo "$1 is not a existing file. You need to create it first!"
  fi
fi
rm -rf $TDIR
