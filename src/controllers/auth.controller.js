const pool = require('../database/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const spService = require('../services/sp.service');

exports.register = async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password) {
      return res.status(400).json({ message: 'Username dan password wajib diisi!' });
    }

    const salt = bcrypt.genSaltSync(10);
    const passwordHash = bcrypt.hashSync(password, salt);

    await spService.executeTambahPengguna(username, passwordHash);
    res.status(201).json({ message: 'Registrasi berhasil! Silakan login.' });
  } catch (err) {
    res.status(400).json({ message: err.message || err.detail || 'Gagal mendaftar pengguna' });
  }
};

exports.login = async (req, res) => {
  try {
    const { username, password } = req.body;
    const { rows } = await pool.query('SELECT * FROM pengguna WHERE username = $1', [username]);
    if (rows.length === 0) return res.status(404).json({ message: 'User Not found.' });

    const user = rows[0];
    const passwordIsValid = bcrypt.compareSync(password, user.password_hash);
    if (!passwordIsValid) return res.status(401).json({ message: 'Invalid Password!' });

    const token = jwt.sign({ id: user.id, peran: user.peran }, process.env.JWT_SECRET, { expiresIn: 86400 });

    res.status(200).json({ id: user.id, username: user.username, peran: user.peran, accessToken: token });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
