# Zindanlar: tam sürüm (Y-A07)

Durum (2026-11-14): **oyunda, seviye seviye harita ve bölge resimleriyle.** Kullanıcı kararları: (1) "maksimum oyuncu
keyfi"; (2) kervan beklerken olay gelir; (3) ilk ağızlar Karaocak galerilerinin yüzeye yakın uçları, maden civarında;
(4) 2026-11-14: "zindanlar için bir map oluştur seviye seviye", arka plan seviyeye ve ağza göre, "placeholder değil
gerçekçi", girişler mağara gibi, sonra kadim ve işlenmiş galeri.

Lore: SIDERIA §11.7 (ağızlar, kör hava, kör dişler, yağmacılar, töre; "İçeriden": her ağzın üç bölgesi; madenci
krokisi = harita).

**Harita (`DungeonMap`).** Ağzın her seviyesi sütunlara dizili, koridorlarla bağlı 4-8 oda: giriş (ilk seviyede ağız,
sonra merdiven dibi), ortada geçit / savaş / hazine / dinlenme / kalıntı odaları, sonda iniş ya da (son seviyede) ağzın
kendi son odası. Her seviyede bir hazine, ikinciden sonra bir savaş ve en çok bir dinlenme; dördüncüden sonra iki
savaş. Oda kartı girilince açılır ve bir kez yaşanır; kartlar türe ve derinlik katmanına göre (`POOLS`). Vardığın
odanın komşuları görünür olur, görmediğin oda soru işaretidir. Harita ağzın kimliğinden ve girişin sırasından türer,
kayıtta durur (`dungeon_run.map`); haritadan önceki kayıtlar o seviyenin girişinden haritaya döner.

**Koridorun bedeli.** Her koridor ışık yer (yanan meşale 3 koridor; fener yanmaz), iki koridor bir gün (kervan bekler,
erzak yer), ışıkla 1, karanlıkta 5 stres; koridorda pusu %6, karanlıkta %22 (kör dişler, tehlike 45). İniş 3/7 stres.
Çıkış her odadan (çıkış kartı: töreyle pay, paysız, vazgeç); derinden dönüş seviye başına yarım gün. Hepsi olay dilinde
(`DUNGEON_MOVE`, `DUNGEON_DEEPER`, `STRESS`, `TRAVEL_DAYS`, `TRIGGER_COMBAT`) ve kartlarla aynı çözümden geçer.

**Ekran.** Galerideyken yolun yerine `DungeonView`: seviyenin bölge resmi ve önünde kadro (savaş figürleri). Altta
`DungeonMapPanel` (madenci krokisi gibi tebeşir çizgisi: oda simgeleri çizilir, `DungeonMapView`), ışık, sırt yükü,
"aşağı in", "çıkışa yönel". Oda kartının resmi ve savaşın arka planı da aynı bölge resmi.

**Bölge resimleri.** 3 ağız x 3 bölge (`agiz`, `gecis`, `galeri`; `DungeonCatalog.DUNGEONS[...].zones`), Blender
Cycles, `tools/dungeon/build_dungeon.py` (`fetch_assets.py` Poly Haven CC0 dokularını ve modellerini indirir; fresk
`fresco.py`). Yandan görünüş, duvar dibi ~%46, ayak çizgisi ~%59; tek sıcak kaynak kadronun meşalesi, gün ışığı soğuk,
dokular solgun. Kadim taş geometriden: harçsız iri bloklar, kıl derzler (dokunun kendi tuğla deseni iri blokta küçük
tuğla gibi okunduğu için kullanılmadı).

Kod: `DungeonCatalog`, `DungeonMap`, `GameSession.dungeon_*`, `DUNGEON_*` etkileri, 18 kart, `EnemyCatalog.KIND_DEEP`.
Ağızda kaybedilen savaş inişi bitirir, yük yağmalanmaz. Test: test_dungeon; ekran: screenshot_dungeon (her ağzın her
bölgesinde harita, kart, savaş).

## Kullanıcı notu

"Sıra zindanlara gelecek fakat bende küçük sürüm diye bir şey yok, tam gaz devam."

## Sütun

Yol yaşar (rota dışı bir yer), İnsanlar aşınır (stres ve ölüm), Defter unutmaz (zindanda düşen deftere ve yola yazılır).

## 1. Giriş: zindan nasıl bulunur

