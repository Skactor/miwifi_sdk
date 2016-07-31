software_for_miwifi

This is for Xiaomi Router(R1D, R2D, etc.) 

Pre-installed

    sudo apt-get install zip unzip build-essential cmake subversion libncurses5-dev zlib1g-dev gawk gcc-multilib flex git-core gettext libssl-dev autoconf zlib1g:i386 libelf1:i386 libstdc++6:i386 libxml-parser-perl lzma automake1.11 bison ia32-libs 

To compile

    make V=s # compile world and index
    make package/comile # compile package
    make V=s -j=99 IGNORE_ERRORS=m # compile quickly and ignore errors 

To clean

    make clean
    make dirclean

This is based on [clean_openwrt_sdk](https://github.com/SmartXiaoMing/clean_openwrt_sdk.git)

Contact me(95813422ATqq.com)



