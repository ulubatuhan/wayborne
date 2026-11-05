# Bölüm 18 — Oyuncu profilleri ve keyif ölçümü (kullanıcı isteği 2026-11-05)

Rapor `docs/design_notes/oyuncu_profilleri.md`. Araç `tests/simulate_personas.gd`
(iz kipi `--iz <profil>`, ablasyon kipi `--ablasyon`), ekran doğrulaması
`tests/screenshot_persona_gate.gd`.

- [x] **PR01 Akademik zemin ve beş profil**
  - Quantic Foundry 12 güdü / 6 küme, ÖBK-PENS (Ryan, Rigby, Przybylski 2006; Johnson ve ark. 2018'in kısmi
    doğrulaması), BrainHex/Bartle eleştirisi (Tondello ve ark.: yedi arketip veriye bakınca üçe iniyor),
    prosedürel persona (Holmgård ve ark.), gelişen persona (Ariyurek ve ark.).
  - **Tip iddiası yok:** beş profil bir sınıflandırma değil, Wayborne'un karar noktalarına göre seçilmiş
    fayda fonksiyonları. Her kaynağın sınırı raporda yazılı.
  - Profiller: Tüccar, Hikâyeci, Hayatta Kalan, Tamamlayıcı, Merhametli.

- [x] **PR02 Persona oynatıcısı**
  - Her profil gerçek kapılardan geçiyor: pazarın hazinesi ve geri satış tavanı, erzak rafı (P5),
    sofra dağıtımı (`apply_meal_distribution`), olay kartının açık seçenekleri.
  - **Özerklik gözlemlenebilir hâle getirildi:** kartta gerçekten açık olan seçenek sayısı ve tek seçenekli
    kart oranı. PENS'in anketle sorduğu şeyin ölçülebilir karşılığı.
  - Üç araç hatası rapora girmeden yakalandı (elle besleme, "aç gün"ün aslında bir karar olması, ölen
    kervanın koşmaya devam etmesi); üçü de dosyanın yorumlarında kayıtlı.

- [x] **PR03 Ölçüm: 5 profil × 3 koşu × 24 sefer**
  - **Yalnız Tüccar yirmi dört seferi bitiriyor.** Hikâyeci ve Merhametli üçüncü seferde, Tamamlayıcı
    dokuzuncu, Hayatta Kalan onuncu civarında ölüyor.
  - Gelişen persona yalnız hayatta kalabilen profillerde ölçülebiliyor: Tamamlayıcı'nın keyfi 17.9 → 38.8,
    ölümü 2.7 → 1.7. Üçüncü seferde ölenin gelişecek zamanı yok.

