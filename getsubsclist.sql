SELECT [SubscriptionId]
     /* ,[DisplayName]*/

  FROM [azuremsk-billing].[dbo].[v_Subscriptions]
  WHERE DisplayName NOT LIKE '%evaluation%'
		AND DisplayName NOT LIKE '%Test%'
		AND DisplayName NOT LIKE '%Preview%'
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
		AND IsSystem <> 1
