DECLARE @TotalCost float
 
SET @TotalCost = (SELECT sum(su.Quantity*p.[PricePerUnit])

	FROM dbo.v_SubscriberUsage su
	JOIN dbo.v_Prices p ON su.MeterName = p.MeterName and su.Info1 = p.Counter
	JOIN dbo.v_ForisClients c ON su.SubscriptionId = c.SubscriptionId
	WHERE su.[SubscriptionId] IN (
		SELECT SubscriptionId
		FROM [$(SQL_DB)].[dbo].[v_Subscriptions]
		WHERE DisplayName NOT LIKE '%evaluation%'
			  AND IsSystem <> 1
			  AND DisplayName NOT LIKE '%Test%'
			  AND DisplayName NOT LIKE '%Preview%'
			  AND DisplayName NOT LIKE '%Disabled%'
			  AND DisplayName NOT LIKE '%tsttenant%'
			  AND DisplayName NOT LIKE '%2delete%'
			  AND DisplayName NOT LIKE '%guest%'
			  AND DisplayName NOT LIKE '%bonava%'
			  AND DisplayName NOT LIKE '%smartuni%'
			  AND DisplayName NOT LIKE '%brunel%'
			  AND DisplayName NOT LIKE '%exocap%'
			  AND DisplayName NOT LIKE '%travellinesys%'
			  AND SubscriptionId <> '64DF5365-85B3-45B1-AC51-FDA172503D7E'
			  AND SubscriptionId <> '1EA25231-8105-4BBB-ADEF-CC0DD3D2F370'
		)
		AND su.MeterId NOT IN ('7ba084ec-ef9c-4d64-a179-7732c6cb5e28','108fa95b-be0d-4cd9-96e8-5b0d59505df1','daef389a-06e5-4684-a7f7-8813d9f792d5','578ae51d-4ef9-42f9-85ae-42b52d3d83ac') 
		AND su.UsageStartTime >=  '$(START_BILL_DATE)'
		AND su.UsageEndTime   <=  '$(END_BILL_DATE)'
		AND su.location = 'azureMSK'
	)
 +
(

    SELECT sum(su.Quantity*p.[PricePerUnit]) AS SSDRegionTotal
    FROM dbo.v_SubscriberUsage su
    JOIN dbo.v_PricesGen2 p ON su.MeterName = p.MeterName and su.Info1 = p.Counter
    JOIN dbo.v_ForisClients c ON su.SubscriptionId = c.SubscriptionId
    WHERE su.[SubscriptionId] IN (
    	SELECT SubscriptionId
    	FROM	[$(SQL_DB)].[dbo].[v_Subscriptions]
    	WHERE DisplayName NOT LIKE '%evaluation%'
    		  AND IsSystem <> 1
    		  AND DisplayName NOT LIKE '%Test%'
    		  AND DisplayName NOT LIKE '%Preview%'
    		  AND DisplayName NOT LIKE '%Disabled%'
    		  AND DisplayName NOT LIKE '%tsttenant%'
    		  AND DisplayName NOT LIKE '%2delete%'
    		  AND DisplayName NOT LIKE '%guest%'
    		  AND DisplayName NOT LIKE '%bonava%'
    		  AND DisplayName NOT LIKE '%smartuni%'
    		  AND DisplayName NOT LIKE '%brunel%'
    		  AND DisplayName NOT LIKE '%exocap%'
    		  AND DisplayName NOT LIKE '%travellinesys%'
    		  AND SubscriptionId <> '64DF5365-85B3-45B1-AC51-FDA172503D7E'
    		  AND SubscriptionId <> '1EA25231-8105-4BBB-ADEF-CC0DD3D2F370'
    		)
    	AND su.MeterId NOT IN ('7ba084ec-ef9c-4d64-a179-7732c6cb5e28','108fa95b-be0d-4cd9-96e8-5b0d59505df1','daef389a-06e5-4684-a7f7-8813d9f792d5','578ae51d-4ef9-42f9-85ae-42b52d3d83ac') 
    	AND su.UsageStartTime >=  '$(START_BILL_DATE)'
    	AND su.UsageEndTime   <=  '$(END_BILL_DATE)'
    	AND su.location IN ('mskeast','msknorth')
    )
/* prepend 'N' before text with cyrillic in select-
  CAST(@TotalCost AS money),1) - allow nice format for large numners
*/
SELECT N'Azure Stack total usage cost for $(CURRENT_MONTH): '+ CONVERT (varchar(12), CAST(@TotalCost AS money),1) + ' Rub' as SummaryCost 

