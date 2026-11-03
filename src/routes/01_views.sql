CREATE OR REPLACE VIEW vw_konser_tersedia AS
SELECT id, nama_konser, tanggal, harga_dasar, kuota_awal, kuota_tersisa
FROM konser
WHERE kuota_tersisa > 0;

CREATE OR REPLACE VIEW vw_riwayat_pesanan ASvi
SELECT 
    p.id AS pesanan_id,
    u.username AS nama_pembeli,
    k.nama_konser,
    p.jumlah_tiket,
    p.total_bayar,
    p.status
FROM pesanan p
JOIN pengguna u ON p.user_id = u.id
JOIN konser k ON p.konser_id = k.id;
