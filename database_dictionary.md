# Kamus Data (Database Dictionary)

## Tabel `pengguna`
| Kolom | Tipe Data | Keterangan |
|---|---|---|
| id | SERIAL | Primary Key |
| username | VARCHAR(50) | Username login (Unique, B-Tree Index) |
| password_hash | VARCHAR(255) | Password terenkripsi bcrypt |
| peran | VARCHAR(20) | Enum: 'pembeli', 'petugas' |

## Tabel `konser`
| Kolom | Tipe Data | Keterangan |
|---|---|---|
| id | SERIAL | Primary Key |
| nama_konser | VARCHAR(150) | Nama acara (B-Tree Index) |
| tanggal | TIMESTAMP | Waktu pelaksanaan acara |
| harga_dasar | NUMERIC(10,2) | Harga 1 tiket |
| kuota_awal | INT | Total tiket yang dijual |
| kuota_tersisa | INT | Tiket yang masih bisa dibeli |

## Tabel `pesanan`
| Kolom | Tipe Data | Keterangan |
|---|---|---|
| id | SERIAL | Primary Key |
| user_id | INT | Foreign Key -> `pengguna` |
| konser_id | INT | Foreign Key -> `konser` |
| jumlah_tiket | INT | Jumlah tiket yang dibeli |
| total_bayar | NUMERIC(10,2) | Total harga pesanan |
| status | VARCHAR(20) | 'Pending', 'Lunas', 'Batal' |

## Tabel `tiket`
| Kolom | Tipe Data | Keterangan |
|---|---|---|
| id | SERIAL | Primary Key |
| pesanan_id | INT | Foreign Key -> `pesanan` |
| konser_id | INT | Foreign Key -> `konser` |
| kode_unik | VARCHAR(50) | UUID untuk verifikasi masuk gate |
| status | VARCHAR(20) | 'valid', 'terpakai', 'batal' |

## Tabel `pembayaran`
| Kolom | Tipe Data | Keterangan |
|---|---|---|
| id | SERIAL | Primary Key |
| pesanan_id | INT | Foreign Key -> `pesanan` |
| jumlah | NUMERIC(10,2) | Uang yang dibayar |
