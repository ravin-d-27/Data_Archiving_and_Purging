
<body>

<h1>SQL Procedures Documentation</h1>

<p>This repository contains all the codes that helps for Data Purging and Archiving in Microsoft SQL Server</p>
<p>I have also added Python and SQL Server Interface for easy access of data in your python applications</p>

<h1>Refer to Data_Purging_Scripts_without_schemas.sql file</h1>

<body>

<h2>CreateandInsertDatawithoutSchemaNames Procedure</h2>

<h3>Description</h3>

<p>
    The <code>CreateandInsertDatawithoutSchemaNames</code> procedure is used to create and insert data from a source table to a destination table without using schema names.
</p>

<h3>Parameters</h3>

<table>
    <tr>
        <th>Parameter</th>
        <th>Description</th>
    </tr>
    <tr>
        <td><code>@SourceDatabase</code></td>
        <td>Name of the source database.</td>
    </tr>
    <tr>
        <td><code>@SourceTable</code></td>
        <td>Name of the source table.</td>
    </tr>
    <tr>
        <td><code>@TargetDatabase</code></td>
        <td>Name of the target database.</td>
    </tr>
    <tr>
        <td><code>@TargetTable</code></td>
        <td>Name of the target table.</td>
    </tr>
</table>

<h3>Usage</h3>

<pre>
EXEC CreateandInsertDatawithoutSchemaNames
    @SourceDatabase = 'SourceDB',
    @SourceTable = 'SourceTable',
    @TargetDatabase = 'TargetDB',
    @TargetTable = 'TargetTable';
</pre>

<h2>Procedure Steps</h2>

<ol>
    <li>Switch to the target database using the <code>USE</code> statement.</li>
    <li>Select all records from the source table and insert them into the target table.</li>
</ol>

<h2>Example</h2>

<pre>
EXEC CreateandInsertDatawithoutSchemaNames
    @SourceDatabase = 'SourceDB',
    @SourceTable = 'SourceTable',
    @TargetDatabase = 'TargetDB',
    @TargetTable = 'TargetTable';
</pre>

</body>



<body>

<h2>CreateandInsertDataintheAbsenceofSchema Procedure</h2>

<h3>Description</h3>

<p>
    The <code>CreateandInsertDataintheAbsenceofSchema</code> procedure is used to create and insert data from a source table to a destination table when the schema is absent in your SQL.
</p>

<h3>Parameters</h3>

<table>
    <tr>
        <th>Parameter</th>
        <th>Description</th>
    </tr>
    <tr>
        <td><code>@SourceDatabase</code></td>
        <td>Name of the source database.</td>
    </tr>
    <tr>
        <td><code>@SourceTable</code></td>
        <td>Name of the source table.</td>
    </tr>
    <tr>
        <td><code>@TargetDatabase</code></td>
        <td>Name of the target database.</td>
    </tr>
    <tr>
        <td><code>@TargetTable</code></td>
        <td>Name of the target table.</td>
    </tr>
</table>

<h3>Usage</h3>

<pre>
EXEC CreateandInsertDataintheAbsenceofSchema
    @SourceDatabase = 'SourceDB',
    @SourceTable = 'SourceTable',
    @TargetDatabase = 'TargetDB',
    @TargetTable = 'TargetTable';
</pre>

<h2>Procedure Steps</h2>

<ol>
    <li>Switch to the target database using the <code>USE</code> statement.</li>
    <li>Select all records from the source table and insert them into the target table.</li>
</ol>

<h2>Example</h2>

<pre>
EXEC CreateandInsertDataintheAbsenceofSchema
    @SourceDatabase = 'SourceDB',
    @SourceTable = 'SourceTable',
    @TargetDatabase = 'TargetDB',
    @TargetTable = 'TargetTable';
</pre>

</body>




<body>

<h2>COPY_ALL_DATA_INCLUDING_CHILD_TABLES_Modified Procedure</h2>

<h3>Description</h3>

