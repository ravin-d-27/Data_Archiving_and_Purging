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

-- Create Table and Insert Data from Source DB to Destination DB along with creation time if some conditions are provided

CREATE PROCEDURE CopyTableFromSourceToTargetConditionWithLogColumn
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
        SELECT *, GETDATE() AS Logs
        INTO ' + QUOTENAME(@TargetDatabase) + '.'+ QUOTENAME(@TargetSchema) +'.' + QUOTENAME(@TargetTable) + '
        FROM ' + QUOTENAME(@SourceDatabase) + '.'+ QUOTENAME(@SourceSchema) +'.' + QUOTENAME(@SourceTable) + 
		' ' + @condition + ';';

    EXEC(@SQL);
END;


CREATE PROCEDURE COPY_ALL_DATA_WITH_LOGS
    @SourceDatabase NVARCHAR(100),
    @SourceSchema NVARCHAR(100),
    @SourceTable NVARCHAR(100),
    @TargetDatabase NVARCHAR(100),
    @TargetSchema NVARCHAR(100),
    @TargetTable NVARCHAR(100),
    @condition NVARCHAR(MAX),
    @LogsID INT OUTPUT,
	@message NVARCHAR(MAX)

AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @ChildTableName NVARCHAR(100);

    -- Create temporary table to store child table names
    CREATE TABLE #ChildTables (TableName NVARCHAR(100));

    -- Find child tables
    INSERT INTO #ChildTables
    SELECT t.name
    FROM sys.foreign_keys AS fk
    INNER JOIN sys.tables AS t ON fk.parent_object_id = t.object_id
    WHERE OBJECT_NAME(fk.referenced_object_id) = @SourceTable
      AND SCHEMA_NAME(t.schema_id) = @SourceSchema
      AND DB_NAME() = @SourceDatabase;

    -- Create Log_Table if it doesn't exist
	SET @SQL = '
		IF NOT EXISTS (SELECT 1 FROM ' + QUOTENAME(@TargetDatabase) + '.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ' + QUOTENAME(@TargetSchema, '''') + ' AND TABLE_NAME = ''Log_Table'')
		BEGIN
			CREATE TABLE ' + QUOTENAME(@TargetDatabase) + '.' + QUOTENAME(@TargetSchema) + '.Log_Table (
				LogsID INT IDENTITY(1,1) PRIMARY KEY,
				LogMessage NVARCHAR(MAX),
				CreationDateTime DATETIME DEFAULT GETDATE()
			);
		END;
	';
	EXEC(@SQL);



    -- Insert a record into Log_Table and get the generated LogsID
    SET @SQL = '
    USE ' + QUOTENAME(@TargetDatabase) + ';
    INSERT INTO ' + QUOTENAME(@TargetDatabase) + '.' + QUOTENAME(@TargetSchema) + '.Log_Table (LogMessage)
    VALUES (@message);
    SET @LogsID = SCOPE_IDENTITY();';
	EXEC sp_executesql @SQL, N'@message NVARCHAR(MAX), @LogsID INT OUTPUT', @message, @LogsID OUTPUT;


    -- Copy data from source table to target table
    SET @SQL = '
        USE ' + QUOTENAME(@TargetDatabase) + ';
        SELECT *, @LogsID AS LogsID
        INTO ' + QUOTENAME(@TargetDatabase) + '.' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable) + '
        FROM ' + QUOTENAME(@SourceDatabase) + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTable) +
		@condition + ';';
    EXEC sp_executesql @SQL, N'@LogsID INT', @LogsID;

    -- Create child tables and constraints
    DECLARE childTablesCursor CURSOR FOR
    SELECT TableName FROM #ChildTables;

    OPEN childTablesCursor;
    FETCH NEXT FROM childTablesCursor INTO @ChildTableName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Generate SQL to create child table in target database
        SET @SQL = '
            USE ' + QUOTENAME(@TargetDatabase) + ';
            SELECT *, @LogsID AS LogsID
            INTO ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@ChildTableName) + '
            FROM ' + QUOTENAME(@SourceDatabase) + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@ChildTableName) + 
            @condition + ';';
        EXEC sp_executesql @SQL, N'@LogsID INT', @LogsID;

        FETCH NEXT FROM childTablesCursor INTO @ChildTableName;
    END;

    CLOSE childTablesCursor;
    DEALLOCATE childTablesCursor;

    -- Clean up temporary table
    DROP TABLE #ChildTables;
END;