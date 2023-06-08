SELECT olm.[name], olm.[file_version], olm.[product_version], olm.[description], SUM(ovad.[region_size_in_bytes])/1024 [Module Size in KB], olm.[base_address] FROM sys.dm_os_virtual_address_dump ovad
INNER JOIN sys.dm_os_loaded_modules olm ON olm.base_address = ovad.region_allocation_base_address
GROUP BY olm.[name],olm.[file_version], olm.[product_version], olm.[description],olm.[base_address]
ORDER BY [Module Size in KB] DESC 
