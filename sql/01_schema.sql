-- 01_schema.sql: DDL, Constraints, B-Tree Index

-- TABEL PENGGUNA
CREATE TABLE pengguna (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    peran VARCHAR(20) NOT NULL CHECK (peran IN ('pembeli', 'petugas'))
);
CREATE UNIQUE INDEX idx_pengguna_username ON pengguna USING btree (username);

-- TABEL KONSER
CREATE TABLE konser (
    id SERIAL PRIMARY KEY,
    nama_konser VARCHAR(150) NOT NULL,
    tanggal TIMESTAMP NOT NULL,
    harga_dasar NUMERIC(10, 2) NOT NULL CHECK (harga_dasar > 0),
    kuota_awal INT NOT NULL,
    kuota_tersisa INT NOT NULL CHECK (kuota_tersisa >= 0)
);
CREATE INDEX idx_konser_nama ON konser USING btree (nama_konser);
CREATE INDEX idx_konser_tanggal ON konser USING btree (tanggal);

-- TABEL PESANAN
CREATE TABLE pesanan (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES pengguna(id),
    konser_id INT NOT NULL REFERENCES konser(id),
    jumlah_tiket INT NOT NULL CHECK (jumlah_tiket > 0),
    total_bayar NUMERIC(10, 2) NOT NULL CHECK (total_bayar >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending', 'Lunas', 'Batal')),
    tanggal_pesan TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_pesanan_user ON pesanan USING btree (user_id);

-- TABEL TIKET
CREATE TABLE tiket (
    id SERIAL PRIMARY KEY,
    pesanan_id INT NOT NULL REFERENCES pesanan(id),
    konser_id INT NOT NULL REFERENCES konser(id),
    kode_unik VARCHAR(50) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'valid' CHECK (status IN ('valid', 'terpakai', 'batal'))
);
CREATE INDEX idx_tiket_konser ON tiket USING btree (konser_id);
CREATE INDEX idx_tiket_pesanan ON tiket USING btree (pesanan_id);

-- TABEL PEMBAYARAN
CREATE TABLE pembayaran (
    id SERIAL PRIMARY KEY,
    pesanan_id INT NOT NULL REFERENCES pesanan(id),
    jumlah NUMERIC(10, 2) NOT NULL CHECK (jumlah > 0),
    tanggal_bayar TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_pembayaran_pesanan ON pembayaran USING btree (pesanan_id);