<p>
    The <code>COPY_ALL_DATA_INCLUDING_CHILD_TABLES_Modified</code> procedure is used to copy data from a source table along with its child tables and constraints to a target database. It also allows the use of a condition to filter the data being copied.
</p>

<h3>Parameters</h3>

<table>
    <tr>
        <th>Parameter</th>
        <th>Description</th>
    </tr>
    <tr>
        <td><code>@SourceDatabase</code></td>
        <td>Name of the source database.</td>
    </tr>
    <tr>
        <td><code>@SourceSchema</code></td>
        <td>Name of the source schema.</td>
    </tr>
    <tr>
        <td><code>@SourceTable</code></td>
        <td>Name of the source table.</td>
    </tr>
    <tr>
        <td><code>@TargetDatabase</code></td>
        <td>Name of the target database.</td>
    </tr>
    <tr>
        <td><code>@TargetSchema</code></td>
        <td>Name of the target schema.</td>
    </tr>
    <tr>
        <td><code>@TargetTable</code></td>
        <td>Name of the target table.</td>
    </tr>
    <tr>
        <td><code>@condition</code></td>
        <td>Optional condition to filter the data being copied.</td>
    </tr>
</table>

<h3>Usage</h3>

<pre>
EXEC COPY_ALL_DATA_INCLUDING_CHILD_TABLES_Modified
    @SourceDatabase = 'SourceDB',
    @SourceSchema = 'SourceSchema',
    @SourceTable = 'SourceTable',
    @TargetDatabase = 'TargetDB',
    @TargetSchema = 'TargetSchema',
    @TargetTable = 'TargetTable',
    @condition = 'WHERE ColumnName = ''Value''';
</pre>

<h2>Procedure Steps</h2>

<ol>
    <li>Create a temporary table to store child table names.</li>
    <li>Find child tables associated with the source table.</li>
    <li>Copy data from the source table to the target table with an optional condition.</li>
    <li>For each child table:</li>
    <ol type="a">
        <li>Copy data from the source child table to the target child table with an optional condition.</li>
        <li>Create a foreign key constraint between the target child table and the source table.</li>
    </ol>
    <li>Clean up temporary table.</li>
</ol>

<h2>Example</h2>

<pre>
EXEC COPY_ALL_DATA_INCLUDING_CHILD_TABLES_Modified
    @SourceDatabase = 'SourceDB',
    @SourceSchema = 'SourceSchema',
    @SourceTable = 'SourceTable',
    @TargetDatabase = 'TargetDB',
    @TargetSchema = 'TargetSchema',
    @TargetTable = 'TargetTable',
    @condition = 'WHERE ColumnName = ''Value''';
</pre>

</body>

<body>

<h2>COPY_ALL_DATA_WITH_LOGS Procedure</h2>

<h2>Description</h2>

<p>
    The <code>COPY_ALL_DATA_WITH_LOGS</code> procedure is used to copy data from a source table to a target database along with its child tables and constraints. It also creates a log table to track the operations.
</p>

<h3>Parameters</h3>

<table>
    <tr>
        <th>Parameter</th>
        <th>Description</th>
    </tr>
    <tr>
        <td><code>@SourceDatabase</code></td>
        <td>Name of the source database.</td>
    </tr>
    <tr>
        <td><code>@SourceSchema</code></td>
        <td>Name of the source schema.</td>
    </tr>
    <tr>
        <td><code>@SourceTable</code></td>
        <td>Name of the source table.</td>
    </tr>
    <tr>
        <td><code>@TargetDatabase</code></td>
        <td>Name of the target database.</td>
    </tr>
    <tr>
        <td><code>@TargetSchema</code></td>
        <td>Name of the target schema.</td>
    </tr>
    <tr>
        <td><code>@TargetTable</code></td>
        <td>Name of the target table.</td>
    </tr>
    <tr>
        <td><code>@condition</code></td>
        <td>Optional condition to filter the data being copied.</td>
    </tr>
    <tr>
        <td><code>@LogsID</code> (output)</td>
        <td>Output parameter to retrieve the generated LogsID.</td>
    </tr>
