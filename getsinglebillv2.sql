DECLARE @tempbill TABLE (ForisCodeId varchar(15), UsageStartTime datetime, UsageEndTime datetime, SubscriptionId uniqueidentifier, MeterId uniqueidentifier, ResourceId nvarchar(255) , Quantity real, Price numeric(9,4), Cost real)
DECLARE @CustomerName nvarchar(255)
set @CustomerName = (select DisplayName from dbo.v_Subscriptions where SubscriptionId = '$(BILL_SUBSCRIPTION_ID)' )
INSERT INTO @tempbill
SELECT 
       c.[ForisCodeId]
      ,su.[UsageStartTime]
      ,su.[UsageEndTime]
      ,su.[SubscriptionId]
      ,su.[MeterId]
      ,su.[ResourceId]
      ,su.[Quantity] as Quantity
      ,p.[PricePerUnit] as Price
      ,su.Quantity*p.[PricePerUnit]  as Cost
	
from dbo.v_SubscriberUsage su
join dbo.v_Prices p on su.MeterName = p.MeterName and su.Info1 = p.Counter
join dbo.v_ForisClients c on su.SubscriptionId = c.SubscriptionId
where su.[SubscriptionId] = '$(BILL_SUBSCRIPTION_ID)'
and su.MeterId NOT IN ('7ba084ec-ef9c-4d64-a179-7732c6cb5e28','108fa95b-be0d-4cd9-96e8-5b0d59505df1','daef389a-06e5-4684-a7f7-8813d9f792d5','578ae51d-4ef9-42f9-85ae-42b52d3d83ac') 
and su.UsageStartTime >= '$(START_BILL_DATE)'
and su.UsageEndTime <= '$(END_BILL_DATE)'

select 'Bill Period from: '+ CONVERT(varchar(12), MIN(UsageStartTime)) +' till: ' + CONVERT(varchar(12),MAX(UsageEndTime))  from @tempbill 
select 'Total usage cost for ' + @CustomerName+': '+ CONVERT(varchar(12), sum(cost))+ ' Rub' from @tempbill

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
		SELECT 'Resource type: '+ @MeterName +' Usage cost: ' + CONVERT(varchar(12),sum(cost)) +' Rub' as MeterCost FROM @tempbill WHERE MeterId like @UMeterID 
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
      ,MeterId
      ,ResourceId
      ,format(Quantity,'N16','de-de') as Quantity
      ,format(Price,'N7','de-de') as Price
      ,format(Cost,'N16','de-de') as Cost
	
from @tempbill
order by UsageStartTime

