#!/bin/bash

#snmp_weblogic8_check.sh -H hostname/IP -C community [-p] [-w] [-c] -t <Weblogic_ServerName> -s 
#This nagios plagin is finished by HongRui Wang at 2010-05-12
#2010-06-12  ��snmpwalkִ�н��ΪNo Such Object available on this agent at this OIDʱ�������״̬Ϊ0�������˴���������ж�
#2010-11-23  ��jvm/queue/jdbc������д���ļ���Ϊ�˸�Ӧ�ù���Ա�ο�
#2010-12-30  ��queue���ʱ����ʱ�ܶ��л�ֻ�õ�һ��ֵ����������������ж�
#2011-04-12  ��queue���ʱ���������ж��ֵ������Ҫ����server�����ڶ����еı��Ϊ1�������ж�if [[ $n -gt 1 ]];Ϊ�٣���ֵΪqueue_total_count=${queue_total_count_g}
#            ����ʵ�ǽ��ܶ����еı��0��ֵ�����˼��server���ܶ��д�С�������Ǵ���ģ������ж�Ϊif [[ ${#queue_total_count_g[@]} -gt 1 ]]
#2011-04-13  ��jvm���жϣ�������ָֻ��warn������ͨ�澯����ָֻ��crit�������ظ澯�������
#2011-04-28  ԭ�������ʷ����д���ļ��ķ�ʽ�����������ӽ�ÿ��ļ����ʷ����д��һ�������ļ�
#2012-1-18 ��ʱ queue_idle_count bigger ����queue_total_count, USED_Q �Ǹ�ֵ
#Test on SUSE10SP2-x86_64

PATH="/usr/bin:/usr/sbin:/bin:/sbin"
LIBEXEC="/usr/local/nagios/libexec"

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

PROGNAME=`basename $0`
SNMPWALK="/usr/bin/snmpwalk"
output="/srv/check_weblogic_output/8"
output1="/srv/check_weblogic_output/8_everyday"
# weblogic9/weblogic10 oid
VER=2c
serverRuntimeName=".1.3.6.1.4.1.140.625.360.1.15"                   #version 10
serverRuntimeState=".1.3.6.1.4.1.140.625.360.1.60"					 #version 10 
#serverLifeCycleRuntimeName=".1.3.6.1.4.1.140.625.361.1.15"			 #version 8	only
#serverLifeCycleRuntimeState=".1.3.6.1.4.1.140.625.361.1.25"			 #version 8 only 

jvmRuntimeName=".1.3.6.1.4.1.140.625.340.1.15"
jvmRuntimeHeapFreeCurrent=".1.3.6.1.4.1.140.625.340.1.25"
jvmRuntimeHeapSizeCurrent=".1.3.6.1.4.1.140.625.340.1.30"

#threadPoolRuntimeObjectName=".1.3.6.1.4.1.140.625.367.1.5"                         #version 10
#threadPoolRuntimeExecuteThreadIdleCount=".1.3.6.1.4.1.140.625.367.1.30"	        #version 10
#threadPoolRuntimeExecuteThreadTotalCount=".1.3.6.1.4.1.140.625.367.1.25"	        #version 10
executeQueueParent=".1.3.6.1.4.1.140.625.550.1.20"
executeQueueThreadCount=".1.3.6.1.4.1.140.625.550.1.25"                             #version 8    "The number of threads assigned to this queue."
#executeQueueThreadsMaximum=".1.3.6.1.4.1.140.625.550.1.26"                         #version 8    "Returns the maximum number of threads in the pool."

executeQueueRuntimeName=".1.3.6.1.4.1.140.625.180.1.15"                             #find the string "weblogic.kernel.Default"                 
executeQueueRuntimeParent=".1.3.6.1.4.1.140.625.180.1.20" 							#version 8
executeQueueRuntimeExecuteThreadCurrentIdleCount=".1.3.6.1.4.1.140.625.180.1.25"	#version 8    "The number of idle threads assigned to the queue."
#executeQueueRuntimeExecuteThreads=".1.3.6.1.4.1.140.625.180.1.45"			        #version 8    "The execute threads currently assigned to the queue."


