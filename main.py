from fastapi import FastAPI, HTTPException
import pymysql
from pydantic import BaseModel
import json

app = FastAPI(
    title="Sistem Tiket Konser API",
    description="API untuk manajemen basis data tiket konser dengan implementasi Stored Procedure, Trigger, View, dan JSON.",
    version="1.0.0"
)

# Konfigurasi Database (Sesuaikan kalau password XAMPP kamu bukan kosong)
DB_CONFIG = {
    'host': 'localhost',
    'user': 'mbd_user',
    'password': 'mbd_pass',
    'database': 'mbd_konser',
    'cursorclass': pymysql.cursors.DictCursor
}

def get_db_connection():
    return pymysql.connect(**DB_CONFIG)

@app.get("/")
def home():
    return {"message": "Server nyala Buka /docs untuk mencoba API."}

# USE CASE 1: LIHAT KONSER HAMPIR HABIS
# Memanfaatkan VIEW
@app.get("/api/konser/hampir-habis")
def get_konser_hampir_habis():
    """ Mengambil data konser yang tiketnya sisa < 20% melalui VIEW database. """
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM vw_konser_hampir_habis")
            return {"data": cursor.fetchall()}
    finally:
        conn.close()


# USE CASE 1B: CARI KONSER
# Memanfaatkan B-TREE INDEX & JSON

@app.get("/api/konser/cari")
def cari_konser(nama: str = ""):
    """ Mencari jadwal konser dan membaca metadata (JSON) """
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM konser WHERE nama_konser LIKE %s", (f"%{nama}%",))
            result = cursor.fetchall()
            # Parse JSON text back to dictionary
            for row in result:
                if row['metadata_json']:
                    row['metadata_json'] = json.loads(row['metadata_json'])
            return {"data": result}
    finally:
        conn.close()

class PembelianRequest(BaseModel):
    pengguna_id: int
    konser_id: int


# USE CASE 2 & 3: BELI TIKET
# Memanfaatkan STORED PROCEDURE, TRANSACTION, TRIGGER, & FUNCTION

@app.post("/api/tiket/beli")
def beli_tiket(req: PembelianRequest):
    """ Proses beli tiket. Akan error otomatis jika kuota habis atau melanggar rule > 4 tiket per user. """
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            # Memanggil Stored Procedure, semuanya (kurang kuota, catat tiket, tagihan) diurus di DB!
            cursor.execute("CALL sp_proses_pembelian_tiket(%s, %s)", (req.pengguna_id, req.konser_id))
        conn.commit()
        return {"status": "sukses", "pesan": "Berhasil beli tiket. Transaksi tersimpan!"}
    except pymysql.MySQLError as e:
        # Menangkap error 45000 dari TRIGGER database kita
        error_msg = e.args[1] if len(e.args) > 1 else str(e)
        raise HTTPException(status_code=400, detail=f"Database Rule Error: {error_msg}")
    finally:
        conn.close()

class ScanRequest(BaseModel):
    tiket_id: int


# USE CASE 4: SCAN TIKET MASUK
# Memanfaatkan TRIGGER (Mencegah Double Scan)

@app.post("/api/tiket/scan")
def scan_tiket(req: ScanRequest):
    """ Scan tiket. Jika di-scan dua kali, Trigger DB akan menolak. """
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("UPDATE tiket SET status = 'terpakai' WHERE id = %s", (req.tiket_id,))
            if cursor.rowcount == 0:
                raise HTTPException(status_code=404, detail="Tiket tidak ditemukan.")
        conn.commit()
        return {"status": "sukses", "pesan": "Pintu terbuka, selamat menonton!"}
    except pymysql.MySQLError as e:
        # Menangkap error anti-calo double scan dari TRIGGER
        error_msg = e.args[1] if len(e.args) > 1 else str(e)
        raise HTTPException(status_code=400, detail=f"Peringatan: {error_msg}")
    finally:
        conn.close()

