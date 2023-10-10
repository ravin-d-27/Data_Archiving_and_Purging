-- THis procedure is used to copy data from one table to another table along with the child tables. If there are any updated rows, running this procedure once again will drop the table and creates the new table with updated column along with the cild tables as well

CREATE PROCEDURE COPY_ALL_DATA_WITH_LOGS_DROPPED_WITH_CHILD
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

    -- Check if target table exists, if yes, drop it
    SET @SQL = '
        IF EXISTS (SELECT 1 FROM ' + QUOTENAME(@TargetDatabase) + '.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ' + QUOTENAME(@TargetSchema, '''') + ' AND TABLE_NAME = ''' + @TargetTable + ''')
        BEGIN
            DROP TABLE ' + QUOTENAME(@TargetDatabase) + '.' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable) + ';
        END;
    ';
    EXEC(@SQL);

		-- Check if child table exists, if yes, drop it
	DECLARE childTablesCursor CURSOR FOR
	SELECT TableName FROM #ChildTables;
	OPEN childTablesCursor;
	FETCH NEXT FROM childTablesCursor INTO @ChildTableName;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @SQL = '
			IF EXISTS (SELECT 1 FROM ' + QUOTENAME(@TargetDatabase) + '.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ' + QUOTENAME(@TargetSchema, '''') + ' AND TABLE_NAME = ''' + @ChildTableName + ''')
			BEGIN
				DROP TABLE ' + QUOTENAME(@TargetDatabase) + '.' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@ChildTableName) + ';
			END;
		';
		EXEC(@SQL);
		FETCH NEXT FROM childTablesCursor INTO @ChildTableName;
	END;
	CLOSE childTablesCursor;
	DEALLOCATE childTablesCursor;

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

-- Executing Command
exec COPY_ALL_DATA_WITH_LOGS_DROPPED_WITH_CHILD 'TestDB', 'dbo', 'ParentTable', 'TestDB_Backup', 'dbo', 'ParentTable', '', '','Copying Parent';