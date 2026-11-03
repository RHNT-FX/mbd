const spService = require('../services/sp.service');
const pool = require('../database/db');

exports.buatPesanan = async (req, res) => {
  try {
    const { konserId, jumlahTiket } = req.body;
    const userId = req.userId;

    if (!konserId || !jumlahTiket) {
        return res.status(400).json({ message: 'konserId dan jumlahTiket harus diisi' });
    }
    if (jumlahTiket <= 0) {
        return res.status(400).json({ message: 'jumlahTiket minimal 1' });
    }

    await spService.executeBuatPesanan(userId, konserId, jumlahTiket);
    res.status(200).json({ message: 'Pesanan berhasil dibuat!' });
  } catch (err) {
    res.status(400).json({ message: err.message || err.detail || 'Gagal membuat pesanan' });
  }
};

exports.bayarPesanan = async (req, res) => {
    try {
        const { pesananId, jumlahBayar } = req.body;
        
        if (!pesananId || !jumlahBayar) {
            return res.status(400).json({ message: 'pesananId dan jumlahBayar harus diisi' });
        }
        if (jumlahBayar <= 0) {
            return res.status(400).json({ message: 'jumlahBayar harus lebih dari 0' });
        }

        // Jalankan Stored Procedure sp_bayar_pesanan (menangani validasi, insert, update status, dan COMMIT/ROLLBACK)
        await spService.executeBayarPesanan(pesananId, jumlahBayar);
        res.status(200).json({ message: 'Pembayaran berhasil, status pesanan menjadi Lunas' });
    } catch (err) {
        res.status(400).json({ message: err.message || err.detail || 'Gagal memproses pembayaran' });
    }
}

exports.riwayatPesanan = async (req, res) => {
    try {
        const { rows } = await pool.query('SELECT * FROM vw_riwayat_pesanan');
        res.status(200).json(rows);
    } catch(err) {
        res.status(500).json({ message: err.message });
    }
}

exports.cekStatusPesanan = async (req, res) => {
    try {
        const { id } = req.params;
        const { rows } = await pool.query(`
            SELECT p.id as pesanan_id, u.username as nama_pembeli, k.nama_konser, p.total_bayar, p.status 
            FROM pesanan p
            JOIN pengguna u ON p.user_id = u.id
            JOIN konser k ON p.konser_id = k.id
            WHERE p.id = $1
        `, [id]);

        if (rows.length === 0) {
            return res.status(404).json({ message: 'Pesanan tidak ditemukan' });
        }

        res.status(200).json(rows[0]);
    } catch(err) {
        res.status(500).json({ message: err.message });
    }
}

exports.pesananSaya = async (req, res) => {
    try {
        const userId = req.userId;
        const { rows } = await pool.query(`
            SELECT pesanan_id, nama_pembeli, nama_konser, tanggal_konser, jumlah_tiket, total_bayar, status, tanggal_pesan
            FROM vw_pesanan_user
            WHERE user_id = $1
            ORDER BY tanggal_pesan DESC
        `, [userId]);

        res.status(200).json(rows);
    } catch(err) {
        res.status(500).json({ message: err.message });
    }
}

exports.batalkanTiket = async (req, res) => {
    try {
        const { tiketId } = req.body;
        if (!tiketId) {
            return res.status(400).json({ message: 'tiketId wajib diisi!' });
        }

        await spService.executeBatalkanTiket(tiketId);
        res.status(200).json({ message: 'Tiket berhasil dibatalkan dan kuota konser dikembalikan!' });
    } catch (err) {
        res.status(400).json({ message: err.message || err.detail || 'Gagal membatalkan tiket' });
    }
}
