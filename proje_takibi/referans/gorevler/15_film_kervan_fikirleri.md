# 15. Film ve kervan fikirleri (2026-10-31)

Kaynak: kullanıcının film listesi (The Road, The Way Back, The Seventh Seal, Mongol, Extraordinary Tales, Black Death) ve tarihteki kervan ve kervansaray araştırması. Fikir listesindeki 30 maddenin cevapları burada; filmler yalnızca his ve teknik kaynağı, lore ve oyun metnine adları girmez.

**Reddedilenler (yeniden önerilmez):** hayvanların kıtlıkta yoldan çekilmesi; karta göre değişen mürekkep dili; yerel rehber kiralamak ("buna para verecek imkânımız olmamalı hiç"); görev unvanları; vakıf finali. **Açıklaması yeniden yazılacak:** inanç mahkemesi kartı.

**Dil kuralı:** oyun metninde "han" denmez, kervansaray denir.

- [ ] **Y-G17 Tek sıcak kaynak: kural ve bütün sahnelerin denetimi**
  - **Öncelik:** P1 · **Dalga:** 6 · **Bağımlı:** Y-C22 · **Kim:** CO
  - **Ne:** Dünyada sıcak renk yalnızca bir ışık kaynağından gelir: ateş, fener, meşale, pencere ışığı, defter sayfası. Kural `kurallar-sanat` Art Rules'a yazıldı. Kalan: yol, şehir, savaş, hub, kervansaray ve kart görsellerinin denetim listesi, aykırı olanların sırayla düzeltilmesi; her düzeltme ekran görüntüsüyle.
  - **Kullanıcı notu:** "Tek sıcak kaynak: Onay. Bunu gene kurallara yaz çünkü buna göre çok düzenleme gerekecek."
  - **Kabul:** Denetim listesi `docs/ui/` altında; her sahne için önce ve sonra görüntüsü.

- [ ] **Y-G18 Kıtlık paleti bölgeye göre: Gokyurt en geç solar**
  - **Öncelik:** P2 · **Dalga:** 6 · **Bağımlı:** Y-C21, Y-G17 · **Kim:** C
  - **Ne:** Kıtlığın derecesi bölge başına bir değer; palet o değere göre solar. Gokyurt hâlâ öbür yerlere göre daha sağlıklı, bu yüzden en geç solar. Bağlarla ilgisi yok.
  - **Kullanıcı notu:** "Hayır bağ ile ilgili bir şey olmamalı bu. Gokyurt hala diğer yerlere kıyasla daha sağlıklı bir yer o sebeple palet daha geç solabilir orada."
  - **Kabul:** Aynı saatte Gokyurt yolu ile Vadi yolunun görüntüsü yan yana; test bölge değerinin palete geçtiğini doğrular.

- [ ] **Y-G19 Portreler baştan yorgun ve aşınmış**
  - **Öncelik:** P2 · **Dalga:** 6 · **Bağımlı:** - · **Kim:** CO
  - **Ne:** Karakter portreleri bir duruma göre aşınmaz, baştan öyle çizilir: yorgun, aşınmış yüzler. El çizimi programının portre yönergesine (`docs/el_cizimi/`) girer; mevcut `BustPortrait` mürekkep gölgelendirmesi ara çözüm olarak aynı yöne çekilir.
  - **Kullanıcı notu:** "Karakter portreleri direkt bu şekilde çizilmeli, zaten aşınmış, yorgun olmalı."
  - **Kabul:** Yönerge yazıldı; mevcut portrelerin önce ve sonra görüntüsü onaylandı.

- [ ] **Y-G20 Olay kartının görsel dili bölgeye göre**
  - **Öncelik:** P3 · **Dalga:** 6 · **Bağımlı:** - · **Kim:** CO
  - **Ne:** Kartın çizim dili kartın türüne göre değişmez, bölgeye göre değişir (Gokyurt, Vaelghard, Vadi, Ayazkaya...).
  - **Kullanıcı notu:** "Bölgeye göre farklılık olmalı, karta göre de farklılık olmasın."
  - **Kabul:** Üç bölgenin kart görünüşü yan yana onaylandı.

