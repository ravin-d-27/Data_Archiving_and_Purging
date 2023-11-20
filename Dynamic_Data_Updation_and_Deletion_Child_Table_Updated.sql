/*
    In this Script, the Child Log Table is Updated with extra columns                     

    1) Column Name of the primary key of the table
    2) Data type of the primary key column
    3) No of primary keys moved

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




CREATE PROCEDURE GetPrimaryKeyInfo_6
    @TableName NVARCHAR(255),
    @PrimaryKeyColumnName NVARCHAR(255) OUTPUT,
    @PrimaryKeyDataType NVARCHAR(50) OUTPUT,
    @PrimaryKeyValues NVARCHAR(MAX) OUTPUT,
    @PrimaryKeyCount INT OUTPUT
AS
BEGIN
    DECLARE @PrimaryKeyConstraintName NVARCHAR(255);

    -- Find the primary key column and constraint name
    SELECT @PrimaryKeyColumnName = COLUMN_NAME,
           @PrimaryKeyConstraintName = CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
    WHERE TABLE_NAME = @TableName
        AND CONSTRAINT_NAME = (
            SELECT CONSTRAINT_NAME
            FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
            WHERE TABLE_NAME = @TableName
                AND CONSTRAINT_TYPE = 'PRIMARY KEY'
        );

    IF @PrimaryKeyColumnName IS NOT NULL
    BEGIN
        -- Get the data type of the primary key column
        SELECT @PrimaryKeyDataType = DATA_TYPE
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = @TableName
            AND COLUMN_NAME = @PrimaryKeyColumnName;

        SET @PrimaryKeyValues = '';

        -- Dynamically generate SQL to retrieve primary key values
        DECLARE @DynamicSQL NVARCHAR(MAX);
        SET @DynamicSQL = '
            SELECT @PrimaryKeyValues = COALESCE(@PrimaryKeyValues + '', '', '''') + CONVERT(NVARCHAR(MAX), ' + QUOTENAME(@PrimaryKeyColumnName) + ')
            FROM ' + QUOTENAME(@TableName);

        -- Execute dynamic SQL
        EXEC sp_executesql @DynamicSQL, N'@PrimaryKeyValues NVARCHAR(MAX) OUTPUT', @PrimaryKeyValues OUTPUT;

        -- Output primary key column information
        PRINT 'Primary Key Column: ' + @PrimaryKeyColumnName;
        PRINT 'Data Type: ' + @PrimaryKeyDataType;
        PRINT 'Primary Key Values: ' + @PrimaryKeyValues;

        -- Get the count of primary keys moved using dynamic SQL
        DECLARE @CountSQL NVARCHAR(MAX);
        SET @CountSQL = 'SELECT @PrimaryKeyCount = COUNT(*) FROM ' + QUOTENAME(@TableName);
        EXEC sp_executesql @CountSQL, N'@PrimaryKeyCount INT OUTPUT', @PrimaryKeyCount OUTPUT;

        -- Output count of primary keys moved
        PRINT 'Number of Primary Keys Moved: ' + CAST(@PrimaryKeyCount AS NVARCHAR(MAX));
    END
    ELSE
    BEGIN
        PRINT 'No primary key found for the specified table.';
    END
END;


DECLARE @result nvarchar(max);
DECLARE @result_cols nvarchar(max);
DECLARE @result_datatype nvarchar(max);
DECLARE @result_count int;



EXEC GetPrimaryKeyInfo_6 'ChildTable2', @result_cols OUTPUT, @result_datatype OUTPUT, @result OUTPUT, @result_count OUTPUT;
print @result;
print @result_cols;
print @result_datatype;
print @result_count;











CREATE PROCEDURE UPDATION_OF_DATA_PROPER_LOGS_FAULT_TOLERANCE_HEADER_CHILD_13
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

	select * from #ChildTables;
	
	DECLARE @StartTime DATETIME, @EndTime DATETIME;
	SET @StartTime = GETDATE();

	Create table #tempPrimary (logid int, tablename nvarchar(max), column_name nvarchar(max), datatype nvarchar(max), prim_keys nvarchar(max), no_of_prim int);


		DECLARE @Purpose NVARCHAR(MAX);
		DECLARE @Status NVARCHAR(MAX);
		DECLARE @DestinationTableNames NVARCHAR(MAX);
		DECLARE @TablesChanged NVARCHAR(MAX);
		DECLARE @SourceTableName NVARCHAR(MAX);
		DECLARE @Message_Req NVARCHAR(MAX);

		DECLARE @final nvarchar(MAX);
		DECLARE @change nvarchar(MAX);

	 -- Creating a fix table if doesnt exists
	  SET @SQL = '
        IF NOT EXISTS (SELECT 1 FROM ' + QUOTENAME(@TargetDatabase) + '.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ' + QUOTENAME(@TargetSchema, '''') + ' AND TABLE_NAME = ''fix_table'')
        BEGIN
            CREATE TABLE ' + QUOTENAME(@TargetDatabase) + '.' + QUOTENAME(@TargetSchema) + '.fix_table (
                LogsID INT IDENTITY(1,1) PRIMARY KEY,
                LogMessage NVARCHAR(MAX),
                CreationDateTime DATETIME DEFAULT GETDATE()
            );
        END;
    ';
    EXEC(@SQL);

    -- Insert a record into fix_table and get the generated LogsID
    SET @SQL = '
        USE ' + QUOTENAME(@TargetDatabase) + ';
        INSERT INTO ' + QUOTENAME(@TargetSchema) + '.fix_table (LogMessage)
        VALUES (@message);
        SET @LogsID = SCOPE_IDENTITY();';
    EXEC sp_executesql @SQL, N'@message NVARCHAR(MAX), @LogsID INT OUTPUT', @message, @LogsID OUTPUT;


	-- Create Header_Log_Table if it doesn't exist
	SET @SQL = '
		IF NOT EXISTS (SELECT 1 FROM ' + QUOTENAME(@TargetDatabase) + '.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ' + QUOTENAME(@TargetSchema, '''') + ' AND TABLE_NAME = ''Header_Log_Table'')
		BEGIN
			CREATE TABLE ' + QUOTENAME(@TargetDatabase) + '.' + QUOTENAME(@TargetSchema) + '.Header_Log_Table (
				LogID INT IDENTITY(1,1) PRIMARY KEY,
				Purpose NVARCHAR(MAX),
				SourceTableName NVARCHAR(MAX),
				DestinationTableNames NVARCHAR(MAX),
				TablesChanged NVARCHAR(MAX),
				StartTime DATETIME,
				EndTime DATETIME,
				Status NVARCHAR(50),
			);
		END;
	';
	EXEC(@SQL);


		-- Create Child_Log_Table if it doesn't exist
	SET @SQL = '
		IF NOT EXISTS (SELECT 1 FROM ' + QUOTENAME(@TargetDatabase) + '.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ' + QUOTENAME(@TargetSchema, '''') + ' AND TABLE_NAME = ''Child_Log_Table'')
		BEGIN
			CREATE TABLE ' + QUOTENAME(@TargetDatabase) + '.' + QUOTENAME(@TargetSchema) + '.Child_Log_Table (
				LogID INT IDENTITY(1,1),
				TableName NVARCHAR(MAX),
				ColumnName NVARCHAR(MAX),
				DataType NVARCHAR(MAX),
				PrimaryKeysMoved NVARCHAR(MAX),
				No_of_Keys_Moved int,
				CreationDateTime DATETIME DEFAULT GETDATE()
			);
		END;
	';
	EXEC(@SQL);

	BEGIN TRY

    -- Check if target table exists, if yes, insert data, else create the table and add the data from the source
    SET @SQL = '
    IF EXISTS (SELECT 1 FROM ' + QUOTENAME(@TargetDatabase) + '.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ' + QUOTENAME(@TargetSchema, '''') + ' AND TABLE_NAME = ''' + @TargetTable + ''')
    BEGIN
        USE ' + QUOTENAME(@TargetDatabase) + ';
        INSERT INTO ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable) + '
        SELECT @LogsID AS LogsID, *
        FROM ' + QUOTENAME(@SourceDatabase) + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTable) +
        @condition + ';
    END;
    ELSE
    BEGIN
        USE ' + QUOTENAME(@TargetDatabase) + ';
        SELECT @LogsID AS LogsID, *
        INTO ' + QUOTENAME(@TargetDatabase) + '.' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable) + '
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
				DECLARE @pri_col_val NVARCHAR(MAX);
				DECLARE @pri_col_datatype NVARCHAR(MAX);
				DECLARE @prim_vals NVARCHAR(MAX);
				DECLARE @prim_count NVARCHAR(MAX);

				EXEC GetPrimaryKeyInfo_6 ''' + @ChildTableName + ''', @pri_col_val OUTPUT, @pri_col_datatype OUTPUT, @prim_vals OUTPUT, @prim_count OUTPUT;
				INSERT INTO #tempPrimary (logid, tablename , column_name, datatype, prim_keys, no_of_prim) VALUES (@LogsID, ''' + QUOTENAME(@ChildTableName) + ''', @pri_col_val, @pri_col_datatype, @prim_vals, @prim_count);
					';

				EXEC sp_executesql @SQL, N'@LogsID INT', @LogsID;

				select * from #tempPrimary;
		
				BEGIN TRY


				SET @SQL = '
						IF EXISTS (SELECT 1 FROM ' + QUOTENAME(@TargetDatabase) + '.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ' + QUOTENAME(@TargetSchema, '''') + ' AND TABLE_NAME = ''' + @ChildTableName + ''')
						BEGIN
							USE ' + QUOTENAME(@TargetDatabase) + ';
							INSERT INTO ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@ChildTableName) + '
							SELECT @LogsID AS LogsID, *
							FROM ' + QUOTENAME(@SourceDatabase) + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@ChildTableName) + @condition + ';
						END;
						ELSE
						BEGIN
							USE ' + QUOTENAME(@TargetDatabase) + ';
							SELECT @LogsID AS LogsID, *
							INTO ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@ChildTableName) + '
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

			DECLARE @primaryKeysList3 NVARCHAR(255);
			set @primaryKeysList3 = 'Need to find';

		-- Insert a record into Header_Log_Table and get the generated LogsID
		SET @SQL = '
		USE ' + QUOTENAME(@TargetDatabase) + ';
		INSERT INTO ' + QUOTENAME(@TargetSchema) + '.Header_Log_Table (
			Purpose,
			SourceTableName,
			DestinationTableNames,
			TablesChanged,
			StartTime,
			EndTime,
			Status
		)
		VALUES (
			@Purpose,
			@SourceTableName,
			@DestinationTableNames,
			@TablesChanged,
			@StartTime,
			@EndTime,
			@Status
		);
 
	';

		
		SET @Purpose = @message;
		SET @Status = 'Done';
		SET @DestinationTableNames = @TargetDatabase +' . '+ @TargetSchema + ' . ' + @TargetTable;
		SET @TablesChanged = 'Deciding';
		SET @SourceTableName = @SourceTable;
		SET @Message_Req = @message;


		EXEC FindChildTablesForParent_Working_5 @parent_table = @SourceTable, @final_list = @final OUTPUT, @changed_list = @change OUTPUT;

		EXEC sp_executesql @SQL, N'@Purpose NVARCHAR(MAX), @SourceTableName NVARCHAR(MAX), @DestinationTableNames NVARCHAR(MAX), @TablesChanged NVARCHAR(MAX), @StartTime DATETIME, @EndTime DATETIME, @Status NVARCHAR(50), @LogsID INT OUTPUT', 
			@Purpose, @SourceTableName, @DestinationTableNames, @change, @StartTime, @EndTime, @Status, @LogsID OUTPUT;

	END TRY
	BEGIN CATCH

		SET @EndTime = GETDATE();
		DECLARE @primaryKeysList4 NVARCHAR(255);
		set @primaryKeysList4 = 'Need to find';

		-- Insert a record into Header_Log_Table and get the generated LogsID
		SET @SQL = '
		USE ' + QUOTENAME(@TargetDatabase) + ';
		INSERT INTO ' + QUOTENAME(@TargetSchema) + '.Header_Log_Table (
			Purpose,
			SourceTableName,
			DestinationTableNames,
			TablesChanged,
			StartTime,
			EndTime,
			Status
		)
		VALUES (
			@Purpose,
			@SourceTableName,
			@DestinationTableNames,
			@TablesChanged,
			@StartTime,
			@EndTime,
			@Status
		);
 
	';
		SET @Purpose = @message;
		SET @Status = '**** Failed ****';
		SET @DestinationTableNames = @TargetDatabase +' . '+ @TargetSchema + ' . ' + @TargetTable;
		SET @TablesChanged = 'Deciding';
		SET @SourceTableName = @SourceTable;
		SET @Message_Req = @message;

		EXEC FindChildTablesForParent_Working_5 @parent_table = @SourceTable, @final_list = @final OUTPUT, @changed_list = @change OUTPUT;

		EXEC sp_executesql @SQL, N'@Purpose NVARCHAR(MAX), @SourceTableName NVARCHAR(MAX), @DestinationTableNames NVARCHAR(MAX), @TablesChanged NVARCHAR(MAX), @StartTime DATETIME, @EndTime DATETIME, @Status NVARCHAR(50), @LogsID INT OUTPUT', 
			@Purpose, @SourceTableName, @DestinationTableNames, @change, @StartTime, @EndTime, @Status, @LogsID OUTPUT;

	END CATCH;

		SET @SQL = '

			SET IDENTITY_INSERT ' + QUOTENAME(@TargetDatabase) + '.' + QUOTENAME(@TargetSchema) + '.Child_Log_Table ON;

			INSERT INTO ' + QUOTENAME(@TargetDatabase) + '.' + QUOTENAME(@TargetSchema) + '.Child_Log_Table (LogID, TableName, ColumnName, DataType, PrimaryKeysMoved, No_of_Keys_Moved)
			SELECT logid, tablename, column_name, datatype, prim_keys, no_of_prim FROM #tempPrimary;

			SET IDENTITY_INSERT ' + QUOTENAME(@TargetDatabase) + '.' + QUOTENAME(@TargetSchema) + '.Child_Log_Table OFF;
	';

	-- Execute the dynamic SQL
	EXEC sp_executesql @SQL;


	select * from #tempPrimary;
	DROP TABLE #tempPrimary;


END;

drop database TestDB_Backup;
Create database TestDB_Backup;


exec UPDATION_OF_DATA_PROPER_LOGS_FAULT_TOLERANCE_HEADER_CHILD_13 'TestDB', 'dbo', 'ParentTable', 'TestDB_Backup', 'dbo', 'ParentTable', '', '','Just a sample try Again';
