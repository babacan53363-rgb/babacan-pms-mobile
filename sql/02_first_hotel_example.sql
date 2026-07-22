-- 1) Supabase Authentication > Users bölümünden önce kullanıcı oluşturun.
-- 2) Aşağıdaki e-posta ve otel adını değiştirip SQL Editor'de çalıştırın.

do $$
declare
  v_hotel uuid;
  v_user uuid;
begin
  insert into public.hotels(name, license_key)
  values ('Babacan Otel','BPMS-DEMO-001')
  returning id into v_hotel;

  select id into v_user from auth.users where email='babacan53363@gmail.com' limit 1;
  if v_user is null then
    raise exception 'Bu e-posta ile Authentication kullanıcısı bulunamadı.';
  end if;

  insert into public.mobile_profiles(user_id,hotel_id,role)
  values(v_user,v_hotel,'owner')
  on conflict(user_id) do update set hotel_id=excluded.hotel_id,role=excluded.role;

  insert into public.mobile_rooms(hotel_id,room_no,status) values
  (v_hotel,'101','vacant'),(v_hotel,'102','vacant'),(v_hotel,'103','vacant'),(v_hotel,'104','vacant'),(v_hotel,'105','vacant'),
  (v_hotel,'201','vacant'),(v_hotel,'202','vacant'),(v_hotel,'203','vacant'),(v_hotel,'204','vacant'),(v_hotel,'205','vacant'),(v_hotel,'206','vacant'),(v_hotel,'207','vacant'),(v_hotel,'208','vacant'),
  (v_hotel,'301','vacant'),(v_hotel,'302','vacant'),(v_hotel,'303','vacant'),(v_hotel,'304','vacant'),(v_hotel,'305','vacant'),(v_hotel,'306','vacant'),(v_hotel,'307','vacant'),(v_hotel,'308','vacant')
  on conflict do nothing;
end $$;
