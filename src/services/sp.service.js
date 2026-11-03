const pool = require('../database/db');

const executeBuatPesanan = async (userId, konserId, jumlahTiket) => {
  const client = await pool.connect();
  try {
    const res = await client.query('CALL sp_buat_pesanan($1, $2, $3, null)', [userId, konserId, jumlahTiket]);
    return res;
  } catch (err) {
    throw err;
  } finally {
    client.release();
  }
};

const executeBayarPesanan = async (pesananId, jumlahBayar) => {
  const client = await pool.connect();
  try {
    const res = await client.query('CALL sp_bayar_pesanan($1, $2)', [pesananId, jumlahBayar]);
    return res;
  } catch (err) {
    throw err;
  } finally {
    client.release();
  }
};

const executeTambahPengguna = async (username, passwordHash) => {
  const client = await pool.connect();
  try {
    const res = await client.query('CALL sp_tambah_pengguna($1, $2, null)', [username, passwordHash]);
    return res;
  } catch (err) {
    throw err;
  } finally {
    client.release();
  }
};

const executeBatalkanTiket = async (tiketId) => {
  const client = await pool.connect();
  try {
    const res = await client.query('CALL sp_batalkan_tiket($1)', [tiketId]);
    return res;
  } catch (err) {
    throw err;
  } finally {
    client.release();
  }
};

module.exports = {
  executeBuatPesanan,
  executeBayarPesanan,
  executeTambahPengguna,
  executeBatalkanTiket
};