- **Haritada yer.** `settlements.json`'a yeni bir tür: `ruin_dungeon` (harabe, maden ağzı, mezar höyüğü, batık kale).
  Bir yolun üstünde değil, bir yolun **yanında**: rota dışı sapma 1-3 gün. Harita ilk başta göstermez.
- **Söylenti.** Tavernada satılan bir söylenti (Y-C10 fiyat söylentisinin deseni, yanlış olabilir) zindanı haritaya
  "duyulmuş" olarak işler. Doğru olup olmadığı gidince anlaşılır.
- **Olay.** Yolda bir kart (ör. "dağda bir ağız", "kaçan bir çoban") zindanı açar. `CHAIN_ADVANCE` ile söylenti
  zinciri başka bir şehre bağlanabilir.
- Haritada keşfedilmiş zindan bir işaretle durur (`map_lights` deseni), yolda sapma noktası bir durak
  (`RouteTerrain` stop: `STOP_DUNGEON`).

## 2. Yapı: oda değil aşama dizisi

- Bir zindan 4-7 **aşama**; her aşama bir kart ya da bir savaş. Harita yok, ızgara yok: oyunun dili kart ve savaş,
  yeni bir keşif sistemi icat edilmez (CLAUDE.md "no perk may invent a new system" ruhu).
- Aşama türleri: geçit (beceri kontrolü, başarısızlık can ya da stres), tuzak (Sezgi), savaş, hazine odası (ganimet),
  dinlenme (kısa kamp, tek sefer), derinlik kapısı (geri dönüş noktası).
- Her aşamadan sonra karar: **devam** ya da **çık**. Derinleştikçe ganimet ve tehlike artar (Oregon Trail'in "bir gün daha"
  gerilimi).
- Zindanın tohumu zindan kimliği + ilk giriş günü: yeniden yüklemek zarı değiştirmez; zindan durumu kayıtta.

## 3. Savaş

- Mevcut `CombatEncounter`. Yeni düşman ailesi: `KIND_DUNGEON` (yaratık şablonları lore'dan; büyücü kuralı geçerli:
  nadir ve istenmeyen). Dar geçit: en fazla 3 sıra (savaş alanı 4 sıra kalır, düşman sırası azalır).
- Işık: fener ya da meşale yoksa isabet cezası (Y-C20 ışık eşyaları burada da harcanır).

## 4. Ganimet

- `loot.json`'a `dungeon_<derinlik>` tabloları: nadir eski mühür, kıyafet, ekipman, `rare` mallar.
- Ganimet zindanda **taşınır**: yük sınırı kişisel çantalar (kervan dışarıda bekler). Fazlası bırakılır ya da sonraki
  girişe kalır.

## 5. Kayıp ve stres

- Zindan günü yol gününden pahalı: aşama başına stres, karanlıkta daha çok.
- Ölüm mevcut kapıdan (`resolve_deaths`), sebep `LEDGER_CAUSE_DUNGEON`; zindanın girişine mezar düşer (Y-B11).
- Geri çekilme (Y-C07) zindanda da var; kaçış zindandan çıkış demek.

## 6. Kervan dışarıda bekler

- Zindana yalnızca parti girer; kervan sapma noktasında kamp kurar. Bekleyen her gün erzak yer (planlayıcıya
  "zindan payı" satırı eklenir; söz bozulmasın).
- Bekleyen kervana olay gelebilir (bir kart: "kervana haydut yanaştı"); tayfa savaşmaz, kayıp yükten olur.
- Zindanda geçen her aşama saat yer; günler dönünce kervanın günlük işleyişi (erzak, kontrat vadeleri) işler.

## 7. Kayıt ve test

- `GameSession.dungeons`: kimlik -> {keşif durumu, derinlik, yağmalanan aşamalar, tohum}. Kayıtta.
- Testler: zar yeniden yüklemeyle değişmez; kervan payı planlayıcıda; çıkış her aşamada mümkün; ölüm defterde ve yolda.

## 8. Sanat ve ses (CC0)

- Yapılar: Quaternius Ultimate Modular Ruins, Modular Dungeon; Kenney Castle Kit. Mevcut render hattı (Prop Rules).
- Ses: OpenGameArt "Loopable Dungeon Ambience", "Dripping water loop" (indirmeden önce lisans sayfası).
- Dini sembol yok.

## Onay için sorular

1. Aşama dizisi (kart + savaş) yeterli mi, yoksa oda haritası mı istiyorsun?
2. Kervan dışarıda beklerken olay gelsin mi?
3. İlk zindan hangi bölgede (lore kapanınca)?
