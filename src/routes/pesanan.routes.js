const express = require('express');
const controller = require('../controllers/pesanan.controller');
const { verifyToken, requireRole } = require('../middlewares/auth.middleware');
const router = express.Router();

router.post('/', [verifyToken, requireRole('pembeli')], controller.buatPesanan);
router.post('/bayar', [verifyToken], controller.bayarPesanan);
router.get('/saya', [verifyToken], controller.pesananSaya);
router.post('/batal-tiket', [verifyToken], controller.batalkanTiket);
router.get('/riwayat', [verifyToken, requireRole('petugas')], controller.riwayatPesanan);
router.get('/:id/status', [verifyToken, requireRole('petugas')], controller.cekStatusPesanan);

module.exports = router;
