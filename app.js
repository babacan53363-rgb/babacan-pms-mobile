const cfg = window.BABACAN_CONFIG || {};
const configured = cfg.SUPABASE_URL && !cfg.SUPABASE_URL.includes('BURAYA_') && cfg.SUPABASE_ANON_KEY && !cfg.SUPABASE_ANON_KEY.includes('BURAYA_');
const sb = configured ? window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY) : null;
let demoMode = false;
let state = { rooms: [], guests: [], cash: [], hotel: null, lastSync: null };

const $ = (id) => document.getElementById(id);
const money = (v) => new Intl.NumberFormat('tr-TR',{style:'currency',currency:'TRY',maximumFractionDigits:0}).format(Number(v||0));
const formatDate = (d) => d ? new Date(d).toLocaleString('tr-TR',{dateStyle:'short',timeStyle:'short'}) : '—';
function toast(msg){ const t=$('toast'); t.textContent=msg; t.classList.add('show'); setTimeout(()=>t.classList.remove('show'),2400); }
function showApp(){ $('loginView').classList.add('hidden'); $('appView').classList.remove('hidden'); $('todayText').textContent=new Date().toLocaleDateString('tr-TR',{weekday:'long',day:'numeric',month:'long'}); }
function showLogin(){ $('appView').classList.add('hidden'); $('loginView').classList.remove('hidden'); }
function setOnline(ok,text){ $('syncDot').className='dot '+(ok?'online':'offline'); $('syncText').textContent=text; }

const demo = {
 hotel:{name:'Babacan Otel'}, lastSync:new Date().toISOString(),
 rooms:[
  {room_no:'101',status:'occupied',guest_name:'Mehmet Yılmaz',check_in:'2026-07-22',check_out:'2026-07-24',balance:0},
  {room_no:'102',status:'vacant'}, {room_no:'103',status:'occupied',guest_name:'Ayşe Demir',check_in:'2026-07-21',check_out:'2026-07-23',balance:500},
  {room_no:'104',status:'cleaning'}, {room_no:'105',status:'vacant'}, {room_no:'201',status:'occupied',guest_name:'Ahmet Kaya',check_in:'2026-07-22',check_out:'2026-07-25',balance:0},
  {room_no:'202',status:'vacant'}, {room_no:'203',status:'vacant'}
 ],
 guests:[
  {guest_name:'Mehmet Yılmaz',room_no:'101',phone:'0532 000 00 01',check_out:'2026-07-24',balance:0},
  {guest_name:'Ayşe Demir',room_no:'103',phone:'0532 000 00 02',check_out:'2026-07-23',balance:500},
  {guest_name:'Ahmet Kaya',room_no:'201',phone:'0532 000 00 03',check_out:'2026-07-25',balance:0}
 ],
 cash:[
  {type:'income',amount:1500,description:'Oda 101 tahsilat',created_at:new Date().toISOString()},
  {type:'expense',amount:350,description:'Market gideri',created_at:new Date(Date.now()-3600000).toISOString()},
  {type:'income',amount:2000,description:'Oda 201 tahsilat',created_at:new Date(Date.now()-7200000).toISOString()}
 ]
};

async function loadData(){
 try{
  if(demoMode){ state=structuredClone(demo); render(); setOnline(true,'Demo verileri gösteriliyor'); return; }
  setOnline(false,'Cloud verileri alınıyor');
  const {data:{user}}=await sb.auth.getUser(); if(!user){showLogin();return;}
  const {data,error}=await sb.rpc('mobile_dashboard_snapshot');
  if(error) throw error;
  const snap=data||{};
  state={
    hotel:snap.hotel||{name:'Otel Yönetim Paneli'},
    rooms:Array.isArray(snap.rooms)?snap.rooms:[],
    guests:Array.isArray(snap.guests)?snap.guests:[],
    cash:Array.isArray(snap.cash)?snap.cash:[],
    lastSync:snap.lastSync||null
  };
  render(); setOnline(true,'Cloud bağlantısı aktif');
 }catch(e){ console.error(e); setOnline(false,'Bağlantı hatası'); toast(e.message||'Veriler alınamadı'); }
}

