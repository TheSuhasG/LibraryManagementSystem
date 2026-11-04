from flask import Flask, render_template, request, redirect, url_for, flash, g
import mysql.connector
from config import DB_CONFIG, LOAN_DAYS, MAX_ACTIVE_LOANS

app = Flask(__name__)
app.secret_key = "library_secret_key"

def get_db():
    if "db" not in g:
        g.db = mysql.connector.connect(**DB_CONFIG)
    return g.db

@app.teardown_appcontext
def close_db(_exc):
    db = g.pop("db", None)
    if db is not None:
        db.close()

def query(sql, params=(), one=False):
    cur = get_db().cursor(dictionary=True)
    cur.execute(sql, params)
    rows = cur.fetchall()
    cur.close()
    if one:
        return rows[0] if rows else None
    return rows

@app.route("/")
def dashboard():
    overdue = query("SELECT * FROM overdue_books ORDER BY days_overdue DESC")
    total_books = query("SELECT COUNT(*) as count FROM Books", one=True)['count']
    total_copies = query("SELECT SUM(available_copies) as count FROM Books", one=True)['count'] or 0
    active_loans = query("SELECT COUNT(*) as count FROM Issue_Records WHERE return_date IS NULL", one=True)['count']
    total_members = query("SELECT COUNT(*) as count FROM Members", one=True)['count']
    unpaid_fines = query("SELECT SUM(fine_amount) as total FROM Fines WHERE paid = 0", one=True)['total'] or 0.0
    return render_template("index.html", overdue=overdue, total_books=total_books,
                           total_copies=total_copies, active_loans=active_loans,
                           total_members=total_members, unpaid_fines=unpaid_fines)

if __name__ == "__main__":
    app.run(debug=True)