- [ ] **Y-G21 Kart açılışında yavaş kayma**
  - **Öncelik:** P3 · **Dalga:** 6 · **Bağımlı:** - · **Kim:** CO
  - **Ne:** Olay kartının resmi açılırken yavaşça kayar (paralaks); Reduce Motion açıkken kayma yok.
  - **Kullanıcı notu:** "Yavaş kayan kart açılışı: Onay."
  - **Kabul:** Hareket eğrisi duruştan başlayıp duruşta biter (`test_motion` kalıbı); görüntü onaylandı.

- [ ] **Y-G22 Bataklık görünüşü: gri-yeşil sis**
  - **Öncelik:** P3 · **Dalga:** 6 · **Bağımlı:** - · **Kim:** CO
  - **Ne:** Samuran ve Liraven çevresindeki yol kesimleri için çamurlu, sisli, gri-yeşil yol katmanları (`RoadStrips` görünüşü).
  - **Kullanıcı notu:** "Gri-yeşil sisli bataklık: Onay."
  - **Kabul:** `screenshot_road_looks` tablosunda bataklık görünüşü.

- [ ] **Y-G23 Soy sonu: ufukta yürüyen adlar**
  - **Öncelik:** P3 · **Dalga:** 6 · **Bağımlı:** Y-D03 · **Kim:** CO
  - **Ne:** Soy bitince üstü çizili adların sahipleri ufukta siluet olarak yürür. Ortaçağın ölüm dansı geleneğinden; filmin karesinden değil.
  - **Kullanıcı notu:** "Soy sonu: ufukta adlar: Onay."
  - **Kabul:** Bitiş ekranının görüntüsü onaylandı.

- [ ] **Y-C25 Veba bir dünya hâli: kart açılmadan görünür**
  - **Öncelik:** P1 · **Dalga:** 2 · **Bağımlı:** Y-C21 · **Kim:** C
  - **Ne:** Veba genel bir durum. Etkileri kart açılmadan görülür: şehrin görünüşü ve kapısı, yol, pazar, işe alınacak insanlar, kervanın sağlığı. Bölgeye göre farklılık var. İlgili olaylar ayrıca olabilir.
  - **Kullanıcı notu:** "Veba genel bir durum olmalı, bununla ilgili olaylar olabilir ama event card çıkmadan da etkilerini görmeliyiz. Bölgeye göre farklılık olmalı."
  - **Kabul:** Veba altındaki bir şehir ve yolun, kart açılmadan farkı gösterilen görüntüsü; etkiler test edilir.

- [ ] **Y-C26 Vebanın hiç bulaşmadığı köyler**
  - **Öncelik:** P2 · **Dalga:** 5 · **Bağımlı:** Y-C25 · **Kim:** C
  - **Ne:** Bazı köylere veba hiç bulaşmamış (kurtulan değil). Oyun nedenini açıklamaz. Durak ya da olay zinciri; lore kaydı LORE.md §6b.
  - **Kullanıcı notu:** "Vebanın hiç bulaşmadığı köyler olabilir, kurtulan köy olmasın."
  - **Kabul:** Kartlar onaya 10'luk partiyle gider.

- [ ] **Y-C27 Gokyurt misafirliği**
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** - · **Kim:** C
  - **Ne:** Gokyurt'taki kervansaray ve öbür konaklamalarda bir gün konaklama ve yeme içme ücretsiz; bedeli konsey öder. Öbür kervansaraylarda bu eskiden vardı, kıtlıkta kaldırıldı. Oyunda gün yalnızca yolda aktığı için varışta bir misafir gecesi olarak çevrilir (erzak harcanmadan dinlenme).
  - **Kullanıcı notu:** "Gokyurt'ta yer alan kervansaray ve diğer konaklama imkanlarında bir gün ücretsiz konaklama ve yeme içme konsey tarafından karşılanır. Bu tavır diğer kervansaraylarda da eskiden olsa da bu kıtlık döneminde kaldırılmıştır."
  - **Kabul:** Orbeyan'a varışta misafirlik; öbür kervansaraylarda yok; `denge-olcum` ile ölçüldü.

- [ ] **Y-C28 Yolcu defteri**
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** Y-C10 · **Kim:** C
  - **Ne:** Kervansaray tavernasında söylenti şansı yüksek; defterde son geçen kervanların yönü, yol tehlikesi ve tarihli fiyatlar (söylenti yalan olabilir).
  - **Kullanıcı notu:** "Yolcu defteri: Onay."
  - **Kabul:** Kervansarayda bilgi şehirdekinden zengin; test eder.

