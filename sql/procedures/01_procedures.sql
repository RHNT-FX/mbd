
CREATE OR REPLACE PROCEDURE sp_buat_pesanan(
    IN p_user_id INT,
    IN p_konser_id INT,
    IN p_jumlah_tiket INT,
    INOUT p_pesanan_id INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
      v_harga NUMERIC;
    v_total NUMERIC;
    i INT;
BEGIN

    SELECT harga_dasar INTO v_harga FROM konser WHERE id = p_konser_id FOR UPDATE;
    
    v_total := v_harga * p_jumlah_tiket;
    
    -- Memanggil function untuk menghitung diskon
    v_total := fn_hitung_diskon(v_total, p_jumlah_tiket);
    

    INSERT INTO pesanan (user_id, konser_id, jumlah_tiket, total_bayar, status)
    VALUES (p_user_id, p_konser_id, p_jumlah_tiket, v_total, 'Pending')
    RETURNING id INTO p_pesanan_id;
    

    FOR i IN 1..p_jumlah_tiket LOOP
        INSERT INTO tiket (pesanan_id, konser_id, kode_unik, status)
        VALUES (p_pesanan_id, p_konser_id, gen_random_uuid()::varchar, 'valid');
    END LOOP;
    
    COMMIT;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_bayar_pesanan(
    IN p_pesanan_id INT,
    IN p_jumlah_bayar NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_bayar NUMERIC;
    v_status VARCHAR;
BEGIN
    SELECT total_bayar, status INTO v_total_bayar, v_status
    FROM pesanan
    WHERE id = p_pesanan_id
    FOR UPDATE;

    IF NOT FOUND THEN
        ROLLBACK;
        RAISE EXCEPTION 'Gagal: Pesanan dengan ID % tidak ditemukan!', p_pesanan_id;
    END IF;

    IF v_status != 'Pending' THEN
        ROLLBACK;
        RAISE EXCEPTION 'Gagal: Pesanan ini sudah berstatus % dan tidak dapat dibayar lagi.', v_status;
    END IF;

    IF p_jumlah_bayar < v_total_bayar THEN
        ROLLBACK;
        RAISE EXCEPTION 'Gagal: Jumlah pembayaran (Rp%) kurang dari total tagihan pesanan (Rp%)!', p_jumlah_bayar, v_total_bayar;
    END IF;

    INSERT INTO pembayaran (pesanan_id, jumlah)
    VALUES (p_pesanan_id, p_jumlah_bayar);

    UPDATE pesanan
    SET status = 'Lunas'
    WHERE id = p_pesanan_id;

    COMMIT;
END;
$$;

-- Stored Procedure: Registrasi Pembeli Baru
CREATE OR REPLACE PROCEDURE sp_tambah_pengguna(
    IN p_username VARCHAR,
    IN p_password_hash VARCHAR,
    INOUT p_user_id INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_exists INT;
BEGIN
    IF p_username IS NULL OR TRIM(p_username) = '' THEN
        ROLLBACK;
        RAISE EXCEPTION 'Gagal: Username tidak boleh kosong!';
    END IF;

    IF p_password_hash IS NULL OR TRIM(p_password_hash) = '' THEN
        ROLLBACK;
        RAISE EXCEPTION 'Gagal: Password tidak boleh kosong!';
    END IF;

    SELECT COUNT(*) INTO v_exists
    FROM pengguna
    WHERE username = p_username;

    IF v_exists > 0 THEN
        ROLLBACK;
        RAISE EXCEPTION 'Gagal: Username "%" sudah terdaftar!', p_username;
    END IF;

    INSERT INTO pengguna (username, password_hash, peran)
    VALUES (p_username, p_password_hash, 'pembeli')
    RETURNING id INTO p_user_id;

    COMMIT;
END;
$$;

-- Stored Procedure: Pembatalan Tiket
CREATE OR REPLACE PROCEDURE sp_batalkan_tiket(
    IN p_tiket_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_konser_id INT;
    v_status VARCHAR;
BEGIN
    SELECT konser_id, status INTO v_konser_id, v_status
    FROM tiket
    WHERE id = p_tiket_id
    FOR UPDATE;

    IF NOT FOUND THEN
        ROLLBACK;
        RAISE EXCEPTION 'Gagal: Tiket dengan ID % tidak ditemukan!', p_tiket_id;
    END IF;

    IF v_status != 'valid' THEN
        ROLLBACK;
        RAISE EXCEPTION 'Gagal: Tiket sudah berstatus % dan tidak dapat dibatalkan lagi.', v_status;
    END IF;

    UPDATE tiket 
    SET status = 'batal' 
    WHERE id = p_tiket_id;

    UPDATE konser 
    SET kuota_tersisa = kuota_tersisa + 1 
    WHERE id = v_konser_id;

    COMMIT;
END;
$$;

