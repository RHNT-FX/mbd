const express = require('express');
const controller = require('../controllers/konser.controller');
const router = express.Router();

router.get('/tersedia', controller.getKonserTersedia);

module.exports = router;