- [ ] **Y-C29 Tarafsız zemin: Duvenmor**
  - **Öncelik:** P3 · **Dalga:** 2 · **Bağımlı:** - · **Kim:** C
  - **Ne:** Duvenmor'un içinde kılıç çekilmez; çeken kervan bir daha giremez. Tetikleyici bir yol düşmanlığının kervansarayda sürmesi (rakip kervan, intikamcı tüccar).
  - **Kullanıcı notu:** "Tarafsız zemin: Onay."
  - **Kabul:** Yasak kaydı kayıtta tutulur ve giriş kilitli, nedeniyle görünür.

- [ ] **Y-C30 Kıtlıkta kervansaray: kapıya bırakılan yemek**
  - **Öncelik:** P3 · **Dalga:** 6 · **Bağımlı:** - · **Kim:** CO
  - **Ne:** Kıtlığın kervansaraydaki izi küçük kalır: diyalogda bir ayrıntı ya da hancının kapıya yemek bıraktığının görüldüğü bir sahne.
  - **Kullanıcı notu:** "Diyalogda belirtilen küçük bir detay ya da sadece görsel olarak hancının kapıya yemek bıraktığını gördüğümüz bir yer olabilir."
  - **Kabul:** Satır ya da görüntü onaylandı.

- [ ] **Y-B14 Yol kenarı kervansarayları**
  - **Öncelik:** P2 · **Dalga:** 3 · **Bağımlı:** - · **Kim:** C
  - **Ne:** Yol üstünde kervansaray durakları: çoğu eskimiş, ücra ama açık; çok azı kapanmış harabe; bazıları haydutların elinde. Oyun metninde "han" denmez, kervansaray denir. Harita verisi (`build_settlements.py`) ve durak kartı düzeni (`near_<durak>`).
  - **Kullanıcı notu:** "Mevcut kervansaraylar içinden, (han demiyoruz) bazıları eskimiş, ücra bir yer haline gelmiş ama hala açık olabilir ya da çok azı kapanmış harabe de olabilir, haydutlar tarafından ele geçirilmiş de olabilir."
  - **Kabul:** Her durak hâlinin kartı ve görünüşü; `test_route_terrain` erzak sözünü yeniden sınar.

- [ ] **Y-B15 Kuyu durağı**
  - **Öncelik:** P2 · **Dalga:** 3 · **Bağımlı:** - · **Kim:** C
  - **Ne:** Çöl ve bozkır kesimlerinde kuyu durağı. Yeni bir su kaynağı değil: erzak ve yorgunluk kollarına bağlanır. "Doğru stoklayan aç kalmaz" sözü korunur.
  - **Kullanıcı notu:** "Kuyu durağı: Onay."
  - **Kabul:** `test_route_terrain` her yolda erzak sözünü sınar.

- [ ] **Y-B16 Küçük lütuf anı**
  - **Öncelik:** P2 · **Dalga:** 3 · **Bağımlı:** - · **Kim:** CO
  - **Ne:** Kampta nadir, arayüzsüz, bir an tutulan sahne; ardından günlük cümlesi seçimi (`DiaryPanel`). Nadir olması ağırlığını korur.
  - **Kullanıcı notu:** "Küçük lütuf anı: Onay."
  - **Kabul:** Sıklık `simulate_road_beats` ile ölçüldü; sahne görüntüsü onaylandı.

- [ ] **Y-C31 Geçiş belgesi**
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** Y-E06 · **Kim:** C
  - **Ne:** Orbeyan tamgası, Ezmerak boynuz fişi, Ayazkaya bedel taşı ve Avuçiçi zili tek sistem: yolun sahibi güce ödenir, karşılığında süreli belge alınır, deftere yazılır. Lore taslakları defter III'te onay bekliyor.
  - **Kullanıcı notu:** "Geçiş belgesi: Onay."
  - **Kabul:** Belgesiz geçişin bedeli ve belgenin süresi test edilir.

- [ ] **Y-C32 Bedeli erzakla öde**
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** - · **Kim:** C
  - **Ne:** Haraç ve bedel kartlarına para yerine erzak seçeneği; ödememek o yolun tehlikesini yükseltir. Gönüllü seçenek, planlayıcının erzak hesabına girmez.
  - **Kullanıcı notu:** "Bedeli erzakla öde: Onay."
  - **Kabul:** Kart seçeneği ve yol tehlikesi testi.

