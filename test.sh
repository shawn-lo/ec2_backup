#!/bin/sh

SIZE_IN_M=$(du -hsm . | awk '{print $1}')
echo $SIZE_IN_M
SIZE=`expr $SIZE_IN_M \\/ 1024`

if [ "$SIZE" = "0" ] 
then
    SIZE=`expr $SIZE \\+ 1`
fi
echo $SIZE
#SIZE=`expr $SIZE_IN_M \\/ 1024 \\+ 1 \\* 2`
#echo $SIZE
#RESULT=`expr $SIZE \\* 2`
#RESULT=$(expr $SIZE + $SIZE)
#echo $RESULT
