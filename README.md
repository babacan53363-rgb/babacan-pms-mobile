# Babacan PMS Mobile V1.3

Bu klasör Vercel'e doğrudan yüklenebilen mobil yönetim panelidir.

## Kurulum

1. Supabase > SQL Editor > New Query açın.
2. `sql/04_mobile_dashboard_rpc.sql` dosyasının tamamını yapıştırıp Run'a basın.
3. GitHub'daki `babacan-pms-mobile` reposuna bu klasörün İÇİNDEKİ dosyaları yükleyin.
4. Vercel ekranında ayarları değiştirmeden Deploy'a basın.
5. Yayın adresini açıp Supabase Authentication kullanıcınızın e-posta ve şifresiyle giriş yapın.
6. Masaüstü PMS > Cloud Merkezi > Şimdi Senkronize Et çalıştırın.

## GitHub ana dizininde görünmesi gerekenler

- index.html
- app.js
- style.css
- config.js
- vercel.json
- manifest.webmanifest
- assets/
- sql/

## Not

Panel salt-okunur çalışır. Oda, misafir ve kasa bilgilerini değiştirmez; sadece Cloud'a gönderilen verileri gösterir.
