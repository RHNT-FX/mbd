const fs = require('fs');
const pool = require('./src/database/db');

const BASE_URL = 'http://localhost:3000/api/v1';

async function runTests() {
    console.log("=== MEMULAI PENGUJIAN ENDPOINT & DATABASE ===\n");
    let tokenPembeli = '';
    let tokenPetugas = '';
    let pesananIdToPay = null;
    let totalTagihan = 0;

    // 0. Setup fresh user untuk testing
    const testUsername = `user_${Date.now()}`;
    await pool.query("INSERT INTO pengguna (username, password_hash, peran) VALUES ($1, '$2a$10$Vi56v70yS1UIqRzLEeWLc.K5DZpn.ZMYVPFdgW5w.jyNd2vMnqNMy', 'pembeli')", [testUsername]);

    // 1. Test Login Pembeli
    console.log(`1. Menguji POST /auth/login (Pembeli: ${testUsername})`);
    let res = await fetch(`${BASE_URL}/auth/login`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username: testUsername, password: 'password123' })
    });
    let data = await res.json();
    tokenPembeli = data.accessToken;
    console.log(res.status === 200 ? `✅ Sukses Login Pembeli (${testUsername})` : "❌ Gagal Login", data);

    // 2. Test Login Petugas
    console.log("\n2. Menguji POST /auth/login (Petugas)");
    res = await fetch(`${BASE_URL}/auth/login`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username: 'admin', password: 'password123' })
    });
    data = await res.json();
    tokenPetugas = data.accessToken;
    console.log(res.status === 200 ? "✅ Sukses Login Petugas" : "❌ Gagal Login");

    // 3. Test View Konser Tersedia
    console.log("\n3. Menguji GET /konser/tersedia (Menguji vw_konser_tersedia)");
    res = await fetch(`${BASE_URL}/konser/tersedia`);
    data = await res.json();
    console.log(res.status === 200 && data.length > 0 ? `✅ Sukses narik View Konser (${data.length} konser tersedia)` : "❌ Gagal narik view");

    // 4. Test Validasi Buat Pesanan (Field Kosong)
    console.log("\n4. Menguji Validasi Node.js - POST /pesanan (Field Kosong)");
    res = await fetch(`${BASE_URL}/pesanan`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${tokenPembeli}` },
        body: JSON.stringify({ konserId: 1 }) // missing jumlahTiket
    });
    data = await res.json();
    console.log(res.status === 400 ? `✅ Ditolak dengan benar: ${data.message}` : "❌ Gagal validasi field kosong");

    // 5. Test Validasi Buat Pesanan (Minus)
    console.log("\n5. Menguji Validasi Node.js - POST /pesanan (Jumlah Tiket Minus)");
    res = await fetch(`${BASE_URL}/pesanan`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${tokenPembeli}` },
        body: JSON.stringify({ konserId: 1, jumlahTiket: -2 }) 
    });
    data = await res.json();
    console.log(res.status === 400 ? `✅ Ditolak dengan benar: ${data.message}` : "❌ Gagal validasi jumlah minus");

    // 6. Test Trigger DB (Anti-Calo > 4 tiket)
    console.log("\n6. Menguji Trigger Database (fn_validasi_tiket) - Beli > 4 tiket");
    res = await fetch(`${BASE_URL}/pesanan`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${tokenPembeli}` },
        body: JSON.stringify({ konserId: 1, jumlahTiket: 5 }) 
    });
    data = await res.json();
    console.log(res.status === 400 && data.message.includes('Anti-Calo') ? `✅ Trigger DB Sukses Menolak: ${data.message}` : "❌ Gagal, tiket calo lolos");

    // 7. Test Sukses Buat Pesanan & Stored Procedure & Diskon Function
    console.log("\n7. Menguji Sukses POST /pesanan (Beli 3 tiket -> Test Diskon SP)");
    res = await fetch(`${BASE_URL}/pesanan`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${tokenPembeli}` },
        body: JSON.stringify({ konserId: 1, jumlahTiket: 3 }) // 3 x 500rb = 1.5jt. Diskon 10% = 1.35jt
    });
    data = await res.json();
    console.log(res.status === 200 ? `✅ Sukses Buat Pesanan (sp_buat_pesanan, Trigger kurang kuota, Function diskon berjalan)` : "❌ Gagal", data);

    // 8. Test View Riwayat Pesanan
    console.log("\n8. Menguji GET /pesanan/riwayat (Petugas) (Menguji vw_riwayat_pesanan)");
    res = await fetch(`${BASE_URL}/pesanan/riwayat`, {
        headers: { 'Authorization': `Bearer ${tokenPetugas}` }
    });
    data = await res.json();
    if (res.status === 200 && data.length > 0) {
        let userOrders = data.filter(o => o.nama_pembeli === testUsername && o.status === 'Pending');
        if (userOrders.length > 0) {
            pesananIdToPay = userOrders[0].pesanan_id;
            totalTagihan = userOrders[0].total_bayar;
            console.log(`✅ View Riwayat Sukses. Order ID Pending: ${pesananIdToPay}, Total Bayar (Setelah Diskon): Rp${totalTagihan}`);
        } else {
            console.log("❌ Gagal, tidak ada order pending atas nama pengguna baru.");
        }
    } else {
        console.log("❌ Gagal tarik riwayat");
    }

    // 9. Test Validasi Bayar Melalui Stored Procedure (Uang Kurang -> ROLLBACK)
    if(pesananIdToPay) {
        console.log("\n9. Menguji Stored Procedure sp_bayar_pesanan (Uang Kurang -> Validasi & ROLLBACK)");
        res = await fetch(`${BASE_URL}/pesanan/bayar`, {
            method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${tokenPembeli}` },
            body: JSON.stringify({ pesananId: pesananIdToPay, jumlahBayar: 10000 }) // Sengaja kurang
        });
        data = await res.json();
        console.log(res.status === 400 && data.message.includes('kurang dari total') ? `✅ Stored Procedure Berhasil Menolak & Rollback: ${data.message}` : "❌ Gagal Validasi", data);

        // 10. Test Validasi Bayar Melalui Stored Procedure (Pas -> COMMIT)
        console.log("\n10. Menguji Sukses Bayar via Stored Procedure sp_bayar_pesanan (COMMIT)");
        res = await fetch(`${BASE_URL}/pesanan/bayar`, {
            method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${tokenPembeli}` },
            body: JSON.stringify({ pesananId: pesananIdToPay, jumlahBayar: totalTagihan }) 
        });
        data = await res.json();
        console.log(res.status === 200 ? `✅ Pembayaran Sukses via Procedure!` : "❌ Gagal", data);

        // 11. Test Validasi Bayar Melalui Stored Procedure (Sudah Lunas -> ROLLBACK)
        console.log("\n11. Menguji Stored Procedure sp_bayar_pesanan - Bayar pesanan yang sudah lunas (ROLLBACK)");
        res = await fetch(`${BASE_URL}/pesanan/bayar`, {
            method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${tokenPembeli}` },
            body: JSON.stringify({ pesananId: pesananIdToPay, jumlahBayar: totalTagihan }) 
        });
        data = await res.json();
        console.log(res.status === 400 && data.message.includes('sudah berstatus Lunas') ? `✅ Stored Procedure Menolak: ${data.message}` : "❌ Gagal Validasi", data);
    }

    console.log("\n=== PENGUJIAN SELESAI ===");
    pool.end();
}

runTests();
