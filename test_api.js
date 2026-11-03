const http = require('http');

const BASE_URL = 'http://localhost:3000/api/v1';

async function request(path, method, body, token) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: `/api/v1${path}`,
      method: method,
      headers: {
        'Content-Type': 'application/json'
      }
    };

    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => { data += chunk; });
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch (e) {
          resolve({ status: res.statusCode, data });
        }
      });
    });

    req.on('error', reject);

    if (body) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
}

async function runTests() {
  console.log("🚀 MEMULAI TESTING API OTOMATIS...\n");

  try {
    // 1. Login Pembeli
    console.log("1️⃣  Login sebagai pembeli (rehan)...");
    const loginRes = await request('/auth/login', 'POST', { username: 'rehan', password: 'password123' });
    console.log("Response:", loginRes.data);
    const tokenPembeli = loginRes.data.accessToken;
    console.log("Token Pembeli berhasil didapatkan!\n");

    // 2. Lihat Konser
    console.log("2️⃣  Melihat jadwal konser tersedia...");
    const konserRes = await request('/konser/tersedia', 'GET');
    console.log("Response:", konserRes.data, "\n");

    // 3. Buat Pesanan
    console.log("3️⃣  Membuat pesanan tiket (Beli 2 tiket Konser ID 1)...");
    const pesanRes = await request('/pesanan', 'POST', { konserId: 1, jumlahTiket: 2 }, tokenPembeli);
    console.log("Response:", pesanRes.data, "\n");

    // 3b. Coba Beli > 4 Tiket (Uji Trigger Anti-Calo)
    console.log("🛑 MENGUJI TRIGGER ANTI-CALO (Beli 5 tiket)...");
    const caloRes = await request('/pesanan', 'POST', { konserId: 1, jumlahTiket: 5 }, tokenPembeli);
    console.log("Response (Harusnya Gagal):", caloRes.data, "\n");

    // 4. Bayar Pesanan
    console.log("4️⃣  Membayar pesanan (Pesanan ID 1)...");
    const bayarRes = await request('/pesanan/bayar', 'POST', { pesananId: 1, jumlahBayar: 1000000 }, tokenPembeli);
    console.log("Response:", bayarRes.data, "\n");

    // 5. Login Petugas
    console.log("5️⃣  Login sebagai Petugas (admin)...");
    const loginAdmin = await request('/auth/login', 'POST', { username: 'admin', password: 'password123' });
    const tokenAdmin = loginAdmin.data.accessToken;
    console.log("Token Petugas berhasil didapatkan!\n");

    // 6. Lihat Riwayat
    console.log("6️⃣  Petugas melihat riwayat pesanan (Cek status Lunas)...");
    const riwayatRes = await request('/pesanan/riwayat', 'GET', null, tokenAdmin);
    console.log("Response:", riwayatRes.data, "\n");

    console.log("✅ SEMUA TEST BERHASIL DIJALANKAN!");

  } catch (err) {
    console.error("❌ Terjadi Error:", err);
  }
}

runTests();
