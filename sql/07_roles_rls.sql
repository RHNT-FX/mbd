-- ==============================================================================
-- 07_roles_rls.sql: Database Control Language (DCL)
-- Manajemen Role, Hak Akses (GRANT / REVOKE), dan Row Level Security (RLS)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. PEMBUATAN ROLE (Hak Akses Berdasarkan Peran)
-- ------------------------------------------------------------------------------
DO $$
BEGIN
    -- Role Admin (Full Privileges)
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_admin') THEN
        CREATE ROLE role_admin;
    END IF;

    -- Role Petugas (Staff Operasional: Melihat riwayat, verifikasi tiket)
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_petugas') THEN
        CREATE ROLE role_petugas;
    END IF;

    -- Role Pembeli (End-User: Melihat konser, memesan tiket, bayar, cek pesanan sendiri)
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_pembeli') THEN
        CREATE ROLE role_pembeli;
    END IF;
END $$;

-- ------------------------------------------------------------------------------
-- 2. PEMBERIAN HAK AKSES SKEMA (GRANT USAGE)
-- ------------------------------------------------------------------------------
GRANT USAGE ON SCHEMA public TO role_admin, role_petugas, role_pembeli;

-- ------------------------------------------------------------------------------
-- 3. PEMBERIAN HAK AKSES UNTUK ROLE_ADMIN (Akses Penuh)
-- ------------------------------------------------------------------------------
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO role_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO role_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO role_admin;
GRANT ALL PRIVILEGES ON ALL PROCEDURES IN SCHEMA public TO role_admin;

-- ------------------------------------------------------------------------------
-- 4. PEMBERIAN HAK AKSES UNTUK ROLE_PETUGAS
-- Petugas berhak:
-- - Membaca semua data konser, pengguna, pesanan, tiket, pembayaran
-- - Membaca view riwayat pesanan (vw_riwayat_pesanan)
-- - Mengupdate status tiket (misal verifikasi check-in konser)
-- - Menjalankan prosedur pembatalan tiket jika ada komplain pelanggan
-- ------------------------------------------------------------------------------
GRANT SELECT ON pengguna, konser, pesanan, tiket, pembayaran TO role_petugas;
GRANT SELECT ON vw_riwayat_pesanan, vw_konser_tersedia, vw_pesanan_user TO role_petugas;
GRANT UPDATE (status) ON tiket TO role_petugas;
GRANT EXECUTE ON PROCEDURE sp_batalkan_tiket TO role_petugas;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO role_petugas;

-- ------------------------------------------------------------------------------
-- 5. PEMBERIAN HAK AKSES UNTUK ROLE_PEMBELI
-- Pembeli dibatasi hak aksesnya demi keamanan (Least Privilege Principle):
-- - Hanya boleh membaca konser yang tersedia (vw_konser_tersedia)
-- - Membaca pesanan miliknya sendiri (vw_pesanan_user)
-- - Mengeksekusi Stored Procedure transaksi (buat pesanan, bayar, batal)
-- - TIDAK DIBERI izin DELETE / UPDATE langsung ke tabel finansial
-- ------------------------------------------------------------------------------
GRANT SELECT ON vw_konser_tersedia, vw_pesanan_user TO role_pembeli;
GRANT SELECT ON konser TO role_pembeli;

-- Izin eksekusi Stored Procedures & Functions untuk transaksi pembeli
GRANT EXECUTE ON PROCEDURE sp_buat_pesanan TO role_pembeli;
GRANT EXECUTE ON PROCEDURE sp_bayar_pesanan TO role_pembeli;
GRANT EXECUTE ON PROCEDURE sp_tambah_pengguna TO role_pembeli;
GRANT EXECUTE ON PROCEDURE sp_batalkan_tiket TO role_pembeli;
GRANT EXECUTE ON FUNCTION fn_hitung_diskon TO role_pembeli;

-- Akses Sequence agar Stored Procedure dapat generate ID otomatis
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO role_pembeli;

-- ------------------------------------------------------------------------------
-- 6. PEMBUATAN DATABASE USER CONTOH (Untuk Login Aplikasi / DBeaver)
-- ------------------------------------------------------------------------------
DO $$
BEGIN
    -- User Petugas
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'user_petugas') THEN
        CREATE USER user_petugas WITH PASSWORD 'petugas123';
    END IF;
    GRANT role_petugas TO user_petugas;

    -- User Pembeli
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'user_pembeli') THEN
        CREATE USER user_pembeli WITH PASSWORD 'pembeli123';
    END IF;
    GRANT role_pembeli TO user_pembeli;

    -- Hubungkan pos_admin sebagai role_admin
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pos_admin') THEN
        GRANT role_admin TO pos_admin;
    END IF;
END $$;

-- ------------------------------------------------------------------------------
-- 7. ROW LEVEL SECURITY (RLS) & POLICIES
-- Menjamin isolasi data di level baris tabel
-- ------------------------------------------------------------------------------
ALTER TABLE pengguna ENABLE ROW LEVEL SECURITY;
ALTER TABLE pesanan ENABLE ROW LEVEL SECURITY;
ALTER TABLE tiket ENABLE ROW LEVEL SECURITY;
ALTER TABLE pembayaran ENABLE ROW LEVEL SECURITY;

-- Bersihkan policy lama jika ada
DROP POLICY IF EXISTS admin_all ON pengguna;
DROP POLICY IF EXISTS admin_all_pesanan ON pesanan;
DROP POLICY IF EXISTS admin_all_tiket ON tiket;
DROP POLICY IF EXISTS admin_all_pembayaran ON pembayaran;

-- Policy untuk Admin & Superuser: Akses Tanpa Batas
CREATE POLICY policy_admin_pengguna ON pengguna FOR ALL USING (pg_has_role(CURRENT_USER, 'role_admin', 'MEMBER') OR CURRENT_USER = 'pos_admin');
CREATE POLICY policy_admin_pesanan ON pesanan FOR ALL USING (pg_has_role(CURRENT_USER, 'role_admin', 'MEMBER') OR CURRENT_USER = 'pos_admin');
CREATE POLICY policy_admin_tiket ON tiket FOR ALL USING (pg_has_role(CURRENT_USER, 'role_admin', 'MEMBER') OR CURRENT_USER = 'pos_admin');
CREATE POLICY policy_admin_pembayaran ON pembayaran FOR ALL USING (pg_has_role(CURRENT_USER, 'role_admin', 'MEMBER') OR CURRENT_USER = 'pos_admin');

-- Policy untuk Petugas: Membaca semua data untuk operasional & verifikasi
CREATE POLICY policy_petugas_select_pesanan ON pesanan FOR SELECT USING (pg_has_role(CURRENT_USER, 'role_petugas', 'MEMBER'));
CREATE POLICY policy_petugas_select_tiket ON tiket FOR SELECT USING (pg_has_role(CURRENT_USER, 'role_petugas', 'MEMBER'));
CREATE POLICY policy_petugas_select_pembayaran ON pembayaran FOR SELECT USING (pg_has_role(CURRENT_USER, 'role_petugas', 'MEMBER'));
