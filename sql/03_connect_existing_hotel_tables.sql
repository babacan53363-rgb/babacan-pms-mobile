-- Babacan PMS Mobile V1.1
-- Mevcut hotel_* tablolarını mobil panele bağlar.
-- Tekrar tekrar güvenle çalıştırılabilir.

create or replace function public.mobile_dashboard_snapshot()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_hotel_id uuid;
  v_hotel_name text;
  v_result jsonb;
begin
  if v_user is null then
    raise exception 'Oturum açmanız gerekiyor';
  end if;

  select mp.hotel_id, h.name
    into v_hotel_id, v_hotel_name
  from public.mobile_profiles mp
  join public.hotels h on h.id = mp.hotel_id
  where mp.user_id = v_user
  limit 1;

  if v_hotel_id is null then
    raise exception 'Bu kullanıcı bir otele bağlanmamış. mobile_profiles kaydını kontrol edin.';
  end if;

  select jsonb_build_object(
    'hotel', jsonb_build_object('id', v_hotel_id, 'name', coalesce(v_hotel_name, 'Otel Yönetim Paneli')),
    'lastSync', greatest(
      coalesce((select max(updated_at) from public.hotel_rooms), '-infinity'::timestamptz),
      coalesce((select max(updated_at) from public.hotel_guests), '-infinity'::timestamptz),
      coalesce((select max(created_at) from public.hotel_transactions), '-infinity'::timestamptz)
    ),
    'rooms', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'room_no', r.room_no,
          'status', case
            when lower(coalesce(r.status,'')) in ('dolu','occupied') then 'occupied'
            when lower(coalesce(r.status,'')) in ('temizlik','cleaning','kirli') then 'cleaning'
            when lower(coalesce(r.status,'')) in ('arızalı','arizali','maintenance','bakım','bakim') then 'maintenance'
            else 'vacant'
          end,
          'guest_name', g.full_name,
          'check_in', g.checkin_date,
          'check_out', coalesce(g.planned_checkout, g.checkout_date),
          'balance', greatest(
            0,
            coalesce(g.nightly_rate,0) * greatest(1, coalesce((coalesce(g.planned_checkout,current_date) - g.checkin_date),1))
            + coalesce((select sum(e.quantity * e.unit_price) from public.hotel_extras e where e.guest_id = g.id),0)
            - coalesce((select sum(p.amount) from public.hotel_payments p where p.stay_source_id = g.source_id),0)
          )
        ) order by r.room_no
      )
      from public.hotel_rooms r
      left join lateral (
        select hg.*
        from public.hotel_guests hg
        where hg.room_no = r.room_no
          and lower(coalesce(hg.status,'')) not in ('çıkış','cikis','checkout','completed','iptal','cancelled')
          and hg.checkout_date is null
        order by hg.updated_at desc nulls last
        limit 1
      ) g on true
    ), '[]'::jsonb),
    'guests', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', g.id,
          'guest_name', g.full_name,
          'phone', g.phone,
          'room_no', g.room_no,
          'check_in', g.checkin_date,
          'check_out', coalesce(g.planned_checkout,g.checkout_date),
          'balance', greatest(
            0,
            coalesce(g.nightly_rate,0) * greatest(1, coalesce((coalesce(g.planned_checkout,current_date) - g.checkin_date),1))
            + coalesce((select sum(e.quantity * e.unit_price) from public.hotel_extras e where e.guest_id = g.id),0)
            - coalesce((select sum(p.amount) from public.hotel_payments p where p.stay_source_id = g.source_id),0)
          )
        ) order by g.room_no
      )
      from public.hotel_guests g
      where lower(coalesce(g.status,'')) not in ('çıkış','cikis','checkout','completed','iptal','cancelled')
        and g.checkout_date is null
    ), '[]'::jsonb),
    'cash', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', t.id,
          'type', case when lower(coalesce(t.transaction_type,'')) in ('gider','expense','çıkış','cikis') then 'expense' else 'income' end,
          'amount', t.amount,
          'description', coalesce(t.description,t.category,'Kasa hareketi'),
          'payment_method', t.payment_method,
          'staff_name', t.personnel_name,
          'created_at', coalesce(t.created_at, t.transaction_date::timestamptz)
        ) order by coalesce(t.created_at, t.transaction_date::timestamptz) desc
      )
      from (
        select * from public.hotel_transactions
        order by coalesce(created_at, transaction_date::timestamptz) desc
        limit 200
      ) t
    ), '[]'::jsonb)
  ) into v_result;

  return v_result;
end;
$$;

revoke all on function public.mobile_dashboard_snapshot() from public;
grant execute on function public.mobile_dashboard_snapshot() to authenticated;