function render(){
 $('hotelName').textContent=state.hotel?.name||'Otel Yönetim Paneli';
 $('lastSync').textContent=formatDate(state.lastSync);
 const occupied=state.rooms.filter(r=>r.status==='occupied').length, vacant=state.rooms.filter(r=>r.status==='vacant').length;
 const income=state.cash.filter(x=>x.type==='income').reduce((a,b)=>a+Number(b.amount||0),0), expense=state.cash.filter(x=>x.type==='expense').reduce((a,b)=>a+Number(b.amount||0),0);
 $('stats').innerHTML=[['Dolu Oda',occupied,`${state.rooms.length} odadan`],['Boş Oda',vacant,'Satışa hazır'],['Aktif Misafir',state.guests.length,'Konaklayan'],['Kasa Net',money(income-expense),'Görünen hareketler']].map(x=>`<div class="stat-card"><span>${x[0]}</span><strong>${x[1]}</strong><small>${x[2]}</small></div>`).join('');
 renderRooms('all'); renderGuests(); renderCash();
}
function statusLabel(s){return ({occupied:'DOLU',vacant:'BOŞ',cleaning:'TEMİZLİK',maintenance:'ARIZALI'})[s]||String(s||'BİLİNMİYOR').toUpperCase()}
function roomHtml(r){return `<article class="room-card" data-status="${r.status}"><div class="room-top"><span class="room-no">${r.room_no}</span><span class="status ${r.status}">${statusLabel(r.status)}</span></div><p>${r.status==='occupied'?`<b>${r.guest_name||'Misafir'}</b><br>Çıkış: ${r.check_out||'—'}<br>Bakiye: ${money(r.balance)}`:r.status==='vacant'?'Oda satışa hazır.':r.status==='cleaning'?'Temizlik işlemi devam ediyor.':'Kontrol gerekiyor.'}</p></article>`}
function renderRooms(filter='all'){ const arr=filter==='all'?state.rooms:state.rooms.filter(r=>r.status===filter); const html=arr.length?arr.map(roomHtml).join(''):'<div class="empty">Bu filtrede oda bulunamadı.</div>'; $('roomList').innerHTML=html; $('roomPreview').innerHTML=state.rooms.map(roomHtml).join(''); }
function renderGuests(){ $('guestCount').textContent=`${state.guests.length} kişi`; $('guestList').innerHTML=state.guests.length?state.guests.map(g=>`<div class="list-item"><div><h4>${g.guest_name}</h4><p>Oda ${g.room_no} · Çıkış ${g.check_out||'—'}<br>${g.phone||''}</p></div><span class="amount ${Number(g.balance)>0?'out':'in'}">${Number(g.balance)>0?money(g.balance):'Ödendi'}</span></div>`).join(''):'<div class="empty">Aktif konaklayan bulunmuyor.</div>'; }
function renderCash(){ const net=state.cash.reduce((a,x)=>a+(x.type==='income'?1:-1)*Number(x.amount||0),0); $('cashTotal').textContent=`Net ${money(net)}`; const html=state.cash.length?state.cash.map(x=>`<div class="list-item"><div><h4>${x.description||'Kasa hareketi'}</h4><p>${formatDate(x.created_at)}${x.payment_method?' · '+x.payment_method:''}</p></div><span class="amount ${x.type==='income'?'in':'out'}">${x.type==='income'?'+':'-'}${money(x.amount)}</span></div>`).join(''):'<div class="empty">Kasa hareketi bulunmuyor.</div>'; $('cashList').innerHTML=html; $('cashPreview').innerHTML=state.cash.slice(0,4).map(x=>`<div class="list-item"><div><h4>${x.description||'Kasa hareketi'}</h4><p>${formatDate(x.created_at)}</p></div><span class="amount ${x.type==='income'?'in':'out'}">${x.type==='income'?'+':'-'}${money(x.amount)}</span></div>`).join('')||'<div class="empty">Kasa hareketi bulunmuyor.</div>'; }
function switchPage(id){ document.querySelectorAll('.page').forEach(x=>x.classList.toggle('active',x.id===id)); document.querySelectorAll('.nav-item').forEach(x=>x.classList.toggle('active',x.dataset.page===id)); window.scrollTo({top:0,behavior:'smooth'}); }

document.addEventListener('click',e=>{ const page=e.target.closest('[data-page]')?.dataset.page; if(page)switchPage(page); const filter=e.target.closest('[data-filter]')?.dataset.filter; if(filter){document.querySelectorAll('.chip').forEach(x=>x.classList.toggle('active',x.dataset.filter===filter));renderRooms(filter);} });
$('loginForm').addEventListener('submit',async e=>{e.preventDefault(); if(!sb){toast('Önce config.js dosyasına Supabase bilgilerini girin.');return;} const {error}=await sb.auth.signInWithPassword({email:$('email').value,password:$('password').value}); if(error){toast(error.message);return;} showApp();loadData();});
$('demoBtn').addEventListener('click',()=>{demoMode=true;showApp();loadData();});
$('refreshBtn').addEventListener('click',loadData);
$('logoutBtn').addEventListener('click',async()=>{demoMode=false;if(sb)await sb.auth.signOut();showLogin();});
if(!configured)$('configWarning').classList.remove('hidden');
(async()=>{if(sb){const {data}=await sb.auth.getSession();if(data.session){showApp();loadData();}}})();
