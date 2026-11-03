const pool = require('../database/db');

exports.getKonserTersedia = async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM vw_konser_tersedia');
    res.status(200).json(rows);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
