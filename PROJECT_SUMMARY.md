# Project Summary

## Teknologi yang Digunakan
- **Database**: PostgreSQL 17 (via Docker Compose)
- **Backend**: Node.js (Express.js)
- **Library**: `pg` (PostgreSQL Client), `jsonwebtoken` (Auth), `bcryptjs` (Hashing)

## Fitur Utama
- Autentikasi berbasis JWT.
- Sistem pembelian tiket konser yang membatasi 1 user hanya bisa membeli maksimal 4 tiket (Anti-Calo).
- Pengurangan kuota otomatis setiap transaksi menggunakan Trigger.
- Perubahan status pesanan otomatis saat dibayar menggunakan Trigger.
- Penyimpanan dan penggunaan data yang efisien menggunakan B-Tree Indexes.
