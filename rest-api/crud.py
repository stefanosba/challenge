from db import get_db
from sqlite3 import IntegrityError

def get_users():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT id, name, email FROM users")
    rows = cursor.fetchall()
    conn.close()
    return rows

def create_user(name: str, email: str):
    conn = get_db()
    cursor = conn.cursor()

    # Controllo se l'email esiste già
    cursor.execute("SELECT COUNT(*) FROM users WHERE email = ?", (email,))
    if cursor.fetchone()[0] > 0:
        raise ValueError("Email already exists")
    
    try:
        cursor.execute("INSERT INTO users (name, email) VALUES (?, ?)", (name, email))
        conn.commit()
        user_id = cursor.lastrowid
        return user_id
    except IntegrityError:
        raise
    finally:
        conn.close()
