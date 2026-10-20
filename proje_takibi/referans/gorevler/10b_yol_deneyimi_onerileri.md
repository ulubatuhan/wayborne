# §10b. Ek öneri: yol sahnesinin "neden oynanır?" paketi

> Bu dosya `../YAPILACAKLAR.md` dizininin bir bölümü. Görev kimlikleri (ör. **8.2**, **12.2c**, **R0**) ve § başvuruları dizindekiyle aynı. Kurallar: `00_kurallar.md`. Başlamadan önce: `../00_BASLA_BURADAN.md`.

**Durum (2026-10-17, yönetmen seçimleri):** R0 ve R1 onaylandı (**Y-B01**, **Y-C17**). R2–R4'ün bazı maddeleri Y kimlikleriyle onaylandı: #7 = **Y-B08**, #5 ve #8 = **Y-B11**, #9 = **Y-B03**, #17 ↔ **Y-B02**, #15 = **Y-C20**, #14 ↔ **Y-I02**. Geri kalan maddeler öneri. Hiçbiri koda geçmedi. Sıra: `../YAPILACAKLAR.md` P08.
**Tam belge:** `../belgeler/YOL_DENEYIMI_ONERILERI.md` (teknik tasarım, veri yapıları, dosya bağlantıları, testler, boyutlar).

**Sorun:** Yolda oyuncunun tek işi kervanı yürütmek gibi hissettiriyor. Kararlar var (tempo, dikkat bölgesi, kamp, sofra) ama duygusal karşılıkları zayıf: yoldaşlar sayıya indirgenmiş, yol hafızasız, merak edilecek soru yok.

**Yaklaşım:** Yeni sistem icat etmeden, var olan sistemleri (ledger, grievance, rapport, arazi tohumu, olay motoru, işaretler) yolda **görünür** yapmak. Akademik dayanak: SDT (ilişkililik), bilgi boşluğu merakı, anlatı mimarisi, Lazzaro'nun dört anahtarı, MDA.

**Elenen fikirler (kullanıcı kararı):** #18 hayalet kervanlar, #20 yaşlanan lider. Belgede yok.

### Faz planı (ayrıntı belgede §8)
- [ ] **R0 Altyapı:** figür→karakter eşlemesi, `RoadBalloon`, `RoadChatter`, `backstory_id` ve `rapport`, yeni ledger türleri, `GameSession` alanları, yeni `EventEffect` türleri. Ön koşul: `RoadSignals` kaydı eksik (bkz. belge §10 madde 3).
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `8d435e1`): Figür-kişi eşlemesi, RoadBalloon, RoadChatter, backstory/rapport, beş yeni defter türü; test TEST_PLANI.md'de.
- [ ] **R1 İnsanlar:** #1 yanına yürü ve konuş, #3 kamp ateşi hikâyesi, #2 bağlar ve yan yana yürüme, #4 yoldaşların görünür özerk eylemleri.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `dd0d737`): 15 hikâye (5 geçmiş x 3 bölüm) tr/en; test TEST_PLANI.md'de.
- [ ] **R2 Hafıza:** #5 ölüler yolda kalır (mezarlar), #7 günün cümlesi, #6 dönüm taşı, #8 yol enkazları, #19 yol seni hatırlar.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `a31c52c`): #7 günün cümlesi (Y-B08) kullanıcı kararı bekliyor (serbest metin mi); test TEST_PLANI.md'de.
- [ ] **R3 Merak ve töre:** #12 kervan töresi, #17 anlatıcı ("yolun ruhu"), #9 belirsiz işaretler, #10 yol notları, #22 tepeye çık (vista).
- [ ] **R4 Risk:** #15 gece yürüyüşü, #16 nehir geçidi.
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `4d5f4ed`): #15 gece yürüyüşü Y-C20'de; #16 v1 kart ve günlük (görsel v2: vagonlar suya girer, sonraki tur); test TEST_PLANI.md'de.
- [ ] **R5 Büyük sahneler:** #21 kervan mahkemesi, #13 sancak, #14 yol şarkısı (ses varlığına bağlı), #11 çatallar (en riskli).

