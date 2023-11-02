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


CREATE PROCEDURE FindChildTablesForParent_Working_5
    @parent_table NVARCHAR(100),
	@final_list NVARCHAR(MAX) OUTPUT,
	@changed_list NVARCHAR(MAX) OUTPUT
AS
BEGIN
    DECLARE @parent_primarykeys NVARCHAR(MAX);
    SET @parent_primarykeys = '';

    
    SET @final_list = '';
	SET @changed_list = '';

	SET @changed_list = @changed_list + QUOTENAME(@parent_table) + ' ';


    -- Get the primary keys of the parent table
    SELECT @parent_primarykeys = @parent_primarykeys + COLUMN_NAME + ', ' 
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
    JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE ccu ON tc.CONSTRAINT_NAME = ccu.CONSTRAINT_NAME
    WHERE tc.TABLE_NAME = @parent_table
      AND tc.CONSTRAINT_TYPE = 'PRIMARY KEY';

    -- Find child tables dynamically
    DECLARE @child_table NVARCHAR(100);
    DECLARE @child_primarykeys NVARCHAR(MAX);

    DECLARE child_cursor CURSOR FOR 
        SELECT
            cu.TABLE_NAME,
            (
                SELECT COLUMN_NAME + ', '
                FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
                WHERE kcu.TABLE_NAME = cu.TABLE_NAME
                FOR XML PATH('')
            ) AS PrimaryKeys
        FROM 
            INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
        JOIN 
            INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc ON rc.UNIQUE_CONSTRAINT_NAME = tc.CONSTRAINT_NAME
        JOIN 
            INFORMATION_SCHEMA.TABLE_CONSTRAINTS cu ON rc.CONSTRAINT_NAME = cu.CONSTRAINT_NAME
        WHERE 
            tc.TABLE_NAME = @parent_table;

    OPEN child_cursor;
    FETCH NEXT FROM child_cursor INTO @child_table, @child_primarykeys;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @final_list = @final_list + 'Child Table: ' + @child_table + CHAR(13) + CHAR(10);
		SET @changed_list = @changed_list +  @child_table + CHAR(13) + CHAR(10);

        SET @final_list = @final_list + 'Primary Keys: ' + @child_primarykeys + CHAR(13) + CHAR(10);
        
        -- Add your processing logic here

        FETCH NEXT FROM child_cursor INTO @child_table, @child_primarykeys;
    END

    CLOSE child_cursor;
    DEALLOCATE child_cursor;

    -- Print the final list for debugging
END;

CREATE PROCEDURE UPDATION_OF_DATA_FINAL_104_WITH_LOGS_UPDATED_17
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
				LogID INT IDENTITY(1,1) PRIMARY KEY,
				Purpose NVARCHAR(MAX),
				SourceTableName NVARCHAR(MAX),
				DestinationTableNames NVARCHAR(MAX),
				TablesChanged NVARCHAR(MAX),
				StartTime DATETIME,
				EndTime DATETIME,
				Status NVARCHAR(50),
				PrimaryKeyMoved NVARCHAR(MAX),
				CreationDateTime DATETIME DEFAULT GETDATE()
			);
		END;
	';
	EXEC(@SQL);


	DECLARE @StartTime DATETIME, @EndTime DATETIME;
	SET @StartTime = GETDATE();

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

	SET @EndTime = GETDATE();

	DECLARE @primaryKeysList NVARCHAR(255);
	EXEC findPrimaryKeys @TargetTablePath_Source, @primaryKeysList OUTPUT;
	SELECT @primaryKeysList;

    -- Insert a record into Log_Table and get the generated LogsID
	SET @SQL = '
    USE ' + QUOTENAME(@TargetDatabase) + ';
    INSERT INTO ' + QUOTENAME(@TargetSchema) + '.Log_Table (
        Purpose,
        SourceTableName,
        DestinationTableNames,
        TablesChanged,
        StartTime,
        EndTime,
        Status,
        PrimaryKeyMoved
    )
    VALUES (
        @Purpose,
        @SourceTableName,
        @DestinationTableNames,
        @TablesChanged,
        @StartTime,
        @EndTime,
        @Status,
        @PrimaryKeyMoved
    );
    SET @LogsID = SCOPE_IDENTITY();
';

	DECLARE @Purpose NVARCHAR(MAX);
	SET @Purpose = @message;

	DECLARE @Status NVARCHAR(MAX);
	SET @Status = 'Done';

	DECLARE @DestinationTableNames NVARCHAR(MAX);
	SET @DestinationTableNames = @TargetDatabase +' . '+ @TargetSchema + ' . ' + @TargetTable;

	DECLARE @TablesChanged NVARCHAR(MAX);
	SET @TablesChanged = 'Deciding';

	DECLARE @SourceTableName NVARCHAR(MAX);
	SET @SourceTableName = @SourceTable;

	DECLARE @Message_Req NVARCHAR(MAX);
	SET @Message_Req = @message;

	DECLARE @final nvarchar(MAX);
	DECLARE @change nvarchar(MAX);
	EXEC FindChildTablesForParent_Working_5 @parent_table = @SourceTable, @final_list = @final OUTPUT, @changed_list = @change OUTPUT;


	EXEC sp_executesql @SQL, N'@Purpose NVARCHAR(MAX), @SourceTableName NVARCHAR(MAX), @DestinationTableNames NVARCHAR(MAX), @TablesChanged NVARCHAR(MAX), @StartTime DATETIME, @EndTime DATETIME, @Status NVARCHAR(50), @PrimaryKeyMoved NVARCHAR(MAX), @LogsID INT OUTPUT', 
		@Purpose, @SourceTableName, @DestinationTableNames, @change, @StartTime, @EndTime, @Status, @final, @LogsID OUTPUT;

END;


exec UPDATION_OF_DATA_FINAL_104_WITH_LOGS_UPDATED_17 'TestDB', 'dbo', 'ParentTable', 'TestDB_Backup', 'dbo', 'ParentTable', '', '','Just a sample try Again';