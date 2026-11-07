# 15. Film ve kervan fikirleri (2026-10-31)

Kaynak: kullanıcının film listesi (The Road, The Way Back, The Seventh Seal, Mongol, Extraordinary Tales, Black Death) ve tarihteki kervan ve kervansaray araştırması. Fikir listesindeki 30 maddenin cevapları burada; filmler yalnızca his ve teknik kaynağı, lore ve oyun metnine adları girmez.

**Reddedilenler (yeniden önerilmez):** hayvanların kıtlıkta yoldan çekilmesi; karta göre değişen mürekkep dili; yerel rehber kiralamak ("buna para verecek imkânımız olmamalı hiç"); görev unvanları; vakıf finali. **Açıklaması yeniden yazılacak:** inanç mahkemesi kartı.

**Dil kuralı:** oyun metninde "han" denmez, kervansaray denir.

- [ ] **Y-G17 Tek sıcak kaynak: kural ve bütün sahnelerin denetimi**
  - **Onay turu (2026-10-31):** kısmen. Kullanıcı kararı: güneşin halesi de soğuk (akşam ve kış güneşi soğuktur).
  - **Durum (2026-10-31):** kısmen. Kural yazılı; denetim docs/ui/sicak_kaynak_denetimi.md (akşam şehir resimleri aykırı, render gerekir; güneş ışık kaynağı mı kararı kullanıcıda).
  - **Öncelik:** P1 · **Dalga:** 6 · **Bağımlı:** Y-C22 · **Kim:** CO
  - **Ne:** Dünyada sıcak renk yalnızca bir ışık kaynağından gelir: ateş, fener, meşale, pencere ışığı, defter sayfası. Kural `kurallar-sanat` Art Rules'a yazıldı. Kalan: yol, şehir, savaş, hub, kervansaray ve kart görsellerinin denetim listesi, aykırı olanların sırayla düzeltilmesi; her düzeltme ekran görüntüsüyle.
  - **Kullanıcı notu:** "Tek sıcak kaynak: Onay. Bunu gene kurallara yaz çünkü buna göre çok düzenleme gerekecek."
  - **Kabul:** Denetim listesi `docs/ui/` altında; her sahne için önce ve sonra görüntüsü.

- [ ] **Y-G18 Kıtlık paleti bölgeye göre: Gokyurt en geç solar**
  - **Öncelik:** P2 · **Dalga:** 6 · **Bağımlı:** Y-C21, Y-G17 · **Kim:** C
  - **Ne:** Kıtlığın derecesi bölge başına bir değer; palet o değere göre solar. Gokyurt hâlâ öbür yerlere göre daha sağlıklı, bu yüzden en geç solar. Bağlarla ilgisi yok.
  - **Kullanıcı notu:** "Hayır bağ ile ilgili bir şey olmamalı bu. Gokyurt hala diğer yerlere kıyasla daha sağlıklı bir yer o sebeple palet daha geç solabilir orada."
  - **Kabul:** Aynı saatte Gokyurt yolu ile Vadi yolunun görüntüsü yan yana; test bölge değerinin palete geçtiğini doğrular.

- [x] **Y-G19 Portreler baştan yorgun ve aşınmış**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı.
  - **Durum (2026-10-31):** test bekliyor. Yönergesi docs/el_cizimi/PORTRE_YONERGESI.md; ara çözüm bust_ink.gdshader weariness (soğuk ışık, soluk renk, derin gölge).
  - **Öncelik:** P2 · **Dalga:** 6 · **Bağımlı:** - · **Kim:** CO
  - **Ne:** Karakter portreleri bir duruma göre aşınmaz, baştan öyle çizilir: yorgun, aşınmış yüzler. El çizimi programının portre yönergesine (`docs/el_cizimi/`) girer; mevcut `BustPortrait` mürekkep gölgelendirmesi ara çözüm olarak aynı yöne çekilir.
  - **Kullanıcı notu:** "Karakter portreleri direkt bu şekilde çizilmeli, zaten aşınmış, yorgun olmalı."
  - **Kabul:** Yönerge yazıldı; mevcut portrelerin önce ve sonra görüntüsü onaylandı.

