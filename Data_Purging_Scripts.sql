-- Creating a Database

Create procedure CreateDB
@db_name nvarchar(20)
as
begin

	declare @sql_query nvarchar(MAX)
	set @sql_query = ('Create Database '+ @db_name)
	exec(@sql_query)
end;


-- Dropping a Database

Create procedure DropDB
@db_name nvarchar(20)
as
begin
	
	declare @sql_query nvarchar(MAX)
	if exists (select * from sys.databases where name = @db_name)
    begin
        set @sql_query = ('Drop Database '+@db_name)
        exec (@sql_query)
    end
    else
    begin
        print 'Database does not exist.'
    end
end;



-- Create Table and Insert Data from Source DB to Destination DB

CREATE PROCEDURE CopyTableFromSourceToTarget2
    @SourceDatabase NVARCHAR(100),
	@SourceSchema nvarchar(100),
    @SourceTable NVARCHAR(100),
    @TargetDatabase NVARCHAR(100),
	@TargetSchema nvarchar(100),
    @TargetTable NVARCHAR(100)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);

    SET @SQL = '
        USE ' + QUOTENAME(@TargetDatabase) + ';
        SELECT *
        INTO ' + QUOTENAME(@TargetDatabase) + '.'+ QUOTENAME(@TargetSchema) +'.' + QUOTENAME(@TargetTable) + '
        FROM ' + QUOTENAME(@SourceDatabase) + '.'+ QUOTENAME(@SourceSchema) +'.' + QUOTENAME(@SourceTable) + ';
    ';

    EXEC(@SQL);
END;

-- Create Table and Insert Data from Source DB to Destination DB if some conditions are provided

CREATE PROCEDURE CopyTableFromSourceToTargetWithConditions
    @SourceDatabase NVARCHAR(100),
	@SourceSchema nvarchar(100),
    @SourceTable NVARCHAR(100),
    @TargetDatabase NVARCHAR(100),
	@TargetSchema nvarchar(100),
    @TargetTable NVARCHAR(100),
	@condition nvarchar(MAX)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);

    SET @SQL = '
        USE ' + QUOTENAME(@TargetDatabase) + ';
        SELECT *
        INTO ' + QUOTENAME(@TargetDatabase) + '.'+ QUOTENAME(@TargetSchema) +'.' + QUOTENAME(@TargetTable) + '
        FROM ' + QUOTENAME(@SourceDatabase) + '.'+ QUOTENAME(@SourceSchema) +'.' + QUOTENAME(@SourceTable) + 
		+ @condition +
		';'
		;

    EXEC(@SQL);
END;
