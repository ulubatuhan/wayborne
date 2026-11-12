# Uygulama planı (uygulayıcı: Opus 5 medium)

**Dalga 1 bitti (2026-11-12).** On dört işin hepsi uygulandı ve ölçüldü; sonuç `08_dalga1_sonucu.md`.

**SIRADAKİ: Dalga 2** — `06_is_plani.md` WP-02'den başlar. Kartları Fable yazar; bu dosya Dalga 1'in kaydıdır.

## Uygulayıcı talimatı

1. Yalnız sıradaki kartı oku: `grep -n "^## IP-001" -A60 docs/playtest/2026-11-12/07_opus_uygulama_plani.md`.
2. Kartın "Oku" satırındaki dosya ve aralıklardan başkasını açma. Büyük dosyayı baştan sona okuma.
3. Kartın "Yapma" satırı kesin sınırdır. Kartta yazmayan bir tasarım kararı gerekirse **DUR**, soruyu yaz.
4. Sayı (fiyat, olasılık, hasar, eşik) değiştirme; kart açıkça vermediyse **DUR**.
5. Metinler kartta hazır; kelimesini değiştirme. Yeni CSV satırından sonra `godot --headless --import` iki kez.
6. "Doğrula" komutu beklenen satırı vermezse bir kez düzelt; yine vermezse **DUR**, çıktının son 20 satırını yaz.
7. Oyuncunun gördüğü bir şey değiştiyse kartın ekran aracını koştur ve görüntüye bak (`ekran-dogrula`).
8. Commit: kartın şablonu, tek commit. Mesajda oturum satırı, bağlantı ya da model adı olmaz. Dal `Wayborne`; PR açma.
9. Bitince bu dosyada kutuyu işaretle, **SIRADAKİ** satırını ilerlet, `gorevler.json`'da durumu "kapandı" yap,
   `python3 proje_takibi/referans/belge_uret.py` koştur, `proje_takibi/DEVAM_NOTU.md`'ye iki satır ekle.
10. **KARAR-BEKLİYOR** kartı kullanıcının cevabı kartta yazmadan başlamaz; sıradaki oysa **DUR**.
11. Depoda referans oyun ya da film adı yazma (kodlar R1-R5). Ara mesaj tek cümle.
12. Ortak doğrulama her kartta: `tools/test_ozet.sh` → son satır `0 başarısız`; günlükte `SCRIPT ERROR` yok.

## Sıra

- [x] IP-015 Sürücünün şehir siyaseti ve yeniden ölçüm · M · **ölçüm aracı, oyun kodu değişmez**
- [x] IP-001 Planlayıcı eksik erzağı günle söyler · S
- [x] IP-002 Meşale erişimi ölçümü · S
- [x] IP-005 İsyan kartı sefer başına en çok iki kez · S
- [x] IP-004 Üç açlık kartı · M
- [x] IP-007 Kapıdaki sayım kartı · M
- [x] IP-010 En çok görülen kartlara iz, 1. parti · M
- [x] IP-011 En çok görülen kartlara iz, 2. parti · M
- [x] IP-009 Kişi isteğinde yön satırı · M
- [x] IP-012 Aramada nadir bulgu deftere adla yazılır · S
- [x] IP-008 İlk saat sahne turu aracı · M
- [x] IP-003 Karşılaşma türü dönüşümü · S · **KARAR-BEKLİYOR K-04**
- [x] IP-006 Kervan avlusunda sıradaki adım · M · **KARAR-BEKLİYOR K-03**
- [x] IP-013 Borcun yüzü · S · **KARAR-BEKLİYOR K-05**
- [x] IP-014 Dalga 1 sonrası yeniden ölçüm ve rapor · S

Sonraki dalgalar (`06_is_plani.md` WP-02…WP-18) bu turda karta dökülmedi: kart metinleri ve yankı satırları önce
yazılmalı. Dalga 1 bitince Fable'a "Dalga 2 kartlarını yaz" denir.

---

## IP-015 Sürücünün şehir siyaseti ve yeniden ölçüm

- **Kimlik:** IP-015 · boyut M · sütun: — (ölçüm aracı) · bağımlılık: yok
- **Amaç:** Üç sürücü siyaseti ölçümü bozuyor (bkz. `05_hata_listesi.md` H-11, H-12, H-13). Düzelt, yeniden koş,
  1. ve 8. bulguyu yeni sayılarla yaz. **Oyun kodu değişmez.**
- **Oku:** `tests/playtest/playtest_driver.gd` satır 855-885 (`_v_vagon_al`, `_v_vagon_sat`), 814-841 (`_v_ise_alma`),
  1014-1045 (`_mal_al`) · `tests/playtest/profiller/*.json`
