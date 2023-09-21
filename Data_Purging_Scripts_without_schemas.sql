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