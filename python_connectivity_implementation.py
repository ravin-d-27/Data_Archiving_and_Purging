from python_SQL_Server_Connect import SQLServerConnect

connection = SQLServerConnect('DB\SQLEXPRESS','AdventureWorks2022')
connection.establish_conn()
records = connection.execute_query("select * from Person.Person;")
print(len(records))
print(records[0])

count = connection.execute_query("select count(*) from HumanResources.Employee")
print(count)