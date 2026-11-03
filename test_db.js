const pool = require('./src/database/db');

async function test() {
  try {
    const res = await pool.query('SELECT NOW()');
    console.log('Success:', res.rows);
  } catch (err) {
    console.error('Full Error Object:', err);
    console.error('Error Code:', err.code);
    console.error('Error Message:', err.message);
  } finally {
    pool.end();
  }
}

test();