- [x] **Y-G20 Olay kartının görsel dili bölgeye göre**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı.
  - **Durum (2026-10-31):** test bekliyor. CardRegionLook: sekiz bölgenin göğü, tonu, örtüsü, çerçeve deseni; vebalı bölgede solma. Tablo: tests/screenshot_card_regions.gd.
  - **Öncelik:** P3 · **Dalga:** 6 · **Bağımlı:** - · **Kim:** CO
  - **Ne:** Kartın çizim dili kartın türüne göre değişmez, bölgeye göre değişir (Gokyurt, Vaelghard, Vadi, Ayazkaya...).
  - **Kullanıcı notu:** "Bölgeye göre farklılık olmalı, karta göre de farklılık olmasın."
  - **Kabul:** Üç bölgenin kart görünüşü yan yana onaylandı.

- [x] **Y-G21 Kart açılışında yavaş kayma**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı.
  - **Durum (2026-10-31):** test bekliyor. CardDrift: kart resmi açılırken yavaşça yaklaşıp kayar; Reduce Motion'da durur; ağaca girince başlar (CI düzeltmesi).
  - **Öncelik:** P3 · **Dalga:** 6 · **Bağımlı:** - · **Kim:** CO
  - **Ne:** Olay kartının resmi açılırken yavaşça kayar (paralaks); Reduce Motion açıkken kayma yok.
  - **Kullanıcı notu:** "Yavaş kayan kart açılışı: Onay."
  - **Kabul:** Hareket eğrisi duruştan başlayıp duruşta biter (`test_motion` kalıbı); görüntü onaylandı.

- [x] **Y-G22 Bataklık görünüşü: gri-yeşil sis**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı.
  - **Durum (2026-10-31):** test bekliyor. TravelBand._draw_marsh_mist: havadan bağımsız gri-yeşil perde, zemin örtüsü, alçak tutamlar; biyom geçişiyle açılır. screenshot_road_looks marsh satırı.
  - **Öncelik:** P3 · **Dalga:** 6 · **Bağımlı:** - · **Kim:** CO
  - **Ne:** Samuran ve Liraven çevresindeki yol kesimleri için çamurlu, sisli, gri-yeşil yol katmanları (`RoadStrips` görünüşü).
  - **Kullanıcı notu:** "Gri-yeşil sisli bataklık: Onay."
  - **Kabul:** `screenshot_road_looks` tablosunda bataklık görünüşü.

- [x] **Y-G23 Soy sonu: ufukta yürüyen adlar**
  - **Onay turu (2026-10-31):** iptal. Kullanıcı (onay turu): Red - kaldırıldı.
  - **Durum (2026-10-31):** test bekliyor. LineageProcession: bitiş panelinde ölenler ufukta yükleriyle yürür, adları üstü çizili. tests/screenshot_lineage_end.gd.
  - **Öncelik:** P3 · **Dalga:** 6 · **Bağımlı:** Y-D03 · **Kim:** CO
  - **Ne:** Soy bitince üstü çizili adların sahipleri ufukta siluet olarak yürür. Ortaçağın ölüm dansı geleneğinden; filmin karesinden değil.
  - **Kullanıcı notu:** "Soy sonu: ufukta adlar: Onay."
  - **Kabul:** Bitiş ekranının görüntüsü onaylandı.

