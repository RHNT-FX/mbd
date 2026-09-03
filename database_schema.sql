CREATE DATABASE IF NOT EXISTS mbd_konser;
USE mbd_konser;

-- 1. TABEL PENGGUNA
CREATE TABLE IF NOT EXISTS pengguna (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nama VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE
);

-- 2. TABEL KONSER (Mengandung JSON)
CREATE TABLE IF NOT EXISTS konser (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nama_konser VARCHAR(150) NOT NULL,
    tanggal DATETIME NOT NULL,
    kuota_awal INT NOT NULL,
    kuota_tersisa INT NOT NULL,
    harga_dasar DECIMAL(10, 2) NOT NULL,
    metadata_json JSON
);

-- B-TREE INDEX
CREATE INDEX idx_nama_konser ON konser(nama_konser);

-- 3. TABEL TIKET
CREATE TABLE IF NOT EXISTS tiket (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pengguna_id INT NOT NULL,
    konser_id INT NOT NULL,
    tanggal_beli DATETIME DEFAULT CURRENT_TIMESTAMP,
    status ENUM('valid', 'terpakai', 'batal') DEFAULT 'valid',
    FOREIGN KEY (pengguna_id) REFERENCES pengguna(id),
    FOREIGN KEY (konser_id) REFERENCES konser(id)
);

-- 4. TABEL PEMBAYARAN
CREATE TABLE IF NOT EXISTS pembayaran (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tiket_id INT NOT NULL,
    total_bayar DECIMAL(10, 2) NOT NULL,
    tanggal_bayar DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tiket_id) REFERENCES tiket(id)
);

-- Hapus routines/views jika sudah ada (agar bisa di-run ulang)
DROP VIEW IF EXISTS vw_konser_hampir_habis;
DROP FUNCTION IF EXISTS fn_hitung_total_bayar;
DROP PROCEDURE IF EXISTS sp_proses_pembelian_tiket;
DROP TRIGGER IF EXISTS trg_sebelum_beli_tiket;
DROP TRIGGER IF EXISTS trg_sebelum_scan_tiket;

-- 5. VIEW
CREATE VIEW vw_konser_hampir_habis AS
SELECT 
    id, 
    nama_konser, 
    kuota_tersisa,
    (kuota_tersisa / kuota_awal) * 100 AS persentase_sisa
FROM konser
WHERE kuota_tersisa > 0 AND (kuota_tersisa / kuota_awal) <= 0.20;

-- 6. FUNCTION
DELIMITER //
CREATE FUNCTION fn_hitung_total_bayar(harga DECIMAL(10,2)) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE pajak DECIMAL(10,2);
    DECLARE biaya_admin DECIMAL(10,2);
    SET pajak = harga * 0.10; -- Pajak 10%
    SET biaya_admin = 5000;   -- Biaya admin flat
    RETURN harga + pajak + biaya_admin;
END //
DELIMITER ;

-- 7. TRIGGER: ACTIVE DB & BUSINESS RULE (Mencegah Over-booking & Calo)
DELIMITER //
CREATE TRIGGER trg_sebelum_beli_tiket
BEFORE INSERT ON tiket
FOR EACH ROW
BEGIN
    DECLARE sisa INT;
    DECLARE jumlah_tiket_user INT;

    -- Rule 1: Cek kuota tersisa
    SELECT kuota_tersisa INTO sisa FROM konser WHERE id = NEW.konser_id;
    IF sisa <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gagal: Kuota tiket konser sudah habis!';
    END IF;

    -- Rule 2: Limit 4 tiket per user (Anti-Calo)
    SELECT COUNT(*) INTO jumlah_tiket_user FROM tiket WHERE pengguna_id = NEW.pengguna_id AND konser_id = NEW.konser_id;
    IF jumlah_tiket_user >= 4 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gagal: Maksimal pembelian 4 tiket per pengguna untuk konser ini!';
    END IF;
END //
DELIMITER ;

-- 8. TRIGGER: Mencegah scan tiket dua kali
DELIMITER //
CREATE TRIGGER trg_sebelum_scan_tiket
BEFORE UPDATE ON tiket
FOR EACH ROW
BEGIN
    IF OLD.status = 'terpakai' AND NEW.status = 'terpakai' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gagal: Tiket ini sudah pernah di-scan di pintu masuk!';
    END IF;
END //
DELIMITER ;

-- 9. STORED PROCEDURE & SQL TRANSACTION
DELIMITER //
CREATE PROCEDURE sp_proses_pembelian_tiket(
    IN p_pengguna_id INT,
    IN p_konser_id INT
)
BEGIN
    DECLARE v_harga_dasar DECIMAL(10,2);
    DECLARE v_total_bayar DECIMAL(10,2);
    DECLARE v_tiket_id INT;

    -- Tangkap error dan rollback otomatis jika ada masalah (contoh: ditolak Trigger)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Ambil harga dasar konser (FOR UPDATE untuk mencegah data berubah oleh orang lain bersamaan)
    SELECT harga_dasar INTO v_harga_dasar FROM konser WHERE id = p_konser_id FOR UPDATE;

    -- Kurangi kuota
    UPDATE konser SET kuota_tersisa = kuota_tersisa - 1 WHERE id = p_konser_id;

    -- Insert tiket (Ini akan memicu TRIGGER trg_sebelum_beli_tiket secara otomatis)
    INSERT INTO tiket (pengguna_id, konser_id) VALUES (p_pengguna_id, p_konser_id);
    SET v_tiket_id = LAST_INSERT_ID();

    -- Hitung total menggunakan FUNCTION
    SET v_total_bayar = fn_hitung_total_bayar(v_harga_dasar);

    -- Catat pembayaran
    INSERT INTO pembayaran (tiket_id, total_bayar) VALUES (v_tiket_id, v_total_bayar);

    COMMIT;
END //
DELIMITER ;

-- DUMMY DATA UNTUK DEMO
INSERT INTO pengguna (nama, email) VALUES 
('Rehan', 'rehan@email.com'),
('Budi', 'budi@email.com')
ON DUPLICATE KEY UPDATE id=id;

INSERT INTO konser (nama_konser, tanggal, kuota_awal, kuota_tersisa, harga_dasar, metadata_json) VALUES 
('Sheila On 7 - Tunggu Aku Di', '2027-10-15 19:00:00', 50, 5, 250000, '{"lokasi": "Stadion", "syarat": ["No Camera", "18+"]}'),
('Coldplay - Music of Spheres', '2027-11-20 20:00:00', 100, 100, 1500000, '{"lokasi": "GBK", "syarat": ["Gelang LED dipinjamkan"]}')
ON DUPLICATE KEY UPDATE id=id;

