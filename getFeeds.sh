#!/bin/sh

curDir=`pwd`
cd ../
git clone git://git.openwrt.org/12.09/packages.git
cd $curDir
ln -s ../package feeds