- [ ] **Y-C25 Veba bir dünya hâli: kart açılmadan görünür**
  - **Onay turu (2026-10-31):** kısmen. Kullanıcı (onay turu): Düzenle - veba kendiliğinden gelip gitmez; arka planda nüfus, bulaşma ve şehirler arası ilişki sistemi kurulacak; nerede veba olduğu yolda ya da şehirde haber olarak öğrenilir.
  - **Durum (2026-10-31):** kısmen. İlk parça: WorldEvents.natural_plague bölge ve 18 günlük dönem; has_plague kriz, bulaşma, işe alma ve şehir özetinde. Kart görseli bölgeyle soluyor (Y-G20).
  - **Öncelik:** P1 · **Dalga:** 2 · **Bağımlı:** Y-C21 · **Kim:** C
  - **Ne:** Veba genel bir durum. Etkileri kart açılmadan görülür: şehrin görünüşü ve kapısı, yol, pazar, işe alınacak insanlar, kervanın sağlığı. Bölgeye göre farklılık var. İlgili olaylar ayrıca olabilir.
  - **Kullanıcı notu:** "Veba genel bir durum olmalı, bununla ilgili olaylar olabilir ama event card çıkmadan da etkilerini görmeliyiz. Bölgeye göre farklılık olmalı."
  - **Kabul:** Veba altındaki bir şehir ve yolun, kart açılmadan farkı gösterilen görüntüsü; etkiler test edilir.

- [ ] **Y-C26 Vebanın hiç bulaşmadığı köyler**
  - **Onay turu (2026-10-31):** onaylandı, uygulanacak. Kart onaylandı; kullanıcı notu: zorla girince ticarette ciddi dezavantaj ve itibar doğrudan zedelenmeli.
  - **Durum (2026-10-31):** öneri. Kart taslağı kart partisi 1'de (docs/design_notes/kart_partisi_01.md), onay bekliyor.
  - **Öncelik:** P2 · **Dalga:** 5 · **Bağımlı:** Y-C25 · **Kim:** C
  - **Ne:** Bazı köylere veba hiç bulaşmamış (kurtulan değil). Oyun nedenini açıklamaz. Durak ya da olay zinciri; lore kaydı SIDERIA.md §5.1.
  - **Kullanıcı notu:** "Vebanın hiç bulaşmadığı köyler olabilir, kurtulan köy olmasın."
  - **Kabul:** Kartlar onaya 10'luk partiyle gider.

- [x] **Y-C27 Gokyurt misafirliği**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı.
  - **Durum (2026-10-31):** test bekliyor. Gokyurt'ta (gocebe) varışta bir gece konsey öder; varış ekranında satır.
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** - · **Kim:** C
  - **Ne:** Gokyurt'taki kervansaray ve öbür konaklamalarda bir gün konaklama ve yeme içme ücretsiz; bedeli konsey öder. Öbür kervansaraylarda bu eskiden vardı, kıtlıkta kaldırıldı. Oyunda gün yalnızca yolda aktığı için varışta bir misafir gecesi olarak çevrilir (erzak harcanmadan dinlenme).
  - **Kullanıcı notu:** "Gokyurt'ta yer alan kervansaray ve diğer konaklama imkanlarında bir gün ücretsiz konaklama ve yeme içme konsey tarafından karşılanır. Bu tavır diğer kervansaraylarda da eskiden olsa da bu kıtlık döneminde kaldırılmıştır."
  - **Kabul:** Orbeyan'a varışta misafirlik; öbür kervansaraylarda yok; `denge-olcum` ile ölçüldü.

- [x] **Y-C28 Yolcu defteri**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı.
  - **Durum (2026-10-31):** test bekliyor. Kervansarayda meyhaneci yolcu defterini okutur: iki yolun haberi.
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** Y-C10 · **Kim:** C
  - **Ne:** Kervansaray tavernasında söylenti şansı yüksek; defterde son geçen kervanların yönü, yol tehlikesi ve tarihli fiyatlar (söylenti yalan olabilir).
  - **Kullanıcı notu:** "Yolcu defteri: Onay."
  - **Kabul:** Kervansarayda bilgi şehirdekinden zengin; test eder.

- [ ] **Y-C29 Tarafsız zemin: Duvenmor**
  - **Onay turu (2026-10-31):** onaylandı, uygulanacak. Kavga kartı onaylandı.
  - **Durum (2026-10-31):** kısmen. Yasak mekanizması (ban_location, haritada kilitli planla düğmesi) hazır; kavga kartı kart partisi 1'de onay bekliyor.
  - **Öncelik:** P3 · **Dalga:** 2 · **Bağımlı:** - · **Kim:** C
  - **Ne:** Duvenmor'un içinde kılıç çekilmez; çeken kervan bir daha giremez. Tetikleyici bir yol düşmanlığının kervansarayda sürmesi (rakip kervan, intikamcı tüccar).
  - **Kullanıcı notu:** "Tarafsız zemin: Onay."
  - **Kabul:** Yasak kaydı kayıtta tutulur ve giriş kilitli, nedeniyle görünür.

