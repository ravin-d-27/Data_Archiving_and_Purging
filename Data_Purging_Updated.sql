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


CREATE PROCEDURE UPDATION_OF_DATA
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
        IF NOT EXISTS (SELECT 1 FROM ' + QUOTENAME(@TargetDatabase) + '.' + QUOTENAME(@TargetSchema) + '.Log_Table)
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
        INSERT INTO ' + QUOTENAME(@TargetSchema) + '.Log_Table (LogMessage)
        VALUES (@message);
        SET @LogsID = SCOPE_IDENTITY();';
    EXEC sp_executesql @SQL, N'@message NVARCHAR(MAX), @LogsID INT OUTPUT', @message, @LogsID OUTPUT;

    -- Check if target table exists, if yes, insert data
    SET @SQL = '
        IF EXISTS (SELECT 1 FROM ' + QUOTENAME(@TargetDatabase) + '.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ' + QUOTENAME(@TargetSchema, '''') + ' AND TABLE_NAME = ''' + @TargetTable + ''')
        BEGIN
            USE ' + QUOTENAME(@TargetDatabase) + ';
            INSERT INTO ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable) + '
            SELECT *, @LogsID AS LogsID
            FROM ' + QUOTENAME(@SourceDatabase) + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTable) +
            @condition + ';
        END;
    ';
    -- Pass @LogsID as parameter
    EXEC sp_executesql @SQL, N'@LogsID INT', @LogsID;

    -- Check if child table exists, if yes, Insert it
    DECLARE childTablesCursor CURSOR FOR
    SELECT TableName FROM #ChildTables;
    OPEN childTablesCursor;
    FETCH NEXT FROM childTablesCursor INTO @ChildTableName;
    WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @SQL = '
			IF EXISTS (SELECT 1 FROM ' + QUOTENAME(@TargetDatabase) + '.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ' + QUOTENAME(@TargetSchema, '''') + ' AND TABLE_NAME = ''' + @ChildTableName + ''')
			BEGIN
				USE ' + QUOTENAME(@TargetDatabase) + ';
				INSERT INTO ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@ChildTableName) + '
				SELECT *, @LogsID AS LogsID
				FROM ' + QUOTENAME(@SourceDatabase) + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@ChildTableName) + @condition + ';
			END;
		';
		EXEC sp_executesql @SQL, N'@LogsID INT', @LogsID;
		FETCH NEXT FROM childTablesCursor INTO @ChildTableName;
	END;

    CLOSE childTablesCursor;
    DEALLOCATE childTablesCursor;

    -- Clean up temporary table
    DROP TABLE #ChildTables;
END;

-- Executing Command

exec UPDATION_OF_DATA_106 'TestDB', 'dbo', 'ParentTable', 'TestDB_Backup', 'dbo', 'ParentTable', '', '','Copying';










CREATE PROCEDURE FindMissingColumns_with_datatype_and_update_1
    @source_table_name NVARCHAR(255),
    @destination_table_name NVARCHAR(255)
