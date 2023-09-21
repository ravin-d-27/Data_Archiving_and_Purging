exec CreateDB 'sampledb';
exec DropDB 'sampledb';

exec CopyTableFromSourceToTarget2 'AdventureWorks2022', 'HumanResources','Department', 'sampledb', 'dbo','sampledb_table3';
exec CopyTableFromSourceToTargetWithConditions 'AdventureWorks2022', 'HumanResources','Department', 'sampledb', 'dbo','sampledb_table5','where GroupName = ''Sales and Marketing''';