- [x] **Y-C30 Kıtlıkta kervansaray: kapıya bırakılan yemek**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı.
  - **Durum (2026-10-31):** test bekliyor. Kıtlıkta kervansaray sahibinin kapıya bıraktığı tas: meyhane açılış satırı.
  - **Öncelik:** P3 · **Dalga:** 6 · **Bağımlı:** - · **Kim:** CO
  - **Ne:** Kıtlığın kervansaraydaki izi küçük kalır: diyalogda bir ayrıntı ya da hancının kapıya yemek bıraktığının görüldüğü bir sahne.
  - **Kullanıcı notu:** "Diyalogda belirtilen küçük bir detay ya da sadece görsel olarak hancının kapıya yemek bıraktığını gördüğümüz bir yer olabilir."
  - **Kabul:** Satır ya da görüntü onaylandı.

- [ ] **Y-B14 Yol kenarı kervansarayları**
  - **Onay turu (2026-10-31):** onaylandı, uygulanacak. Duraklar onaylandı; üç kart onaylandı.
  - **Durum (2026-10-31):** kısmen. Yol kenarı kervansaray durakları (eskimiş, harabe, haydut elinde) yolda ve şeritte; üç kartı kart partisi 1'de onay bekliyor.
  - **Öncelik:** P2 · **Dalga:** 3 · **Bağımlı:** - · **Kim:** C
  - **Ne:** Yol üstünde kervansaray durakları: çoğu eskimiş, ücra ama açık; çok azı kapanmış harabe; bazıları haydutların elinde. Oyun metninde "han" denmez, kervansaray denir. Harita verisi (`build_settlements.py`) ve durak kartı düzeni (`near_<durak>`).
  - **Kullanıcı notu:** "Mevcut kervansaraylar içinden, (han demiyoruz) bazıları eskimiş, ücra bir yer haline gelmiş ama hala açık olabilir ya da çok azı kapanmış harabe de olabilir, haydutlar tarafından ele geçirilmiş de olabilir."
  - **Kabul:** Her durak hâlinin kartı ve görünüşü; `test_route_terrain` erzak sözünü yeniden sınar.

- [x] **Y-B15 Kuyu durağı**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı.
  - **Durum (2026-10-31):** test bekliyor. Kuyu durağı: yolda türetilen durak, faydası bir kez.
  - **Öncelik:** P2 · **Dalga:** 3 · **Bağımlı:** - · **Kim:** C
  - **Ne:** Çöl ve bozkır kesimlerinde kuyu durağı. Yeni bir su kaynağı değil: erzak ve yorgunluk kollarına bağlanır. "Doğru stoklayan aç kalmaz" sözü korunur.
  - **Kullanıcı notu:** "Kuyu durağı: Onay."
  - **Kabul:** `test_route_terrain` her yolda erzak sözünü sınar.

- [x] **Y-B16 Küçük lütuf anı**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı.
  - **Durum (2026-10-31):** test bekliyor. Kampta nadir an (akşam başına ~0,077, en az 7 gün arayla; test_waybook_pages ölçer), sinema bantları ve tek cümle, günlük o akşam lütfu yazar. tests/screenshot_mercy.gd.
  - **Öncelik:** P2 · **Dalga:** 3 · **Bağımlı:** - · **Kim:** CO
  - **Ne:** Kampta nadir, arayüzsüz, bir an tutulan sahne; ardından günlük cümlesi seçimi (`DiaryPanel`). Nadir olması ağırlığını korur.
  - **Kullanıcı notu:** "Küçük lütuf anı: Onay."
  - **Kabul:** Sıklık `simulate_road_beats` ile ölçüldü; sahne görüntüsü onaylandı.

