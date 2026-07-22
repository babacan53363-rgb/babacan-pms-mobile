# Babacan PMS Mobile V1.1 — Mevcut Cloud Tablolarına Bağlı

Bu sürüm, yeni `mobile_rooms` veya `mobile_guests` tablolarına veri kopyalamaz. Masaüstü PMS'nin doldurduğu mevcut tabloları doğrudan okur:

- `hotel_rooms`
- `hotel_guests`
- `hotel_extras`
- `hotel_payments`
- `hotel_transactions`

## Kurulum sırası

### 1. Supabase SQL
Supabase → **SQL Editor → New Query** bölümünde yalnızca şu dosyayı açıp çalıştırın:

`sql/03_connect_existing_hotel_tables.sql`

Başarılı olunca `Success. No rows returned` benzeri mesaj görünür.

### 2. Kullanıcıyı otele bağlama
Authentication → Users ekranındaki kullanıcının UUID değerini ve Table Editor → hotels tablosundaki otel UUID değerini alın.

SQL Editor'de çalıştırın:

```sql
insert into public.mobile_profiles (user_id, hotel_id, role)
values ('KULLANICI_UUID', 'OTEL_UUID', 'owner')
on conflict (user_id) do update
set hotel_id = excluded.hotel_id, role = excluded.role;
```

### 3. Supabase bağlantısı
`config.js` dosyasına Supabase **Project URL** ve **anon/publishable key** değerini yazın.

### 4. Vercel'e yükleme
Bu klasörün içindeki dosyaları mobil panel için kullandığınız GitHub deposunun kök dizinine yükleyin. Vercel otomatik deploy eder.

### 5. Masaüstü senkronizasyonu
Babacan PMS → **Cloud Merkezi** üzerinden aynı Supabase kullanıcı hesabıyla giriş yapın ve **Şimdi Senkronize Et** seçeneğini çalıştırın.

Mobil paneli yenilediğinizde gerçek oda, misafir ve kasa bilgileri görünür.

## Not
`01_mobile_schema.sql` dosyasını tekrar çalıştırmanız gerekmez. Daha önce aldığınız “policy already exists” hatası bu nedenle oluşmuştur.
