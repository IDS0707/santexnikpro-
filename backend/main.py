# -*- coding: utf-8 -*-
"""Santexnika Pro — Backend API v3 (multi-tenant: dokon + admin + super-admin)."""
import os, datetime, jwt, time
from typing import Optional, List
from contextlib import asynccontextmanager
import asyncpg
from fastapi import FastAPI, HTTPException, Depends, Header, Query, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

UPLOAD_DIR = "/uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

DB_DSN = os.environ.get("DB_DSN", "postgresql://santexnika:santexnika@postgres:5432/santexnika")
JWT_SECRET = os.environ.get("JWT_SECRET", "change-me")
pool: Optional[asyncpg.Pool] = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global pool
    pool = await asyncpg.create_pool(DB_DSN, min_size=1, max_size=12)
    yield
    await pool.close()

app = FastAPI(title="Santexnika Pro API v3", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

API_PUBLIC = os.environ.get("API_PUBLIC", "http://109.123.253.238:8091")

@app.post("/upload")
async def upload(file: UploadFile = File(...), store_id: str = "0"):
    ext = (file.filename or "img.jpg").lower().rsplit(".", 1)[-1]
    if ext not in ("png","jpg","jpeg","webp"): ext = "jpg"
    name = f"{store_id}_{int(time.time()*1000)}.{ext}"
    with open(os.path.join(UPLOAD_DIR, name), "wb") as f:
        f.write(await file.read())
    return {"url": f"{API_PUBLIC}/uploads/{name}"}

def make_token(sub, role): return jwt.encode({"sub": str(sub), "role": role, "exp": datetime.datetime.utcnow()+datetime.timedelta(days=60)}, JWT_SECRET, algorithm="HS256")
def row(r): return dict(r) if r else None
def rows(rs): return [dict(r) for r in rs]

@app.get("/health")
async def health():
    async with pool.acquire() as c:
        await c.fetchval("SELECT 1")
    return {"ok": True, "version": 3}

# ==================================================================
#  MIJOZ (dokon ilovasi)
# ==================================================================
class RegisterIn(BaseModel):
    full_name: str
    phone: str

@app.post("/register")
async def register(b: RegisterIn):
    async with pool.acquire() as c:
        r = await c.fetchrow("INSERT INTO app_users(full_name,phone) VALUES($1,$2) "
            "ON CONFLICT (phone) DO UPDATE SET full_name=EXCLUDED.full_name RETURNING id,full_name,phone", b.full_name, b.phone)
    return {"token": make_token(r["id"], "user"), "user": row(r)}

@app.get("/stores")
async def list_stores():
    async with pool.acquire() as c:
        rs = await c.fetch("SELECT id,name,address,phone,description FROM stores WHERE is_active AND status<>'blocked' ORDER BY name")
    return rows(rs)

class StoreLoginIn(BaseModel):
    store_id: int
    password: str

@app.post("/stores/login")
async def store_login(b: StoreLoginIn):
    async with pool.acquire() as c:
        s = await c.fetchrow("SELECT id,name,address,access_password,password_hash FROM stores WHERE id=$1 AND is_active", b.store_id)
    if not s: raise HTTPException(404, "Do'kon topilmadi")
    pw = s["access_password"]
    if pw and pw != "" and pw != b.password:
        raise HTTPException(401, "Do'kon paroli noto'g'ri")
    return {"token": make_token(s["id"], "store"), "store": {"id": s["id"], "name": s["name"], "address": s["address"]}}

@app.get("/categories")
async def categories(store_id: int = Query(...)):
    async with pool.acquire() as c:
        rs = await c.fetch("SELECT c.id,c.name,c.code,c.icon, "
            "(SELECT count(*) FROM products p WHERE p.category_id=c.id AND p.is_active) AS product_count "
            "FROM categories c WHERE c.is_active AND c.store_id=$1 ORDER BY c.name", store_id)
    return rows(rs)

@app.get("/products")
async def products(store_id: int = Query(...), category_id: Optional[int] = None):
    q = ("SELECT p.id,p.name,p.price,p.old_price,p.stock,p.unit,p.badge,p.icon,p.image_url,p.category_id,"
         "c.name AS category_name FROM products p LEFT JOIN categories c ON c.id=p.category_id "
         "WHERE p.is_active AND p.store_id=$1 ")
    args = [store_id]
    if category_id: q += "AND p.category_id=$2 "; args.append(category_id)
    q += "ORDER BY p.name"
    async with pool.acquire() as c:
        rs = await c.fetch(q, *args)
    return rows(rs)

class OrderItemIn(BaseModel):
    product_id: Optional[int] = None
    name: str
    price: float
    quantity: int = 1

class OrderIn(BaseModel):
    store_id: int
    app_user_id: int
    customer_name: Optional[str] = None
    phone: Optional[str] = None
    items: List[OrderItemIn]
    total: Optional[float] = None
    note: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

@app.post("/orders")
async def create_order(b: OrderIn):
    total = b.total if b.total is not None else sum(i.price*i.quantity for i in b.items)
    items_json = [{"product_id": i.product_id, "name": i.name, "quantity": i.quantity, "price": i.price} for i in b.items]
    import json as _json
    async with pool.acquire() as c:
        o = await c.fetchrow(
            "INSERT INTO orders(store_id,app_user_id,customer_name,phone,address,items,total,status,latitude,longitude,note) "
            "VALUES($1,$2,$3,$4,$5,$6::jsonb,$7,'pending',$8,$9,$10) RETURNING id,total,status,created_at",
            b.store_id, b.app_user_id, b.customer_name, b.phone, b.address, _json.dumps(items_json),
            total, b.latitude, b.longitude, b.note)
        # bildirishnomani trigger (trg_notify_new_order) avtomatik yaratadi
    res = row(o); res["earned_points"] = 0
    return res

@app.get("/orders")
async def my_orders(app_user_id: Optional[int] = None, phone: Optional[str] = None):
    async with pool.acquire() as c:
        if phone:
            rs = await c.fetch("SELECT id,total,status,created_at FROM orders WHERE phone=$1 ORDER BY id DESC LIMIT 100", phone)
        else:
            rs = await c.fetch("SELECT id,total,status,created_at FROM orders WHERE app_user_id=$1 ORDER BY id DESC LIMIT 100", app_user_id)
    return rows(rs)

@app.get("/bonus/me")
async def my_bonus(store_id: int, app_user_id: int):
    async with pool.acquire() as c:
        p = await c.fetchval("SELECT points FROM user_points WHERE store_id=$1 AND user_id=$2", store_id, app_user_id) or 0
    return {"balance": float(p)}

@app.get("/bonus/rewards")
async def bonus_rewards(store_id: int):
    async with pool.acquire() as c:
        rs = await c.fetch("SELECT id,name,points_cost,image_url FROM bonus_items WHERE is_active AND store_id=$1 ORDER BY points_cost", store_id)
    return rows(rs)

class RedeemIn(BaseModel):
    store_id: int
    app_user_id: int
    bonus_item_id: int
    points_cost: int

@app.post("/bonus/redeem")
async def redeem(b: RedeemIn):
    async with pool.acquire() as c:
        await c.execute("INSERT INTO bonus_requests(store_id,user_id,bonus_item_id,points_cost,status) VALUES($1,$2,$3,$4,'pending')",
            b.store_id, b.app_user_id, b.bonus_item_id, b.points_cost)
    return {"ok": True}

class DeviceIn(BaseModel):
    owner_type: str
    owner_id: int
    token: str
    platform: str = "android"

@app.post("/devices")
async def register_device(b: DeviceIn):
    async with pool.acquire() as c:
        await c.execute("INSERT INTO device_tokens(owner_type,owner_id,token,platform) VALUES($1,$2,$3,$4) "
            "ON CONFLICT (token) DO UPDATE SET owner_type=EXCLUDED.owner_type, owner_id=EXCLUDED.owner_id",
            b.owner_type, b.owner_id, b.token, b.platform)
    return {"ok": True}

# ==================================================================
#  SUPER ADMIN
# ==================================================================
class LoginIn(BaseModel):
    login: str
    password: str

@app.post("/sa/login")
async def sa_login(b: LoginIn):
    async with pool.acquire() as c:
        r = await c.fetchrow("SELECT id,name FROM super_admins WHERE login=$1 AND password=$2", b.login, b.password)
    if not r: raise HTTPException(401, "Login yoki parol noto'g'ri")
    return {"user_id": str(r["id"]), "name": r["name"]}

@app.get("/sa/stats")
async def sa_stats():
    async with pool.acquire() as c:
        rev = await c.fetchval("SELECT COALESCE(SUM(total),0) FROM orders WHERE status<>'cancelled'") or 0
        orders = await c.fetchval("SELECT count(*) FROM orders") or 0
        stores = await c.fetchval("SELECT count(*) FROM stores") or 0
        active = await c.fetchval("SELECT count(*) FROM stores WHERE is_active AND status<>'blocked'") or 0
        comm = await c.fetchval("SELECT COALESCE(SUM(o.total * s.commission_rate/100),0) FROM orders o JOIN stores s ON s.id=o.store_id WHERE o.status='completed'") or 0
    return {"total_revenue": float(rev), "total_orders": orders, "total_stores": stores,
            "active_stores": active, "blocked_stores": stores-active, "total_commission": float(comm)}

@app.get("/sa/stores")
async def sa_stores():
    async with pool.acquire() as c:
        rs = await c.fetch(
            "SELECT s.*, "
            "(SELECT count(*) FROM orders o WHERE o.store_id=s.id) AS orders_count, "
            "(SELECT COALESCE(SUM(total),0) FROM orders o WHERE o.store_id=s.id AND o.status<>'cancelled') AS revenue, "
            "(SELECT count(*) FROM products p WHERE p.store_id=s.id) AS products_count "
            "FROM stores s ORDER BY s.created_at DESC NULLS LAST, s.id DESC")
    return rows(rs)

@app.get("/sa/top-stores")
async def sa_top_stores(limit: int = 5):
    async with pool.acquire() as c:
        rs = await c.fetch("SELECT s.id AS store_id, s.name, COALESCE(SUM(o.total),0) AS revenue, count(o.id) AS orders "
            "FROM stores s LEFT JOIN orders o ON o.store_id=s.id AND o.status<>'cancelled' "
            "GROUP BY s.id,s.name ORDER BY revenue DESC LIMIT $1", limit)
    return rows(rs)

class StoreCreateIn(BaseModel):
    slug: str
    name: str
    description: str = ""
    invite_code: Optional[str] = None
    admin_login: str
    admin_password: str
    admin_name: Optional[str] = None
    category: Optional[str] = None
    commission_rate: float = 5.0
    access_password: Optional[str] = None

@app.post("/sa/stores")
async def sa_create_store(b: StoreCreateIn):
    import random, string
    inv = b.invite_code or ''.join(random.choices(string.ascii_uppercase+string.digits, k=6))
    async with pool.acquire() as c:
        try:
            s = await c.fetchrow("INSERT INTO stores(name,slug,description,invite_code,category,commission_rate,access_password,password_hash,is_active,status) "
                "VALUES($1,$2,$3,$4,$5,$6,$7,'',TRUE,'active') RETURNING id,name,slug",
                b.name, b.slug, b.description, inv, b.category, b.commission_rate, b.access_password)
        except asyncpg.UniqueViolationError:
            raise HTTPException(400, "Slug band")
        await c.execute("INSERT INTO store_admins(store_id,login,password,name) VALUES($1,$2,$3,$4)",
            s["id"], b.admin_login, b.admin_password, b.admin_name or b.name)
    return {"store_id": str(s["id"]), "name": s["name"], "slug": s["slug"]}

class StorePatchIn(BaseModel):
    status: Optional[str] = None
    commission_rate: Optional[float] = None
    name: Optional[str] = None
    description: Optional[str] = None
    access_password: Optional[str] = None
    is_active: Optional[bool] = None

@app.patch("/sa/stores/{sid}")
async def sa_patch_store(sid: int, b: StorePatchIn):
    sets, args, i = [], [], 1
    for f in ("status","commission_rate","name","description","access_password","is_active"):
        v = getattr(b, f)
        if v is not None:
            sets.append(f"{f}=${i}"); args.append(v); i += 1
    if not sets: return {"ok": True}
    args.append(sid)
    async with pool.acquire() as c:
        await c.execute(f"UPDATE stores SET {','.join(sets)} WHERE id=${i}", *args)
    return {"ok": True}

@app.delete("/sa/stores/{sid}")
async def sa_delete_store(sid: int):
    async with pool.acquire() as c:
        await c.execute("DELETE FROM stores WHERE id=$1", sid)
    return {"ok": True}

@app.get("/sa/users")
async def sa_users():
    async with pool.acquire() as c:
        rs = await c.fetch("SELECT id,full_name AS name,phone,email,current_store_id,status,role,created_at FROM app_users ORDER BY created_at DESC")
    return rows(rs)

class UserStatusIn(BaseModel):
    status: str

@app.patch("/sa/users/{uid}")
async def sa_user_status(uid: int, b: UserStatusIn):
    async with pool.acquire() as c:
        await c.execute("UPDATE app_users SET status=$1 WHERE id=$2", b.status, uid)
    return {"ok": True}

class TransferIn(BaseModel):
    store_id: int

@app.post("/sa/users/{uid}/transfer")
async def sa_transfer(uid: int, b: TransferIn):
    async with pool.acquire() as c:
        await c.execute("UPDATE app_users SET current_store_id=$1 WHERE id=$2", b.store_id, uid)
    return {"ok": True}

@app.get("/sa/activity-logs")
async def sa_logs(limit: int = 50):
    async with pool.acquire() as c:
        rs = await c.fetch("SELECT * FROM activity_logs ORDER BY id DESC LIMIT $1", limit)
    return rows(rs)

@app.get("/sa/orders")
async def sa_orders(store_id: Optional[int] = None):
    async with pool.acquire() as c:
        if store_id:
            rs = await c.fetch("SELECT id,store_id,total,status,items,created_at FROM orders WHERE store_id=$1 ORDER BY id DESC", store_id)
        else:
            rs = await c.fetch("SELECT id,store_id,total,status,items,created_at FROM orders ORDER BY id DESC LIMIT 1000")
    return rows(rs)

# ---- Banners ----
@app.get("/banners")
async def get_banners(store_id: Optional[int] = None):
    async with pool.acquire() as c:
        if store_id is None:
            rs = await c.fetch("SELECT * FROM banners ORDER BY sort_order")
        else:
            rs = await c.fetch("SELECT * FROM banners WHERE store_id=$1 OR store_id IS NULL ORDER BY sort_order", store_id)
    return rows(rs)

class BannerIn(BaseModel):
    id: Optional[int] = None
    store_id: Optional[int] = None
    title: Optional[str] = None
    subtitle: Optional[str] = None
    image_url: Optional[str] = None
    link_url: Optional[str] = None
    background_color: Optional[str] = None
    sort_order: int = 0
    is_active: bool = True

@app.post("/banners")
async def upsert_banner(b: BannerIn):
    async with pool.acquire() as c:
        if b.id:
            await c.execute("UPDATE banners SET title=$1,subtitle=$2,image_url=$3,link_url=$4,background_color=$5,sort_order=$6,is_active=$7,store_id=$8 WHERE id=$9",
                b.title,b.subtitle,b.image_url,b.link_url,b.background_color,b.sort_order,b.is_active,b.store_id,b.id)
        else:
            await c.execute("INSERT INTO banners(store_id,title,subtitle,image_url,link_url,background_color,sort_order,is_active) VALUES($1,$2,$3,$4,$5,$6,$7,$8)",
                b.store_id,b.title,b.subtitle,b.image_url,b.link_url,b.background_color,b.sort_order,b.is_active)
    return {"ok": True}

@app.delete("/banners/{bid}")
async def delete_banner(bid: int):
    async with pool.acquire() as c:
        await c.execute("DELETE FROM banners WHERE id=$1", bid)
    return {"ok": True}

# ---- Notification templates ----
@app.get("/notification-templates")
async def get_ntpl(store_id: Optional[int] = None):
    async with pool.acquire() as c:
        if store_id is None:
            rs = await c.fetch("SELECT * FROM notification_templates WHERE store_id IS NULL ORDER BY event")
        else:
            rs = await c.fetch("SELECT * FROM notification_templates WHERE store_id=$1 ORDER BY event", store_id)
    return rows(rs)

class NtplIn(BaseModel):
    id: Optional[int] = None
    store_id: Optional[int] = None
    event: str
    language: str = "uz"
    title: Optional[str] = None
    body: Optional[str] = None
    is_active: bool = True

@app.post("/notification-templates")
async def upsert_ntpl(b: NtplIn):
    async with pool.acquire() as c:
        if b.id:
            await c.execute("UPDATE notification_templates SET event=$1,language=$2,title=$3,body=$4,is_active=$5 WHERE id=$6",
                b.event,b.language,b.title,b.body,b.is_active,b.id)
        else:
            await c.execute("INSERT INTO notification_templates(store_id,event,language,title,body,is_active) VALUES($1,$2,$3,$4,$5,$6)",
                b.store_id,b.event,b.language,b.title,b.body,b.is_active)
    return {"ok": True}

# ==================================================================
#  DO'KON ADMIN
# ==================================================================
class AdminLoginIn(BaseModel):
    store_slug: Optional[str] = None
    login: str
    password: str

@app.post("/admin/login")
async def admin_login(b: AdminLoginIn):
    async with pool.acquire() as c:
        r = None
        if b.store_slug:
            r = await c.fetchrow("SELECT sa.id, sa.store_id, s.name AS store_name, s.slug FROM store_admins sa "
                "JOIN stores s ON s.id=sa.store_id WHERE sa.login=$1 AND sa.password=$2 AND s.slug=$3",
                b.login, b.password, b.store_slug)
        if r is None:
            r = await c.fetchrow("SELECT sa.id, sa.store_id, s.name AS store_name, s.slug FROM store_admins sa "
                "JOIN stores s ON s.id=sa.store_id WHERE sa.login=$1 AND sa.password=$2 LIMIT 1",
                b.login, b.password)
    if not r: raise HTTPException(401, "Login yoki parol noto'g'ri")
    return {"admin_id": str(r["id"]), "store_id": str(r["store_id"]), "store_name": r["store_name"], "store_slug": r["slug"]}

@app.get("/admin/snapshot")
async def admin_snapshot(store_id: int = Query(...)):
    async with pool.acquire() as c:
        cats = await c.fetch("SELECT id,name,code,description,icon,created_at FROM categories WHERE store_id=$1 ORDER BY created_at", store_id)
        prods = await c.fetch("SELECT id,name,category_id,price,old_price,stock,sku,description,badge,sold_count,image_url,created_at FROM products WHERE store_id=$1 ORDER BY created_at", store_id)
        ords = await c.fetch("SELECT id,customer_name,phone,email,address,items,total,status,driver_id,latitude,longitude,created_at FROM orders WHERE store_id=$1 ORDER BY created_at DESC", store_id)
        drv = await c.fetch("SELECT id,name,phone,login,password,vehicle_number,status,completed_orders,rating,current_order_id FROM drivers WHERE store_id=$1 ORDER BY created_at", store_id)
    return {"categories": rows(cats), "products": rows(prods), "orders": rows(ords), "drivers": rows(drv), "applications": []}

class CategoryIn(BaseModel):
    id: Optional[int] = None
    store_id: int
    name: str
    code: Optional[str] = None
    description: Optional[str] = None
    icon: Optional[str] = None

@app.post("/admin/categories")
async def admin_upsert_category(b: CategoryIn):
    async with pool.acquire() as c:
        if b.id:
            r = await c.fetchrow("UPDATE categories SET name=$1,code=$2,description=$3,icon=$4 WHERE id=$5 RETURNING *",
                b.name,b.code,b.description,b.icon,b.id)
        else:
            r = await c.fetchrow("INSERT INTO categories(store_id,name,code,description,icon) VALUES($1,$2,$3,$4,$5) RETURNING *",
                b.store_id,b.name,b.code,b.description,b.icon)
    return row(r)

@app.delete("/admin/categories/{cid}")
async def admin_delete_category(cid: int):
    async with pool.acquire() as c:
        await c.execute("DELETE FROM categories WHERE id=$1", cid)
    return {"ok": True}

class ProductIn(BaseModel):
    id: Optional[int] = None
    store_id: int
    name: str
    price: float
    category_id: Optional[int] = None
    old_price: Optional[float] = None
    stock: int = 0
    sku: Optional[str] = None
    description: Optional[str] = None
    badge: Optional[str] = None
    image_url: Optional[str] = None
    icon: Optional[str] = None
    unit: str = "dona"

@app.post("/admin/products")
async def admin_upsert_product(b: ProductIn):
    async with pool.acquire() as c:
        if b.id:
            r = await c.fetchrow("UPDATE products SET name=$1,price=$2,category_id=$3,old_price=$4,stock=$5,sku=$6,description=$7,badge=$8,image_url=$9,icon=$10,unit=$11 WHERE id=$12 RETURNING *",
                b.name,b.price,b.category_id,b.old_price,b.stock,b.sku,b.description,b.badge,b.image_url,b.icon,b.unit,b.id)
        else:
            r = await c.fetchrow("INSERT INTO products(store_id,name,price,category_id,old_price,stock,sku,description,badge,image_url,icon,unit) "
                "VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) RETURNING *",
                b.store_id,b.name,b.price,b.category_id,b.old_price,b.stock,b.sku,b.description,b.badge,b.image_url,b.icon,b.unit)
    return row(r)

@app.delete("/admin/products/{pid}")
async def admin_delete_product(pid: int):
    async with pool.acquire() as c:
        await c.execute("DELETE FROM products WHERE id=$1", pid)
    return {"ok": True}

class DriverIn(BaseModel):
    id: Optional[int] = None
    store_id: int
    name: str
    phone: Optional[str] = None
    login: Optional[str] = None
    password: Optional[str] = None
    vehicle_number: Optional[str] = None
    status: str = "free"

@app.post("/admin/drivers")
async def admin_upsert_driver(b: DriverIn):
    async with pool.acquire() as c:
        if b.id:
            r = await c.fetchrow("UPDATE drivers SET name=$1,phone=$2,login=$3,password=$4,vehicle_number=$5,status=$6 WHERE id=$7 RETURNING *",
                b.name,b.phone,b.login,b.password,b.vehicle_number,b.status,b.id)
        else:
            r = await c.fetchrow("INSERT INTO drivers(store_id,name,phone,login,password,vehicle_number,status,full_name) "
                "VALUES($1,$2,$3,$4,$5,$6,$7,$2) RETURNING *",
                b.store_id,b.name,b.phone,b.login,b.password,b.vehicle_number,b.status)
    return row(r)

@app.delete("/admin/drivers/{did}")
async def admin_delete_driver(did: int):
    async with pool.acquire() as c:
        await c.execute("DELETE FROM drivers WHERE id=$1", did)
    return {"ok": True}

class OrderPatchIn(BaseModel):
    status: Optional[str] = None
    driver_id: Optional[int] = None

@app.patch("/admin/orders/{oid}")
async def admin_patch_order(oid: int, b: OrderPatchIn):
    async with pool.acquire() as c:
        r = await c.fetchrow("UPDATE orders SET status=COALESCE($1,status), driver_id=COALESCE($2,driver_id), updated_at=now() WHERE id=$3 RETURNING *",
            b.status, b.driver_id, oid)
    return row(r)

@app.delete("/admin/orders/{oid}")
async def admin_delete_order(oid: int):
    async with pool.acquire() as c:
        await c.execute("DELETE FROM orders WHERE id=$1", oid)
    return {"ok": True}

# ---- Do'kon bonus boshqaruvi ----
@app.get("/admin/bonus/settings")
async def admin_bonus_settings(store_id: int):
    async with pool.acquire() as c:
        r = await c.fetchrow("SELECT bonus_enabled,bonus_amount,bonus_points,access_password FROM stores WHERE id=$1", store_id)
    return row(r)

class StoreBonusIn(BaseModel):
    store_id: int
    bonus_enabled: bool
    bonus_amount: float
    bonus_points: int

@app.put("/admin/bonus/settings")
async def admin_set_bonus(b: StoreBonusIn):
    async with pool.acquire() as c:
        await c.execute("UPDATE stores SET bonus_enabled=$1,bonus_amount=$2,bonus_points=$3 WHERE id=$4",
            b.bonus_enabled,b.bonus_amount,b.bonus_points,b.store_id)
    return {"ok": True}

class AccessPwIn(BaseModel):
    store_id: int
    password: Optional[str] = None

@app.put("/admin/access-password")
async def admin_access_pw(b: AccessPwIn):
    async with pool.acquire() as c:
        await c.execute("UPDATE stores SET access_password=$1 WHERE id=$2", b.password, b.store_id)
    return {"ok": True}

@app.get("/admin/bonus/items")
async def admin_bonus_items(store_id: int):
    async with pool.acquire() as c:
        rs = await c.fetch("SELECT * FROM bonus_items WHERE store_id=$1 ORDER BY points_cost", store_id)
    return rows(rs)

class BonusItemIn(BaseModel):
    id: Optional[int] = None
    store_id: int
    name: str
    points_cost: int
    image_url: Optional[str] = None
    is_active: bool = True

@app.post("/admin/bonus/items")
async def admin_upsert_bonus_item(b: BonusItemIn):
    async with pool.acquire() as c:
        if b.id:
            await c.execute("UPDATE bonus_items SET name=$1,points_cost=$2,image_url=$3,is_active=$4 WHERE id=$5",
                b.name,b.points_cost,b.image_url,b.is_active,b.id)
        else:
            await c.execute("INSERT INTO bonus_items(store_id,name,points_cost,image_url,is_active) VALUES($1,$2,$3,$4,$5)",
                b.store_id,b.name,b.points_cost,b.image_url,b.is_active)
    return {"ok": True}

@app.delete("/admin/bonus/items/{iid}")
async def admin_delete_bonus_item(iid: int):
    async with pool.acquire() as c:
        await c.execute("DELETE FROM bonus_items WHERE id=$1", iid)
    return {"ok": True}

@app.get("/admin/bonus/requests")
async def admin_bonus_requests(store_id: int):
    async with pool.acquire() as c:
        rs = await c.fetch("SELECT r.*, bi.name AS item_name, u.full_name AS user_name, u.phone AS user_phone "
            "FROM bonus_requests r LEFT JOIN bonus_items bi ON bi.id=r.bonus_item_id LEFT JOIN app_users u ON u.id=r.user_id "
            "WHERE r.store_id=$1 ORDER BY r.created_at DESC", store_id)
    return rows(rs)

class BonusReqStatusIn(BaseModel):
    status: str

@app.patch("/admin/bonus/requests/{rid}")
async def admin_bonus_req_status(rid: int, b: BonusReqStatusIn):
    async with pool.acquire() as c:
        await c.execute("UPDATE bonus_requests SET status=$1 WHERE id=$2", b.status, rid)
    return {"ok": True}

class AdjustPointsIn(BaseModel):
    store_id: int
    user_id: int
    delta: int

@app.post("/admin/bonus/adjust-points")
async def admin_adjust_points(b: AdjustPointsIn):
    async with pool.acquire() as c:
        cur = await c.fetchval("SELECT points FROM user_points WHERE store_id=$1 AND user_id=$2", b.store_id, b.user_id) or 0
        await c.execute("INSERT INTO user_points(store_id,user_id,points,updated_at) VALUES($1,$2,$3,now()) "
            "ON CONFLICT (store_id,user_id) DO UPDATE SET points=EXCLUDED.points, updated_at=now()",
            b.store_id, b.user_id, cur + b.delta)
    return {"ok": True}

@app.get("/admin/notifications")
async def admin_notifs(store_id: int):
    async with pool.acquire() as c:
        rs = await c.fetch("SELECT * FROM notifications WHERE target_type='store' AND target_id=$1 ORDER BY id DESC LIMIT 100", store_id)
    return rows(rs)

class StoreIdIn(BaseModel):
    store_id: int

@app.post("/admin/notifications/read")
async def admin_notifs_read(b: StoreIdIn):
    async with pool.acquire() as c:
        await c.execute("UPDATE notifications SET is_read=true WHERE target_type='store' AND target_id=$1 AND is_read=false", b.store_id)
    return {"ok": True}

# ==================================================================
#  HAYDOVCHI
# ==================================================================
class DriverLoginIn(BaseModel):
    login: str
    password: str

@app.post("/driver/login")
async def driver_login(b: DriverLoginIn):
    async with pool.acquire() as c:
        r = await c.fetchrow("SELECT id FROM drivers WHERE login=$1 AND password=$2", b.login, b.password)
    if not r: raise HTTPException(401, "Login yoki parol noto'g'ri")
    return {"driver_id": str(r["id"])}

@app.get("/driver/profile")
async def driver_profile(driver_id: int):
    async with pool.acquire() as c:
        r = await c.fetchrow("SELECT id,name,phone,vehicle_number,status,completed_orders,rating,current_order_id,store_id FROM drivers WHERE id=$1", driver_id)
        o = await c.fetch("SELECT id,customer_name,phone,address,items,total,status,latitude,longitude FROM orders WHERE driver_id=$1 AND status IN ('pending','processing') ORDER BY created_at DESC LIMIT 1", driver_id)
    return {"driver": row(r), "active_order": rows(o)[0] if o else None}

class DriverStatusIn(BaseModel):
    status: str

@app.patch("/driver/{did}/status")
async def driver_set_status(did: int, b: DriverStatusIn):
    async with pool.acquire() as c:
        await c.execute("UPDATE drivers SET status=$1 WHERE id=$2", b.status, did)
    return {"ok": True}

@app.post("/driver/{did}/complete/{oid}")
async def driver_complete(did: int, oid: int):
    async with pool.acquire() as c:
        await c.execute("UPDATE orders SET status='completed', updated_at=now() WHERE id=$1", oid)
        await c.execute("UPDATE drivers SET status='free', completed_orders=completed_orders+1, current_order_id=NULL WHERE id=$1", did)
    return {"ok": True}
