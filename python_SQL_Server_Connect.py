import pyodbc

class SQLServerConnect:

    def __init__(self,server,database) -> None:
        self.server = server
        self.database = database

    def establish_conn(self):
        try:
            conn_str = f'DRIVER={{SQL Server}};SERVER={self.server};DATABASE={self.database};Trusted_Connection=yes;'
            self.conn = pyodbc.connect(conn_str)
            print("***** Connection Established Successfully *****")
        except:
            print("Unable to Establish the Connection")
            print("Server Name or Database Name has some mistake. Please Check! ")
        
    def execute_query(self,query):
        cursor = self.conn.cursor()
        cursor.execute(query)
        rows = cursor.fetchall()
        for row in rows:
            print(row)

        return rows

    def close_conn(self):
        self.conn.close()
        print("***** Closed the Connection Successfully *****")

if __name__ ==  "__main__":
    obj = SQLServerConnect('servername','database')
    obj.establish_conn()
    obj.execute_query("SELECT * FROM Person")
    obj.execute_query("SELECT first_name FROM Person")
    obj.close_conn()
