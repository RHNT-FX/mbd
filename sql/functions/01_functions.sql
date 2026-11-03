
CREATE OR REPLACE FUNCTION fn_validasi_tiket()
RETURNS TRIGGER AS $$
DECLARE
    v_kuota INT;
    v_jumlah_tiket_user INT;
    v_user_id INT;
BEGIN

    SELECT kuota_tersisa INTO v_kuota FROM konser WHERE id = NEW.konser_id;
    IF v_kuota <= 0 THEN
        RAISE EXCEPTION 'Gagal: Kuota tiket konser sudah habis!';
    END IF;


    SELECT user_id INTO v_user_id FROM pesanan WHERE id = NEW.pesanan_id;

    SELECT COUNT(*) INTO v_jumlah_tiket_user 
    FROM tiket t
    JOIN pesanan p ON t.pesanan_id = p.id
    WHERE p.user_id = v_user_id AND t.konser_id = NEW.konser_id AND t.status != 'batal';

    IF v_jumlah_tiket_user >= 4 THEN
        RAISE EXCEPTION 'Gagal: Maksimal pembelian 4 tiket per pengguna untuk konser ini (Anti-Calo)!';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_kurangi_kuota()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE konser SET kuota_tersisa = kuota_tersisa - 1 WHERE id = NEW.konser_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_hitung_diskon(p_total_awal NUMERIC, p_jumlah_tiket INT)
RETURNS NUMERIC AS $$
BEGIN
    IF p_jumlah_tiket >= 3 THEN
        RETURN p_total_awal * 0.90;
    ELSE
        RETURN p_total_awal;
    END IF;
END;
$$ LANGUAGE plpgsql;