- **Adımlar:**
  1. **Vagon değirmeni (H-11):** `_v_vagon_sat` yalnız iki koşulda satsın: (a) vadesi geçmiş borç var ve kese borcu
     kapatmaya yetmiyor, (b) kadro o vagonu süremiyor (`get_idle_wagon_count() > 0`). Kese dibi tek başına yetmesin.
  2. **İşe alım (H-12):** aday seçimi profilden gelsin: `sehir.aday_secimi` = `"ucuz"` (en düşük `hire_cost`) ya da
     `"kidemli"` (bugünkü hâl). Varsayılan `"ucuz"`; `p4_somurucu` ve `p2_hayatta_kalan`'a `"ucuz"`, ötekilere de
     `"ucuz"` yaz (kimse 4 saatte kıdemliye para yetiştiremiyor). `ise_alma_sonrasi_kese` 60'tan 20'ye insin.
  3. **Mal payı (H-13):** `_mal_al` bütçesini hesaplarken büyüme hedefi varsa onu da ayır: profile
     `sehir.buyume_hedefi` (bool, varsayılan `true`) ekle; doğruysa `_s.get_next_donkey_cost()` kadarını bütçeden düş.
  4. **first_decision tanımı (H-14):** planlayıcıdaki "eksik erzakla yola çık" ve rota seçimi de `_ilk("first_decision")`
     saysın; eski dar ölçüm `first_card` adıyla ayrıca kalsın.
  5. 15 koşuyu yeniden koştur (`ALTYAPI.md`'deki komut), `python3 tools/playtest_toplam.py > build/playtest/toplam.txt`.
  6. Yeni sayılarla **yalnız şunları** güncelle: `00_yonetici_ozeti.md` 1., 4. ve 8. madde · `01`'deki özet tablo ·
     `02`'deki huni, ilkler ve R-1 maddesi · `03`'ün 1. ve 2. katman tabloları · `05`'te H-07, H-11, H-12, H-13.
  7. R-1 (büyüme) yeni sayılarla hâlâ tutmuyorsa IP-006 sırada kalır; tutuyorsa IP-006'yı listeden **çıkar** ve
     gerekçesini `06_is_plani.md` §5 K-03 satırına yaz.
- **Yapma:** `scripts/` altına dokunma. Profillerin ahlakını, ağırlıklarını, rotasını, tempo ve sofra kipini
  değiştirme. Tohumları değiştirme (101, 202, 303).
- **Doğrula:** `tools/test_ozet.sh` → `0 başarısız`; yeni `toplam.txt`'te 15 satır; `grep -c "vagon satıldı"`
  bütün günlüklerde toplam 31'den küçük; en az bir profilde 4:00 kontrol noktasında vagon ≥ 2.
- **Commit:** `Oyun testi: sürücünün şehir siyaseti düzeltildi, yeniden ölçüldü (IP-015)`
- **Bitiş ölçütü:** Yeni sayılar raporda; 1. ve 8. bulgu ya doğrulanmış ya düzeltilmiş.

## IP-001 Planlayıcı eksik erzağı günle söyler

- **Kimlik:** IP-001 · boyut S · sütun: İnsanlar aşınır · bağımlılık: yok
- **Amaç:** Eksik erzakla yola çıkan oyuncu kaç gün aç yürüyeceğini çıkmadan önce sayıyla görsün. Kilit yok.
- **Oku:**
  - `scripts/ui/caravan_planner.gd` satır 596-660
  - `grep -n "func get_required_provisions" -A14 scripts/travel/caravan_plan.gd`
  - `grep -n "func get_daily_provision_consumption" -A8 scripts/autoload/game_session.gd`
  - `grep -n "UI_PLANNER_PROVISIONS_SHORT\|UI_PLANNER_DEPART_HUNGRY\|UI_PLANNER_DEPART_CONFIRM" data/locale/ui.csv`
- **Adımlar:**
  1. `caravan_planner.gd`'de `shortfall > 0` dalında iki tam sayı hesapla (ikisi de açık tipli):
     `var daily: int = maxi(1, _session.get_daily_provision_consumption())`,
     `var fed_days: int = current_provisions / daily`,
     `var route_days: int = ceili(float(required_provisions) / float(daily))`,
     `var hungry_days: int = maxi(0, route_days - fed_days)`.
  2. `_shortfall_label.text`'in sonuna yeni satır ekle: `"\n" + tr("UI_PLANNER_HUNGRY_DAYS") % [fed_days, route_days, hungry_days]`.
  3. Silahlanmış onayda (`_departure_armed` doğruyken) düğme metni: `tr("UI_PLANNER_DEPART_CONFIRM_DAYS") % hungry_days`.
  4. `data/locale/ui.csv`'ye iki satır ekle (sütun sayısı komşu satırla aynı, 12):
     - `"UI_PLANNER_HUNGRY_DAYS","Erzak %d gün yeter, yol %d gün: %d gün aç yürürsün.","Provisions last %d days, the road is %d: %d days walked hungry.","","","","","","","","",""`
     - `"UI_PLANNER_DEPART_CONFIRM_DAYS","%d gün aç yürüyeceksin. Tekrar bas ve yola çık","%d days hungry. Press again to set out","","","","","","","","",""`
  5. `tests/test_caravan_planner.gd` yoksa açma; `grep -rn "UI_PLANNER_DEPART_HUNGRY" tests/` ile planlayıcıyı
     sınayan paketi bul ve oraya bir sınama ekle: erzak 10, günlük 5, yol 6 gün → metin "2", "6", "4" içerir.
     Bulunamazsa sınamayı `tests/test_ui_scenes.gd`'ye ekle.
- **Yapma:** Yola çıkışı kilitleme. `UI_PLANNER_PROVISIONS_SHORT` metnini değiştirme. Erzak formülüne dokunma.
- **Doğrula:** `godot --headless --import` (iki kez); `tools/test_ozet.sh` → `0 başarısız`;
  `grep -c "UI_PLANNER_HUNGRY_DAYS" data/locale/ui.csv` → `1`. Ekran: planlayıcıyı çeken aracı
  `ls tests | grep -i "screenshot.*\(plan\|journey\)"` ile bul, koştur, eksik erzaklı görüntüde yeni satırı gör.
- **Commit:** `Planlayıcı: eksik erzak gün olarak da yazılır (IP-001)`
- **Bitiş ölçütü:** Eksik erzaklı planda üç sayı görünür; testler geçer.

## IP-002 Meşale erişimi ölçümü

- **Kimlik:** IP-002 · S · sütun: Yol yaşar · bağımlılık: yok
- **Amaç:** Hiçbir profil gece ışığı yakamadı. Sebep oyunda mı sürücüde mi, ayır. Oyun kodu değişmez.
- **Oku:** `grep -n "MAKE_TORCHES" -B2 -A6 scripts/economy/recipe_catalog.gd` ·
  `grep -n "light_for_night\|TORCHES_PER_NIGHT" scripts/autoload/game_session.gd` ·
  `grep -n "zanaat\|isik" tests/playtest/playtest_driver.gd | head -30`
- **Adımlar:**
  1. Tarifin girdisi olan malın (bez) başlangıç şehirlerinin (orsolune ve komşuları) pazarında satılıp satılmadığını
     `tests/playtest/` altına yazacağın `olc_mesale.gd` ile say: 27 yerleşimin kaçında var, fiyatı ne.
  2. Sürücünün `zanaat` adımının neden "yeterli malzeme yok" dediğini bul: mal alınmıyor mu, pay yetmiyor mu.
  3. Sonucu `docs/playtest/2026-11-12/05_hata_listesi.md` H-01 satırının altına üç cümleyle yaz.
  4. Sürücü hatasıysa sürücüde düzelt (profil `sehir.sira`'da `zanaat`tan önce bez alımı). Oyun hatasıysa **DUR**.
- **Yapma:** Tarifi, fiyatı, pazar stokunu değiştirme.
- **Doğrula:** `godot --headless --script res://tests/playtest/olc_mesale.gd` bir tablo basar;
  P2 tohum 101 yeniden koşunca `grep -c "İki meşale yok" build/playtest/p2_hayatta_kalan/101/olaylar.jsonl` önceki
  sayıdan (≈87) küçük.
- **Commit:** `Oyun testi: meşale erişimi ölçüldü (IP-002)`
- **Bitiş ölçütü:** H-01 satırında sebep yazılı.

## IP-005 İsyan kartı sefer başına en çok iki kez

- **Kimlik:** IP-005 · S · sütun: Yol yaşar · bağımlılık: yok
- **Amaç:** Aç yürüyüşte aynı kartın 21 kez çıkması tekrar; baskı kalsın, kart değişsin.
- **Oku:** `grep -n "evt_mutiny" scripts/events/event_catalog.gd | head` (kurucu fonksiyonu bul, 40 satır oku) ·
  `grep -n "cooldown_days\|once\|max_per_journey" scripts/events/game_event.gd scripts/events/event_engine.gd`
- **Adımlar:**
  1. `GameEvent`'te sefer başına tavan alanı varsa `evt_mutiny` için 2 yap.
  2. Yoksa `GameEvent`'e `max_per_journey: int = 0` (0 = sınırsız) ekle; `EventEngine`'in uygunluk süzgecinde,
     motorun zaten tuttuğu görülme sayacını kullanarak tavanı uygula; `evt_mutiny`'de 2 ver.
  3. `tests/test_event_engine.gd`'ye sınama: tavanı 2 olan kart aynı motorda üçüncü kez çekilemez.
- **Yapma:** İsyanın ağırlığını, koşulunu, etkilerini değiştirme. Başka karta tavan koyma.
- **Doğrula:** `tools/test_ozet.sh` → `0 başarısız`.
- **Commit:** `Olay motoru: sefer başına tavan; isyan en çok iki kez (IP-005)`
- **Bitiş ölçütü:** Sınama geçer.

## IP-004 Üç açlık kartı

- **Kimlik:** IP-004 · M · sütun: İnsanlar aşınır · Defter unutmaz · bağımlılık: IP-005
- **Amaç:** Erzak bitince karar bitmesin. Aç gece 2, 4 ve 6'dan sonra birer kart; her seçenek bir şeyi feda eder.
- **Oku:** `.claude/skills/olay-karti/SKILL.md` · örnek olarak `evt_starving_roadside` kurucusu
  (`grep -n "evt_starving_roadside" scripts/events/event_catalog.gd`, 50 satır) ·
  `grep -n "consecutive_hungry_days\|crew_hungry_nights" scripts/autoload/game_session.gd | head` (bağlam anahtarı var mı) ·
  `grep -n "IZ_BIRAK\|BEDEL" scripts/events/event_catalog.gd | head -4` (yazım örneği)
- **Adımlar:**
  1. Olay bağlamında aç gece sayısı yoksa `build_event_context`'e `hungry_nights` ekle
     (`maxi(crew_hungry_nights, liderin consecutive_hungry_days)`).
  2. Üç kart ekle; hepsi `max_per_journey = 1`, koşul `hungry_nights >=` 2 / 4 / 6 ve `provisions == 0`:
     - `evt_hunger_draft_animal` (≥ 2): **Koşumu kes** → erzak +14, yol +2 gün, `IZ_BIRAK -40 "soylenti|bolge|kisa|fiyat"`;
       **Dokunma** → moral −8, stres +6.
     - `evt_hunger_eat_cargo` (≥ 4), koşul: yenebilir yük var: **Yükü ye** → o maldan en çok 6 birim gider, erzak +
       aynı sayı, `BEDEL 4 "STRESS|gecmisi_uyan"`; **Yükü yak, ısın** → 4 birim gider, stres −6, moral −4;
       **Yüke dokunma** → `BEDEL 0 "LEAVE_BEHIND|en_zayif"`, `IZ_BIRAK -50 "kin|bolge|kisa|fiyat"`.
     - `evt_hunger_send_ahead` (≥ 6), koşul: kadro ≥ 2: **En diri olanı önden gönder** → Dayanıklılık sınaması;
       başarı: erzak +10, 2 gün sonra; başarısız: o kişi ayrılır (ölüm değil), `IZ_BIRAK -30 "soylenti|bolge|kisa|yuz"`;
       **Birlikte yürü** → stres +8.
  3. Metinler (`data/locale/events.csv`, TR / EN):
     - `EVT_HUNGER_DRAFT_TITLE`: "Koşumdaki Hayvan" / "The Animal in Harness"
     - `EVT_HUNGER_DRAFT_TEXT`: "İki gecedir kazan boş. Arabacı dizgini bırakmış, öküzün sağrısına bakıyor. Kimse bir şey demiyor." / "Two nights the pot has been empty. The wagoner has dropped the reins and is looking at the ox's flank. Nobody says anything."
     - `EVT_HUNGER_DRAFT_OPT_KILL`: "Kes. Vagonu sırayla çekeriz." / "Slaughter it. We take turns at the yoke."
     - `EVT_HUNGER_DRAFT_OPT_KEEP`: "Hayvan kalır." / "The animal stays."
     - `EVT_HUNGER_CARGO_TITLE`: "Çuvalların Ağzı" / "The Mouths of the Sacks"
     - `EVT_HUNGER_CARGO_TEXT`: "Yük başkasının: sayılmış, mühürlenmiş, bekleniyor. Dört gündür kimse yemedi. Bir el çuvalın ipine gitti, durdu, sana baktı." / "The cargo is someone else's: counted, sealed, waited for. Nobody has eaten in four days. A hand went to the cord of a sack, stopped, and looked at you."
     - `EVT_HUNGER_CARGO_OPT_EAT`: "Aç. Hesabını ben veririm." / "Open it. I will answer for it."
     - `EVT_HUNGER_CARGO_OPT_BURN`: "Yenmeyeni yak, bu gece ısınalım." / "Burn what can't be eaten. Tonight we are warm."
     - `EVT_HUNGER_CARGO_OPT_REFUSE`: "Mühür durur." / "The seal holds."
     - `EVT_HUNGER_AHEAD_TITLE`: "Önden Giden" / "The One Sent Ahead"
     - `EVT_HUNGER_AHEAD_TEXT`: "Altı gece. Kervan bu hızla varmaz. Yükü olmayan tek kişi iki günde varır, belki bir çuvalla döner. Belki dönmez." / "Six nights. At this pace the caravan will not arrive. One person without a load gets there in two days and may come back with a sack. Or may not."
     - `EVT_HUNGER_AHEAD_OPT_SEND`: "En diri olan gitsin." / "Whoever is strongest goes."
     - `EVT_HUNGER_AHEAD_OPT_STAY`: "Ayrılmıyoruz." / "We stay together."
     - Sonuç satırları: `EVT_HUNGER_AHEAD_OUT_BACK`: "Üçüncü sabah döndü. Sırtında bir çuval, ağzında tek kelime yok." / "Back on the third morning. A sack on the shoulder and not a word." · `EVT_HUNGER_AHEAD_OUT_GONE`: "Dönmedi. Yolda izi de yok." / "Never came back. No track on the road either."
  4. Kartları kalite listesinden geçir: `godot --headless --script res://tests/report_event_quality.gd`.
- **Yapma:** Açlık ölümü eşiğini, erzak tüketimini değiştirme. Kartlara altın ödülü koyma. Kimseyi kartla öldürme
  (olaylar öldürmez).
- **Doğrula:** `tools/test_ozet.sh` → `0 başarısız`; kalite raporunda üç yeni kart "sorun yok";
  P1 tohum 303 yeniden koşunca `grep -c "evt_hunger_" build/playtest/p1_acemi/303/olaylar.jsonl` ≥ 3.
- **Commit:** `Olaylar: üç açlık kartı (IP-004)`
- **Bitiş ölçütü:** Üç kart çekilir, kaliteden geçer, P1 koşusunda görülür.

## IP-007 Kapıdaki sayım kartı

- **Kimlik:** IP-007 · M · sütun: Yol yaşar · Defter unutmaz · bağımlılık: yok
- **Amaç:** İlk karar 7-11. dakikadan ilk çıkışa insin; ilk iz ilk saatte dönsün.
- **Oku:** `.claude/skills/olay-karti/SKILL.md` · `grep -n "evt_customs_checkpoint" scripts/events/event_catalog.gd`
  (kurucu, 60 satır) · `grep -n "journeys_completed\|total_journeys" scripts/autoload/game_session.gd | head -5`
- **Adımlar:**
  1. Yeni kart `evt_gate_count`: koşul tamamlanan sefer sayısı 0 ve yol günü 1; ağırlık çok yüksek (ilk gün kesin
     çıksın), `once = true`.
  2. Seçenekler: **Yükünü say** → `IZ_BIRAK 40 "minnet|bolge|kisa|kapi"`; **Eksik söyle** → Karizma sınaması; başarı:
     altın +8; başarısız: `IZ_BIRAK -40 "soylenti|bolge|kisa|kapi"`; **Sus, yürü** → stres +2.
  3. Metinler: `EVT_GATE_COUNT_TITLE`: "Kapıdaki Sayım" / "The Count at the Gate" ·
     `EVT_GATE_COUNT_TEXT`: "Kapıdan çıkarken tebeşirli bir adam vagonun yanında yürüyor. Tahtasına çentik atıyor, başını kaldırmadan soruyor: \"Ne götürüyorsun?\"" / "On the way out a man with chalk walks beside the wagon. He cuts notches in his board and asks without looking up: \"What are you carrying?\"" ·
     `EVT_GATE_COUNT_OPT_TELL`: "Hepsini say." / "Count it all out." ·
     `EVT_GATE_COUNT_OPT_SHORT`: "Yarısını söyle." / "Tell him half." ·
     `EVT_GATE_COUNT_OPT_SILENT`: "Yürümeye devam et." / "Keep walking."
- **Yapma:** Öğretici metin, ipucu kutusu, anlatıcı ekleme.
- **Doğrula:** `tools/test_ozet.sh` → `0 başarısız`; P3a tohum 101 yeniden koşunca `ozet.json` `ilkler_oturum.first_decision`
  önceki değerden (≈677) küçük.
- **Commit:** `Olaylar: kapıdaki sayım, ilk çıkışın kararı (IP-007)`
- **Bitiş ölçütü:** Kart ilk seferin ilk gününde çıkar.

## IP-010 En çok görülen kartlara iz, 1. parti

- **Kimlik:** IP-010 · M · sütun: Defter unutmaz · bağımlılık: yok (Y-R01'in ilk dilimi)
- **Amaç:** İz bırakan kart oyuncunun en çok gördüğü kart olsun.
- **Oku:** `grep -n "IZ_BIRAK" scripts/events/event_catalog.gd | head -4` (yazım) ·
  `sed -n 21,60p scripts/campaign/trace.gd` (geçerli tür, kapsam, vade, dönüş değerleri) · her kart için kurucusu
  (`grep -n "evt_<ad>" scripts/events/event_catalog.gd`, 50 satır)
- **Adımlar:** Aşağıdaki seçeneklere, anlamca eşleşen seçeneğin etki listesine `_fx(EventEffect.Type.IZ_BIRAK, <n>, "<metin>")` ekle.

  | kart | seçenek (anlam) | n | metin |
  |---|---|---|---|
  | `evt_bandit_ambush` | fidyeyi ödemek | -40 | `soylenti\|bolge\|kisa\|dusman` |
  | `evt_customs_checkpoint` | rüşvet vermek | -40 | `soylenti\|bolge\|kisa\|kapi` |
  | `evt_customs_checkpoint` | dürüst beyan | 30 | `minnet\|bolge\|kisa\|kapi` |
  | `evt_deserter_levy` | kaçağı ele vermek | -60 | `kin\|kisi\|uzun\|dusman` |
  | `evt_deserter_levy` | kaçağı saklamak | 50 | `minnet\|kisi\|uzun\|aday` |
  | `evt_guard_patrol` | yalan ya da rüşvet | -40 | `soylenti\|bolge\|kisa\|kapi` |
  | `evt_military_convoy` | erzak vermek | 40 | `minnet\|bolge\|kisa\|yuz` |
  | `evt_military_convoy` | reddetmek | -30 | `kin\|bolge\|kisa\|kapi` |

  Anlamca eşleşen seçenek yoksa o satırı atla ve commit mesajına yaz. Değerlerden biri `trace.gd`'de geçerli değilse **DUR**.
- **Yapma:** Kartların öbür etkilerini, metnini, ağırlığını değiştirme. İz tavanlarına dokunma.
- **Doğrula:** `tools/test_ozet.sh` → `0 başarısız`; `grep -c "IZ_BIRAK" scripts/events/event_catalog.gd` 14'ten büyük.
- **Commit:** `İz: en çok görülen beş karta iz (IP-010, Y-R01)`
- **Bitiş ölçütü:** En az altı satır işlendi.

## IP-011 En çok görülen kartlara iz, 2. parti

- **Kimlik:** IP-011 · M · sütun: Defter unutmaz · bağımlılık: IP-010
- **Oku / Yapma / Doğrula:** IP-010 ile aynı.
- **Adımlar:**

  | kart | seçenek (anlam) | n | metin |
  |---|---|---|---|
  | `evt_cargo_toll` | ödemeden kaçmak | -40 | `kin\|bolge\|kisa\|dusman` |
  | `evt_village_provisions` | fahiş fiyata satmak ya da pazarlığı ezmek | -50 | `kin\|bolge\|kisa\|fiyat` |
  | `evt_village_provisions` | hakça alışveriş | 40 | `minnet\|bolge\|kisa\|fiyat` |
  | `evt_road_ultimatum` | boyun eğmek | -30 | `soylenti\|bolge\|kisa\|dusman` |
  | `evt_refugee_column` | erzak vermek | 50 | `minnet\|bolge\|uzun\|aday` |
  | `evt_refugee_column` | yoldan sürmek | -50 | `kin\|bolge\|uzun\|ret` |
  | `evt_sick_merchant` | yanında kalmak | 40 | `minnet\|kisi\|uzun\|teklif` |
  | `evt_sick_merchant` | malını alıp gitmek | -60 | `kin\|kisi\|uzun\|dusman` |

  Bir seçenekte zaten `IZ_BIRAK` varsa o satırı atla.
- **Commit:** `İz: ikinci parti (IP-011, Y-R01)`
- **Bitiş ölçütü:** En az altı satır işlendi.

## IP-009 Kişi isteğinde yön satırı

- **Kimlik:** IP-009 · M · sütun: Ticaret bilgi oyunudur · bağımlılık: yok
- **Amaç:** "4 tane eksik" diyen istek, malın hangi yönde bulunduğunu haber olarak söylesin; kesin yer vermesin.
- **Oku:** `grep -n "func offer_chain\|func deliver_chain" -A25 scripts/campaign/people.gd` ·
  `grep -n "Tanıdıklar\|UI_BRIEF_PEOPLE" scripts/ui/*.gd data/locale/ui.csv | head` ·
  `grep -n "func get_produced\|produces\|supply" scripts/travel/location.gd | head -5`
- **Adımlar:**
  1. `People`'a `chain_hint(session, person) -> String`: istenen malı üreten ve bu şehre rota komşusu olan
     yerleşimlerden en yakınının **yönünü** (kuzey, güney, doğu, batı; harita konum farkından) döndür; yoksa boş.
  2. Şehir özetindeki kişi satırına ekle: `tr("UI_PEOPLE_HINT") % [yön]`.
  3. `ui.csv`: `"UI_PEOPLE_HINT","%s yolundan gelenlerde olur diyorlar.","They say those who come by the %s road carry it.",…` ve
     dört yön anahtarı yoksa: `UI_DIR_NORTH` "kuzey"/"north", `UI_DIR_SOUTH` "güney"/"south", `UI_DIR_EAST` "doğu"/"east", `UI_DIR_WEST` "batı"/"west".
  4. Sınama: bilinen bir tohumda ipucu boş değil ve bir yön adı içerir.
- **Yapma:** Şehir adı ya da fiyat söyleme. İstenen miktarı değiştirme.
- **Doğrula:** `tools/test_ozet.sh` → `0 başarısız`; şehir özeti ekran aracı (`ls tests | grep -i "screenshot.*brief\|city"`) ile görüntü.
- **Commit:** `Tanıdıklar: isteğin yönü haber olarak söylenir (IP-009)`

## IP-012 Aramada nadir bulgu deftere adla yazılır

- **Kimlik:** IP-012 · S · sütun: Defter unutmaz · bağımlılık: yok (Y-B16'ya bağlanır)
- **Amaç:** Her gece yapılan arama alışkanlık; nadir iyi sonuç bir an olsun.
- **Oku:** `grep -n "func forage\|FORAGE" scripts/autoload/game_session.gd | head -8` (fonksiyon, 40 satır) ·
  `grep -n "func add_entry\|func record" scripts/campaign/caravan_ledger.gd | head -4`
- **Adımlar:**
  1. Aramanın sonucu o kervanın o seferdeki en yüksek bulgusuysa ve ≥ 6 erzaksa deftere bir satır yaz:
     `tr("LEDGER_FORAGE_FIND") % [bulan kişinin adı, miktar, yer]`. Bulan: arama işini yapan kişi; yoksa lider.
  2. `game.csv`: `"LEDGER_FORAGE_FIND","%s bir kuytuda %d öğünlük yiyecek buldu, %s yakınlarında.","%s found %d meals' worth in a hollow, near %s.",…`
  3. Sınama: aynı seferde ikinci, daha küçük bulgu satır yazmaz.
- **Yapma:** Arama olasılığını ya da miktarını değiştirme.
- **Doğrula:** `tools/test_ozet.sh` → `0 başarısız`.
- **Commit:** `Defter: aramadaki nadir bulgu adla yazılır (IP-012)`

## IP-008 İlk saat sahne turu aracı

- **Kimlik:** IP-008 · M · sütun: — (ölçüm) · bağımlılık: yok
- **Amaç:** İlk saat gerçek sahnelerle görüntülensin; sürücü geri dönüşü kullansın.
- **Oku:** `tests/screenshot_menu.gd` (tamamı, örnek) · `tests/screenshot_journey_screen.gd` ilk 80 satır ·
  `grep -n "sapma\|geri_don" tests/playtest/playtest_driver.gd | head -20`
- **Adımlar:**
  1. `tests/playtest/playtest_ilk_saat.gd`: sırayla başlık, ana menü, karakter kurma, şehir, şehir özeti, pazar,
     planlayıcı (eksik erzaklı), yol (gün 1), ilk kart, kamp, sofra, varış ekranlarını açar; her birini
     `user://playtest_ilk_saat/NN_ad.png` olarak kaydeder. Sahne yolları `screenshot_*.gd` araçlarından alınır.
  2. Sürücüde `yol.sapma == "aclikta"` iken: erzak 0 ve kalan gün > geçen gün ise geri dönüş kapısını dene, sonucu
     "engel" ya da "rota" olarak kaydet.
  3. `ALTYAPI.md`'nin "Görülmeyen" maddesini güncelle.
- **Yapma:** `scripts/` altına dokunma.
- **Doğrula:** `LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --script res://tests/playtest/playtest_ilk_saat.gd`
  en az 10 PNG yazar; günlükte `SCRIPT ERROR` yok.
- **Commit:** `Oyun testi: ilk saat sahne turu, sürücüde geri dönüş (IP-008)`

## IP-003 Karşılaşma türü dönüşümü · KARAR-BEKLİYOR K-04

- **Kimlik:** IP-003 · S · sütun: Yol yaşar · bağımlılık: K-04 = evet
- **Amaç:** Garantili karşılaşma son üç seferde görülen türü geri sıraya atsın. Sıklık değişmez.
- **Oku:** `grep -n "guaranteed\|en az bir" scripts/events/road_director.gd scripts/travel/journey_controller.gd | head` ·
  görülmemişi kayıran çekiliş: `grep -n "unseen\|gorulmemis" scripts/events/event_engine.gd | head`
- **Adımlar:** `GameSession`'a `recent_encounter_kinds: Array[String]` (en çok 3, kayda girer; `test_memory`'nin alan
  listesine ekle). Garantili çekilişte adaylar arasında bu listede olmayan varsa yalnız onlardan çek. Sınama: üç
  seferde aynı tür üst üste gelmez (en az iki tür uygunsa).
- **Yapma:** Karşılaşma olasılığını, düşman gücünü değiştirme.
- **Doğrula:** `tools/test_ozet.sh` → `0 başarısız`; P2 tohum 101'de pusunun payı %20'den küçük.
- **Commit:** `Yol: garantili karşılaşmada tür dönüşümü (IP-003)`

## IP-006 Kervan avlusunda sıradaki adım · KARAR-BEKLİYOR K-03

- **Kimlik:** IP-006 · M · sütun: Defter unutmaz · Ticaret bilgi oyunudur · bağımlılık: K-03
- **Amaç:** Büyümenin ara basamağı (eşek, yarım vagon, vagon) fiyatıyla ve "kesende ne kadarı var" ile tek satırda görünsün.
- **Oku:** `grep -n "eşek\|donkey\|half_wagon" scripts/ui/caravan_yard*.gd scripts/autoload/game_session.gd | head -12`
- **Adımlar:** Avlunun başına bir satır: en ucuz alınamayan basamak, fiyatı, kesenin yüzdesi.
  `ui.csv`: `"UI_YARD_NEXT_STEP","Sıradaki: %s, %d GG. Kesen bunun %d'de %d'i.","Next: %s, %d GP. Your purse covers %d in %d of it.",…`
  Hesap: `yüzde = clampi(kese * 100 / fiyat, 0, 100)`; metne `[ad, fiyat, 100, yüzde]` ver. İlk kârlı varışta deftere:
  `"LEDGER_FIRST_PROFIT","İlk kârlı varış: %s, %d GG.","First arrival in profit: %s, %d GP.",…`
- **Yapma:** Fiyat değiştirme (K-03 "fiyat ölçümü" derse ayrı kart yazılır).
- **Doğrula:** `tools/test_ozet.sh` → `0 başarısız`; avlu ekran aracıyla görüntü.
- **Commit:** `Avlu: sıradaki adım satırı, ilk kâr deftere (IP-006)`

## IP-013 Borcun yüzü · KARAR-BEKLİYOR K-05

- **Kimlik:** IP-013 · S · sütun: İnsanlar aşınır · bağımlılık: K-05
- **Amaç:** 1006 borçla moral 100 kalmasın diye değil; borcun bir yüzü olduğu görülsün diye.
- **Oku:** `grep -n "evt_creditor_rider\|evt_bailiffs_at_camp" scripts/events/event_catalog.gd` (kurucular) ·
  `grep -n "debt_overdue" scripts/autoload/game_session.gd`
- **Adımlar:** Bağlama `debt_total` ekle. `evt_creditor_rider`'a ağırlık değiştirici: borç ≥ 300 ise ×2, ≥ 600 ise ×3
  (K-05 "yalnız kart"). Vadesi geçmiş borçla şehre girişte şehir özetine tefecinin tek cümlesi:
  `"UI_BRIEF_LENDER_WAITS","%s kapıda bekletmiş: \"Defter açık duruyor.\"","%s left word at the gate: \"The ledger stays open.\"",…`
- **Yapma:** Faiz, vade, ceza sayılarını değiştirme. K-05 "ikisi" derse lider stresi için ayrı kart yazılır.
- **Doğrula:** `tools/test_ozet.sh` → `0 başarısız`; P3b tohum 101'de `kart_gorulme.evt_creditor_rider` ≥ 2.
- **Commit:** `Borç: alacaklı borçla sıklaşır, tefeci kapıda söz bırakır (IP-013)`

## IP-014 Yeniden ölçüm ve rapor

- **Kimlik:** IP-014 · S · bağımlılık: öncekilerin hepsi (KARAR-BEKLİYOR olanlar hariç tutulabilir)
- **Adımlar:** 15 koşuyu yeniden koştur (`ALTYAPI.md`'deki komut, beş profil × tohum 101, 202, 303, `--saat 4`),
  `python3 tools/playtest_toplam.py > build/playtest/toplam.txt`. `docs/playtest/<tarih>/02_retention.md` adıyla
  yalnız iki tabloyu (ilkler, tempo) ve `06_is_plani.md` S-01…S-07 satırlarının "bugün" sütununu yeni sayılarla yaz.
- **Yapma:** Yorum yazma; yalnız sayı. Hedefi tutmayan satırı kalın yaz.
- **Commit:** `Oyun testi: Dalga 1 sonrası yeniden ölçüm (IP-014)`
