import mysql.connector
from config import DB_CONFIG

def split_statements(text):
    delimiter, statements, buffer = ";", [], []
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.upper().startswith("DELIMITER"):
            delimiter = stripped.split(None, 1)[1].strip()
            continue
        if not buffer and (not stripped or stripped.startswith("--")):
            continue
        buffer.append(line)
        if stripped.endswith(delimiter):
            statement = "\n".join(buffer).rstrip()
            statement = statement[:-len(delimiter)].rstrip()
            if statement:
                statements.append(statement)
            buffer = []
    return statements

def init_db():
    conn_config = DB_CONFIG.copy()
    db_name = conn_config.pop('database')
    
    conn = mysql.connector.connect(**conn_config)
    cursor = conn.cursor()
    
    with open('database/library_schema.sql', 'r') as f:
        sql_script = f.read()
        
    statements = split_statements(sql_script)
    for stmt in statements:
        if stmt.strip():
            cursor.execute(stmt)
            
    conn.commit()
    cursor.close()
    conn.close()
    print("Database library_db configured successfully!")

if __name__ == "__main__":
    init_db()