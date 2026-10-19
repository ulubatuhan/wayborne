# Zindanlar: tam sürüm (Y-A07)

Durum: tasarım notu, kullanıcı onayı bekliyor. Kod henüz değişmedi. Adlar, yerler ve yaratıklar lore'a (Y-E06) bağlı;
aşağıda yer tutucu olarak geçiyor.

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
