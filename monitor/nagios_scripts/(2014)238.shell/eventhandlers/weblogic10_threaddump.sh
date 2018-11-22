#!/bin/bash

#This script is used as nagios event handler.
#��weblogic10���г�����nagios�ĸ澯��ֵ���������ظ澯ʱ���ᴥ���˽ű����˽ű���Ϊnagios���¼�������ʹ�ã�
#�˽ű���ͨ������Nagios�������ϵ�WLSThreadsMonitor.class java��������ȡԶ��weblogic10��threaddump


#$PROGNAME -H HOST -S ServerName -P port -u username -p password -s $SERVICESTATE$ -t $SERVICESTATETYPE$ -n $SERVICEATTEMPT$
#���� -H HOST, -S ServerName,  -P port, -u username, -p password ��Щ��������ָ�����ĸ�weblogic server����threaddump
#���� -s $SERVICESTATE$,-t $SERVICESTATETYPE$, -n $SERVICEATTEMPT$ ������������nagios�ĺ꣬�Ƿ����¼�����ű��б��봦���
#  $SERVICESTATE$  				��ΪOK,WARNING,UNKNOWN,CRITICAL
#  $SERVICESTATETYPE$			��ΪSOFT,HARD
#  $SERVICEATTEMPT$				Ϊ���������ԵĴ���

#�˽ű���nagios���÷����£�
#һ�� ��nagios.cfg��������¶���(���������¼�):
#		enable_event_handlers=1
#
#
#
#���� ��nagios check_commands.cfg���������壺
#          define command{
#					        command_name                    weblogic10_threaddump
#				    	    command_line                    $USER1$/eventhandlers/weblogic10_threaddump.sh -H $HOSTADDRESS$ -S $ARG1$ -P $ARG2$ -u $ARG3$ -p $ARG4$ -s $SERVICESTATE$ -t $SERVICESTATETYPE$ -n $SERVICEATTEMPT$
#						}
#
#���� ��Ҫ�������¼�����ķ���������������¶��壺
#					event_handler                   weblogic10_threaddump!PerServer!8001!weblogic!Weblogic123
#					event_handler_enabled           1
#

#Finished by HRWANG at  2011-10-25 and Published at 10.1.37.238

JAVA_HOME=/BEA/jdk1.6.0_16
CLASSPATH=:/BEA/jdk1.6.0_16/lib:/BEA/jdk1.6.0_16/jre/lib
PATH=/BEA/jdk1.6.0_16/bin/:/BEA/jdk1.6.0_16/jre/bin/:/sbin:/usr/sbin:/usr/local/sbin:/opt/gnome/sbin:/root/bin:/usr/local/bin:/usr/bin:/usr/X11R6/bin:/bin:/usr/games:/opt/gnome/bin:/opt/kde3/bin:/usr/lib/mit/bin:/usr/lib/mit/sbin:/root/bin:/opt/perf/bin

DumpDir="/srv/weblogic_thread_dump/10"
PROGNAME=`basename $0`

print_usage() {
        echo "Usage: "
        echo "  $PROGNAME -H HOST -S ServerName -P Port -u User -p Pass -s SERVICESTATE -t SERVICESTATETYPE -n SERVICEATTEMPT"
		echo " "
        echo "Get thread dump of weblogic server through t3 when assgined nagios state is happened"
		echo " "
		echo "eg:    "
		echo "  $PROGNAME -H 10.1.8.74 -S PerServer -P 8001 -u weblogic -p Weblogic123 -s CRITICAL -t HARD -n 1"
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
			exit 0
			;;
		-h)
			print_help
			exit 0
			;;
		-H)
			WEBLOGIC_HOSTNAME="$2"
			shift
			;;
		-S)
			WEBLOGIC_SERVERNAME="$2"
			shift
			;;
		-P)
			WEBLOGIC_PORT="$2"
			shift
			;;
		-u)
			WEBLOGIC_USER="$2"
			shift
			;;
		-p)
			WEBLOGIC_PASS="$2"
			shift
			;;
		-s)
			NAGIOS_STATE="$2"
			shift
			;;
		-t)
			NAGIOS_STATETYPE="$2"
			shift
			;;
		-n)
			NAIGOS_ATTEMPT="$2"
			shift
			;;
		*)
			print_help
			exit 0
			;;
	esac
	shift
done


CUR_TIME=$(date +%Y%m%d%H%M%S)


if [[ -n ${WEBLOGIC_HOSTNAME} && -n ${WEBLOGIC_SERVERNAME} && -n ${WEBLOGIC_PORT} && -n ${WEBLOGIC_USER} && -n ${WEBLOGIC_PASS} ]];then
	case "${NAGIOS_STATE}" in
		OK)
			#nothing to do 
			;;
		WARNING)
			#nothing to do 
			;;
		UNKNOWN)
			#nothing to do 
			;;
		CRITICAL)
			case "${NAGIOS_STATETYPE}" in
				SOFT)
					#nothing to do 
					;;
				HARD)
					cd /usr/local/nagios/libexec/eventhandlers/weblogic10
					/BEA/jdk1.6.0_16/bin/java -cp .:/BEA/weblogic10/wlserver_10.3/server/lib/weblogic.jar WLSThreadsMonitor ${WEBLOGIC_HOSTNAME} ${WEBLOGIC_SERVERNAME} ${WEBLOGIC_PORT} ${WEBLOGIC_USER} ${WEBLOGIC_PASS} > ${DumpDir}/${WEBLOGIC_HOSTNAME}_${WEBLOGIC_SERVERNAME}_${WEBLOGIC_PORT}_${CUR_TIME} 2>&1
					;;
			esac
			;;
	esac
else
	print_help
fi

exit 0