</table>

<h3>Usage</h3>

<pre>
DECLARE @LogsID INT;
EXEC COPY_ALL_DATA_WITH_LOGS
    @SourceDatabase = 'SourceDB',
    @SourceSchema = 'SourceSchema',
    @SourceTable = 'SourceTable',
    @TargetDatabase = 'TargetDB',
    @TargetSchema = 'TargetSchema',
    @TargetTable = 'TargetTable',
    @condition = 'WHERE ColumnName = ''Value''',
    @LogsID = @LogsID OUTPUT;
</pre>

<h2>Procedure Steps</h2>

<ol>
    <li>Create a temporary table to store child table names.</li>
    <li>Find child tables associated with the source table.</li>
    <li>Create a log table in the target database if it doesn't already exist.</li>
    <li>Insert a record into the log table with a default log message.</li>
    <li>Get the generated LogsID from the log table.</li>
    <li>Copy data from the source table to the target table with an optional condition, including the LogsID.</li>
    <li>For each child table:</li>
    <ol type="a">
        <li>Copy data from the source child table to the target child table with an optional condition, including the LogsID.</li>
    </ol>
    <li>Clean up temporary table.</li>
</ol>

<h2>Example</h2>

<pre>
DECLARE @LogsID INT;
EXEC COPY_ALL_DATA_WITH_LOGS
    @SourceDatabase = 'SourceDB',
    @SourceSchema = 'SourceSchema',
    @SourceTable = 'SourceTable',
    @TargetDatabase = 'TargetDB',
    @TargetSchema = 'TargetSchema',
    @TargetTable = 'TargetTable',
    @condition = 'WHERE ColumnName = ''Value''',
    @LogsID = @LogsID OUTPUT;
</pre>


</body>

<body>
    <h1>Stored Procedures for Dynamic Data Updation</h1>
    <p>This SQL script contains two stored procedures for dynamic data updation and finding extra columns in a source table that are not present in a destination table.</p>
    <h2>FindMissingColumns_with_datatype_and_update_1</h2>
    <p>The first stored procedure, FindMissingColumns_with_datatype_and_update_1, creates a temporary table to store column names and data types of a source table. It then removes the column names that exist in the destination table and selects the remaining columns (missing in destination) along with their data types. The stored procedure then uses a cursor to loop through the remaining columns and their data types, and adds them to the destination table. Finally, the temporary table is dropped.</p>
    <h3>Parameters:</h3>
    <ul>
        <li>@source_table_name: the name of the source table</li>
        <li>@destination_table_name: the name of the destination table</li>
    </ul>
    <h3>Example usage:</h3>
    <pre>EXEC FindMissingColumns_with_datatype_and_update_1 'source_table', 'destination_table'</pre>
    <h2>Find_Extra_Columns_Modified_2</h2>
    <p>The second stored procedure, Find_Extra_Columns_Modified_2, finds the extra columns in a source table that are not present in a destination table. It takes the source table name, destination table name, and an output parameter for the column list as input. The output parameter will contain a comma-separated list of the extra columns in the source table. The procedure creates two temporary tables to store the column names and uses dynamic SQL to query the column names from the source and destination tables. It then removes the column names that exist in the destination table and concatenates the remaining column names into the output parameter.</p>
    <h3>Parameters:</h3>
    <ul>
        <li>@source_table_name: the name of the source table</li>
        <li>@destination_table_name: the name of the destination table</li>
        <li>@ColumnList: an output parameter for the column list</li>
    </ul>
    <h3>Example usage:</h3>
    <pre>
    DECLARE @ColumnList NVARCHAR(MAX);
    EXEC Find_Extra_Columns_Modified_2 'source_table', 'destination_table', @ColumnList OUTPUT;
    SELECT @ColumnList AS Extra_Columns;
    </pre>
</body>



</html>
