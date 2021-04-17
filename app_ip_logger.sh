source ./app_ip_logger-config.txt
public_ip=`curl -s $public_ip_host`
os=`uname -o`

if [ -f ${app_list_file} ]
then
	declare -a app_list
	while read -r n
	do
		app_list+=( "$n" )
	done <<< `cat $app_list_file`
else
	declare -a app_list
	for name in ${app_name}
	do
		app_list+=( "${name}" )
	done
fi

if [ ! -f ${log_file} ]
then
	touch ${log_file}
	else
	echo >> ${log_file}
fi

ip_logged=`cat ${log_file}`

echo [`date`] starting $0 on $os ...
echo [`date`] starting $0 on $os ... >> ${log_file}
echo app list : ${app_list[@]}
echo app list : ${app_list[@]} >> ${log_file}
echo current public ip : ${public_ip}
echo current public ip : ${public_ip} >> ${log_file}


case ${os} in
    "GNU/Linux")
        ps_cmd="ps -ax"
		ps_col=1
        netstat_cmd="netstat -4np"
        netstat_col=5
        ;;
    Msys)
        ps_cmd="ps -W"
		ps_col=4
        netstat_cmd="netstat -no"
        netstat_col=3
        ;;
    *)
        echo os not supported!!!
        exit;;
esac

while true
do
    for loop in ${!app_list[@]}
    do
		app="${app_list[$loop]}"
		app_pids=`$ps_cmd | grep -i "${app}" | awk '{print $'${ps_col}'}'`
        if [ ! -z "${app_pids}" ]
        then
            for pid in ${app_pids}
            do
                new_ip_list=`$netstat_cmd | grep ${pid} | awk '{print $'${netstat_col}'}'`
				if [ ! -z "$new_ip_list" ]
                then
                    for new_ip in ${new_ip_list}
                    do
						#skip localhost 127.0.0.1
						echo ${new_ip} | grep -q 127.0.0.1
						if [ $? -eq 1 ]
						then
							echo ${current_ip_list} | grep -q ${new_ip}
							if [ $? -eq 1 ]
							then
								current_ip_list="${current_ip_list} ${new_ip}"
								if [ ${reverse_lookup} -eq 1 ]
								then
									ip_only=`echo ${new_ip} | sed 's/:.*//'`
									ip_name=`nslookup ${ip_only} ${dns_server} 2> /dev/null | grep -i name | awk {'print $2'}`
								fi
								echo ${ip_logged} | grep -q ${new_ip}
								if [ $? -eq 1 ]
								then
									echo "[+] "${app} : ${new_ip} ${ip_name}
									echo ${app} : ${new_ip} ${ip_name} >> ${log_file}
									ip_logged=`cat ${log_file}`
								else
									echo "[=] "${app} : ${new_ip} ${ip_name}
								fi
							fi
                        fi
                    done
                fi
            done
        fi
    done
	#debug
    sleep ${sleep}
done
