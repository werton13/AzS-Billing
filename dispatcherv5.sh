#!/bin/bash
#export START_BILL_DATE=$(date -d "$date -30 day" +%F  )
#export END_BILL_DATE=$(date  +%F  )
export START_BILL_DATE="$(date +%Y)-$(date -d "$date - 1 month" +%m)-25 16:00:00"
export END_BILL_DATE="$(date +%Y-%m-25) 18:00:00"


sublist=($(sed '/^$/d' <(sed '$d' <(sed '1,2d' <(sqlcmd -m 1 -S "$SQL_IP,$SQL_TCPPORT" -d "$SQL_DB" -U "$SQL_USER" -P "$SQL_PWD" -V 1 -i ./getsubsclist.sql  -W -w 999 -s";")))))
for s in ${sublist[@]}
do
        #echo $s
	export BILL_SUBSCRIPTION_ID=${s}
	FOLDERNAME=$(sed 's/"//g' <(sed 's/ /_/g' <(sed '$d' <( sed '3,5d' <(sed '1,2d' <(  sqlcmd -m 1 -S "$SQL_IP,$SQL_TCPPORT" -d "$SQL_DB"  \
	 -U "$SQL_USER" -P "$SQL_PWD" -i ./getsubscribername.sql  -W -w 999 -s";")))))).$(date +%B-%Y)
	mkdir $FOLDERNAME
	cd  $FOLDERNAME
	REPORTPATH=$(pwd)
	cd ..

	sqlcmd -m 1 -S "$SQL_IP,$SQL_TCPPORT" -d "$SQL_DB" \
	 -U "$SQL_USER" -P "$SQL_PWD" -i ./getsinglebillv2.sql  -W -w 999 -s";"  -o "temporary.csv" \
	 && sed '$d' <(sed '2d' <(sed -n '/ForisCodeId/,$p'  <(cat temporary.csv))) >$REPORTPATH/AzureStackBillingDetails$(date +%F).csv  \
	 && sed -n '/Bill Period/,/ForisCodeId/p' temporary.csv | grep 'Bill\|Total\|Resource type' >$REPORTPATH/AzureStackUsageBillInfo$(date +%F).txt

	zip -r $FOLDERNAME.zip $FOLDERNAME
	
	 az storage blob upload \
	    --account-name billingreports \
	    --container-name bill-uploads \
	    --name $FOLDERNAME.zip \
	    --file $FOLDERNAME.zip \
            --auth-mode key \
	    --account-key "$SA_KEY"



done