jdbcConnectionPoolRuntimeName=".1.3.6.1.4.1.140.625.190.1.15"						#"BEA-proprietary MBean name"
jdbcConnectionPoolRuntimeParent=".1.3.6.1.4.1.140.625.190.1.20"						
jdbcConnectionPoolRuntimeActiveConnectionsCurrentCount=".1.3.6.1.4.1.140.625.190.1.25"		#"The current total active connections."
jdbcConnectionPoolRuntimeWaitingForConnectionCurrentCount=".1.3.6.1.4.1.140.625.190.1.30"	#"The current total waiting for a connection."
jdbcConnectionPoolRuntimeActiveConnectionsHighCount=".1.3.6.1.4.1.140.625.190.1.40"		    #The high water mark of active connections in this JDBCConnectionPoolRuntimeMBean.
																							#The count starts at zero each time the JDBCConnectionPoolRuntimeMBean
																							#is instantiated
jdbcConnectionPoolRuntimeWaitingForConnectionHighCount=".1.3.6.1.4.1.140.625.190.1.45"      #The high water mark of waiters for a connection in this JDBCConnectionPoolRuntimeMBean.
																							#The count starts at zero each time the JDBCConnectionPoolRuntimeMBean
																							#is instantiated.
jdbcConnectionPoolRuntimeMaxCapacity=".1.3.6.1.4.1.140.625.190.1.60"						#"The maximum capacity of this JDBC pool"#
#jdbcConnectionPoolRuntimeActiveConnectionsAverageCount=".1.3.6.1.4.1.140.625.190.1.61"		#"The running average of active connections in this JDBCConnectionPoolRuntimeMBean"
#jdbcConnectionPoolRuntimeCurrCapacity=".1.3.6.1.4.1.140.625.190.1.64"						#"Returns the current capacity of this connection pool."
#jdbcConnectionPoolRuntimeHighestNumAvailable=".1.3.6.1.4.1.140.625.190.1.66"				#"Returns the highest number of available connections in this pool"
#jdbcConnectionPoolRuntimeHighestNumUnavailable=".1.3.6.1.4.1.140.625.190.1.67"				#"Returns the highest number of unavailable connections in this pool"
#jdbcConnectionPoolRuntimeNumAvailable=".1.3.6.1.4.1.140.625.190.1.69"						#"Returns the number of available connections in this pool"
#jdbcConnectionPoolRuntimeNumUnavailable=".1.3.6.1.4.1.140.625.190.1.70"						#"Returns the number of unavailable connections in this pool"

#jdbcConnectionPoolName=.1.3.6.1.4.1.140.625.560.1.15               				#"BEA-proprietary MBean name"
#jdbcConnectionPoolInitialCapacity=.1.3.6.1.4.1.140.625.560.1.50       				#"The initial number of connections."
#jdbcConnectionPoolMaxCapacity=.1.3.6.1.4.1.140.625.560.1.55          				#"The maximum number of connections."
#jdbcConnectionPoolHighestNumUnavailable=.1.3.6.1.4.1.140.625.560.1.103    			#"Gets the highestNumUnavailable attribute of the JDBCConnectionPoolMBean object"
#jdbcConnectionPoolHighestNumWaiters=.1.3.6.1.4.1.140.625.560.1.104    				#"Gets the highestNumWaiters attribute of the JDBCConnectionPoolMBean object"


print_usage() {
        echo "Usage: "
        echo "		$PROGNAME [-v version]  -H HOST -C community [-p port] -t Weblogic_ServerName [-w warning] [-c critical] -s [serverstate|jvm|queue|jdbc]"
        echo "Check Weblogic Status:"
		echo "		$PROGNAME [-v 1|2c] -H HOST -C community [-p port] -t Weblogic_ServerName -s serverstate"
		echo "Check Weblogic JVM Heap Usage"
		echo "		$PROGNAME [-v 1|2c] -H HOST -C community [-p port] -t Weblogic_ServerName -w warning -c critical -s jvm"
		echo "Check Weblogic Queue Runing Num"
		echo " 		$PROGNAME [-v 1|2c] -H HOST -C community [-p port] -t Weblogic_ServerName -w warning -c critical -s queue"
		echo "Check Weblogic JDBC Pool"
		echo " 		$PROGNAME [-v 1|2c] -H HOST -C community [-p port] -t Weblogic_ServerName -s jdbc"
		echo " "
}

print_help() {
        echo ""
        print_usage
        echo ""
}

