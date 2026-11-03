CREATE TRIGGER trg_validasi_kuota
BEFORE INSERT ON tiket
FOR EACH ROW
EXECUTE FUNCTION fn_validasi_tiket();
    
CREATE TRIGGER trg_kurangi_kuota
AFTER INSERT ON tiket
FOR EACH ROW
EXECUTE FUNCTION fn_kurangi_kuota();