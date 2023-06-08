SELECT olm.[name], olm.[file_version], olm.[product_version], olm.[description], ovad.[region_size_in_bytes], olm.[base_address], ovad.[region_base_address], ovad.[region_type]
FROM sys.dm_os_virtual_address_dump ovad
INNER JOIN sys.dm_os_loaded_modules olm ON olm.base_address = ovad.region_allocation_base_address
ORDER BY name
