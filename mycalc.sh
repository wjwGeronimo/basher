#!/usr/bin/env bash

fn_usage() {
	echo -e "$0: Calculate memory usage from MySQL variables"
	echo -e "\t\t-S For connections to localhost, the Unix socket file to use"
	echo -e "\t\t-n Show Memory usage of Running instance"
	echo -e "\t\t-a Show Memory usage after MySQL Restart"
	exit 0
}

ARGS="-N -B"

chng=0
aft=1
now=1

SOCK=`sed -n '/\[client\]/,/\[/p' /etc/my.cnf | grep socket | cut -f 2 -d "=" | cut -f 1 -d "#" | tr -d [:blank:]`

while getopts ":S:an" opt
do
	case $opt in
		S) [[ -e ${OPTARG} ]]&&ARGS=${ARGS}" -S "${OPTARG}&&SOCK=${OPTARG}||echo "No such sock-file; Using ${SOCK}";;
		a) [[ ${chng} -eq 0 ]] && now=0 && chng=1 || aft=1;;
		n) [[ ${chng} -eq 0 ]] && aft=0 && chng=1 || now=1;;
		*) fn_usage;;
	esac
done

declare -A LIST1=(
["tmp_table_size"]=16777216
["key_buffer_size"]=8384512
["innodb_additional_mem_pool_size"]=1048576
["query_cache_size"]=0
["innodb_buffer_pool_size"]=8388608
["innodb_log_buffer_size"]=1048576
)

declare -A LIST2=(
["thread_stack"]=262144
["join_buffer_size"]=131072
["binlog_cache_size"]=32768
["read_buffer_size"]=131072
["read_rnd_buffer_size"]=262144
["sort_buffer_size"]=2097144
)

fn_now() {
	SQL_CVARS=`for i in "${!LIST2[@]}"
		do
			mysql $ARGS -e "SHOW GLOBAL VARIABLES;" | egrep "^${i}" | awk '{print $2}'
		done | awk '{s+=$1}END{print s}'`

	SQL_MCON=`mysql $ARGS -e "SHOW GLOBAL VARIABLES LIKE 'max_connections';" | awk '{print $2}'`

	SQL_GVARS=`for i in "${!LIST1[@]}"
		do
			mysql $ARGS -e "SHOW GLOBAL VARIABLES;" | egrep "^${i}" | awk '{print $2}'
		done | awk '{s+=$1}END{print s}'`

	echo MySQL Memory Usage Now:
	echo $SQL_GVARS $SQL_MCON $SQL_CVARS | awk '{print ($1+($2*$3))/1024/1024" Mb"}'
}

fn_after() {
	DCNT=`grep mysqld /etc/my.cnf | grep -v mysqldump | wc -l`
	if [[ ${DCNT} -gt 1 ]]
	then
		DMNS=`grep mysqld /etc/my.cnf | grep -v mysqldump | tr -d [=\[=] | tr -d [=\]=]`
		for dmn in ${DMNS}
		do
			CHE=`sed -n "/\[${dmn}\]/,/\[/p" /etc/my.cnf | grep ${SOCK}`
			[[ -z ${CHE} ]] || WDMN=${dmn}
		done
	fi

	for k in "${!LIST1[@]}"
	do
		if [[ ${DCNT} -eq 1 ]]
		then
			var=`egrep "^${k}" /etc/my.cnf | cut -f 2 -d "=" | cut -f 1 -d "#" | tr -d [:blank:]`
		elif [[ ${DCNT} -gt 1 ]]
		then
			var=`sed -n "/\[${WDMN}\]/,/\[/p" /etc/my.cnf | egrep "^${k}" | cut -f 2 -d "=" | cut -f 1 -d "#" | tr -d [:blank:]`
		fi
		[[ "${var}" =~ "k" || "${var}" =~ "kb" ]] && var=`echo ${var} | tr -d [:alpha:]` && var=$((var*1024))
		[[ "${var}" =~ "M" || "${var}" =~ "Mb" ]] && var=`echo ${var} | tr -d [:alpha:]` && var=$((var*1024*1024))
		[[ "${var}" =~ "G" || "${var}" =~ "Gb" ]] && var=`echo ${var} | tr -d [:alpha:]` && var=$((var*1024*1024*1024))
		[[ -z ${var} ]] || LIST1["$k"]=${var}
	done

	for k in "${!LIST2[@]}"
	do
		if [[ ${DCNT} -eq 1 ]]
		then
			var=`egrep "^${k}" /etc/my.cnf | cut -f 2 -d "=" | cut -f 1 -d "#" | tr -d [:blank:]`
		elif [[ ${DCNT} -gt 1 ]]
		then
			var=`sed -n "/\[${WDMN}\]/,/\[/p" /etc/my.cnf | egrep "^${k}" | cut -f 2 -d "=" | cut -f 1 -d "#" | tr -d [:blank:]`
		fi
		[[ "${var}" =~ "k" || "${var}" =~ "kb" ]] && var=`echo ${var} | tr -d [:alpha:]` && var=$((var*1024))
		[[ "${var}" =~ "M" || "${var}" =~ "Mb" ]] && var=`echo ${var} | tr -d [:alpha:]` && var=$((var*1024*1024))
		[[ "${var}" =~ "G" || "${var}" =~ "Gb" ]] && var=`echo ${var} | tr -d [:alpha:]` && var=$((var*1024*1024*1024))
		[[ -z ${var} ]] || LIST2["$k"]=${var}
	done

	CNF_MCON=151
	if [[ ${DCNT} -eq 1 ]]
	then
		var=`egrep "^max_connections" /etc/my.cnf | cut -f 2 -d "=" | cut -f 1 -d "#" | tr -d [:blank:]`
	elif [[ ${DCNT} -gt 1 ]]
	then
		var=`sed -n "/\[${WDMN}\]/,/\[/p" /etc/my.cnf | egrep "^max_connections" | cut -f 2 -d "=" | cut -f 1 -d "#" | tr -d [:blank:]`
	fi
	[[ -z ${var} ]] || CNF_MCON=${var}

	CNF_CVARS=`for k in "${!LIST2[@]}"
		do
			echo ${LIST2["$k"]}
		done | awk '{s+=$1}END{print s}'`

	CNF_GVARS=`for k in "${!LIST1[@]}"
		do
			echo ${LIST1["$k"]}
		done | awk '{s+=$1}END{print s}'`

	echo MySQL Memory Usage After Restart
	echo ${CNF_GVARS} ${CNF_MCON} ${CNF_CVARS} | awk '{print ($1+($2*$3))/1024/1024" Mb"}'
}

[[ ${now} -eq 1 ]] && fn_now
[[ ${aft} -eq 1 ]] && fn_after
