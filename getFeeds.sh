#!/bin/sh

curDir=`pwd`
cd ../
git clone http://git.openwrt.org/12.09/packages.git
cd $curDir
ln -s ../package feeds

