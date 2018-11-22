#!/bin/bash
#���Nagios�������check_nt�������ӡ������10.1.5.128��10.1.5.129�����ŵ�14����ӡ����
#��Щ���̿����κ����������̨�����ϣ�ֻҪ14�������У���OK
#Finished by HongRui Wang at 2012-1-13
#�����쳣ʱ����ʾ��10.1.5.128���еĽ����10.1.5.129����check_nt�Ľ��������track��
#Test on SUSE10SP2 x86_64


CHECK_NT=/usr/local/nagios/libexec/check_nt 
YY_HOST1="10.1.5.128"
YY_HOST2="10.1.5.129"
NRPE_PORT=12489

#Ҫ�������н���
procs="901221_ZDYY1.exe,901222_ZDYY2.exe,901223_ZDYY3.exe,901227_PLYY1.exe,901233_TCPJ1.exe,901234_TCPJ2.exe,901235_TCPJ3.exe,901224_ZDYY4.exe,901225_ZDYY5.exe,901226_ZDYY6.exe,901236_TCPJ4.exe,901237_TCPJ5.exe,901238_TCPJ6.exe,901239_PLYY2.exe"
#ͨ��check_nt���������10.1.5.128�ϵĽ��̣��᷵��û�����еĽ�������״̬
R_ON_YYHOST1=$( ${CHECK_NT} -H ${YY_HOST1} -t 20 -p ${NRPE_PORT} -v PROCSTATE -l ${procs} )
#���˳�û��������10.1.5.128�ϵĽ����б�
UNRUN_ON_YYHOST1=$( echo ${R_ON_YYHOST1} |gawk -F" " '{printf $1$5$9$13$17$21$25}'|sed -e 's/:$//g' -e 's/:/,/g' )
#���û��������10.1.5.128�ϵĽ����Ƿ���10.1.5.129������
R_ON_YYHOST2=$( ${CHECK_NT} -H ${YY_HOST2} -t 20 -p ${NRPE_PORT} -v PROCSTATE -l ${UNRUN_ON_YYHOST1} )
#���Ƿ�OK
OK_ON_BOTH=$( echo ${R_ON_YYHOST2} | gawk -F":" '{printf $1}' )
if [[ ${OK_ON_BOTH} == "OK" ]];then
	echo "OK - 14 YanYin Services are running on ${YY_HOST1} and ${YY_HOST2}"
	exit 0
else
	ERR_ON_BOTH=$( echo ${R_ON_YYHOST2} |gawk -F" " '{printf $1$5$9$13$17$21$25}'|sed -e 's/:$//g' -e 's/:/,/g' )
	echo "ERR - Below YANYIN Services: ${ERR_ON_BOTH} are not running on ${YY_HOST1} or ${YY_HOST2}"
	echo "check_nt Result from 10.1.5.128: $R_ON_YYHOST1"
	echo "Not running on 10.1.5.128 : $UNRUN_ON_YYHOST1"
	echo "check_nt Result from 10.1.5.129: $R_ON_YYHOST2"
	exit 2
fi