**Önerilen ilk dilim:** R0 + #1 (baloncuk ve rapport) + #5 (prosedürel mezar). Yolda hem **kişi** hem **hafıza** görünür olur.

**Bu bölümle ilişkili mevcut maddeler:** §9.10 (kervan enkazı eşyası, biyom arka planları), §9.11 ("Düşenler" sayfası, mezar işaretleri), §9.9 (yol HUD'u; yeni düğmeler buraya oturacak), §5 (performans; yeni UI "değer değişince" kalıbını izlemeli).

**Kullanıcıya sorulacaklar (belge §10):**
1. Günün cümlesinde serbest metin açılsın mı, yalnızca hazır cümleler mi?
2. Sancak ve yol şarkısı için ücretli görsel/ses üretimi olacak mı? (Önce maliyet çıkarılıp onaya sunulur.)
3. Anlatıcı profili oyun başında kilitli mi, oyun içinde değiştirilebilir mi?
4. Kamp hikâyeleri için ayrı bir yazım akışı kurulacak mı (~15 hikâye)?
5. Mahkeme v1 (kart) ile mi başlanacak?

## Doğrulama ve düzeltmeler (2026-10-17, kod karşılaştırması)

Belgedeki kod başvuruları `main` üzerinde `git grep` ile kontrol edildi. Satır numaralarının ve sınıf adlarının büyük çoğunluğu doğru. **Uygulamadan önce aşağıdakiler belgeye işlenmeli ya da uygulama sırasında dikkate alınmalı:**

| Belgede | İddia | Gerçek | Yapılacak |
|---|---|---|---|
| §4.5, §10 madde 8 | Ledger yükleme yolu `from_array`, yeni alanlar sorunsuz | Gerçek ad `load_from_array` (`caravan_ledger.gd:151`); yedi alanı tek tek kopyalıyor. `text`/`extra` yüklemede **sessizce düşer**. | R0'a "`load_from_array` genişletilmeli" ekle. |
| #3 | `engine.fire(event_id)` | Böyle bir fonksiyon yok. `triggered_only` olaylar `unlock_event()` ile açılıp günlük çekilişe giriyor (`event_engine.gd:56`, `:67`). | Yeni API diye işaretle ya da `unlock_event` + `draw_event` kullan. |
| #5 | `evt_grave_visit` yeni olay | Mezar zinciri zaten var: `evt_grave_on_the_road`, `evt_grave_keeper`, `evt_grave_offering` (`event_catalog.gd:1823+`), bayraklar `grave_seen`/`grave_tended`. | #5 bu zinciri genişletsin, ikinci bir mezar olayı yazılmasın. |
| #4 | Ayrılma yeni yol | Grievance'a bağlı ayrılma var: `resolve_stress_breaks`, `GRIEVANCE_DEPARTURE_PER_POINT` (`game_session.gd:1262-1300`). | Mevcut mekaniği temel al. "Son üye ayrılamaz" kuralı yeni kod. |
| #21 v1 | Suçlama kartı yeni | `evt_party_investigation` (`event_catalog.gd:1355`) zaten bir suçlama olayı. | v1 bunun üzerine kurulsun. |
| §6.2 `PERSON_STRESS` | Kişiye hedefleme yolu yok | `PARTY_HP`, `text_value` ve `_pick_party_target` ile hedef seçiyor. | Aynı seçici kullanılsın; belirli bir kişi (anlatıcı) için yeni seçici. |
| §4.6, §7.1 | Test "listesine eklenir" | `test_memory.gd:181` alanları kendisi geziyor; listede yalnız `TRANSIENT_FIELDS` var. | İfade: "kalıcı alanlar kendiliğinden yakalanır". CharacterData kapsamı **doğrulanmalı**. |
| §4.3 / §4.4 | `last_topic` / `last_chat_topic` | Belge kendi içinde tutarsız. | Tek ad seç. |
| #5 örnek | `LEDGER_CAUSE_WOLVES` | Yok. Gerçek anahtar: `LEDGER_CAUSE_COMBAT_WILDLIFE` (`ui.csv:641`). | Düzelt. |
| #19 | `market_pricing` fonksiyonu | Dosya: `scripts/economy/market_pricing.gd`. Kültür çarpanı `game_session.gd:1674`. | Düzelt. |
| §10 madde 1 | `RouteTerrain.build(route_key)` | Gerçek imza `build(key, days)`, anahtar yönsüz (`route_conditions.gd:48`). | Düzelt. Anıtların iki yönde aynı yerde çıkması **doğrulanmalı**. |
| Özet | "var olan … rapport" | `rapport` kodda yok, yeni alan. | Özette düzeltildi (aşağıdaki not). |

**Not:** `rapport` kodda henüz yok, R0'da eklenecek yeni bir alan. Yukarıdaki "Yaklaşım" paragrafındaki listede yanlışlıkla var olan sistemler arasında sayılıyor.

**Kural notları:**
- **Road Screen Layout Rules:** "Kararlar ekranın ortasında tek bir kartta" kuralı var. #1 v2'deki baloncuk içi "Dinle/Geç" düğmeleri bu kuralla çelişebilir; düğmeler HUD alt şeridine alınabilir. **Doğrulanmalı.**
- **Töre maliyetleri:** "Gömeriz" (+1 saat) ve "Beklenir" (tempo ×0.95) töre seçilince zorunlu hâle geliyor. Planlayıcı sözüyle ölçülmeli.
- **Ad:** `ADD_MEMORIAL` içinde "referans oyun" harf dizisi geçiyor. Kural kısaltmayı hedefliyor, yine de düz metin taramasına takılmaması için `RAISE_MEMORIAL` gibi bir ad daha güvenli.

**Çapraz bağlantılar** (bu öneriler aşağıdaki görevlerden sonra gelmeli ya da onlarla birlikte yapılmalı):

| Bağlantı | Neden |
|---|---|
| **§11.1** (`RoadSignals` kaydı) | R0'ın ön koşulu. Belgedeki "§10 madde 3" ve "KOD_DENETIMI'ne eklenecek" notları bu göreve işaret ediyor. |
| **§12.2b, §12.2d, §12.2e** | #5, #6 ve #8'in anıt ve enkazları `_draw_stops` desenini kullanıyor; kule kayması hatası onlara da geçer. "Ahşap direk", kervan bandındaki boş bant kuralıyla çakışır. #5'ten önce 12.2b ve 12.2d bitmeli. |
| **§12.2c** (kamp toplanma ve `CAMP_HOURS`) | #3 (`_camp_ends_at_hours - 5` tetiği), #21 ve #14 kamp akışına bağlı. Önce 12.2c. |
| **§8.10–8.11, §12.2e adım 7** (gece ve fener ışık dili) | #15 gece yürüyüşünün feneri bu dile uymalı. |
| **§10.1–10.3** (binici, arabacı, vagon) | #13 sancak `KIND_MOUNTED` ve `ArtDraw.wagon` üstüne biniyor. Önce §10. |
| **§12.2a** (şehir kapısı ve varış) | #13'teki "kervan geliyor" satırı varış akışında. |
| **§8.1–8.4** (yeni harita ve kimlik eşlemesi) | #5 ve #6'nın `world_map.gd` işaretleri yeni karo haritaya taşınmalı. #5 ve #19'un `route_key` ile sakladığı veri, yer kimliği eşlemesinde göç ister. |
| **§1.1** (mezra adı değişimi) | #11 ve #16'nın yeni durak türleri aynı `_pick_stop` tablosuna dokunuyor. Önce §1.1. |

**Sonuç:** Öneriler doğru yerde. §10b ayrı bir öneri paketi olarak kalmalı; yürütme sırası §11.1, §10 ve §12.2'den sonra gelmeli.
