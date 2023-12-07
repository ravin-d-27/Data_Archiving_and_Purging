
/*
    This stored procedure creates a temporary table to store column names and data types of a source table.
    It then removes the column names that exist in the destination table and selects the remaining columns (missing in destination) along with their data types.
    The stored procedure then uses a cursor to loop through the remaining columns and their data types, and adds them to the destination table.
    Finally, the temporary table is dropped.
    
    Parameters:
        @source_table_name: the name of the source table
        @destination_table_name: the name of the destination table
    
    Example usage:
        EXEC FindMissingColumns_with_datatype_and_update_1 'source_table', 'destination_table'
*/
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



/*
    This stored procedure finds the extra columns in a source table that are not present in a destination table.
    It takes the source table name, destination table name, and an output parameter for the column list as input.
    The output parameter will contain a comma-separated list of the extra columns in the source table.
    The procedure creates two temporary tables to store the column names and uses dynamic SQL to query the column names from the source and destination tables.
    It then removes the column names that exist in the destination table and concatenates the remaining column names into the output parameter.
*/

CREATE PROCEDURE Find_Extra_Columns_Modified_2
    @source_table_name NVARCHAR(255),
    @destination_table_name NVARCHAR(255),
	@ColumnList NVARCHAR(MAX) OUTPUT
AS
BEGIN
    -- Create temporary tables to store column names
    CREATE TABLE #temp_columns (column_name NVARCHAR(255));
	CREATE TABLE #temp_columns2 (column_name NVARCHAR(255));
    
    DECLARE @source_db NVARCHAR(255);
    SET @source_db = PARSENAME(@source_table_name, 3);

    -- Get the column names from the source table
    DECLARE @source_query NVARCHAR(MAX);
    SET @source_query = 'INSERT INTO #temp_columns (column_name) SELECT COLUMN_NAME FROM ' + @source_db + '.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''' + PARSENAME(@source_table_name, 1) + '''';
    EXEC(@source_query);

	SET @source_query = 'INSERT INTO #temp_columns2 (column_name) SELECT COLUMN_NAME FROM ' + @source_db + '.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''' + PARSENAME(@source_table_name, 1) + '''';
    EXEC(@source_query);

    -- Debug: Print the column names from source table
    PRINT 'Source Table Columns:';
    SELECT column_name FROM #temp_columns;
    
    -- Remove column names that exist in the destination table
    DECLARE @destination_db NVARCHAR(255);
    DECLARE @destination_table NVARCHAR(255);
    SET @destination_db = PARSENAME(@destination_table_name, 3);
    SET @destination_table = PARSENAME(@destination_table_name, 1);
    
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = 'DELETE FROM #temp_columns WHERE column_name IN (SELECT COLUMN_NAME FROM ' + @destination_db + '.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ''' + @destination_table + ''')';
    EXEC(@sql);
    
    -- Debug: Print the remaining columns
    PRINT 'Remaining Columns:';
    SELECT column_name FROM #temp_columns;

    SET @sql = 'DELETE FROM #temp_columns2 WHERE column_name IN (SELECT COLUMN_NAME FROM #temp_columns)';
    EXEC(@sql);

    -- Concatenate column names into @ColumnList
    -- Concatenate column names into @ColumnList
	SET @ColumnList = '';
	SELECT @ColumnList = @ColumnList + ', ' + column_name
	FROM #temp_columns2;

	-- Remove leading comma and space
	IF LEN(@ColumnList) > 2
		SET @ColumnList = SUBSTRING(@ColumnList, 3, LEN(@ColumnList) - 2);

    -- Drop the temporary tables
    DROP TABLE #temp_columns;
    DROP TABLE #temp_columns2;
END;


/*
    This stored procedure updates data from a source table to a target table and its child tables.
    It takes in the names of the source and target databases, schemas, and tables, as well as a condition to filter the data.
    The procedure first finds the child tables of the source table and stores them in a temporary table.
    It then creates a log table in the target database if it doesn't exist and inserts a record into it.
    Next, it checks if the target table exists and inserts data into it if it does.
    It then checks if each child table exists and inserts data into it if it does.
    If a child table doesn't exist, it tries to alter the table structure to match the source table and inserts data into it.
    If altering the table structure fails, it finds the extra columns in the destination table and inserts data into it.
*/
CREATE PROCEDURE UPDATION_OF_DATA_FINAL_104
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

				BEGIN TRY
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

				END TRY
				BEGIN CATCH

				DECLARE @TargetTablePath_Dest NVARCHAR(1000);
				DECLARE @TargetTablePath_Source NVARCHAR(1000);
				SET @TargetTablePath_Dest = QUOTENAME(@TargetDatabase) + '.' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@ChildTableName);
				SET @TargetTablePath_Source = QUOTENAME(@SourceDatabase) + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@ChildTableName);

				DECLARE @result nvarchar(max);
				EXEC Find_Extra_Columns_Modified_2 @TargetTablePath_Dest, @TargetTablePath_Source, @ColumnList = @result OUTPUT;
				PRINT CONVERT(VARCHAR, @result);

				

				SET @SQL = '
				IF EXISTS (SELECT 1 FROM ' + QUOTENAME(@TargetDatabase) + '.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ' + QUOTENAME(@TargetSchema, '''') + ' AND TABLE_NAME = ''' + @ChildTableName + ''')
				BEGIN
					USE ' + QUOTENAME(@TargetDatabase) + ';
					INSERT INTO ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@ChildTableName) + ' ('+'LogsID, '+ @result + ')
					SELECT @LogsID AS LogsID, ' + @result + '
					FROM ' + QUOTENAME(@SourceDatabase) + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@ChildTableName) + @condition + ';
				END;
				';

				PRINT 'Dynamic SQL Statement:';
				PRINT @SQL;

				EXEC sp_executesql @SQL, N'@LogsID INT', @LogsID;

				-- Write the part here
				END CATCH

			END CATCH

			FETCH NEXT FROM childTablesCursor INTO @ChildTableName;

		END;

		CLOSE childTablesCursor;
		DEALLOCATE childTablesCursor;

    -- Clean up temporary table
    DROP TABLE #ChildTables;
END;

exec UPDATION_OF_DATA_FINAL_104 'TestDB', 'dbo', 'ParentTable', 'TestDB_Backup', 'dbo', 'ParentTable', '', '','Copying';