# Panduan Serah Terima Proyek — Sistem Tiket Konser

## Checklist Lengkap: Semua Komponen yang Harus Ada di Project Ini

> Dokumen ini dibuat agar teman atau penguji yang menerima project ini dapat memahami **apa saja yang ada**, **di mana letaknya**, dan **bagaimana cara menjalankannya** dari nol dengan standar arsitektur profesional.

---

## BAGIAN 1 — STRUKTUR FOLDER LENGKAP

Pastikan seluruh folder dan file berikut ada di direktori project:

```text
/home/rehant/Coding/mbd/
│
├── .env                         <- Konfigurasi variabel lingkungan (DB, JWT)
├── .gitignore                   <- File yang dikecualikan dari Git
├── compose.yaml                 <- Konfigurasi Docker Compose (PostgreSQL 17)
├── package.json                 <- Dependensi Node.js & script npm
├── README.md                    <- Panduan teknis singkat
├── PROJECT_SUMMARY.md           <- Dokumentasi komprehensif sistem
├── database_dictionary.md       <- Kamus data tabel sistem tiket
├── erd_and_usecase.md           <- ERD & spesifikasi Use Case
├── ex.md                        <- File ini (panduan serah terima)
├── postman_collection.json      <- Koleksi test API siap import ke Postman (OPSIONAL)
│
├── sql/                         <- SEMUA SKRIP SQL POSTGRESQL
│   ├── 01_schema.sql            <- DDL: Tabel + Constraints + B-Tree Index
│   ├── 02_seed.sql              <- Data awal (User, Konser, Pesanan demo)
│   ├── 07_roles_rls.sql         <- Hak akses Roles & Row Level Security (RLS)
│   ├── functions/
│   │   └── 01_functions.sql     <- Fungsi Read-Only / Trigger Functions
│   ├── procedures/
│   │   └── 01_procedures.sql    <- Stored Procedures transaksi
│   ├── triggers/
│   │   └── 01_triggers.sql      <- 3 Trigger Utama Sistem Konser
│   └── views/
│       └── 01_views.sql         <- Views laporan & rekap
│
└── src/                         <- SOURCE CODE BACKEND NODE.JS
    ├── app.js                   <- Entry point server Express.js
    ├── database/
    │   └── db.js                <- Koneksi pool PostgreSQL (pg.Pool)
    ├── middlewares/
    │   └── auth.middleware.js   <- JWT verification & requireRole()
    ├── services/
    │   └── sp.service.js        <- Eksekusi Stored Procedure ke DB
    ├── controllers/             <- Handler logika setiap endpoint
    └── routes/                  <- Definisi rute API (/api/v1/...)
```

---

## BAGIAN 3 — CARA MENJALANKAN PROJECT (DARI NOL) DI LINUX

### Langkah 1 — Jalankan Database PostgreSQL di Docker

```bash
cd /home/rehant/Coding/mbd
docker compose up -d
```
Tunggu hingga container database berstatus *Running*.

### Langkah 2 — Install Dependensi Node.js

```bash
npm install
```

### Langkah 3 — Eksekusi Skrip SQL (WAJIB BERURUTAN!)

```bash
# 1. Buat struktur tabel + constraints + B-Tree index
cat sql/01_schema.sql | docker exec -i pos_jalur_langit_db psql -U pos_admin -d pos_jalur_langit

# 2. Isi data awal (seed)
cat sql/02_seed.sql | docker exec -i pos_jalur_langit_db psql -U pos_admin -d pos_jalur_langit

# 3. Buat views
cat sql/views/01_views.sql | docker exec -i pos_jalur_langit_db psql -U pos_admin -d pos_jalur_langit

# 4. Buat fungsi & trigger
cat sql/functions/01_functions.sql | docker exec -i pos_jalur_langit_db psql -U pos_admin -d pos_jalur_langit
cat sql/triggers/01_triggers.sql | docker exec -i pos_jalur_langit_db psql -U pos_admin -d pos_jalur_langit

# 5. Buat stored procedures
cat sql/procedures/01_procedures.sql | docker exec -i pos_jalur_langit_db psql -U pos_admin -d pos_jalur_langit

# 6. Setup roles & RLS (Terakhir)
cat sql/07_roles_rls.sql | docker exec -i pos_jalur_langit_db psql -U pos_admin -d pos_jalur_langit
```

### Langkah 4 — Menjalankan Server Node.js

```bash
npm run dev
```

Server akan menyala di `http://localhost:3000`.
