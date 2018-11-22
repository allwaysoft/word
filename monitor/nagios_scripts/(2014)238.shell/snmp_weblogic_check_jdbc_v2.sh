#!/bin/bash

#snmp_weblogic10_check.sh -H hostname/IP -C community [-p] [-w] [-c] -t <Weblogic_ServerName> -s 
#This nagios plagin is finished by HongRui Wang at 2010-05-18
#2010-06-12  ��snmpwalkִ�н��ΪNo Such Object available on this agent at this OIDʱ�������״̬Ϊ0�������˴���������ж�
#2010-11-19  ���Ķ��е��жϷ�ʽ��ֻҪ�����г��ֵȴ����̣߳�����и澯
#2010-11-24  ��jvm/queue/jdbc������д���ļ���Ϊ�˸�Ӧ�ù���Ա�ο�
#2010-11-30  ���Ķ��е��жϷ�ʽ
#            "Execute Thread Total Count" = threadPoolRuntimeExecuteThreadTotalCount
#			 "Execute Thread Idle Count"  = threadPoolRuntimeExecuteThreadIdleCount
#			  "Standby Thread Count"      = threadPoolRuntimeStandbyThreadCount
#             "Active Execute Threads"    = "Execute Thread Total Count" - "Standby Thread Count"
#             Used Thread                 = "Active Execute Threads" - "Execute Thread Idle Count"
#2011-03-28  ����˿� weblogic �����޶�ռ�̣߳�����ж�ռ�̣߳�hogging thread����˵���̻߳��������stuck ��������״̬���߳�
#2011-04-08  ����weblogic10��jvm��С�Ƕ�̬�����ġ�������ͨ��oidֻ�ܻ�ȡ��ǰ�ܴ�С�����ֵ��ָ�������jvmʹ�õĴ�С����Щ���롣
#            ͨ����ǰ�ܴ�С����������Ҫ�����������������ָ�������jvm��С������õ�ǰ�ܴ�С����jvmʹ������Щ��̫׼ȷ��
#            �������˿���ָ�������jvmʹ�õ��ڴ��С�����ֵ�Ƕ�̬�����ļ��ޣ�ͨ������ʹ���ʸ����ʡ����û��ָ�������jvmʹ��
#            ���ڴ��С���㷨��������ȥ����ʽ��
#2011-04-28  ԭ�������ʷ����д���ļ��ķ�ʽ�����������ӽ�ÿ��ļ����ʷ����д��һ�������ļ�
#2011-05-06  jvm�Ĳ�ѯ����г����˴������͵���ʾ�����»�ȡ��ֵ������
#2011-07-05  queue���֣���ȡ��oid��ֵ��Ϊȡ���һ���ֶΣ����ǵ��ĸ�
#2011-07-05  jdbc���֣���ȡֵoid�Ĳ��ָ�Ϊȡ���һ���ֶΣ�������":"Ϊ�ָ����ĵ��ĸ��ֶ�
#2011-08-08  serverstate��jvm���֣���ȡֵoid�Ĳ��ָ�Ϊ���һ���ֶΣ������ԡ�����Ϊ�ָ����ĵ��ĸ��ֶ�
#2011-08-31  ͬһ̨����������domain��ÿ��domian����һ��AdminServer����ʷ��¼����IP_SERVER����ʽ���棬
#            ������������domian��AdminServer����д��һ���ļ����������snmp�˿�������
#2011-12-29  hoggingthread����������ָ�����ظ澯��ֵ�Ĺ���
#2012-01-31  jdbc����������"$jdbc_pool_g"������OID�����
#2012-03-15  (NOT VERIFY)��ʱ��server��״̬����ʾ�ɿ�("AppServer1" status is )�������״̬��δ֪��������$statusΪ�յ����
#2012-03-26  ��hoggingthread��ȡ���ĸ��ֶε�����gawk '{printf $4}'����Ϊ��ȡ���һ���ֶ� gawk '{printf $NF}'

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
output="/srv/check_weblogic_output/10"
output1="/srv/check_weblogic_output/10_everyday"

VER=2c
serverRuntimeName=".1.3.6.1.4.1.140.625.360.1.15"                   #version 8 9 10
serverRuntimeState=".1.3.6.1.4.1.140.625.360.1.60"					 #version 8 9 10 