AS
BEGIN
    -- Create a temporary table to store column names and data types
    CREATE TABLE #temp_columns (column_name NVARCHAR(255), data_type NVARCHAR(50));
    
    -- Get the column names and data types from the source table
    INSERT INTO #temp_columns (column_name, data_type)
    SELECT COLUMN_NAME, DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = @source_table_name;
    
    -- Remove column names that exist in the destination table
    DECLARE @destination_db NVARCHAR(255);
    DECLARE @destination_table NVARCHAR(255);
    SET @destination_db = PARSENAME(@destination_table_name, 3);
    SET @destination_table = PARSENAME(@destination_table_name, 1);
    
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = 'DELETE FROM #temp_columns WHERE column_name IN (SELECT COLUMN_NAME FROM ' + @destination_db + '.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''' + @destination_table + ''')';
    EXEC(@sql);
    
    -- Select the remaining columns (missing in destination) along with their data types
    SELECT column_name, data_type FROM #temp_columns;

	DECLARE @column_name NVARCHAR(255);
	DECLARE @data_type NVARCHAR(50);

	-- ... previous code ...

		DECLARE alter_cursor CURSOR FOR
		SELECT column_name, data_type FROM #temp_columns;

		OPEN alter_cursor;
		FETCH NEXT FROM alter_cursor INTO @column_name, @data_type;

		WHILE @@FETCH_STATUS = 0
		BEGIN
			DECLARE @alter_sql NVARCHAR(MAX);
			SET @alter_sql = 'ALTER TABLE ' + @destination_table_name + ' ADD ' + @column_name + ' ' + @data_type;
			EXEC(@alter_sql);

			FETCH NEXT FROM alter_cursor INTO @column_name, @data_type;
		END

		CLOSE alter_cursor;
		DEALLOCATE alter_cursor;

		-- ... rest of the code ...

    
    -- Drop the temporary table
    DROP TABLE #temp_columns;
END;

EXEC FindMissingColumns_with_datatype_and_update_1 'ChildTable1', 'TestDB_Backup.dbo.ChildTable1';

select * from ChildTable1;
select * from TestDB_Backup.dbo.ChildTable1;

select * from TestDB_Backup.dbo.ChildTable2;




CREATE PROCEDURE UPDATION_OF_DATA_WITH_COLUMNS_UPDATED
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
        IF NOT EXISTS (SELECT 1 FROM ' + QUOTENAME(@TargetDatabase) + '.' + QUOTENAME(@TargetSchema) + '.Log_Table)
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
        INSERT INTO ' + QUOTENAME(@TargetSchema) + '.Log_Table (LogMessage)
        VALUES (@message);
        SET @LogsID = SCOPE_IDENTITY();';
    EXEC sp_executesql @SQL, N'@message NVARCHAR(MAX), @LogsID INT OUTPUT', @message, @LogsID OUTPUT;

    -- Check if target table exists, if yes, insert data
    SET @SQL = '
        IF EXISTS (SELECT 1 FROM ' + QUOTENAME(@TargetDatabase) + '.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ' + QUOTENAME(@TargetSchema, '''') + ' AND TABLE_NAME = ''' + @TargetTable + ''')
        BEGIN
            USE ' + QUOTENAME(@TargetDatabase) + ';
            INSERT INTO ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable) + '
            SELECT @LogsID AS LogsID, *
            FROM ' + QUOTENAME(@SourceDatabase) + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTable) +
            @condition + ';
        END;
    ';
    -- Pass @LogsID as parameter
    EXEC sp_executesql @SQL, N'@LogsID INT', @LogsID;


			 -- Check if child table exists, if yes, Insert it
		DECLARE childTablesCursor CURSOR FOR
		SELECT TableName FROM #ChildTables;
		OPEN childTablesCursor;
		FETCH NEXT FROM childTablesCursor INTO @ChildTableName;
		WHILE @@FETCH_STATUS = 0
		BEGIN
		
		BEGIN TRY


			SET @SQL = '
				IF EXISTS (SELECT 1 FROM ' + QUOTENAME(@TargetDatabase) + '.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ' + QUOTENAME(@TargetSchema, '''') + ' AND TABLE_NAME = ''' + @ChildTableName + ''')
				BEGIN
					USE ' + QUOTENAME(@TargetDatabase) + ';
					INSERT INTO ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@ChildTableName) + '
					SELECT @LogsID AS LogsID, *
					FROM ' + QUOTENAME(@SourceDatabase) + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@ChildTableName) + @condition + ';
				END;
			';
			EXEC sp_executesql @SQL, N'@LogsID INT', @LogsID;

			END TRY
			BEGIN CATCH
				 SET @message = 'Altering the Table Structure';
				 PRINT @message;
				 DECLARE @TargetTablePath NVARCHAR(1000);
				 SET @TargetTablePath = QUOTENAME(@TargetDatabase) + '.' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@ChildTableName);
				 
				 PRINT @ChildTableName;
				 EXEC FindMissingColumns_with_datatype_and_update_1 @ChildTableName, @TargetTablePath;

				SET @SQL = '
				IF EXISTS (SELECT 1 FROM ' + QUOTENAME(@TargetDatabase) + '.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ' + QUOTENAME(@TargetSchema, '''') + ' AND TABLE_NAME = ''' + @ChildTableName + ''')
				BEGIN
					USE ' + QUOTENAME(@TargetDatabase) + ';
					INSERT INTO ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@ChildTableName) + '
					SELECT @LogsID AS LogsID, *
					FROM ' + QUOTENAME(@SourceDatabase) + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@ChildTableName) + @condition + ';
				END;
			';
			EXEC sp_executesql @SQL, N'@LogsID INT', @LogsID;

			END CATCH

			FETCH NEXT FROM childTablesCursor INTO @ChildTableName;

		END;

		CLOSE childTablesCursor;
		DEALLOCATE childTablesCursor;

    -- Clean up temporary table
    DROP TABLE #ChildTables;
END;

-- Executing Command

exec UPDATION_OF_DATA_FINAL_17_TEST'TestDB', 'dbo', 'ParentTable', 'TestDB_Backup', 'dbo', 'ParentTable', '', '','Copying';