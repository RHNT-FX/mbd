-- Roles & Row Level Security
ALTER TABLE pengguna ENABLE ROW LEVEL SECURITY;
ALTER TABLE pesanan ENABLE ROW LEVEL SECURITY;
ALTER TABLE tiket ENABLE ROW LEVEL SECURITY;
ALTER TABLE pembayaran ENABLE ROW LEVEL SECURITY;

CREATE POLICY admin_all ON pengguna FOR ALL USING (true);
CREATE POLICY admin_all_pesanan ON pesanan FOR ALL USING (true);
CREATE POLICY admin_all_tiket ON tiket FOR ALL USING (true);
CREATE POLICY admin_all_pembayaran ON pembayaran FOR ALL USING (true);
