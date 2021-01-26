#!/bin/bash

# version 6.1

# Here we set Start & End billing period, each billing period here start from 25 of previous month
# each billing period start from 16:00:00 and end at 18:00:00 - 25th of current month
# we creating this ENV variables to let them be available from SQL request files

#export START_BILL_DATE="$(date +%Y)-$(date -d "$date - 1 month" +%m)-26 00:00:00"
#export END_BILL_DATE="$(date +%Y-%m-26) 00:00:00"
#change below
export CURRENT_MONTH="$(date +%B)"

	if [ $(date +%m) -eq 01 ]
	then
	        export START_BILL_DATE="$(date -d "$date - 1 year" +%Y)-$(date -d "$date - 1 month" +%m)-26 00:00:00"


	else
	       export START_BILL_DATE="$(date +%Y)-$(date -d "$date - 1 month" +%m)-26 00:00:00"


	fi

	
	export END_BILL_DATE="$(date +%Y-%m-26) 00:00:00"

# Here we get total cost
sed '$d' <(sed '1,2d' <(sqlcmd -m 1 -S "$SQL_IP,$SQL_TCPPORT" -d "$SQL_DB" -U "$SQL_USER" -P "$SQL_PWD" -V 1 -i ./gettotalcost.sql  -W -w 999 -s";")) > AzureStackTotalCost-$CURRENT_MONTH.txt

# Here we get active subscriptions list from database, to place it in array at  iterate through each
sublist=($(sed '/^$/d' <(sed '$d' <(sed '1,2d' <(sqlcmd -m 1 -S "$SQL_IP,$SQL_TCPPORT" -d "$SQL_DB" -U "$SQL_USER" -P "$SQL_PWD" -V 1 -i ./getsubsclist.sql  -W -w 999 -s";")))))
for s in ${sublist[@]}
do
        #echo $s
	export BILL_SUBSCRIPTION_ID=${s}

	# Here we get Subscription Displayname and remove raws above and below, then trailing raw, then parsing Subscriber name to substiture spaces with '_' and remove all ''"''
    # then we creating folder with the name of this subscriber
	FOLDERNAME=$(sed 's/"//g' <(sed 's/ /_/g' <(sed '$d' <( sed '3,5d' <(sed '1,2d' <(  sqlcmd -m 1 -S "$SQL_IP,$SQL_TCPPORT" -d "$SQL_DB"  \
	 -U "$SQL_USER" -P "$SQL_PWD" -i ./getsubscribername.sql  -W -w 999 -s";")))))).$(date +%B-%Y)
	mkdir $FOLDERNAME
	cd  $FOLDERNAME
	REPORTPATH=$(pwd)
	cd ..

    #  in this block we creating two files -1) with information about this Bill 2) with detais usage information and place these file to the folder prepared in the previous step
	sqlcmd -m 1 -S "$SQL_IP,$SQL_TCPPORT" -d "$SQL_DB" \
	 -U "$SQL_USER" -P "$SQL_PWD" -i ./getsinglebillv2.sql  -W -w 999 -s";"  -o "temporary.csv" \
	 && sed '$d' <(sed '2d' <(sed -n '/ForisCodeId/,$p'  <(cat temporary.csv))) >$REPORTPATH/AzureStackBillingDetails$(date +%F).csv  \
	 && sed '2G' <(sed -n '/Bill Period/,/ForisCodeId/p' temporary.csv | grep 'Bill\|Total\|Resource type') >$REPORTPATH/AzureStackUsageBillInfo$(date +%F).txt \
	 && grep "Total" temporary.csv >> AzureStackTotalCost-$CURRENT_MONTH.txt
	
	# here we zip this folder to prepare uploat to the Azure Stack Blob storage 
	zip -r $FOLDERNAME.zip $FOLDERNAME
	
	# here we uploading resulting zip file to the Azure Stack Blob storage
	 az storage blob upload \
	    --account-name $SA_NAME \
	    --container-name $SA_CONTAINER_NAME \
	    --name $FOLDERNAME.zip \
	    --file $FOLDERNAME.zip \
        --auth-mode key \
	    --account-key "$SA_KEY"



done

	 az storage blob upload \
	    --account-name $SA_NAME \
	    --container-name $SA_CONTAINER_NAME \
	    --name AzureStackTotalCost-$CURRENT_MONTH.txt \
	    --file AzureStackTotalCost-$CURRENT_MONTH.txt \
        --auth-mode key \
	    --account-key "$SA_KEY"