- [ ] **Y-C31 Geçiş belgesi**
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** Y-E06 · **Kim:** C
  - **Ne:** Orbeyan tamgası, Ezmerak boynuz fişi, Ayazkaya bedel taşı ve Avuçiçi zili tek sistem: yolun sahibi güce ödenir, karşılığında süreli belge alınır, deftere yazılır. Lore taslakları defter III'te onay bekliyor.
  - **Kullanıcı notu:** "Geçiş belgesi: Onay."
  - **Kabul:** Belgesiz geçişin bedeli ve belgenin süresi test edilir.

- [x] **Y-C32 Bedeli erzakla öde**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı.
  - **Durum (2026-10-31):** test bekliyor. Haraç kartında erzakla öde seçeneği (8 erzak, moral -4).
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** - · **Kim:** C
  - **Ne:** Haraç ve bedel kartlarına para yerine erzak seçeneği; ödememek o yolun tehlikesini yükseltir. Gönüllü seçenek, planlayıcının erzak hesabına girmez.
  - **Kullanıcı notu:** "Bedeli erzakla öde: Onay."
  - **Kabul:** Kart seçeneği ve yol tehlikesi testi.

- [ ] **Y-E09 Yozlaşmış yol bekçisi kartı**
  - **Onay turu (2026-10-31):** onaylandı, uygulanacak. Kart partisi 1 onaylandı.
  - **Durum (2026-10-31):** öneri. Kart taslağı kart partisi 1'de, onay bekliyor.
  - **Öncelik:** P2 · **Dalga:** 5 · **Bağımlı:** Y-C31 · **Kim:** C
  - **Ne:** Yol bekçisi zayıf görünen kervandan fazla ister, fiş vermez, muaf olandan da alır.
  - **Kullanıcı notu:** "Yozlaşmış yol bekçisi: Onay."
  - **Kabul:** Kalite listesinden geçer; onaya 10'luk partide.

- [ ] **Y-E10 Esirlikten kaçış zinciri**
  - **Onay turu (2026-10-31):** onaylandı, uygulanacak. Kart partisi 1 onaylandı.
  - **Durum (2026-10-31):** öneri. Kart taslağı kart partisi 1'de, onay bekliyor.
  - **Öncelik:** P2 · **Dalga:** 5 · **Bağımlı:** Y-E02 · **Kim:** C
  - **Ne:** Kervandan biri ya da lider esir düşer; kaçarken gizli sebepleri olan yabancılar geçici olarak gruba katılır.
  - **Kullanıcı notu:** "Esirlikten kaçış zinciri: Onay."
  - **Kabul:** Zincir taslağı onaya gider.

- [ ] **Y-E11 Gezgin oyuncular ve tövbe alayı**
  - **Onay turu (2026-10-31):** onaylandı, uygulanacak. Kart partisi 1 onaylandı.
  - **Durum (2026-10-31):** öneri. İki kart taslağı kart partisi 1'de, onay bekliyor.
  - **Öncelik:** P2 · **Dalga:** 5 · **Bağımlı:** - · **Kim:** C
  - **Ne:** İki yol kartı: gezgin oyuncular (küçük lütuf, haber) ve tövbe alayı (kıtlıkta yardım ister; Septisizm ve Yumruk gözünden başka okunur).
  - **Kullanıcı notu:** "Gezgin oyuncular ve tövbe alayı: Onay."
  - **Kabul:** Kalite listesinden geçer; onaya partide.

- [ ] **Y-E12 Gizli güdülü kılavuz**
  - **Onay turu (2026-10-31):** onaylandı, uygulanacak. Kart partisi 1 onaylandı.
  - **Durum (2026-10-31):** öneri. Kart taslağı kart partisi 1'de, onay bekliyor.
  - **Öncelik:** P2 · **Dalga:** 5 · **Bağımlı:** - · **Kim:** C
  - **Ne:** Kervanı bir yere götürmeyi öneren kılavuz yalnızca olayda çıkar, kiralanamaz. Saklı bir sebebi var (`NpcDisposition`).
  - **Kullanıcı notu:** "Gizli güdülü kılavuz: Onay. (Yerel rehber kiralamak: Red, buna para verecek imkânımız olmamalı hiç.)"
  - **Kabul:** Kart onaya partide.

