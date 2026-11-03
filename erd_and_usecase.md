# ERD & Spesifikasi Use Case

## 1. Use Case Diagram

```mermaid
usecaseDiagram
    actor Pembeli
    actor Petugas

    usecase "Login" as UC1
    usecase "Melihat Konser Tersedia" as UC2
    usecase "Buat Pesanan Tiket (Maks 4)" as UC3
    usecase "Bayar Pesanan" as UC4
    usecase "Melihat Riwayat Pesanan" as UC5

    Pembeli --> UC1
    Pembeli --> UC2
    Pembeli --> UC3
    Pembeli --> UC4

    Petugas --> UC1
    Petugas --> UC2
    Petugas --> UC5
```

## 2. Entity Relationship Diagram (ERD)

```mermaid
erDiagram
    PENGGUNA ||--o{ PESANAN : "membuat"
    PENGGUNA {
        INT id PK
        VARCHAR username "UNIQUE"
        VARCHAR password_hash
        VARCHAR peran
    }

    KONSER ||--o{ PESANAN : "memiliki"
    KONSER ||--o{ TIKET : "memiliki"
    KONSER {
        INT id PK
        VARCHAR nama_konser "INDEX"
        TIMESTAMP tanggal
        NUMERIC harga_dasar
        INT kuota_awal
        INT kuota_tersisa
    }

    PESANAN ||--o{ TIKET : "terdiri_dari"
    PESANAN ||--o{ PEMBAYARAN : "dilunasi_oleh"
    PESANAN {
        INT id PK
        INT user_id FK
        INT konser_id FK
        INT jumlah_tiket
        NUMERIC total_bayar
        VARCHAR status
    }

    TIKET {
        INT id PK
        INT pesanan_id FK
        INT konser_id FK
        VARCHAR kode_unik "UNIQUE"
        VARCHAR status
    }

    PEMBAYARAN {
        INT id PK
        INT pesanan_id FK
        NUMERIC jumlah
        TIMESTAMP tanggal_bayar
    }
```
