# Data_Archiving_And_Purging_Stable.sql Documentation

## Procedure: FindMissingColumns_with_datatype_and_update_1

### Description:
This procedure is designed to find columns that exist in a source table but not in a destination table, and then add those missing columns to the destination table.

### Parameters:
- `@source_table_name`: The name of the source table to compare.
- `@destination_table_name`: The name of the destination table to be updated.

### Process:
1. A temporary table `#temp_columns` is created to store the column names and their data types from the source table.
2. The column names and data types from the source table are inserted into `#temp_columns`.
3. The column names that exist in the destination table are removed from `#temp_columns`.
4. The remaining columns in `#temp_columns` (those that are missing in the destination table) are selected along with their data types.
5. A cursor `alter_cursor` is declared and opened to iterate through each row of `#temp_columns`.
6. For each row, an `ALTER TABLE` statement is dynamically constructed and executed to add the missing column to the destination table.


## Procedure: Find_Extra_Columns_Modified_2

### Description:
This procedure is designed to find extra columns that exist in a destination table but not in a source table. It's a modified version of a previous procedure, hence the suffix "_2".

### Parameters:
- `@source_table_name`: The name of the source table to compare.
- `@destination_table_name`: The name of the destination table to be checked.

### Process:
1. A temporary table `#temp_columns` is created to store the column names from the destination table.
2. The column names from the destination table are inserted into `#temp_columns`.
3. The column names that exist in the source table are removed from `#temp_columns`.
4. The remaining columns in `#temp_columns` (those that are extra in the destination table) are selected.


## Procedure: FindChildTablesForParent_Working_5

### Description:
This procedure is designed to find child tables for a given parent table in a database. It's a working version of a previous procedure, hence the suffix "_Working_5".

### Parameters:
- `@parent_table`: The name of the parent table for which child tables are to be found.

### Process:
1. `@final_list` is created to store the names of the child tables.
2. The names of the child tables are retrieved from the database metadata (usually from system tables or information schema views) based on the foreign key relationships with the parent table.
3. The formated names of the child tables are stored into `@changed_list`.


## Procedure: GetPrimaryKeyInfo_6

### Description:
This procedure is designed to retrieve information about the primary key of a given table in a database.

### Parameters:
- `@TableName`: The name of the table for which primary key information is to be retrieved.

### Process:
1. The information about the primary key is retrieved from the database metadata (usually from system tables or information schema views).
2. The primary key information includes the primary key name, the column(s) that make up the primary key, and possibly other information such as the data type of the column(s), the order of the columns in the primary key, etc.
3. The primary key information is returned as a result set or possibly inserted into a table or temporary table for further processing.


## Procedure: UPDATION_OF_DATA_PROPER_LOGS_FAULT_TOLERANCE_HEADER_CHILD_25

### Description:
This is the final procedure which is designed to update data in the target database with proper logging and fault tolerance mechanisms. 

### Parameters:
- `@SourceDatabase`- Name of the Source Database
- `@SourceSchema` - Source Database Schema
- `@SourceTable` - Name of the Source Table
- `@TargetDatabase`
- `@TargetSchema` 
- `@TargetTable` 
- `@condition` 
- `@LogsID` 
- `@message`

### Process:
1. The procedure archives the data from source table to target table along with its child tables using procedure `FindChildTablesForParent_Working_5` and `GetPrimaryKeyInfo_6`.
2. The procedure logs its actions in a way that allows for recovery in case of a failure.
3. If an error occurs during the update process, the procedure handles the error in a way that allows for fault tolerance. Whenever a new column is added in the source table, the same column will also be added in the target table also. If a column is removed from the source table, the script won't delete the column in the target table. Instead it preserves the previous data in the column. This operation is done using the procedures `FindMissingColumns_with_datatype_and_update_1` and `Find_Extra_Columns_Modified_2`
4. After finishing the operation (Eventhough the operation is failed), the procedure sends an Email, which has the details of the operation done.