- [ ] **Y-E13 Dağılan tayfa yolda karşına çıkar**
  - Kullanıcı, soru defteri IV (dagilma): aç kalıp kervanı bırakan tayfa en yakın şehre gider ve çoğu oraya
    varamaz; bazıları kaçakların yanına katılır.
  - Kart: yolu kesen silahlı grubun içinde **adı deftere yazılmış** eski arabacın duruyor. Defter onu
    "açlıktan ayrıldı" diye yazmıştı; şimdi karşında.
  - Seçenekler kurgulanacak: tanıdığını söyle (karizma), hiç tanımamış gibi yap, dövüş. Tanıdığını söylemek
    yükü kurtarabilir ama kervanın geri kalanının gözünde kervanbaşını küçültür.
  - Bağlar: `crew_lost_to_hunger` sayacı, `CaravanLedger` satırı, `People` hafızası.

- [ ] **Y-C33 Ant bağı**
  - **Onay turu (2026-10-31):** açık. Kullanıcı kararı: ant bağını yalnızca Gokyurtlular ve dağ kabileleri içer.
  - **Öncelik:** P2 · **Dalga:** 4 · **Bağımlı:** Y-C17 · **Kim:** C
  - **Ne:** İki yoldaşın bağı +3'e çıkınca birbirine söz verir; söz bozulursa ağır kırgınlık. Göçebe töresinden.
  - **Kullanıcı notu:** "Gokyurt'ta ant bağı: Onay."
  - **Kabul:** Bağ ve kırgınlık testi; soru: yalnızca Gokyurtlu yoldaşlar mı, herkes mi.

