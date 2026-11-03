const http = require('http');
async function run() {
  const login = await fetch('http://localhost:3000/api/v1/auth/login', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'rehan', password: 'password123' })
  }).then(r => r.json());
  
  const token = login.accessToken;
  
  const res = await fetch('http://localhost:3000/api/v1/pesanan', {
    method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
    body: JSON.stringify({ konserId: 1, jumlahTiket: 4 })
  });
  const text = await res.text();
  console.log("STATUS:", res.status, "BODY:", text);
}
run();
