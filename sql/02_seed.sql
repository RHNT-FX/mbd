-- Seed Data
INSERT INTO pengguna (username, password_hash, peran) VALUES 
('rehan', '$2a$10$Vi56v70yS1UIqRzLEeWLc.K5DZpn.ZMYVPFdgW5w.jyNd2vMnqNMy', 'pembeli'), -- password: password123
('admin', '$2a$10$Vi56v70yS1UIqRzLEeWLc.K5DZpn.ZMYVPFdgW5w.jyNd2vMnqNMy', 'petugas'),
('budi', '$2a$10$Vi56v70yS1UIqRzLEeWLc.K5DZpn.ZMYVPFdgW5w.jyNd2vMnqNMy', 'pembeli');

INSERT INTO konser (nama_konser, tanggal, harga_dasar, kuota_awal, kuota_tersisa) VALUES 
('Konser Dewa 19', '2027-10-10 19:00:00', 500000, 100, 100),
('Coldplay Jakarta', '2027-11-15 20:00:00', 1500000, 50, 50),
('Tulus Live Intimate', '2027-12-01 19:30:00', 350000, 50, 3);
