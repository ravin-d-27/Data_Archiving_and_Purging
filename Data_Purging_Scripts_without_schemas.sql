-- Creating and Inserting Data from source table to destination table without any schema names.

CREATE PROCEDURE CreateandInsertDatawithoutSchemaNames
    @SourceDatabase NVARCHAR(100),
    @SourceTable NVARCHAR(100),
    @TargetDatabase NVARCHAR(100),
    @TargetTable NVARCHAR(100)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);

    SET @SQL = '
        USE ' + QUOTENAME(@TargetDatabase) + ';
        SELECT *
        INTO ' + QUOTENAME(@TargetDatabase) + '.dbo.' + QUOTENAME(@TargetTable) + '
        FROM ' + QUOTENAME(@SourceDatabase) + '.dbo.' + QUOTENAME(@SourceTable) + ';
    ';

    EXEC(@SQL);
END;

-- Creating and Inserting Data from source table to destination table if the schema is absent in your SQL

-- Note: This procedure works when the schema is only dbo

CREATE PROCEDURE CreateandInsertDataintheAbsenceofSchema
    @SourceDatabase NVARCHAR(100),
    @SourceTable NVARCHAR(100),
    @TargetDatabase NVARCHAR(100),
    @TargetTable NVARCHAR(100)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);

    SET @SQL = '
        USE ' + QUOTENAME(@TargetDatabase) + ';
        SELECT *
        INTO ' + QUOTENAME(@TargetDatabase) + '.' + QUOTENAME(@TargetTable) + '
        FROM ' + QUOTENAME(@SourceDatabase) + '.' + QUOTENAME(@SourceTable) + ';
    ';

    EXEC(@SQL);
END;


CREATE PROCEDURE COPY_ALL_DATA_INCLUDING_CHILD_TABLES_Modified
    @SourceDatabase NVARCHAR(100),
    @SourceSchema NVARCHAR(100),
    @SourceTable NVARCHAR(100),
    @TargetDatabase NVARCHAR(100),
    @TargetSchema NVARCHAR(100),
    @TargetTable NVARCHAR(100),
    @condition NVARCHAR(MAX)
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

    -- Copy data from source table to target table
    SET @SQL = '
        USE ' + QUOTENAME(@TargetDatabase) + ';
        SELECT *
        INTO ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@TargetTable) + '
        FROM ' + QUOTENAME(@SourceDatabase) + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@SourceTable) +
		@condition + ';';
    EXEC(@SQL);

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
            SELECT *
            INTO ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@ChildTableName) + '
            FROM ' + QUOTENAME(@SourceDatabase) + '.' + QUOTENAME(@SourceSchema) + '.' + QUOTENAME(@ChildTableName) + 
            @condition + ';';
        EXEC(@SQL);

        -- Generate SQL to create foreign key constraint
        SET @SQL = '
            ALTER TABLE ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@ChildTableName) + '
            ADD CONSTRAINT FK_' + @ChildTableName + '_' + @SourceTable + ' FOREIGN KEY (...) 
            REFERENCES ' + QUOTENAME(@TargetSchema) + '.' + QUOTENAME(@SourceTable) + '(...);';
        EXEC(@SQL);

        FETCH NEXT FROM childTablesCursor INTO @ChildTableName;
    END;

    CLOSE childTablesCursor;
    DEALLOCATE childTablesCursor;

    -- Clean up temporary table
    DROP TABLE #ChildTables;
END;
