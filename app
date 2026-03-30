# Mini Facebook-like Web App using Flask
# Features: User registration, login, logout, create posts, feed display
# Simple SQLite database (no ORM for simplicity)

from flask import Flask, render_template_string, request, redirect, session, url_for
import sqlite3
from datetime import datetime

app = Flask(__name__)
app.secret_key = "supersecretkey"

DB = "social.db"

# -------------------- DB SETUP --------------------
def init_db():
    conn = sqlite3.connect(DB)
    c = conn.cursor()

    c.execute("""
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT
    )
    """)

    c.execute("""
    CREATE TABLE IF NOT EXISTS posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user TEXT,
        content TEXT,
        created_at TEXT
    )
    """)

    conn.commit()
    conn.close()

init_db()

# -------------------- HELPERS --------------------
def get_db():
    return sqlite3.connect(DB)

# -------------------- ROUTES --------------------

@app.route('/')
def index():
    if "user" not in session:
        return redirect('/login')

    conn = get_db()
    c = conn.cursor()
    c.execute("SELECT user, content, created_at FROM posts ORDER BY id DESC")
    posts = c.fetchall()
    conn.close()

    html = """
    <h1>Mini Facebook</h1>
    <p>Logged in as {{user}} | <a href='/logout'>Logout</a></p>

    <form method='POST' action='/post'>
        <textarea name='content' required></textarea><br>
        <button type='submit'>Post</button>
    </form>

    <hr>

    {% for p in posts %}
        <div style='border:1px solid #ccc; padding:10px; margin:10px;'>
            <b>{{p[0]}}</b><br>
            {{p[1]}}<br>
            <small>{{p[2]}}</small>
        </div>
    {% endfor %}
    """

    return render_template_string(html, posts=posts, user=session["user"])

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']

        conn = get_db()
        c = conn.cursor()
        try:
            c.execute("INSERT INTO users (username, password) VALUES (?,?)", (username, password))
            conn.commit()
        except:
            return "User already exists"
        conn.close()
        return redirect('/login')

    return """
    <h2>Register</h2>
    <form method='POST'>
        <input name='username' placeholder='username' required>
        <input name='password' type='password' placeholder='password' required>
        <button>Register</button>
    </form>
    <a href='/login'>Login</a>
    """

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']

        conn = get_db()
        c = conn.cursor()
        c.execute("SELECT * FROM users WHERE username=? AND password=?", (username, password))
        user = c.fetchone()
        conn.close()

        if user:
            session['user'] = username
            return redirect('/')
        return "Invalid login"

    return """
    <h2>Login</h2>
    <form method='POST'>
        <input name='username' placeholder='username' required>
        <input name='password' type='password' placeholder='password' required>
        <button>Login</button>
    </form>
    <a href='/register'>Register</a>
    """

@app.route('/logout')
def logout():
    session.pop('user', None)
    return redirect('/login')

@app.route('/post', methods=['POST'])
def post():
    if "user" not in session:
        return redirect('/login')

    content = request.form['content']
    user = session['user']
    created_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    conn = get_db()
    c = conn.cursor()
    c.execute("INSERT INTO posts (user, content, created_at) VALUES (?,?,?)",
              (user, content, created_at))
    conn.commit()
    conn.close()

    return redirect('/')

# -------------------- RUN --------------------
if __name__ == '__main__':
    app.run(debug=True)