- [x] **PR04 Ablasyon çalışması (kendi üretimimiz)**
  - Hikâyeci'nin üç davranışı tek tek çevrildi: **tayfayı beslemek tek başına dayanıklılığı 3 → 11.2 sefer
    değiştiriyor.** Planlayıcıyı okumak hiçbir şey değiştirmiyor (hiçbir yol yetmiyorsa ceza eşit biniyor),
    pazarlık da (P1'in %15 tavanı zordaki oyuncuya bir şey vermiyor - bedelin ölçülmüş hâli).

- [x] **PR05 Ekran doğrulaması (Y-K01)**
  - **Beklenti yanlış çıktı: planlayıcı açıkça uyarıyor** (gerekli/eksik erzak, "Bu şehirde yalnız 69 erzak
    var", "Kervan bu yolda 31 gün aç kalır", "yine de yola çık" düğmesi).
  - Eksik olan uyarı değil **bedelin ölçeği**: "moral düşer, stres birikir" atlatılabilir okunuyor, oysa aynı
    karar kervanı üç seferde bitiriyor.

- [x] **PR06 Öneriler uygulandı ve yeniden ölçüldü**
  - Yedisi de yapıldı (Ö6 hariç: Ö1'in güçlenen uyarısı aynı işi planlayıcıda yapıyor, haritaya ikinci
    gösterge ölçümle desteklenmedi).
  - **Sonuç, aynı tohumlarla:** Hayatta Kalan 18.7 → **24.0 sefer** ve üç koşunun üçünde ölmekten
    hiçbirinde ölmemeye geçti (keyif 0 → 29.9); Merhametli 3.0 → **9.7**; Tamamlayıcı (gelişen)
    11.0 → **16.7**, keyif 38.8 → **53.7**. Tüccar neredeyse değişmedi (53.3 → 55.3) ve gündelik işi
    koşu başına yalnız 1.3 gün kullandı - can simidi zordakine açık, güçlüye bedava kazanç değil.
  - **Hikâyeci hâlâ ölüyor** (5.0 sefer, 3/3) ve keyfi düştü (18.5 → 8.8): daha uzun yaşayınca daha çok
    aç gün görüyor. Dürüst sonuç: ertelendi, çözülmedi. Çözümü kıtlık kipine dokunuyor (affedici rota
    ya da sınırlı ilk sefer), **kullanıcı kararı bekliyor**.
  - Ekran doğrulaması üç kusur daha yakaladı: gündelik iş düğmesi tam gerektiği anda gizliydi
    (engel bugünkü depoyu soruyordu, oysa ihtiyacı sefer belirler); düğme `_plan` kurulmadan
    tazeleniyordu; ve eklenen satırlar "yola çık" düğmesini kaydırmanın altına itti.
  - Kabul: `tests/test_persona_fixes.gd` (6 test), `tests/screenshot_persona_gate.gd`.

- [ ] **PR07 Hikâyeci için karar (kullanıcı)**
  - Ö1 uyarının şiddeti ölümü adıyla ansın (S) · Ö2 sofra kipi planlayıcıda görünsün, günlük maliyetiyle (M)
    · Ö3 zordaki oyuncuya gündelik iş: zaman öder, para değil (M) · Ö4 Tamamlayıcı'ya sayaçlar (S)
    · Ö5 ölümden sonra son üç karar gösterilsin (S) · Ö6 ilk seferde erzağın yettiği yollar işaretlensin (S)
    · Ö7 Tüccar'a ad ile ödül: bölgesel itibar eşiği deftere yazılsın (M).
  - Hiçbiri sistem kesmiyor; Ö3 pazarlığı geri büyütmeyi **önermiyor** (para basma noktası oydu).

## İkinci tur: altı profil, oyun günlüğü (2026-11-05)

Rapor: `docs/design_notes/oyuncu_gunlukleri.md` · Günlükler: `docs/design_notes/oyuncu_gunlukleri/*.md`
Araç: `tests/simulate_player_diaries.gd` · Ekran: `tests/screenshot_diary_fixes.gd`
Kilitler: `tests/test_persona_fixes.gd` (12 test, 32 055 geçti)

- [x] **PR08 Altı profil + günlük aracı**
  - Kâğıt Üstünde Tüccar · Defter Tutan · Ucunda Yürüyen · Listeyi Kapatan · Bedeli Soran ·
    **Vagonu Kuran** (yeni). Her profil `keyif_yerleri` listesiyle geliyor ve şehrin tüm fiillerini
    deniyor (taverna, şölen, pano, avans, pazar, takas, atölye, kilise, hekim, işe alma, kişi işleri,
    dövüş, kamp, yolda arama).
  - Günlük üç tür satır tutuyor: `istedim` (oyunun kendi sebep yazısıyla) · `keyif` · `anladım`.
    Toplam 808 keyif, 1022 istedim, 103 anladım.

- [x] **PR09 Ölçüm aracının üç yalanı yakalandı**
  - Savaş simülatörde hiç çözülmüyordu (`TRIGGER_COMBAT` yalnız `road_journey.gd`'de): "sıfır ölüm"
    sahteydi. `simulate_journeys.gd`'nin headless politikası taşındı.
  - "148 kez sebep yazmıyor" benim uydurduğum cümleydi; kilitli seçenek sebebini zaten söylüyor.
    Gerçek bulgu: **102 kez "Yeterli altının yok"** - yolda kapalı seçeneklerin birinci sebebi yoksulluk.
  - "Sıfır aç gün" yalnız adı olan partiyi sayıyordu; `crew_hungry` ayrı ve 60-98 gün doğru.

- [x] **PR10 Yedi kusur düzeltildi (hepsi testli, görünenler ekranda doğrulandı)**
  - K1 `TRAVEL_DAYS` kat edilen yolu siliyordu (`get_days_travelled()` sıfıra kırpılıyordu) →
    `GameSession.extend_journey()`.
  - K2 arama yalnız en iyi sezgiye bakıyordu, el sayısına değil → `FORAGE_PER_EXTRA_HAND`.
  - K3 konaklama, şölen ve bağış sebep söylemeden ölüyordu → üç yeni `*_block_reason`.
  - K4 teslimat kaç tane eksik olduğunu söylemiyordu → `get_chain_missing_text`.
  - K5 emirler paneli kadro listesinin üstüne biniyordu → `_default_orders_position` tavanı düzeltildi.
  - K6 yolda yiyecek arama emri (önceki turdan) · K7 soy bilgiyi taşıyor (önceki turdan).

- [ ] **PR11 Baş bulgu: oyunun ortası yok (kullanıcı kararı)**
  - Dört profil 20/20 sefer **sıfır ölümle**; iki profil **iki koşunun ikisinde de** 5-6,5 seferde bitti.
    Arada bant yok. Ayıran şey beceri değil, tek bir başlangıç kararı: sofra herkese mi açık.
  - Sebebi aritmetik: **ticaret dışında günlük tüketimi aşan tek bir gelir yok.** Gündelik iş net
    +0,4 gün, arama ≈0, dövüş küçük ve yarısı kaybediliyor. Sermayesi olmayan oyuncu için ayakta
    kalmanın matematiksel yolu yok.
  - Kullanıcının istediği bant ("çaba göstererek az ölümle devam etmek") bu yüzden yok.

- [ ] **PR12 Öneriler (G1-G8), uygulanmadı**
  - G1 ticaret dışı gelir: kervanı ücretle yük taşımaya vermek (M, **kullanıcı kararı**) · G2 isimsiz
    ekibin açlığı deftere geçsin (M, **kullanıcı kararı**) · G3 atölye girdileri pazarda görünsün (S)
    · G4 kişilerin istekleri pazara/deftere taşınsın (S) · G5 kaybedilen dövüşün bedeli olsun (M)
    · G6 vagon büyümesinin görünür bedeli olsun (M) · G7 avans eşiğini yazsın (S) · G8 pano ilanının
    neden alınamadığını yazsın (S).
  - Hiçbiri sistem kesmiyor; G1 ticareti küçültmüyor, yoksulluğa taban koyuyor.
