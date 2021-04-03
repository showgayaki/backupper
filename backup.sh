#!/bin/bash
function backup_db(){
    DB_FILE="kakeibosan.db"
    DB_DIR="kakeibosan/models/"
    COPY_TARGET_DIR="/mnt/nas/_backup/_kakeibosan/"

    root=$(dirname $(cd $(dirname $0); pwd))"/"
    current=$(cd $(dirname $0); pwd)"/"
    log_file="${current}backup.log"
    
    write_log $log_file "INFO" "Backup Started."
    db_file_path=$root$DB_DIR$DB_FILE
    db_file_size=$(wc -c < ${db_file_path})

    # Backup対象ファイルがあったら実行、なければ終了
    if [[ -f $db_file_path ]]; then
        log="Backup target is exists. => [${db_file_path}]"
        write_log $log_file "INFO" "${log}"

	# Backup対象ディレクトリがあったら実行、なければ終了
        if [[ -d $COPY_TARGET_DIR ]]; then
            log="Backup directory is exists. => [${COPY_TARGET_DIR}]"
            write_log $log_file "INFO" "${log}"
	    # コピー実行
            copy_result=$(copy_file $db_file_path $COPY_TARGET_DIR $DB_FILE)
	    # コピー実行後にファイルサイズ比較して、一致すれば成功
            if [[ $copy_result ]]; then
                sleep 15
                copy_file_size=$(wc -c < ${copy_result})
                if [[ $copy_file_size -ge $db_file_size ]]; then
                    write_log $log_file "INFO" "Backup Succeeded. => [$copy_result]"
                fi
                remove_old_file $COPY_TARGET_DIR $DB_FILE $log_file
            else
                log="Backup failed."
                write_log $log_file "WARN" "${log}" 
            fi
        else
            log="Backup directory is NOT exists. => [${COPY_TARGET_DIR}]"
            write_log $log_file "WARN" "${log}"            
        fi
    else
        log="Backup target is NOT exists. => [${db_file_path}]"
        write_log $log_file "WARN" "${log}"
    fi

    write_log $log_file "INFO" "Backup Stopped."
}


function copy_file(){
    datetime=$(date +"%Y%m%d%H%M%S")
    copy_file_path=${2}$datetime"_"${3}
    # コピーコマンドが成功したら、コピー先のファイルパスを返す
    $(cp ${1} $copy_file_path)
    [[ $? -eq 0 ]] && echo $copy_file_path || echo ""
}


function remove_old_file(){
    # Backupファイルの数の上限
    FILE_COUNT_MAX=10
    file_array=()

    files=$(find ${1} -name *${2} | sort)
    for file in $files; do
        file_array+=($file)
    done

    # Backupファイルの上限を超えていたら、古いファイルから削除する
    if [[ ${#file_array[@]} -gt $FILE_COUNT_MAX ]]; then
        for ((i=0; i < ${#file_array[@]} - $FILE_COUNT_MAX; i++)); do
            $(rm ${file_array[$i]})
            if [[ $? -eq 0 ]]; then
                write_log ${3} "INFO" "Removed old backup. => [${file_array[$i]}]"
            fi
        done
    fi
}


function write_log(){
    datetime=`date +"%Y/%m/%d %H:%M:%S"`
    echo "${datetime}:[${2}]:${3}" >>${1}
}


backup_db
