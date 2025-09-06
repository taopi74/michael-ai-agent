#!/usr/bin/env bash
set -e
mkdir -p /app/database
python - <<'PY'
import os, sqlite3, datetime, pathlib, random, datetime as dt
db_path = "/app/database/business_data.db"
pathlib.Path(db_path).parent.mkdir(parents=True, exist_ok=True)
con = sqlite3.connect(db_path)
cur = con.cursor()
cur.execute("CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY,username TEXT UNIQUE,api_key TEXT UNIQUE,role TEXT,created_at DATETIME)")
cur.execute("CREATE TABLE IF NOT EXISTS products(id INTEGER PRIMARY KEY,name TEXT,category TEXT,cost_price REAL,sell_price REAL)")
cur.execute("CREATE TABLE IF NOT EXISTS customers(id INTEGER PRIMARY KEY,name TEXT,segment TEXT)")
cur.execute("CREATE TABLE IF NOT EXISTS sales(id INTEGER PRIMARY KEY,date DATE,product_id INTEGER,customer_id INTEGER,quantity INTEGER,unit_price REAL)")
con.commit()
cur.execute("SELECT COUNT(*) FROM users")
if cur.fetchone()[0]==0:
    now=datetime.datetime.utcnow().isoformat()
    rows=[("admin",os.environ.get("ADMIN_API_KEY","demo-admin-key"),"admin",now),("analyst","demo-analyst-key","analyst",now),("viewer","demo-viewer-key","viewer",now)]
    cur.executemany("INSERT INTO users(username,api_key,role,created_at) VALUES (?,?,?,?)",rows)
    con.commit()
    print("✅ Seeded users")
cur.execute("SELECT COUNT(*) FROM sales")
if cur.fetchone()[0]==0:
    cur.execute("INSERT INTO products(name,category,cost_price,sell_price) VALUES ('Widget A','Gadgets',50,100)")
    cur.execute("INSERT INTO products(name,category,cost_price,sell_price) VALUES ('Widget B','Gadgets',30,70)")
    cur.execute("INSERT INTO customers(name,segment) VALUES ('Alpha Ltd','B2B')")
    cur.execute("INSERT INTO customers(name,segment) VALUES ('Beta Mart','Retail')")
    con.commit()
    cur.execute("SELECT id FROM products"); pids=[r[0] for r in cur.fetchall()]
    cur.execute("SELECT id FROM customers"); cids=[r[0] for r in cur.fetchall()]
    base=dt.date.today()-dt.timedelta(days=30)
    for i in range(30):
        d=base+dt.timedelta(days=i)
        for _ in range(random.randint(0,3)):
            pid=random.choice(pids); cid=random.choice(cids)
            qty=random.randint(1,5); up=70 if pid==2 else 100
            cur.execute("INSERT INTO sales(date,product_id,customer_id,quantity,unit_price) VALUES (?,?,?,?,?)",(d.isoformat(),pid,cid,qty,float(up)))
    con.commit()
    print("✅ Seeded sales data")
con.close()
PY
exec uvicorn app.main:app --host 0.0.0.0 --port 8000
