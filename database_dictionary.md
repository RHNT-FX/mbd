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

---

## Role & Hak Akses (Data Control Language - DCL)

File Skrip: `sql/07_roles_rls.sql`

| Role | Target Objek | Hak Akses (Privileges) | Keterangan / Alasan Desain |
|---|---|---|---|
| `role_admin` | Seluruh Tabel, View, Procedure, Sequence | `ALL PRIVILEGES` | Superuser / Administrator dengan kendali penuh atas database. |
| `role_petugas` | `pengguna`, `konser`, `pesanan`, `tiket`, `pembayaran`, View | `SELECT`, `UPDATE (status)` pada `tiket`, `EXECUTE` pada `sp_batalkan_tiket` | Petugas loket/gate untuk cek riwayat pesanan dan validasi status tiket masuk. |
| `role_pembeli` | `vw_konser_tersedia`, `vw_pesanan_user`, `konser` | `SELECT` | Pembeli hanya bisa melihat konser yang aktif dan pesanan miliknya sendiri. |
| `role_pembeli` | `sp_buat_pesanan`, `sp_bayar_pesanan`, `sp_tambah_pengguna`, `sp_batalkan_tiket`, `fn_hitung_diskon` | `EXECUTE` | Seluruh transaksi perubahan data dibatasi melalui Stored Procedure (tidak boleh direct INSERT/UPDATE ke tabel). |
| `user_petugas` | User DB khusus petugas | Di-assign `role_petugas` | Password: `petugas123` |
| `user_pembeli` | User DB khusus pembeli | Di-assign `role_pembeli` | Password: `pembeli123` |

