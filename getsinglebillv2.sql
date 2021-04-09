DECLARE @tempbill TABLE (ForisCodeId varchar(15), 
						 UsageStartTime datetime,
						 UsageEndTime datetime, 
						 SubscriptionId uniqueidentifier, 
						 MeterId uniqueidentifier,
						 MeterName nchar(50),
						 Category varchar(25),
						 MeterDesc  nchar(50),
						 Info1 nvarchar(255),
						 ResourceId nvarchar(255), 
						 Quantity real,
						 [GPL Price] numeric(9,4),
						 [Base Cost] real,
						 [Personal Discont] varchar(10),
						 [Final Cost] real
						 )


DECLARE @CustomerName nvarchar(255)
set @CustomerName = (select DisplayName from dbo.v_Subscriptions where SubscriptionId = '$(BILL_SUBSCRIPTION_ID)' )
INSERT INTO @tempbill
SELECT 
       c.[ForisCodeId] /*this column should ne first*/
      ,su.[UsageStartTime]
      ,su.[UsageEndTime]
      ,su.[SubscriptionId]
      ,su.[MeterId]
	  ,meters.[MeterName]
      ,p.Category 
	  ,d.[MeterDesc]
	  ,su.[Info1]
	  ,su.[ResourceId]
      ,su.[Quantity] as Quantity
      ,p.[PricePerUnit] as 'GPL Price'
	  ,su.Quantity*p.PricePerUnit as 'Base Cost'
	/*Here we comparing dbo.v_Prices category column with all hardcoded categorys and if match - we compute a 'Personal Discont' column value here as varchar  */  
	  ,(case 
			 when p.category like 'Compute' then ( CONVERT(varchar(10),(select (1 -(select [compute] from Disconts where ForisCodeId  = c.ForisCodeId))*100) ) + ' %' )
			 when p.category like 'Storage' then ( CONVERT(varchar(10),(select (1 -(select [Storage] from Disconts where ForisCodeId  = c.ForisCodeId))*100) ) + ' %' )
			 when p.category like 'WebApp'  then ( CONVERT(varchar(10),(select (1 -(select [WebApp] from Disconts where ForisCodeId  = c.ForisCodeId))*100) ) + ' %'  )									    
			 when p.category like 'EventHub'  then ( CONVERT(varchar(10),(select (1 -(select [EventHubs] from Disconts where ForisCodeId  = c.ForisCodeId))*100) ) + ' %' )
			 when p.category like 'Database'  then ( CONVERT(varchar(10),(select (1 -(select [Database] from Disconts where ForisCodeId  = c.ForisCodeId))*100) ) + ' %' )
			 when p.category like 'IP Address'  then ( CONVERT(varchar(10),(select (1 -(select [IP Address] from Disconts where ForisCodeId  = c.ForisCodeId))*100) ) + ' %' )
		end ) as 'Personal Discont'
	/*Here we comparing dbo.v_Prices category column with all hardcoded categorys and if match - we compute a 'Personal Discont' * Price*Quantity as a Final Cost after Discont  */  
    
    ,(case 
			 when p.category like 'Compute' then ( 	(select (select [compute] from Disconts where ForisCodeId  = c.ForisCodeId)*su.Quantity*p.PricePerUnit  )  )
			 when p.category like 'Storage' then (  (select (select [Storage] from Disconts where ForisCodeId  = c.ForisCodeId)*su.Quantity*p.PricePerUnit  )  )
			 when p.category like 'WebApp'  then (	(select (select [WebApp] from Disconts where ForisCodeId  = c.ForisCodeId)*su.Quantity*p.PricePerUnit  )  )									    
			 when p.category like 'EventHub'  then ( (select (select [EventHubs] from Disconts where ForisCodeId  = c.ForisCodeId)*su.Quantity*p.PricePerUnit  ) )
             when p.category like 'Database'  then ( (select (select [Database] from Disconts where ForisCodeId  = c.ForisCodeId)*su.Quantity*p.PricePerUnit  )  )
			 when p.category like 'IP Address'  then ( (select (select [IP Address] from Disconts where ForisCodeId  = c.ForisCodeId)*su.Quantity*p.PricePerUnit  ) )
	 end ) as 'Final Cost'



from dbo.v_SubscriberUsage su
join dbo.v_Prices p on su.MeterName = p.MeterName and su.Info1 = p.Counter /*join dbo.v_Prices to extend table with Prices by SKU */
join dbo.v_ForisClients c on su.SubscriptionId = c.SubscriptionId          /*join dbo.v_ForisClients to extend table with ForisClients */
join dbo.v_Meters meters on su.MeterId = meters.MeterId                    /*join dbo.v_Meters to extend table with MeterNames */
join dbo.v_MetersInfo d on meters.metername = d.MeterName                  /*join dbo.v_MetersInfo  to extend table with additional info about SKU-s*/
join dbo.v_Disconts Discont on c.ForisCodeId = Discont.ForisCodeId         /*join dbo.v_Disconrs  to extend table with additional info about Disconts*/


where su.[SubscriptionId] = '$(BILL_SUBSCRIPTION_ID)'
and su.MeterId NOT IN ('7ba084ec-ef9c-4d64-a179-7732c6cb5e28','108fa95b-be0d-4cd9-96e8-5b0d59505df1','daef389a-06e5-4684-a7f7-8813d9f792d5','578ae51d-4ef9-42f9-85ae-42b52d3d83ac') 
and su.UsageStartTime >= '$(START_BILL_DATE)'
and su.UsageEndTime <= '$(END_BILL_DATE)'

select 'Bill Period from: '+ CONVERT(varchar(12), MIN(UsageStartTime)) +' till: ' + CONVERT(varchar(12),MAX(UsageEndTime))  from @tempbill 
select 'Total usage cost for ' + @CustomerName+': '+ CONVERT(varchar(12), sum([Final Cost]))+ ' Rub' from @tempbill

DECLARE @UMeterID nvarchar(255)
DECLARE @MeterName nvarchar(50)
DECLARE @UniquMetersCount int = (select count(DISTINCT(MeterId)) FROM @tempbill)


DECLARE index_umeters CURSOR
    FOR	SELECT  DISTINCT(MeterId) FROM @tempbill
OPEN index_umeters


/*WHILE @@FETCH_STATUS = 0  */
WHILE @UniquMetersCount  > 0
    BEGIN
        FETCH  FROM index_umeters INTO @UMeterID
		set @MeterName = (select MeterName FROM dbo.v_Meters WHERE MeterId = @UMeterID)
		SELECT 'Resource type: '+ @MeterName +' Usage cost: ' + CONVERT(varchar(12),sum([Final Cost])) +' Rub' as MeterCost FROM @tempbill WHERE MeterId like @UMeterID 
		GROUP BY MeterId
		SET @UniquMetersCount = @UniquMetersCount - 1;
    END;
CLOSE  index_umeters
DEALLOCATE  index_umeters

select /*top (5)*/
       ForisCodeId
      ,UsageStartTime
      ,UsageEndTime
      ,SubscriptionId
      ,MeterName
	  ,MeterDesc
      ,ResourceId
      ,format(Quantity,'N16','de-de') as Quantity
      ,format([GPL Price],'N7','de-de') as 'GPL Price'
      ,format([Base Cost],'N16','de-de') as 'Base Cost'
	  ,[Personal Discont]
	  ,format([Final Cost],'N16','de-de') as 'Final Cost'
	
from @tempbill
order by UsageStartTime

