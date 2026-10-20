# §10. Yol ekranı: binici, arabacı ve koşum düzeltmeleri (kullanıcı, 2026-10-17)

> Bu dosya `../YAPILACAKLAR.md` dizininin bir bölümü. Görev kimlikleri (ör. **8.2**, **12.2c**, **R0**) ve § başvuruları dizindekiyle aynı. Kurallar: `00_kurallar.md`. Başlamadan önce: `../00_BASLA_BURADAN.md`.

Her madde düzeltildikten sonra yol ekranının ekran görüntüsü alınıp kullanıcıya gösterilmeli: yürürken, kampta ve dönüşte.

- [ ] **10.1 Binici atın biraz fazla önünde oturuyor, çok az geriye alınmalı.**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `ba76d99`): Binici at boyunun %5'i geride; iniş noktası aynı.
  - **Yer:** `scripts/ui/walk_figure.gd:460-470` (`KIND_MOUNTED`).
    - Atın sırt y'si `_draw_quadruped()` içinden geliyor.
    - Biniciyi çizen `_draw_person(height * MOUNT_RIDER_RATIO, back_y, true)` ise yatayda figürün ortasında (`origin.x = size.x * 0.5`, `:578`) duruyor.
  - **Çözüm:** Atın eğer noktasına (sırtın orta-arka kısmı) göre küçük bir geri kaydırma ekle, örneğin `MOUNT_SEAT_BACK_RATIO`.
    - Gidiş yönüne göre işareti değişmeli: sola giderken sağa, sağa giderken sola.
    - At dönüşte aynalanıyorsa binici de aynalanmalı.
  - **Test:** Eğer noktası ile kalça arasındaki mesafe için `tests/` altına bir kontrol.
- [ ] **10.2 At üstündeki binici yürür gibi kol sallamaya devam ediyor.**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `ba76d99`): Oturan figürde kol salınımı yok; ride klibi dinlenme karesinde.
  - **Yer:** `walk_figure.gd:256-276` (`pick_clip`). `seated` olduğunda yalnız `available.has("ride")` ise `ride` klibi seçiliyor; yoksa `walk` klibine düşüyor ve kollar sallanıyor.
  - **Olası sebep:** `shared_clips(frames, garments)` biniciyle birlikte giyilen kıyafetlerin kesişimini alıyor. Giyilen kıyafetlerden birinin frame setinde `ride` klibi yoksa ortak listeden düşüyor.
  - **Çözüm:**
    1. Hangi kıyafet ve beden setlerinde `ride` eksik, tara (`data/assets/characters/frames/*/frames.tres` içindeki `clip_names`).
    2. Eksik setleri `ride` ile yeniden render et (figür hattı: `tools/figure_pipeline/`).
    3. Kod tarafında `seated` iken asla `walk` seçilmesin; `ride` yoksa sabit bir oturma karesine düşülsün.
  - **Test:** `seated=true` için `pick_clip` hiçbir giysi kombinasyonunda `walk*` dönmemeli.
- [x] **10.3 Vagon sürücüsü hâlâ eski manken modeliyle çiziliyor; yeni mankenlerden olmalı.**
  - **Yapıldı** (`yerel/yapilacaklar-p05-p06`, commit `19555b5`): N27 ile kapandı: koltukta gerçek sürücü figürü.
  - **Yer:** `scripts/ui/art_draw.gd:471` (`wagon_driver_seat`). Arabacı `:541-542` ve `:579` civarında silüet olarak vagonla birlikte çiziliyor (`draw_driver`).
  - **Çözüm:** Arabacıyı vagon çiziminden çıkar. Koltukta oturan gerçek bir `WalkFigure` olarak çiz:
    - yeni manken frame'leri (`BodyFrames`), atanmış tayfa üyesinin beden ve kıyafetiyle,
    - `seated=true` ve `ride` ya da `sit` klibiyle.
  - **Kolaylık:** Kampta figürün koltuktan kalkıp ateşe yürümesi zaten `road_caravan.gd:851` (`_driver_bench_position`) ile aynı noktayı kullanıyor. Geçiş doğal olur.
  - `draw_driver=false` yolu zaten var.
- [ ] **10.4 Vagonu çeken hayvanlar vagona bağlı görünmüyor.**
  - **Yapıldı, test bekliyor** (`yerel/yapilacaklar-p05-p06`, commit `ba76d99`): Ok öküzün boynuna uzanıyor, boyunduruk üst katmanda.
  - **Yer:**
    - `scripts/ui/road_caravan.gd:1352-1373`: `HITCH_GAP`, "Öküzle vagonun arasına hiçbir şey girmez, orası koşum yeri".
    - `:249-263`: öküz ölçüsü ve `CART_HITCH_M = WagonFigure.CART_HITCH_M`.
    - `scripts/ui/wagon_figure.gd`
  - **Çözüm:** Hayvanla vagon arasına görünür koşum çiz:
    - vagondan hayvanın göğsüne uzanan ok (dingil),
    - öküzde boyunduruk, atta ve eşekte göğüslük ile kayış.
  - **Hizalama:** Kayış uçları hayvanın omuz eklemine ve vagonun ön dingiline bağlanmalı, rig eklemlerinden okunarak (`BeastRig`, `shoulder_px`). Böylece yürüyüşte, dönüşte ve eğimde kopmaz.
  - **Not:** Dönüşte (`_wagon_turn`) hayvan ile vagonun ayrı aynalandığı yerler kontrol edilmeli.
