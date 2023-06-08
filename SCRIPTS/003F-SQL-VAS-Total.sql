SELECT SUM(ovad.[region_size_in_bytes])/1024.0/1024.0 [Total Module Size in MB] FROM sys.dm_os_virtual_address_dump ovad INNER JOIN sys.dm_os_loaded_modules olm ON olm.base_address = ovad.region_allocation_base_address