- [ ] **Y-E09 Yozlaşmış yol bekçisi kartı**
  - **Öncelik:** P2 · **Dalga:** 5 · **Bağımlı:** Y-C31 · **Kim:** C
  - **Ne:** Yol bekçisi zayıf görünen kervandan fazla ister, fiş vermez, muaf olandan da alır.
  - **Kullanıcı notu:** "Yozlaşmış yol bekçisi: Onay."
  - **Kabul:** Kalite listesinden geçer; onaya 10'luk partide.

- [ ] **Y-E10 Esirlikten kaçış zinciri**
  - **Öncelik:** P2 · **Dalga:** 5 · **Bağımlı:** Y-E02 · **Kim:** C
  - **Ne:** Kervandan biri ya da lider esir düşer; kaçarken gizli sebepleri olan yabancılar geçici olarak gruba katılır.
  - **Kullanıcı notu:** "Esirlikten kaçış zinciri: Onay."
  - **Kabul:** Zincir taslağı onaya gider.

- [ ] **Y-E11 Gezgin oyuncular ve tövbe alayı**
  - **Öncelik:** P2 · **Dalga:** 5 · **Bağımlı:** - · **Kim:** C
  - **Ne:** İki yol kartı: gezgin oyuncular (küçük lütuf, haber) ve tövbe alayı (kıtlıkta yardım ister; Septisizm ve Yumruk gözünden başka okunur).
  - **Kullanıcı notu:** "Gezgin oyuncular ve tövbe alayı: Onay."
  - **Kabul:** Kalite listesinden geçer; onaya partide.

- [ ] **Y-E12 Gizli güdülü kılavuz**
  - **Öncelik:** P2 · **Dalga:** 5 · **Bağımlı:** - · **Kim:** C
  - **Ne:** Kervanı bir yere götürmeyi öneren kılavuz yalnızca olayda çıkar, kiralanamaz. Saklı bir sebebi var (`NpcDisposition`).
  - **Kullanıcı notu:** "Gizli güdülü kılavuz: Onay. (Yerel rehber kiralamak: Red, buna para verecek imkânımız olmamalı hiç.)"
  - **Kabul:** Kart onaya partide.

- [ ] **Y-C33 Ant bağı**
  - **Öncelik:** P2 · **Dalga:** 4 · **Bağımlı:** Y-C17 · **Kim:** C
  - **Ne:** İki yoldaşın bağı +3'e çıkınca birbirine söz verir; söz bozulursa ağır kırgınlık. Göçebe töresinden.
  - **Kullanıcı notu:** "Gokyurt'ta ant bağı: Onay."
  - **Kabul:** Bağ ve kırgınlık testi; soru: yalnızca Gokyurtlu yoldaşlar mı, herkes mi.

- [ ] **Y-C34 Hacı kafilesine katılmak**
  - **Öncelik:** P2 · **Dalga:** 2 · **Bağımlı:** Y-C25 · **Kim:** CK
  - **Ne:** Avuçiçi yolunda bir kafileye katılma seçeneği: güvenli ama yavaş ve kurallı. Şart aynı inançtan olmak ya da rol yapmak; rol yapan yakalanırsa Avuçiçi'nin El'i taşıyan inançsıza cezası (Ç14'e bağlı). Kervanın inancını tutan bir değer gerekir.
  - **Kullanıcı notu:** "Ek bir seçenek olarak eklenebilir ama aynı dinden olmamız lazım ya da rol yapmalıyız."
  - **Kabul:** Karar: kervanın inancı neye göre belirlenir.

- [ ] **Y-H08 Sessizlik anları**
  - **Öncelik:** P2 · **Dalga:** 6 · **Bağımlı:** - · **Kim:** C
  - **Ne:** Bir feda kararından sonra ya da çok gergin anlarda müzik ve ortam sesi kesilir; yalnızca adım, sürünme ve nefes sesleri duyulur.
  - **Kullanıcı notu:** "Tamamen sessizlik ve adım, sürünme, nefes gibi seslerin daha belirgin olması, daha doğrusu sadece onların duyulması daha etkili."
  - **Kabul:** Ses varlıkları (CC0 ya da sentez yer tutucu); geçiş `AudioManager` üzerinden.

- [ ] **Y-C35 İlan panosu**
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
