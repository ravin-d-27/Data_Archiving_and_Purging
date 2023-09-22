exec CreateDB 'sampledb';
exec DropDB 'sampledb';

exec CopyTableFromSourceToTarget2 'AdventureWorks2022', 'HumanResources','Department', 'sampledb', 'dbo','sampledb_table3';
exec CopyTableFromSourceToTargetWithConditions 'AdventureWorks2022', 'HumanResources','Department', 'sampledb', 'dbo','sampledb_table5','where GroupName = ''Sales and Marketing''';

-- For using COPY_ALL_DATA_INCLUDING_CHILD_TABLES_Modified, you have to be in the source database itself for proper functioning
use AdventureWorks2022;
exec COPY_ALL_DATA_INCLUDING_CHILD_TABLES_Modified 'AdventureWorks2022', 'Person', 'Person', 'AdventureWorks2022Backup', 'dbo', 'Person', '';