- [ ] **Y-C34 Hacı kafilesine katılmak**
  - **Onay turu (2026-10-31):** açık. Kullanıcı kararı: kervanın inancı kervanbaşının inancıdır; rol yapma seçeneği Karizma/manipülasyon kontrolüyle.
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** Y-C25 · **Kim:** CK
  - **Ne:** Avuçiçi yolunda bir kafileye katılma seçeneği: güvenli ama yavaş ve kurallı. Şart aynı inançtan olmak ya da rol yapmak; rol yapan yakalanırsa Avuçiçi'nin El'i taşıyan inançsıza cezası (Ç14'e bağlı). Kervanın inancını tutan bir değer gerekir.
  - **Kullanıcı notu:** "Ek bir seçenek olarak eklenebilir ama aynı dinden olmamız lazım ya da rol yapmalıyız."
  - **Kabul:** Karar: kervanın inancı neye göre belirlenir.

- [x] **Y-H08 Sessizlik anları**
  - **Onay turu (2026-10-31):** bitti. Onay turunda onaylandı (sesler yer tutucu).
  - **Durum (2026-10-31):** test bekliyor. AudioManager.hush: feda ve ölümden sonra müzik susar, adım, nefes, sürünme; yer tutucu sesler.
  - **Öncelik:** P2 · **Dalga:** 6 · **Bağımlı:** - · **Kim:** C
  - **Ne:** Bir feda kararından sonra ya da çok gergin anlarda müzik ve ortam sesi kesilir; yalnızca adım, sürünme ve nefes sesleri duyulur.
  - **Kullanıcı notu:** "Tamamen sessizlik ve adım, sürünme, nefes gibi seslerin daha belirgin olması, daha doğrusu sadece onların duyulması daha etkili."
  - **Kabul:** Ses varlıkları (CC0 ya da sentez yer tutucu); geçiş `AudioManager` üzerinden.

- [x] **Y-C35 İlan panosu**
  - **Onay turu (2026-10-31):** kısmen. Kullanıcı (onay turu): Düzenle - menü sekmesi değil, ilanların çivili kâğıt olarak asılı durduğu görünür bir pano olmalı.
  - **Durum (2026-10-31):** test bekliyor. Lonca sekmesi İlan Panosu; kafile ve sürücü ilanları Y-C34'ü bekliyor.
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** Y-C02 · **Kim:** C
  - **Ne:** Kontrat panosunun adı İlan Panosu olur; kafile ve sürücü ilanları da aynı panoda.
  - **Kullanıcı notu:** "Bu ilanlar da kontrat panosunda olabilir. Bu panoya kontrat panosu yerine ilan panosu deriz mesela."
  - **Kabul:** Çeviri anahtarları ve ekran görüntüsü.

- [x] **Y-A08 Kampanya: konforlu final yok**
  - **Yapıldı (2026-10-31):** kullanıcı "oyundaki mevcut senaryo sistemini ve kurgusunu kaldır" dedi. `CampaignCatalog`, `CampaignChapter`, bölüm sayacı, şehir özetindeki hikâye bloğu, çeviri anahtarları, Codex bölümü ve kural notları silindi; `simulate_career` bölüme değil sefer sayısına bakıyor.
  - **Öncelik:** P1 · **Dalga:** 5 · **Bağımlı:** Y-C21 · **Kim:** CO
  - **Ne:** "Kendi hanını kur" gibi bir final yok. Oyun zorluk ve kıtlık içinde geçer; yapılan tek şey kervanı ilerletmek ve ek görevleri başarmak. Kampanya bölümlerinin hedefleri ve metinleri buna göre yeniden yazılır (defter III'teki kampanya metni sorusu da buraya bağlı).
  - **Kullanıcı notu:** "Böyle bir final olmayacak, oyun zorluk ve kıtlık içinde geçecek, şimdilik tek yaptığımız ve yapabildiğimiz kervanı ilerletmek ve ek görevleri başarmak."
  - **Kabul:** Yeni bölüm taslağı onaylandı; `simulate_career` yeniden ölçüldü.

- [x] **Y-G24 Zemin ve hava efektleri: yağmur, kar, sıçrama, iz**
  - **Yapıldı (2026-11-03):** kullanıcı isteği - "tüm efektleri çizip sprite'a dökebilir misin... yağmur, kar, yerdeki su birikintisi, yağmurun suya düşüşü, yoldan geçen yaya, vagon ve hayvanların yerdeki kar çamur ve suyla tepkisi gibi gibi".
  - **Öncelik:** P2 · **Dalga:** 6 · **Bağımlı:** - · **Kim:** C
  - **Ne:** 46 efekt, hepsi **kod** (parçacık parametreleri); sprite sheet o kodun çıktısı. Üretici `tools/efekt/` (tuval + beş çekirdek + palet + katalog), çıktı `data/assets/fx/sheets/<id>.png` ve `fx.json`. Yeniden basmak: `python3 tools/efekt/uret.py [<id>...] [--tabaka]`.
  - **Aileler:**
    - *Perde (döşenir, zamanda döngülü):* `rain_light/medium/heavy`, `sleet`, `hail`, `snow_light/heavy`, `blizzard`, `fog_drift`, `ground_mist`.
    - *Yere düşüş:* `rain_impact_dry` (kuru toprağa damla), `rain_ripple` (birikintide halka), `rain_crown` (taç sıçrama), `snow_settle`, `canopy_drip` (brandanın kenarından).
    - *Ayak, toynak, pençe:* `step_*` ve `hoof_*` dört zeminde (`_dust`, `_mud`, `_splash`, `_snow`), `paw_snow`.
    - *Tekerlek:* `wheel_dust/mud/splash/snow`.
    - *Yerde kalan iz:* `track_foot_*`, `track_hoof_*`, `track_wheel_*` (çamur ve kar).
    - *Soğuk ve nem:* `breath_vapor`, `breath_vapor_beast`, `frost_glint`, `puddle_shiver`.
    - *Ateş (tek sıcak kaynak):* `ember_rise`, `smoke_thin/thick`, `fire_steam`, `lantern_halo`.
    - *Rüzgâr:* `dust_gust`, `leaf_drift`, `snow_gust`.
  - **Oyun tarafı:** `FxCatalog` (manifesto, doku, kare, dünya ölçüsü), `FxLayer` (havuzlu; efekt bırakıldığı **toprağa** çivili, kervanla birlikte kaymıyor), `WeatherCurtain` (iki derinlikte döşenen perde), `GroundCover` (ıslak/çamur/kar/toz; `RouteWeather` + `Temperature`'dan **hesaplanır, saklanmaz**, üç gün hafıza). `RoadCaravan` her ayak, toynak ve tekerlek temasında zemine göre efekt ve iz bırakıyor (`WalkFigure.take_footfalls`).
  - **Karar:** Perde varken `TravelBand`'in kendi prosedürel yağmuru susuyor (ekranda iki yağmur üst üste biniyordu); sanat eksikse geri geliyor - `PropArt`'ın "resmi yoksa çağıran kendi çizimine düşer" kuralı.
  - **Kabul:** `tests/test_road_fx.gd` (280 test: ad uyumu, manifesto bütünlüğü, zeminin yinelenebilirliği, adım sayacı, havuz tavanı), `tests/screenshot_road_fx.gd` sekiz kare (kuru, yağmur, fırtına, çamur, kar, tipi, sis, katalog) ve `docs/ui/efekt_tabakasi.png`.

- [x] **Y-G25 Yağmur ve kar bedende: ıslanma ve kar birikmesi**
  - **Yapıldı (2026-11-05):** kullanıcı isteği - "yağmur ve suyun hayvanlar, insanlar ve vagon üzerinde de etkisi olsun. Islansınlar, üstlerinde kar biriksin vs."
  - **Öncelik:** P2 · **Dalga:** 6 · **Bağımlı:** Y-G24 · **Kim:** C
  - **Model:** `Soaking` (`scripts/travel/soaking.gd`) - kervanın **üstündeki** su ve kar, `GroundCover`'ın gövde karşılığı. İkisi aynı iki girdiyi (`RouteWeather` + `Temperature`) ve aynı yağış tablosunu okuyor ama ayrı şeyler biriktiriyor: yol çamur olurken sırtta kuru kar durabilir, kar erirken tersi. **Hesaplanır, saklanmaz**; iki gün hafıza; gövde zeminden hızlı ıslanır ve hızlı kurur; eriyen kar suya döner; **ateş günün sonunda kurutur** (kampın görünmeyen karşılığı).
  - **Görünüş:** `ArtDraw.snow_cap` (düzensiz tek yığın, tabanı yüzeye gömülü, yumuşak mürekkep), `wet_sheen` (ıslak üst yüzeyde gökyüzünün soğuk parıltısı), `wet_tint` (tek formül: figür, vagon ve eşya aynı yağmurun altında). `WalkFigure` baş tepesi, sırtın üstü ve dört ayaklının sırtı; `ArtDraw.wagon` brandanın tepesi. Pay `RoadCaravan`'dan dağıtılıyor ve hedefe doğru yumuşakça gidiyor - ıslanmak görünen bir süreç.
  - **Mekanik bağ (yeni ceza sistemi değil, var olan kolun çevrilmesi):** ıslak giysi ısısının `Temperature.WET_WARMTH_LOSS` (%55) kadarını kaybediyor, yani yağmurlu bir günün bedeli o gece stres, yorgunluk ve humma olarak ödeniyor; kuruma yolu ateştir. Planlayıcının erzak sözü etkilenmiyor (erzak payı yalnızca sıcaklığa bakıyor).
  - **Ayrıca:** yağmur dindikten sonra brandanın kenarından `canopy_drip` damlıyor (katalogdaki efekt artık bağlı).
  - **Ekran görüntüsünün yakaladığı dört hata** (hiçbirini yapısal test göremezdi): kar tümseği önce kalas, sonra sıra sıra şekerleme, sonra aşçı şapkası oldu; ve render edilmiş figürler `head` değil `head_top` verdiği için insanların hiçbirinde kar çizilmemişti.
  - **Kabul:** `tests/test_road_fx.gd` 311 test (toplam 30923 geçti), `tests/screenshot_road_fx.gd` `09_islak_kervan` ve `10_karli_kervan`.
