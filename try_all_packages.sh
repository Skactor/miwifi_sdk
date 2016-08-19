#! /bin/bash
if [[ $# -lt 1 ]]; then
    echo $0 feeds_pacakge_dir
fi

log_file=compile.result
cat /dev/null > $log_file
function read_dir(){
    for file in `ls $1`
    do
        path=$1"/"$file
        if [[ -d $path ]]; then
          if [[ -f $path"/Makefile" ]]; then
            echo $path
            pkgName=${path##*/}
            make V=s package/$pkgName/compile
            if [[ $? = 0 ]]; then
              echo "success $pkgName $path" >> $log_file
            else 
              echo "error $pkgName $path" >> $log_file
            fi
          else
            read_dir $path
          fi
        fi 
    done
}
read_dir $1 