while [ -n "$1" ]
do
	case "$1" in 
		--help)
			print_help
			exit $STATE_UNKNOWN
			;;
		-h)
			print_help
			exit $STATE_UNKNOWN
			;;
		-v)
			VER="$2"
			shift
			;;
		-H)
			HOSTNAME="$2"
			shift
			;;
		-C)
			COMMUNITY="$2"
			shift
			;;
		-p)
			PORT="$2"
			shift
			;;
		-s)
			PR="$2"
			shift
			;;
		-w)
			WARN="$2"
			shift
			;;
		-c)
			CRIT="$2"
			shift
			;;
		-t)
			TITLE1="$2"					#servername��������˫���ţ�������������public@servername�У���˫�����ڽű����޷�ִ��
			TITLE='"'$TITLE1'"'
			shift
			;;
		*)
			print_help
			exit $STATE_UNKNOWN
			;;
	esac
	shift
done

check_time=$( date +"%Y-%m-%d %H:%M" )

if [[ -n $HOSTNAME && -n $COMMUNITY && -n $PR && -n $TITLE ]];then 
	case $PR in 
		#Check Weblogic Status
		serverstate)
			if [[ -n $PORT ]];then
				status=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $serverRuntimeState )
				r1=$?
				status=$( echo ${status} | gawk '{print $4}' )
			else
				status=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $serverRuntimeState )
				r1=$?
				status=$( echo ${status} | gawk '{print $4}' )
			fi
			if [[ "$r1" -eq 0 ]];then
				if [[ "$status" = '"RUNNING"' ]];then
					printf "%s%s%s\n" $TITLE " status is " $status
					exit $STATE_OK
				elif [[ "$status" = "Such" ]];then
					echo "ERROR -Can't get Server State"
					exit $STATE_UNKNOWN
				elif [[ "$status" = "more" ]];then
					printf "Server may be shutdown\n"
					exit $STATE_UNKNOWN
				else 
					printf "%s%s%s\n" $TITLE " status is " $status
					exit $STATE_UNKNOWN
				fi
			else
				echo  "ERROR -Can't get Server State"
				exit $STATE_UNKNOWN
			fi
			;;
		#Check Weblogic JVM Heap
		jvm)
			if [[ -n $PORT ]];then
				server=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jvmRuntimeName | gawk '{print $4}' )
				jvm_cur_free=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jvmRuntimeHeapFreeCurrent | gawk '{print $4}' )
				jvm_cur_size=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jvmRuntimeHeapSizeCurrent | gawk '{print $4}' )
			else
				server=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jvmRuntimeName | gawk '{print $4}' )
				jvm_cur_free=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} $HOSTNAME $jvmRuntimeHeapFreeCurrent | gawk '{print $4}' )
				jvm_cur_size=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} $HOSTNAME $jvmRuntimeHeapSizeCurrent | gawk '{print $4}' )
			fi
			
			
			if [[ -n $jvm_cur_free && -n $jvm_cur_size && "$jvm_cur_size" != "Such" && "$jvm_cur_size" != "OID" ]];then
				(( jvm_cur_usage=(${jvm_cur_size}-${jvm_cur_free})*100/${jvm_cur_size} ))
				(( jvm_cur_use=${jvm_cur_size}-${jvm_cur_free} ))
				
				if [[ -n $WARN && -n $CRIT ]];then
					(( jvm_cur_warn=${jvm_cur_size}*${WARN}/100 ))
					(( jvm_cur_cirt=${jvm_cur_size}*${CRIT}/100 ))
					if [[ $jvm_cur_usage -le $WARN ]];then
						printf "%s%s%s%s%%%s%s" "OK - " $TITLE " JVM Heap is used: " $jvm_cur_usage "  Total is: " $jvm_cur_size
						STATUS=$STATE_OK
					elif [[ $jvm_cur_usage -gt $WARN && $jvm_cur_usage -le $CRIT ]];then
						printf "%s%s%s%s%%%s%s" "WARN - " $TITLE " JVM Heap is used: " $jvm_cur_usage "  Total is: " $jvm_cur_size
						STATUS=$STATE_WARNING
					else
						printf "%s%s%s%s%%%s%s" "CRITICAL - " $TITLE " JVM Heap is used: " $jvm_cur_usage "  Total is: " $jvm_cur_size
						STATUS=$STATE_CRITICAL
					fi
					printf "%s%s%s%s%s%s%s%s\n" "| used=" $jvm_cur_use ";" $jvm_cur_warn ";" $jvm_cur_cirt ";0;" $jvm_cur_size 
				#2011-04-13  ��jvm���жϣ�������ָֻ��warn������ͨ�澯����ָֻ��crit�������ظ澯�������	
				elif [[ -n $WARN && ! -n $CRIT ]];then
					(( jvm_cur_warn=${jvm_cur_size}*${WARN}/100 ))
					if [[ $jvm_cur_usage -le $WARN ]];then
						printf "%s%s%s%s%%%s%s\n" "OK - " $TITLE " JVM Heap is used: " $jvm_cur_usage "  Total is: " $jvm_cur_size
						STATUS=$STATE_OK
					else
						printf "%s%s%s%s%%%s%s\n" "WARN - " $TITLE " JVM Heap is used: " $jvm_cur_usage "  Total is: " $jvm_cur_size
						STATUS=$STATE_WARNING
					fi					
				elif [[ ! -n $WARN && -n $CRIT ]];then
					(( jvm_cur_cirt=${jvm_cur_size}*${CRIT}/100 ))
					if [[ $jvm_cur_usage -le $CRIT ]];then
						printf "%s%s%s%s%%%s%s\n" "OK - " $TITLE " JVM Heap is used: " $jvm_cur_usage "  Total is: " $jvm_cur_size
						STATUS=$STATE_OK
					else
						printf "%s%s%s%s%%%s%s\n" "CRITICAL - " $TITLE " JVM Heap is used: " $jvm_cur_usage "  Total is: " $jvm_cur_size
						STATUS=$STATE_CRITICAL
					fi				
					
				else
					print_help
					exit $STATE_UNKNOWN
				fi
				
				#2011-11-23 write data to file for administrator
				DATE_TIME=$( /bin/date "+%Y-%m-%d %H:%M:%S" )
				printf "%-10s %s\tTotal : %-15s Free : %-15s Used : %-15s Usage : %2s%% \n" $DATE_TIME $jvm_cur_size $jvm_cur_free $jvm_cur_use $jvm_cur_usage >>${output}/${HOSTNAME}_${TITLE1}_${PORT}_jvm.out
				#2011-04-28 write data to file order by date
				File_Date=$( /bin/date +%Y%m%d )
				printf "%-10s %s\tTotal : %-15s Free : %-15s Used : %-15s Usage : %2s%% \n" $DATE_TIME $jvm_cur_size $jvm_cur_free $jvm_cur_use $jvm_cur_usage >>${output1}/${HOSTNAME}_${TITLE1}_${PORT}_jvm.${File_Date}
				exit $STATUS
				
			else
				echo "ERROR -Can't get JVM Heap"
				exit $STATE_UNKNOWN
			fi
			;;
		#Check Weblogic Queue
		queue)
			if [[ -n $PORT ]];then
				#server_g�е�˳���queue_total_count_g�е�˳���Ƕ�Ӧ�ģ���queue_runtime_type_g��queue_runtime_idle_count_g�е�˳���Ƕ�Ӧ�ġ�
				server_g=($( $SNMPWALK -v $VER -c ${COMMUNITY} ${HOSTNAME}:${PORT} $executeQueueParent | gawk -F: '{print $5}'| sed -e 's/^/"/g' ))
				queue_runtime_type_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $executeQueueRuntimeName | gawk '{print $4}'| sed -e 's/"//g' ))
				queue_total_count_g=($( $SNMPWALK -v $VER -c ${COMMUNITY} ${HOSTNAME}:${PORT} $executeQueueThreadCount | gawk '{print $4}' ))
				queue_runtime_idle_count_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $executeQueueRuntimeExecuteThreadCurrentIdleCount | gawk '{print $4}' ))
			else
				server_g=($( $SNMPWALK -v $VER -c ${COMMUNITY} ${HOSTNAME} $executeQueueParent | gawk -F: '{print $5}'| sed -e 's/^/"/g' ))
				queue_runtime_type_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $executeQueueRuntimeName | gawk '{print $4}' | sed -e 's/"//g' ))
				queue_total_count_g=($( $SNMPWALK -v $VER -c ${COMMUNITY} ${HOSTNAME} $executeQueueThreadCount | gawk '{print $4}' ))
				queue_runtime_idle_count_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $executeQueueRuntimeExecuteThreadCurrentIdleCount | gawk '{print $4}' ))
			fi
			#��server_g���ҵ���Ӧ��servername����Ӧ�����кţ��Ӷ����Դ�queue_total_count_g���Ҵ�servername�Ķ����ܴ�С
			n=0
			for i in "${server_g[@]}";do
				if [[ $i = $TITLE ]];then
					break
				fi
				(( n=${n}+1 ))			
			done
			#��queue_runtime_type_g���ҵ���Ӧservername��weblogic.kernel.Default��Ӧ�����кţ��������кſ�����servername��queue_runtime_idle_count_g���ҵ���Ӧ�Ŀ�����
			m=0
			for j in "${queue_runtime_type_g[@]}";do
				if [[ $j = "weblogic.kernel.Default" ]];then
						break
				fi
				(( m=${m}+1 ))
			done 
			
			#2010-12-30 ������ʱqueue_total_countֻ��һ����û����ô��
			#if [[ $n -gt 1 ]];then
			#2011-04-12 ���ڼ��server���ǡ��Ϊ1����������жϸ�Ϊ������ĸ����Ƿ����1
			if [[ ${#queue_total_count_g[@]} -gt 1 ]];then
				queue_total_count=${queue_total_count_g[${n}]}
			else
				queue_total_count=${queue_total_count_g}
			fi			
			queue_idle_count=${queue_runtime_idle_count_g[${m}]}
			
			if [[ -n $queue_idle_count && -n $queue_total_count ]];then
				if [[ -n $WARN && -n $CRIT ]];then
					(( USED_Q=${queue_total_count}-${queue_idle_count} ))
					if [[ $USED_Q -lt 0 ]];then
						#2012-1-18 ��ʱ queue_idle_count bigger ����queue_total_count, USED_Q �Ǹ�ֵ
						printf "%s%s%s%s%s%s%s%s" "UNKNOWN - " $TITLE " Queue Total num:" $queue_total_count " Current_Idle num:" $queue_idle_count "  Current_Running num:" $USED_Q 
						STATUS=$STATE_UNKNOWN
					else						
						if [[ $USED_Q -le $WARN ]];then
							printf "%s%s%s%s%s%s%s%s" "OK - " $TITLE " Queue Total num:" $queue_total_count " Current_Running num:" $USED_Q  "  Warn_value:" $WARN
							STATUS=$STATE_OK
						elif [[ $USED_Q -gt $WARN && $USED_Q -le $CRIT ]];then
							printf "%s%s%s%s%s%s%s%s%s%s" "WARN - " $TITLE " Queue Total num:" $queue_total_count " Current_Running num:" $USED_Q "  Warn_value:" $WARN "  Crit_value:" $CRIT
							STATUS=$STATE_WARNING
						else [[ $USED_Q -gt $CRIT ]]
							printf "%s%s%s%s%s%s%s%s" "CRITICAL - " $TITLE " Queue Total num:" $queue_total_count " Current_Running num:" $USED_Q "  Crit_value:" $CRIT 
							STATUS=$STATE_CRITICAL
						fi
						
						printf "%s%s%s%s%s%s%s%s\n" "| used=" $USED_Q ";" $WARN ";" $CRIT ";0;" $queue_total_count
						#2011-11-23 write data to file for administrator
						DATE_TIME=$( /bin/date "+%Y-%m-%d %H:%M:%S" )
						printf "%-10s %s\tTotal : %-15s Idle : %-15s Used : %-15s \n" $DATE_TIME $queue_total_count $queue_idle_count $USED_Q >>${output}/${HOSTNAME}_${TITLE1}_${PORT}_queue.out
						#2011-04-28 write data to file order by date
						File_Date=$( /bin/date +%Y%m%d )
						printf "%-10s %s\tTotal : %-15s Idle : %-15s Used : %-15s \n" $DATE_TIME $queue_total_count $queue_idle_count $USED_Q >>${output1}/${HOSTNAME}_${TITLE1}_${PORT}_queue.${File_Date}						
					fi
					exit $STATUS
				else
					print_help
					exit $STATE_UNKNOWN
				fi
			else
				echo "ERROR -Can't get Weblogic Queue"
				exit $STATE_UNKNOWN
			fi
			;;
		#Check Weblogic JDBC
		jdbc)
			#servername�����ڶ��jdbc pool�ж������ӣ�����servername�����κ�һ��jdbc pool���Ƿ��еȴ����ӣ�����о͸澯
			if [[ -n $PORT ]];then
				jdbc_pool_test=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcConnectionPoolRuntimeName )
				r1=$?
				jdbc_pool_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcConnectionPoolRuntimeName |gawk -F: '{print $4}'| sed -e 's/"//g' -e 's/ //g' ))
				jdbc_wait_count_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcConnectionPoolRuntimeWaitingForConnectionCurrentCount |gawk -F: '{print $4}' ))
				
				#2010-11-23 write data to file for administrator
				jdbc_active_count_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcConnectionPoolRuntimeActiveConnectionsCurrentCount |gawk -F: '{print $4}' ))
				jdbc_wait_highcount_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcConnectionPoolRuntimeWaitingForConnectionHighCount |gawk -F: '{print $4}' ))
				jdbc_active_highcount_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcConnectionPoolRuntimeActiveConnectionsHighCount |gawk -F: '{print $4}' ))
				jdbc_capacity_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcConnectionPoolRuntimeMaxCapacity |gawk -F: '{print $4}' ))
			else
				jdbc_pool_test=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcConnectionPoolRuntimeName )
				r1=$?
				jdbc_pool_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcConnectionPoolRuntimeName |gawk -F: '{print $4}'| sed -e 's/"//g' -e 's/ //g' ))
				jdbc_wait_count_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcConnectionPoolRuntimeWaitingForConnectionCurrentCount |gawk -F: '{print $4}' ))
				
				#2010-11-23 write jdbc data to file for administrator
				jdbc_active_count_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcConnectionPoolRuntimeActiveConnectionsCurrentCount |gawk -F: '{print $4}' ))
				jdbc_wait_highcount_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcConnectionPoolRuntimeWaitingForConnectionHighCount |gawk -F: '{print $4}' ))
				jdbc_active_highcount_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcConnectionPoolRuntimeActiveConnectionsHighCount |gawk -F: '{print $4}' ))
				jdbc_capacity_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcConnectionPoolRuntimeMaxCapacity |gawk -F: '{print $4}' ))
			fi
			
			if [[ $r1 -eq 0 && "$jdbc_pool_g" != "Such" ]];then
				n=0
				crit_num=0
				for i in "${jdbc_pool_g[@]}";do
					if [[ ${jdbc_wait_count_g[$n]} -gt 0 ]];then
						printf "%s%s%s%s%s" " <= CRIT - JDBC Pool : " ${jdbc_pool_g[$n]} " - Current Waiting Connections Num:" ${jdbc_wait_count_g[$n]} " =>" 
						(( crit_num=${crit_num}+1 ))
					else	
						printf "%s%s%s%s%s" " <= JDBC Pool : " ${jdbc_pool_g[$n]} " - Current Waiting Connections Num:" ${jdbc_wait_count_g[$n]} " =>"    
					fi
					(( n=${n}+1 ))			
				done

				#2010-11-23 write jdbc data to file for administrator
				DATE_TIME=$( /bin/date "+%Y-%m-%d %H:%M:%S" )
				#2011-04-28 write data to file order by date
				File_Date=$( /bin/date +%Y%m%d )
				for ((j=0;j<${#jdbc_pool_g[@]};j++))
				do
					printf "%-10s %s\tPool: %-10s Capacity: %-3s Active_High: %-3s Waiting_High: %-3s Current_Active: %-3s Current_Waiting: %-3s \n" ${DATE_TIME} ${jdbc_pool_g[$j]} ${jdbc_capacity_g[$j]} ${jdbc_active_highcount_g[$j]} ${jdbc_wait_highcount_g[$j]} ${jdbc_active_count_g[$j]} ${jdbc_wait_count_g[$j]} >> ${output}/${HOSTNAME}_${TITLE1}_${PORT}_jdbc.out
					printf "%-10s %s\tPool: %-10s Capacity: %-3s Active_High: %-3s Waiting_High: %-3s Current_Active: %-3s Current_Waiting: %-3s \n" ${DATE_TIME} ${jdbc_pool_g[$j]} ${jdbc_capacity_g[$j]} ${jdbc_active_highcount_g[$j]} ${jdbc_wait_highcount_g[$j]} ${jdbc_active_count_g[$j]} ${jdbc_wait_count_g[$j]} >> ${output1}/${HOSTNAME}_${TITLE1}_${PORT}_jdbc.${File_Date}
				done
				
				if [[ ${crit_num} -gt 0 ]];then
					exit $STATE_CRITICAL
				else
					exit $STATE_OK
				fi
			else
				echo "ERROR -Can't get Weblogic JDBC INFO"
				exit $STATE_UNKNOWN
			fi
			;;
	esac
else
	print_help
	exit $STATE_UNKNOWN
fi

