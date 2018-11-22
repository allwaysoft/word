#!/bin/bash

#This script is used as nagios event handler.
#��linuxƽ̨�ϵ�weblogic���г�����nagios�ĸ澯��ֵ���������ظ澯ʱ���ᴥ���˽ű����˽ű���Ϊnagios���¼�������ʹ�ã�
#�˽ű���ͨ��check_nrpe ���ñ����ƽ̨�ϵ�jvm�ڴ�dump�ű�


#$PROGNAME -H HOST -S ServerName -s $SERVICESTATE$ -t $SERVICESTATETYPE$ -n $SERVICEATTEMPT$
#���� -H HOST, -S ServerName ��������������ָ�����ĸ�weblogic server���п���ץȡ
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
#					        command_name                    weblogic_jstack_snapshot
#				    	    command_line                    $USER1$/eventhandlers/nagios_eventhandle_weblogic_jstack.sh -H #$HOSTADDRESS$ -S $ARG1$ -s $SERVICESTATE$ -t $SERVICESTATETYPE$ -n $SERVICEATTEMPT$
#						}
#
#���� ��Ҫ�������¼�����ķ���������������¶��壺
#					event_handler                   weblogic_jstack_snapshot!PerServer
#					event_handler_enabled           1
#

#Finished by HRWANG at  2011-09-01 and Published at 10.1.37.238


PROGNAME=`basename $0`

print_usage() {
        echo "Usage: "
        echo "  $PROGNAME -H HOST -S ServerName -s SERVICESTATE -t SERVICESTATETYPE -n SERVICEATTEMPT"
		echo " "
        echo "Get event queue of weblogic server through t3 when assgined nagios state is happened"
		echo " "
		echo "eg:    "
		echo "  $PROGNAME -H 10.1.8.74 -S PerServer -s CRITICAL -t HARD -n 1"
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


if [[ -n ${WEBLOGIC_HOSTNAME} && -n ${WEBLOGIC_SERVERNAME} ]];then
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
					echo "${CUR_TIME} - Execute weblogic event handler jstack" >> /var/log/jstack_event.log
					/usr/local/nagios/libexec/check_nrpe -H ${WEBLOGIC_HOSTNAME} -t 30 -c jstack_dump -a ${WEBLOGIC_SERVERNAME}
					;;
			esac
			;;
	esac
else
	print_help
fi

exit 0

