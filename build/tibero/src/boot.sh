#!/bin/sh

clean_tac() {
    :
}

init_hdfs() { 
    if [ -d $HADOOP_HOME ]; then
        echo "Hadoop already exists."
    else
        sh $SRC_HOME/hadoop/install.sh;
    fi
}

set_value() {

   cp $SRC_HOME/env ~/.bashrc
    . ~/.bashrc

    if [ -d $TB_HOME/database ]; then
        :
    else
        echo "export cnt=0"> $TB_VOLUME/cnt
        chmod +x $TB_VOLUME/cnt
    fi

    ### Value.yaml 파일로 이동 필요
    export tas_disk_size=2
    export tas_disk_cnt=4
    export tas_redun=2
    export tas_disk=$TB_HOME/database
    ##############################

    if [ $tas_redun -eq 1 ]; then
        redun="EXTERNAL"
    elif [ $tas_redun -eq 2 ]; then
        redun="NORMAL"
    else
        redun="HIGH"
    fi

    export dd_bs=$(($tas_disk_size * 1024))

    . $TB_VOLUME/cnt
    export CM_SID=cm$cnt 
}

init_tb() {
    tar -xzf $SRC_HOME/tibero/*.tar.gz -C $TB_VOLUME/
    cp $SRC_HOME/tibero/license.xml $TB_HOME/license/license.xml
    cp -r $SRC_HOME/client $TB_VOLUME/
    mkdir -p $TB_HOME/hd
}

create_cm_tip() {
    echo CM_NAME=cm$cnt >> $CM_HOME/config/cm$cnt.tip
    echo CM_UI_PORT=11000 >> $CM_HOME/config/cm$cnt.tip
    echo CM_RESOURCE_FILE=$CM_HOME/cm$cnt.res >> $CM_HOME/config/cm$cnt.tip
}

create_tas_tip() {
    echo LISTENER_PORT=14000 >> $TB_HOME/config/tas$cnt.tip
    echo THREAD=$cnt >> $TB_HOME/config/tas$cnt.tip
    echo CM_PORT=11000 >> $TB_HOME/config/tas$cnt.tip
    echo LOCAL_CLUSTER_PORT=13000 >> $TB_HOME/config/tas$cnt.tip
    echo TOTAL_SHM_SIZE=${TOTAL_SHM_SIZE}G >> $TB_HOME/config/tas$cnt.tip
    echo MEMORY_TARGET=${MEMORY_TARGET}G >> $TB_HOME/config/tas$cnt.tip
    echo MAX_SESSION_COUNT=$MAX_SESSION_COUNT >> $TB_HOME/config/tas$cnt.tip
    echo CLUSTER_DATABASE=Y >> $TB_HOME/config/tas$cnt.tip
    echo BOOT_WITH_AUTO_DOWN_CLEAN=Y >> $TB_HOME/config/tas$cnt.tip
    echo LOCAL_CLUSTER_ADDR=$IP_ADDR >> $TB_HOME/config/tas$cnt.tip
    echo _SLEEP_ON_SIG=Y >> $TB_HOME/config/tas$cnt.tip
    echo INSTANCE_TYPE=AS >> $TB_HOME/config/tas$cnt.tip
    echo AS_ALLOW_ONLY_RAW_DISKS=N >> $TB_HOME/config/tas$cnt.tip
    echo AS_DISKSTRING='"'$tas_disk/*'"' >> $TB_HOME/config/tas$cnt.tip
    echo _ACF_NMGR_MAX_NODES=10 >>  $TB_HOME/config/tas$cnt.tip
}

create_tac_tip() {
    echo LISTENER_PORT=10000 >> $TB_HOME/config/tac$cnt.tip
    echo AS_PORT=14000 >> $TB_HOME/config/tac$cnt.tip
    echo CM_PORT=11000 >> $TB_HOME/config/tac$cnt.tip
    echo LOCAL_CLUSTER_PORT=12000 >> $TB_HOME/config/tac$cnt.tip
    echo THREAD=$cnt >> $TB_HOME/config/tac$cnt.tip
    echo UNDO_TABLESPACE=UNDO$cnt >> $TB_HOME/config/tac$cnt.tip
    echo DB_NAME=tac  >> $TB_HOME/config/tac$cnt.tip
    echo LOCAL_CLUSTER_ADDR=$IP_ADDR  >> $TB_HOME/config/tac$cnt.tip
    echo CONTROL_FILES=+DS0/c1.ctl  >> $TB_HOME/config/tac$cnt.tip
    echo DB_CREATE_FILE_DEST=+DS0  >> $TB_HOME/config/tac$cnt.tip
    echo LOG_ARCHIVE_DEST=+DS0/archive  >> $TB_HOME/config/tac$cnt.tip
    echo TOTAL_SHM_SIZE=${TOTAL_SHM_SIZE}G  >> $TB_HOME/config/tac$cnt.tip
    echo MEMORY_TARGET=${MEMORY_TARGET}G  >> $TB_HOME/config/tac$cnt.tip
    echo MAX_SESSION_COUNT=$MAX_SESSION_COUNT >> $TB_HOME/config/tac$cnt.tip
    echo THROW_WHEN_GETTING_OSSTAT_FAIL=N >> $TB_HOME/config/tac$cnt.tip
    echo BOOT_WITH_AUTO_DOWN_CLEAN=Y >> $TB_HOME/config/tac$cnt.tip
    echo _ALLOW_DIFF_CHARSET_INSTANCE=Y >> $TB_HOME/config/tac$cnt.tip
    echo _SLEEP_ON_SIG=Y  >> $TB_HOME/config/tac$cnt.tip
    echo USE_ACTIVE_STORAGE=Y  >> $TB_HOME/config/tac$cnt.tip
    echo CLUSTER_DATABASE=Y  >> $TB_HOME/config/tac$cnt.tip
    echo _ACF_NMGR_MAX_NODES=10 >>  $TB_HOME/config/tac$cnt.tip
}

create_tbdsn() {
    echo "tas$cnt=((INSTANCE=(HOST=$IP_ADDR)(PORT=14000)(DB_NAME=tas)))" >> $TB_HOME/client/config/tbdsn.tbr
    echo "tac$cnt=((INSTANCE=(HOST=$IP_ADDR)(PORT=10000)(DB_NAME=tac)))"  >> $TB_HOME/client/config/tbdsn.tbr
}

create_1st_sql() {
    echo "create database \"tac\"" >> $TB_HOME/hd/tac$cnt.sql
    echo "user sys identified by tibero" >> $TB_HOME/hd/tac$cnt.sql
    echo "maxinstances 10" >> $TB_HOME/hd/tac$cnt.sql
    echo "maxdatafiles 200" >> $TB_HOME/hd/tac$cnt.sql
    echo "character set UTF8" >> $TB_HOME/hd/tac$cnt.sql
    echo "logfile group 0 '+DS0/log000.log' size 50m," >> $TB_HOME/hd/tac$cnt.sql
    echo "group 1 '+DS0/log001.log' size 50m," >> $TB_HOME/hd/tac$cnt.sql
    echo "group 2 '+DS0/log002.log' size 50m" >> $TB_HOME/hd/tac$cnt.sql
    echo "maxloggroups 255" >> $TB_HOME/hd/tac$cnt.sql
    echo "maxlogmembers 8" >> $TB_HOME/hd/tac$cnt.sql
    echo "noarchivelog" >> $TB_HOME/hd/tac$cnt.sql
    echo "datafile '+DS0/system001.dtf' size 100M" >> $TB_HOME/hd/tac$cnt.sql
    echo "autoextend on next 10M maxsize unlimited" >> $TB_HOME/hd/tac$cnt.sql
    echo "default tablespace usr" >> $TB_HOME/hd/tac$cnt.sql
    echo "datafile '+DS0/usr.dtf' size 100M" >> $TB_HOME/hd/tac$cnt.sql
    echo "autoextend on next 10M" >> $TB_HOME/hd/tac$cnt.sql
    echo "extent management local autoallocate" >> $TB_HOME/hd/tac$cnt.sql
    echo "default temporary tablespace TEMP" >> $TB_HOME/hd/tac$cnt.sql
    echo "tempfile '+DS0/temp001.dtf' size 100M" >> $TB_HOME/hd/tac$cnt.sql
    echo "autoextend on next 10M" >> $TB_HOME/hd/tac$cnt.sql
    echo "extent management local autoallocate" >> $TB_HOME/hd/tac$cnt.sql
    echo "undo tablespace UNDO0" >> $TB_HOME/hd/tac$cnt.sql
    echo "datafile '+DS0/undo000.dtf' size 100M" >> $TB_HOME/hd/tac$cnt.sql
    echo "autoextend on next 10M" >> $TB_HOME/hd/tac$cnt.sql
    echo "extent management local autoallocate;" >> $TB_HOME/hd/tac$cnt.sql
    echo "quit;" >> $TB_HOME/hd/tac$cnt.sql
    
    mkdir -p $tas_disk
    
    i=1
    while [ $i -le $tas_disk_cnt ]; do
        dd if=/dev/zero of=$tas_disk/disk$i bs=$dd_bs count=1048576
        chmod 755 $tas_disk/disk$i
        i=$((i+1))
    done
    
    echo CREATE DISKSPACE DS0 $redun REDUNDANCY >> $TB_HOME/hd/tas$cnt.sql
    echo CREATE DISKSPACE DS0 FORCE $redun REDUNDANCY >> $TB_HOME/hd/tas${cnt}_force.sql
    
    disk_no=1
    i=1
    while [ $i -le $tas_redun  ]; do
        echo "FAILGROUP FG$i DISK" >> $TB_HOME/hd/tas$cnt.sql
        echo "FAILGROUP FG$i DISK" >> $TB_HOME/hd/tas${cnt}_force.sql
    
        j=1
        while [ $j -le `expr $tas_disk_cnt / $tas_redun`  ]; do
            if [ $j -eq `expr $tas_disk_cnt / $tas_redun`  ]; then
                echo "'$tas_disk/disk$disk_no' NAME FG${i}_DISK${j}" >> $TB_HOME/hd/tas$cnt.sql
                echo "'$tas_disk/disk$disk_no' NAME FG${i}_DISK${j}" >> $TB_HOME/hd/tas${cnt}_force.sql
            else
                echo "'$tas_disk/disk$disk_no' NAME FG${i}_DISK${j}," >> $TB_HOME/hd/tas$cnt.sql
                echo "'$tas_disk/disk$disk_no' NAME FG${i}_DISK${j}," >> $TB_HOME/hd/tas${cnt}_force.sql
            fi
            disk_no=`expr $disk_no + 1`
            j=$((j+1))
        done
        i=$((i+1))
    done
    
    echo ";" >> $TB_HOME/hd/tas$cnt.sql
    echo ";" >> $TB_HOME/hd/tas${cnt}_force.sql

    echo "quit;" >> $TB_HOME/hd/tas$cnt.sql
    echo "quit;" >> $TB_HOME/hd/tas${cnt}_force.sql
}

create_1st() {
    export TB_SID=tac0 
    tbcm -b
    sleep 2

    cmrctl add network --nettype private --ipaddr $IP_ADDR --portno 15000 --name net1
    cmrctl add cluster --incnet net1  --cfile "+$tas_disk/*" --name cls1

    export TB_SID=tas0 
    tbboot nomount
    sleep 2

    tbsql sys/tibero@tas0 @$TB_HOME/hd/tas$cnt.sql
    tbsql sys/tibero@tas0 @$TB_HOME/hd/tas${cnt}_force.sql

    cmrctl start cluster --name cls1
    sleep 2
    cmrctl add service --name tas --type as --cname cls1
    sleep 2
    cmrctl add service --name tac --cname cls1
    sleep 2

    cmrctl add as --name tas0 --svcname tas --dbhome $CM_HOME
    cmrctl add db --name tac0 --svcname tac --dbhome $CM_HOME

    export TB_SID=tas0 
    tbboot
    sleep 2

    export TB_SID=tac0 
    tbboot nomount

    tbsql sys/tibero@tac0 @$TB_HOME/hd/tac$cnt.sql

    tbboot
    sleep 2

    sh $TB_HOME/scripts/system.sh -p1 tibero -p2 syscat -a1 y -a2 y -a3 y -a4 y
}

create_other_sql() {
    echo "alter diskspace DS0 add thread $cnt;" >> $TB_HOME/hd/tas$cnt.sql
    echo "quit;" >> $TB_HOME/hd/tas$cnt.sql

    group_no1=`expr $cnt \* 3`
    group_no2=`expr $group_no1 + 1`
    group_no3=`expr $group_no1 + 2`


    echo "create undo tablespace undo${cnt} datafile '+DS0/undo00${cnt}.dtf' size 100M autoextend on next 10m;" >> $TB_HOME/hd/tac$cnt.sql

    echo "alter database add logfile THREAD $cnt group $group_no1 '+DS0/log00${group_no1}.log' size 50M;" >> $TB_HOME/hd/tac$cnt.sql
    echo "alter database add logfile THREAD $cnt group $group_no2 '+DS0/log00${group_no2}.log' size 50M;" >> $TB_HOME/hd/tac$cnt.sql
    echo "alter database add logfile THREAD $cnt group $group_no3 '+DS0/log00${group_no3}.log' size 50M;" >> $TB_HOME/hd/tac$cnt.sql

    echo "alter database ENABLE PUBLIC THREAD $cnt;" >> $TB_HOME/hd/tac$cnt.sql
    echo "quit;" >> $TB_HOME/hd/tac$cnt.sql
}

create_other() {   
    tbsql sys/tibero@tas0 @$TB_HOME/hd/tas$cnt.sql
    tbsql sys/tibero@tac0 @$TB_HOME/hd/tac$cnt.sql

    tbcm -b
    sleep 2

    cmrctl add network --nettype private --ipaddr $IP_ADDR --portno 15000 --name net1
    cmrctl add cluster --incnet net1  --cfile "+$tas_disk/*" --name cls1
    
    cmrctl start cluster --name cls1
    sleep 2

    cmrctl add as --name tas$cnt --svcname tas --dbhome $CM_HOME
    cmrctl add db --name tac$cnt --svcname tac --dbhome $CM_HOME

    export TB_SID=tas$cnt 
    tbboot
    sleep 2

    export TB_SID=tac$cnt 
    tbboot
    sleep 5
}

update_cnt() {
    echo "export cnt=`expr $cnt + 1`" > $TB_VOLUME/cnt
}

### MAIN
init_hdfs
set_value

if [ -d $TB_HOME/database ]; then
    :
else
    init_tb
fi

create_cm_tip
create_tas_tip
create_tac_tip
create_tbdsn

if [ -d $TB_HOME/database ]; then
    create_other_sql
    create_other
else
    create_1st_sql
    create_1st
fi

update_cnt