jvmRuntimeName=".1.3.6.1.4.1.140.625.340.1.15"
jvmRuntimeHeapFreeCurrent=".1.3.6.1.4.1.140.625.340.1.25"
jvmRuntimeHeapSizeCurrent=".1.3.6.1.4.1.140.625.340.1.30"

threadPoolRuntimeObjectName=".1.3.6.1.4.1.140.625.367.1.5"                          #version 9 10
threadPoolRuntimeExecuteThreadTotalCount=".1.3.6.1.4.1.140.625.367.1.25"	        #version 9 10
threadPoolRuntimeExecuteThreadIdleCount=".1.3.6.1.4.1.140.625.367.1.30"	            #version 9 10
#threadPoolRuntimeQueueLength=".1.3.6.1.4.1.140.625.367.1.35"                        #version 9 10
#threadPoolRuntimePendingUserRequestCount=".1.3.6.1.4.1.140.625.367.1.40"            #version 9 10
threadPoolRuntimeStandbyThreadCount=".1.3.6.1.4.1.140.625.367.1.60"                 #version 9 10


executeQueueRuntimeName=".1.3.6.1.4.1.140.625.180.1.15"                             #version 8    find the string "weblogic.kernel.Default"                 
executeQueueRuntimeParent=".1.3.6.1.4.1.140.625.180.1.20" 							#version 8
executeQueueRuntimeExecuteThreadCurrentIdleCount=".1.3.6.1.4.1.140.625.180.1.25"	#version 8    "The number of idle threads assigned to the queue."

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

#jdbc state 
jdbcConnectionPoolRuntimeState=".1.3.6.1.4.1.140.625.190.1.75"                              #The current state of the connection pool. Running...
jdbcDataSourceRuntimeState=".1.3.6.1.4.1.140.625.191.1.35"				    #The current state of datasource, Running... for weblogic  10.3.0
threadPoolRuntimeHoggingThreadCount=".1.3.6.1.4.1.140.625.367.1.55"                         #��� weblogic �����޶�ռ�̣߳�������ж�ռ�̣߳�hogging thread��˵���̻߳�����н�Ҫ��stuck ��������״̬���߳�

print_usage() {
        echo "Usage: "
        echo "		$PROGNAME [-v version]  -H HOST -C community [-p port] -t Weblogic_ServerName [-w warning] [-c critical] -s [serverstate|jvm|queue|jdbc|jdbcstat]"
        echo "Check Weblogic Status:"
		echo "		$PROGNAME [-v 1|2c] -H HOST -C community [-p port] -t Weblogic_ServerName -s serverstate"
		echo "Check Weblogic JVM Heap Usage:"
		echo "		$PROGNAME [-v 1|2c] -H HOST -C community [-p port] -t Weblogic_ServerName -w warning -c critical -a assign-memory -s jvm"
		echo "Check Weblogic Queue Runing Num:"
		echo " 		$PROGNAME [-v 1|2c] -H HOST -C community [-p port] -t Weblogic_ServerName -w warning -c cirtical -s queue"
		echo "Check Weblogic JDBC Pool:"
		echo " 		$PROGNAME [-v 1|2c] -H HOST -C community [-p port] -t Weblogic_ServerName -s jdbc"
		echo "Check Weblogic JDBC state:"
		echo " 		$PROGNAME [-v 1|2c] -H HOST -C community [-p port] -t Weblogic_ServerName -s jdbcstat"
		echo "Check Weblogic Hogging Thread:"
		echo "		$PROGNAME [-v 1|2c] -H HOST -C community [-p port] -t Weblogic_ServerName [-c critical] [-w warning]  -s hoggingthread"
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
		-a)                             #2011-04-08 ������ָ��jvm��С�Ĳ���
			AssignJVM="$2"
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
				status=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $serverRuntimeState |gawk '{print $NF}' )
				#2012-02-02 ������������Ϊ���ж��Ƿ��ܹ�������ȡsnmp��Ϣ
				$SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $serverRuntimeState >/dev/null 2>&1
				r1=$?
			else
				status=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $serverRuntimeState |gawk '{print $NF}' )
				$SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $serverRuntimeState >/dev/null 2>&1
				r1=$?
			fi
			if [[ "$r1" -eq 0 ]];then
				if [[ "$status" = '"RUNNING"' ]];then
					printf "%s%s%s\n" $TITLE " status is " $status
					exit $STATE_OK
				elif [[ "$status" = "Such" || "$status" = "more" || "$status" = "OID" || -z ${status} ]];then
					echo "ERROR -Can't get Server State"
					exit $STATE_UNKNOWN
				else
					printf "%s%s%s\n" $TITLE " status is " $status
					exit $STATE_CRITICAL
				fi
			else
				echo "ERROR -Can't get Server State"
				exit $STATE_UNKNOWN
			fi
			;;
		#Check Weblogic JVM Heap
		jvm)
			if [[ -n $PORT ]];then
				server=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jvmRuntimeName | gawk '{print $NF}' )
				jvm_cur_free=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jvmRuntimeHeapFreeCurrent |gawk '{print $NF}' )
				jvm_cur_size=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jvmRuntimeHeapSizeCurrent |gawk '{print $NF}' )
			else
				server=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jvmRuntimeName | gawk '{print $NF}' )
				jvm_cur_free=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jvmRuntimeHeapFreeCurrent |gawk '{print $NF}' )
				jvm_cur_size=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jvmRuntimeHeapSizeCurrent |gawk '{print $NF}' )				
			fi
			
			
			if [[ -n $jvm_cur_free && -n $jvm_cur_size && "$jvm_cur_size" != "Such" && "$jvm_cur_size" != "OID" ]];then
				if [[ -n $WARN && -n $CRIT ]];then
					#2011-04-08 ָ�������JVM���ڴ��СΪjvm���ܴ�С�����û��ָ�������jvm�������򰴻�ȡ�ĵ�ǰ�ܴ�С������
					if [[ -n $AssignJVM ]];then
						(( jvm_cur_usage=(${jvm_cur_size}-${jvm_cur_free})*100/${AssignJVM} ))
						(( jvm_cur_use=${jvm_cur_size}-${jvm_cur_free} ))
						(( jvm_cur_warn=${AssignJVM}*${WARN}/100 ))
						(( jvm_cur_cirt=${AssignJVM}*${CRIT}/100 ))
						jvm_cur_size=${AssignJVM}	
					else		
					(( jvm_cur_usage=(${jvm_cur_size}-${jvm_cur_free})*100/${jvm_cur_size} ))
					(( jvm_cur_use=${jvm_cur_size}-${jvm_cur_free} ))
					(( jvm_cur_warn=${jvm_cur_size}*${WARN}/100 ))
					(( jvm_cur_cirt=${jvm_cur_size}*${CRIT}/100 ))
					fi
										
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
					#2011-11-24 write data to file for administrator
					DATE_TIME=$( /bin/date "+%Y-%m-%d %H:%M:%S" )
					printf "%-10s %s\tTotal : %-15s Free : %-15s Used : %-15s Usage : %2s%% \n" $DATE_TIME $jvm_cur_size $jvm_cur_free $jvm_cur_use $jvm_cur_usage >>${output}/${HOSTNAME}_${TITLE1}_${PORT}_jvm.out
					#2011-04-28 write data to file order by date
				    File_Date=$( /bin/date +%Y%m%d )
					printf "%-10s %s\tTotal : %-15s Free : %-15s Used : %-15s Usage : %2s%% \n" $DATE_TIME $jvm_cur_size $jvm_cur_free $jvm_cur_use $jvm_cur_usage >>${output1}/${HOSTNAME}_${TITLE1}_${PORT}_jvm.${File_Date}
					exit $STATUS
				else
					print_help
					exit $STATE_UNKNOWN
				fi
			else
				echo "ERROR -Can't get JVM Heap"
				exit $STATE_UNKNOWN
			fi
			;;
		#Check Weblogic Queue
		queue)
			if [[ -n $PORT ]];then				
				#2010-11-30 write data to file for administrator
				queue_total_count=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $threadPoolRuntimeExecuteThreadTotalCount | gawk '{print $NF}' )
				queue_idle_count=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $threadPoolRuntimeExecuteThreadIdleCount | gawk '{print $NF}' )
				queue_standby_count=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $threadPoolRuntimeStandbyThreadCount | gawk '{print $NF}' )
			else				
				#2010-11-30 write data to file for administrator
				queue_total_count=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $threadPoolRuntimeExecuteThreadTotalCount | gawk '{print $NF}' )
				queue_idle_count=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $threadPoolRuntimeExecuteThreadIdleCount | gawk '{print $NF}' )
				queue_standby_count=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $threadPoolRuntimeStandbyThreadCount | gawk '{print $NF}' )
			fi
			if [[ -n $WARN && -n $CRIT ]];then		
				if [[ -n $queue_total_count && "$queue_total_count" != "OID" && -n $queue_idle_count && "$queue_idle_count" != "OID" && -n $queue_standby_count && "$queue_standby_count" != "OID" ]];then
						#2010-11-30 write data to file for administrator
						(( active_Q=${queue_total_count}-${queue_standby_count} ))
						(( used_Q=${active_Q}-${queue_idle_count} ))
					
						if [[ $used_Q -le $WARN ]];then
							printf "%s%s%s%s%s%s%s%s\n" "OK - Active_Execute_Threads: " $active_Q " Execute_Thread_Total_Count: " $queue_total_count " Execute_Thread_Idle_Count: " $queue_idle_count " Used_Thread_Count: " $used_Q 
							STATUS=$STATE_OK
						elif [[ $used_Q -gt $WARN && $used_Q -le $CRIT ]];then
							printf "%s%s%s%s%s%s%s%s\n" "WARN - Active_Execute_Threads: " $active_Q " Execute_Thread_Total_Count: " $queue_total_count " Execute_Thread_Idle_Count: " $queue_idle_count " Used_Thread_Count: " $used_Q 
							STATUS=$STATE_WARNING
						else
							printf "%s%s%s%s%s%s%s%s\n" "CRIT - Active_Execute_Threads: " $active_Q " Execute_Thread_Total_Count: " $queue_total_count " Execute_Thread_Idle_Count: " $queue_idle_count " Used_Thread_Count: " $used_Q 
							STATUS=$STATE_CRITICAL
						fi
						#��������
						printf "%s%s%s%s%s%s%s%s\n" "| used=" $used_Q ";" $WARN ";" $CRIT ";0;" $queue_total_count
						#2011-11-30 write data to file for administrator
						DATE_TIME=$( /bin/date "+%Y-%m-%d %H:%M:%S" )
						printf "%-10s %s\tActive_Execute_Threads : %-7s Execute_Thread_Total_Count : %-7s Execute_Thread_Idle_Count : %-7s Execute_Thread_Used_Count : %-7s \n" $DATE_TIME $active_Q $queue_total_count $queue_idle_count $used_Q >>${output}/${HOSTNAME}_${TITLE1}_${PORT}_queue.out
						#2011-04-28 write data to file order by date
						File_Date=$( /bin/date +%Y%m%d )
						printf "%-10s %s\tActive_Execute_Threads : %-7s Execute_Thread_Total_Count : %-7s Execute_Thread_Idle_Count : %-7s Execute_Thread_Used_Count : %-7s \n" $DATE_TIME $active_Q $queue_total_count $queue_idle_count $used_Q >>${output1}/${HOSTNAME}_${TITLE1}_${PORT}_queue.${File_Date}
						exit $STATUS
				else
					echo "ERROR -Can't get Weblogic Queue"
					exit $STATE_UNKNOWN
				fi
			else
				print_help
				exit $STATE_UNKNOWN
			fi
			;;
		#Check Weblogic JDBC
		jdbc)
			#servername�����ڶ��jdbc pool�ж������ӣ�����servername�����κ�һ��jdbc pool���Ƿ��еȴ����ӣ�����о͸澯
			if [[ -n $PORT ]];then
				#�����������������Ϊ��ȷ����ǰ����������ȡOIDֵ����Ϊsnmp������Ϲܵ��������ֺ󣬷���ֵ��Ϊ0
				jdbc_pool_test=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcConnectionPoolRuntimeName )
				r1=$?
				jdbc_pool_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcConnectionPoolRuntimeName |gawk -F: '{print $NF}'| sed -e 's/"//g' -e 's/ //g' ))
				jdbc_wait_count_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcConnectionPoolRuntimeWaitingForConnectionCurrentCount |gawk '{print $NF}' ))
				
				#2010-11-24 write data to file for administrator
				jdbc_active_count_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcConnectionPoolRuntimeActiveConnectionsCurrentCount |gawk '{print $NF}' ))
				jdbc_wait_highcount_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcConnectionPoolRuntimeWaitingForConnectionHighCount |gawk '{print $NF}' ))
				jdbc_active_highcount_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcConnectionPoolRuntimeActiveConnectionsHighCount |gawk '{print $NF}' ))
				jdbc_capacity_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcConnectionPoolRuntimeMaxCapacity |gawk '{print $NF}' ))
			else
				jdbc_pool_test=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcConnectionPoolRuntimeName )
				r1=$?
				jdbc_pool_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcConnectionPoolRuntimeName |gawk -F: '{print $NF}'| sed -e 's/"//g' -e 's/ //g' ))
				jdbc_wait_count_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcConnectionPoolRuntimeWaitingForConnectionCurrentCount |gawk '{print $NF}' ))
				
				#2010-11-24 write jdbc data to file for administrator
				jdbc_active_count_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcConnectionPoolRuntimeActiveConnectionsCurrentCount |gawk '{print $NF}' ))
				jdbc_wait_highcount_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcConnectionPoolRuntimeWaitingForConnectionHighCount |gawk '{print $NF}' ))
				jdbc_active_highcount_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcConnectionPoolRuntimeActiveConnectionsHighCount |gawk '{print $NF}' ))
				jdbc_capacity_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcConnectionPoolRuntimeMaxCapacity |gawk '{print $NF}' ))
			fi
			
			if [[ "$r1" -eq 0 && "$jdbc_pool_g" != "Such"  && "$jdbc_pool_g" != "jdbcConnectionPoolRuntimeName=NoSuchObjectavailableonthisagentatthisOID" && "$jdbc_pool_g" != "OID" ]];then
				n=0
				crit_num=0
				for i in "${jdbc_pool_g[@]}";do
					if [[ ${jdbc_wait_count_g[$n]} -gt 0 ]];then
						printf "%s%s%s%s%s" " <= CRIT - JDBC Pool : " ${jdbc_pool_g[$n]} " - Current Waiting Connections Num:" ${jdbc_wait_count_g[$n]} "=>" 
						(( crit_num=${crit_num}+1 ))
					else		
						printf "%s%s%s%s%s" " <= JDBC Pool : " ${jdbc_pool_g[$n]} " - Current Waiting Connections Num:" ${jdbc_wait_count_g[$n]} "=>"         						
					fi
					(( n=${n}+1 ))			
				done

				#2010-11-24 write jdbc data to file for administrator
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
		jdbcstat)
		    #servername�����ڶ��jdbc pool�ж������ӣ�����servername�����κ�һ��jdbc pool���Ƿ��еȴ����ӣ�����о͸澯
			if [[ -n $PORT ]];then
				#�����������������Ϊ��ȷ����ǰ����������ȡOIDֵ����Ϊsnmp������Ϲܵ��������ֺ󣬷���ֵ��Ϊ0
				jdbc_pool_test=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcConnectionPoolRuntimeName )
				r1=$?
				if [[ $r1 -ne 0 ]] ; then
					echo "ERROR -Can't get Weblogic JDBC state"
					exit $STATE_UNKNOWN
				fi
				jdbc_pool_li=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcConnectionPoolRuntimeName | wc -l )
				jdbc_pool_stat_li=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcDataSourceRuntimeState | wc -l)
				if [[ $jdbc_pool_li -ne $jdbc_pool_stat_li ]]; then
					echo "ERROR - Weblogic JDBC state is unknown"
					exit $STATE_UNKNOWN
				fi
				jdbc_pool_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcConnectionPoolRuntimeName |gawk -F: '{print $NF}'| sed -e 's/"//g' -e 's/ //g' ))
				jdbc_pool_stat_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcDataSourceRuntimeState |gawk -F: '{print $NF}'| sed -e 's/"//g' -e 's/ //g' ))
			else
				jdbc_pool_test=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcConnectionPoolRuntimeName )
				r1=$?
				if [[ $r1 -ne 0 ]] ; then
					echo "ERROR -Can't get Weblogic JDBC state"
					exit $STATE_UNKNOWN
				fi
				jdbc_pool_li=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcConnectionPoolRuntimeName | wc -l )
				jdbc_pool_stat_li=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcDataSourceRuntimeState | wc -l)
				if [[ $jdbc_pool_li -ne $jdbc_pool_stat_li ]]; then
					echo "ERROR - Weblogic JDBC state is unknown"
					exit $STATE_UNKNOWN
				fi
				jdbc_pool_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcConnectionPoolRuntimeName |gawk -F: '{print $NF}'| sed -e 's/"//g' -e 's/ //g' ))
				jdbc_pool_stat_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcDataSourceRuntimeState |gawk -F: '{print $NF}'| sed -e 's/"//g' -e 's/ //g' ))
			fi
			
			if [[ "$r1" -eq 0 && "$jdbc_pool_g" != "Such"  && "$jdbc_pool_g" != "jdbcConnectionPoolRuntimeName=NoSuchObjectavailableonthisagentatthisOID" && "$jdbc_pool_g" != "OID" ]];then
				n=0
				crit_num=0
				for i in "${jdbc_pool_g[@]}";do
					if [[ ${jdbc_pool_stat_g[$n]} != "Running" ]];then
						if [ -n "`echo ${jdbc_pool_stat_g[$n]} | grep NoSuchObjectavailableonthisagentatthisOID`" ] ; then
							printf "%s%s%s%s%s" " <=  OK - JDBC Pool : " ${jdbc_pool_g[$n]} " - Current state:" ${jdbc_pool_stat_g[$n]} "=>" 
						else
							printf "%s%s%s%s%s" " <= CRIT - JDBC Pool : " ${jdbc_pool_g[$n]} " - Current state:" ${jdbc_pool_stat_g[$n]} "=>" 
							(( crit_num=${crit_num}+1 ))
						fi
					else		
						printf "%s%s%s%s%s" " <= JDBC Pool : " ${jdbc_pool_g[$n]} " - Current state:" ${jdbc_pool_stat_g[$n]} "=>"         						
					fi
					(( n=${n}+1 ))			
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
		#check jdbc state(warning)
		jdbcstatwarn)
                    #servername�����ڶ��jdbc pool�ж������ӣ�����servername�����κ�һ��jdbc pool���Ƿ��еȴ����ӣ�����о͸澯
                        if [[ -n $PORT ]];then
                                #�����������������Ϊ��ȷ����ǰ����������ȡOIDֵ����Ϊsnmp������Ϲܵ��������ֺ󣬷���ֵ��Ϊ0
                                jdbc_pool_test=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcConnectionPoolRuntimeName )
                                r1=$?
                                if [[ $r1 -ne 0 ]] ; then
                                        echo "ERROR -Can't get Weblogic JDBC state"
                                        exit $STATE_UNKNOWN
                                fi
                                jdbc_pool_li=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcConnectionPoolRuntimeName | wc -l )
                                jdbc_pool_stat_li=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcDataSourceRuntimeState | wc -l)
                                if [[ $jdbc_pool_li -ne $jdbc_pool_stat_li ]]; then
                                        echo "ERROR - Weblogic JDBC state is unknown"
                                        exit $STATE_UNKNOWN
                                fi
                                jdbc_pool_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcConnectionPoolRuntimeName |gawk -F: '{print $NF}'| sed -e 's/"//g' -e 's/ //g' ))
                                jdbc_pool_stat_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $jdbcDataSourceRuntimeState |gawk -F: '{print $NF}'| sed -e 's/"//g' -e 's/ //g' ))
                        else
                                jdbc_pool_test=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcConnectionPoolRuntimeName )
                                r1=$?
                                if [[ $r1 -ne 0 ]] ; then
                                        echo "ERROR -Can't get Weblogic JDBC state"
                                        exit $STATE_UNKNOWN
                                fi
                                jdbc_pool_li=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcConnectionPoolRuntimeName | wc -l )
                                jdbc_pool_stat_li=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcDataSourceRuntimeState | wc -l)
                                if [[ $jdbc_pool_li -ne $jdbc_pool_stat_li ]]; then
                                        echo "ERROR - Weblogic JDBC state is unknown"
                                        exit $STATE_UNKNOWN
                                fi
                                jdbc_pool_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcConnectionPoolRuntimeName |gawk -F: '{print $NF}'| sed -e 's/"//g' -e 's/ //g' ))
                                jdbc_pool_stat_g=($( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $jdbcDataSourceRuntimeState |gawk -F: '{print $NF}'| sed -e 's/"//g' -e 's/ //g' ))
                        fi

                        if [[ "$r1" -eq 0 && "$jdbc_pool_g" != "Such"  && "$jdbc_pool_g" != "jdbcConnectionPoolRuntimeName=NoSuchObjectavailableonthisagentatthisOID" && "$jdbc_pool_g" != "OID" ]];then
                                n=0
                                crit_num=0
				warn_num=0
                                for i in "${jdbc_pool_g[@]}";do
                                        if [[ ${jdbc_pool_stat_g[$n]} != "Running" ]];then
                                                if [ -n "`echo ${jdbc_pool_stat_g[$n]} | grep NoSuchObjectavailableonthisagentatthisOID`" ] ; then
                                                        printf "%s%s%s%s%s" " <=  OK - JDBC Pool : " ${jdbc_pool_g[$n]} " - Current state:" ${jdbc_pool_stat_g[$n]} "=>"
                                                else
							if [[ ${jdbc_pool_stat_g[$n]} = "Overloaded" ]];then
								printf "%s%s%s%s%s" " <= WARN - JDBC Pool : " ${jdbc_pool_g[$n]} " - Current state:" ${jdbc_pool_stat_g[$n]} "=>"
								(( warn_num=${warn_num}+1 ))
							else
                                                        	printf "%s%s%s%s%s" " <= CRIT - JDBC Pool : " ${jdbc_pool_g[$n]} " - Current state:" ${jdbc_pool_stat_g[$n]} "=>"
                                                        	(( crit_num=${crit_num}+1 ))
							fi
                                                fi
                                        else
                                                printf "%s%s%s%s%s" " <= JDBC Pool : " ${jdbc_pool_g[$n]} " - Current state:" ${jdbc_pool_stat_g[$n]} "=>"              
                                        fi
                                        (( n=${n}+1 ))
                                done
                                if [[ ${crit_num} -gt 0 ]];then
                                        exit $STATE_CRITICAL
                                else
					if [[ ${warn_num} -gt 0 ]]; then
						exit $STATE_WARNING
					else
                                        	exit $STATE_OK
					fi
                                fi
                        else
                                echo "ERROR -Can't get Weblogic JDBC STATE INFO"
                                exit $STATE_UNKNOWN
                        fi
                        ;;	
		#Check Hogging Thread    
		#2011-03-28 add below check portion
		hoggingthread)
			if [[ -n $PORT ]];then
				hogging_thread=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME}:${PORT} $threadPoolRuntimeHoggingThreadCount | gawk '{print $NF}' )
			else
				hogging_thread=$( $SNMPWALK -v $VER -c ${COMMUNITY}@${TITLE1} ${HOSTNAME} $threadPoolRuntimeHoggingThreadCount | gawk '{print $NF}' )
			fi
			if [[ -n ${hogging_thread} && ${hogging_thread} != "Such" ]];then
				DATE_TIME=$( /bin/date "+%Y-%m-%d %H:%M:%S" )
				printf "%-10s %s\tHoggingThread: %-10s \n" ${DATE_TIME} ${hogging_thread} >>${output}/${HOSTNAME}_${TITLE1}_${PORT}_hoggingthread.out
				#2011-04-28 write data to file order by date
				File_Date=$( /bin/date +%Y%m%d )
				printf "%-10s %s\tHoggingThread: %-10s \n" ${DATE_TIME} ${hogging_thread} >>${output1}/${HOSTNAME}_${TITLE1}_${PORT}_hoggingthread.${File_Date}
				if [[ -n $CRIT ]] || [[ -n $WARN ]];then
					if [[ -n $CRIT ]];then
						if [[ ${hogging_thread} -gt $CRIT ]];then
							printf "%s%s%s%s\n" "CRIT - " ${TITLE1} " Hogging Thread Count: " ${hogging_thread}
							exit $STATE_UNKNOWN
						fi
					fi
					if [[ -n $WARN ]];then
						if [[ ${hogging_thread} -gt $WARN ]];then
							printf "%s%s%s%s\n" "WARN - " ${TITLE1} " Hogging Thread Count: " ${hogging_thread}
							exit $STATE_WARNING
						fi
					fi
					printf "%s%s%s%s\n" "OK - " ${TITLE1} " Hogging Thread Count: " ${hogging_thread}
					exit $STATE_OK
							
				else
					if [[ ${hogging_thread} -gt 0 ]];then
						printf "%s%s%s%s\n" "CRIT - " ${TITLE1} " Hogging Thread Count: " ${hogging_thread}
						exit $STATE_UNKNOWN
					else
						printf "%s%s\n"  "OK - There is no hogging thread on " ${TITLE1}
						exit $STATE_OK
					fi
				fi
			else
				echo "ERROR -Can't get Weblogic Hogging Thread INFO"
				exit $STATE_UNKNOWN
			fi			
			;;
	esac
else
	print_help
	exit $STATE_UNKNOWN
fi

