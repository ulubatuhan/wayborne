# Kıtlık için üç tasarım dersi

Kullanıcı notu (2026-10-30): üç konuşmadan çıkan önerileri detaylandır, oyuna uygun hâle getir, hedeflere ekle.
Bu belge görev Y-C21'in (kıtayı saran kıtlık) tasarım zemini. Görev listesinde Y-C22, Y-C23 ve Y-C24 olarak duruyor.

Kaynaklar:

- GDC, "Lessons from Frostpunk & This War of Mine": ahlaki zorunluluk ve umutsuz görsel dil.
- Jacob Geller, "Fear of Cold": yenilmez çevre ve domino etkisi.
- Adam Millard, "How To Design An Unsolvable Problem": kusursuz dengeye asla ulaşamamak.

## Önce bir sınır: ne kesilmeyecek

İlk öneri "geleneksel ödül ve güçlenme mekaniklerini kaldırmak" diyor. Bu, kullanıcının kendi ilkesiyle çatışıyor
(derinleşme, asla sadeleştirme; ölçülmüş sistemler kesilmez). Uyarlama şu:

- **Güç kalır, bedava olmaz.** Seviye, ekipman, yetkinlik ve kazanılan vagonlar silinmez. Her güçlenmenin yanına bir
  ağırlık eklenir: vagon ağız getirir (zaten öyle), seviye ünü artırır ve haraç ister, iyi silah dağlıyı kışkırtır.
- **Ödül kalır, temiz olmaz.** Bir kartın "iyi" seçeneği yoktur; her seçenek bir şeyi korur, başka bir şeyi feda eder.
- **Kazanmak kaybı silmez.** Final zaten kayıp ister (iki üstü çizili ad). Bu yön derinleşir.

Kararı kullanıcı verir: bu sınır doğru mu, yoksa bazı ödül sistemleri gerçekten kalksın mı? (Soru defteri II'ye eklenecek.)

## 1. Ahlaki zorunluluk, doğru ya da yanlış yok (Y-C22)

Ders: oyuncuya "doğru" ve "yanlış" sunulmaz. İki kötü arasında seçim sunulur ve bedel bir insana düşer.

Oyunda bugün olanlar (bu dersin tohumu):

- `LEAVE_BEHIND` ve `PARTY_HP` seçim yapılmadan önce kimin üstüne düşeceğini söylüyor.
- Yemek dağıtımında kimin aç kalacağı seçiliyor; kasıtlı aç bırakma kırgınlık bırakıyor.
- Varis seçimi kıdemliyi geçince kırgınlık bırakıyor.

Uyarlama:

1. **Kart kalite listesine bir madde.** `EventQuality.problems()`: kıtlık kartlarında baskın bir seçenek olmasın.
   - Her seçenek en az bir kaynaktan ya da kişiden bir şey alsın.
   - Hiçbir seçenek her eksende öbürlerinden iyi olmasın.
   - Ölçüm: kartın seçeneklerini sayısal etkilerine göre karşılaştıran bir rapor (`report_event_quality.gd`).
2. **Feda kartları.** Bedeli adı olan bir yoldaşa yükleyen kartlar:
   - erzağı yetmeyen bir köyde yaşlıyı bırakmak;
   - hastayı karantinaya alıp kervanı korumak;
   - bir vagonu ve tayfasını, aç bir kasabaya buğday taşısın diye ayırmak.
   Kim olduğu seçimden önce yazılır (Event Engine Rules).
3. **Şehrin hâliyle ahlak.** Görev Y-C21'in şehir morali buraya bağlanır:
   - Aç bir şehre yükünü satmamak kâr getirir ama şehrin hâlini ve kervanın adını düşürür.
   - Satmak yolun erzağını azaltır.
   - İkisi de "doğru" değil.
4. **Defter hükmü yazar.** Bir feda kararından sonra akşam günlüğünün cümle seçenekleri o kararı anar
   (`DiaryPanel`, `note_beat`): oyuncu kendi kararını kendi diliyle deftere geçirir. "Defter unutmaz" sütunu.

## 2. Yenilmez çevre ve domino etkisi (Y-C23)

Ders: soğuk ve kıtlık yenilecek bir düşman değildir, yalnızca dayanılır. Küçük bir hata zincirleme bir felakete döner
ve oyuncuyu son eşyalarını yakmaya iter.

Oyunda bugün olanlar:

- Yok sayılan yol işaretleri büyüyor (gıcırdayan tekerlek üç gün sonra kırık aks).
- Soğuk gece stres, yorgunluk ve ateş getiriyor; donan gün daha çok yediriyor.
- Açlık üçüncü geceden sonra can alıyor; tayfa birer birer ölüyor.

Uyarlama:

1. **Zincirler birbirine bağlansın.** Bugün her sistem kendi bedelini ödetiyor. Domino için birinin bedeli
   öbürünün kapısını açmalı:
   - kırık aks yolu uzatır;
   - uzayan yol erzağı bitirir;
   - açlık ateşi getirir;
   - ateşli biri savaşta düşer.
   Her halka var olan bir sistem; yeni olan yalnızca halkaların birbirini tetiklemesi.
   `RoadDirector` hangi zincirin açık olduğunu bilir ve bir sonraki halkanın kartına ağırlık verir.
2. **Yakılacak eşya.** Soğukta ve açlıkta kervan elindekini tüketebilsin:
   - brandayı yakmak (ısınır, vagon hasar alır);
   - tohumluk buğdayı yemek (bugün doyar, bir kontrat teslim edilemez);
   - kürkü sırta almak (ısınır, satılacak mal gider);
   - sandığı ve vagon tahtasını yakmak (son çare: vagon kaybı).
   Hepsi var olan kollara dokunur (hasar, yük, kontrat, vagon). Kamp eylemlerine (`CampActionsPanel`) eklenir.
3. **Çevre düşman değil.** Kar, kıtlık ve soğuk için "yenme" ödülü yok. Atlatılan bir kış ganimet vermez, yalnızca
   hayatta kalanları ve defterdeki satırları bırakır.
4. **Domino görünür olsun.** Oyuncu zinciri ancak görürse yönetebilir. Durum sekmesindeki dertler listesi (Wording)
   bir halkanın neyi tetiklediğini cümleyle söyler: "Aks çatlak; kırılırsa iki gün kaybederiz, erzak yetmez."

## 3. Çözülemeyen problem (Y-C24)

Ders: oyuncu asla kusursuz dengeye ulaşmamalı. Kervan büyüdükçe ya da zenginleştikçe sistem kendiliğinden yeni bir
kriz üretmeli; her zaman tam bir çözümü olmayan, dinamik bir problem yönetilmeli.

Oyunda bugün olanlar:

- Kervan büyüdükçe düşman güçleniyor (`POWER_SCALE_PER_PARTY_MEMBER`); her vagon iki ağız getiriyor.
- Kariyer evreleri tehditleri artırıyor (`career_stage`, `CAREER_THREATS`).
- Stres seferler boyunca birikiyor; şehir dinlenmesi zamanla azalıyor.

Uyarlama:

1. **Büyüme kriz doğursun, yalnızca zorluk değil.** Kervanın büyüklüğüne ve servetine bağlı yeni dertler:
   - Ün artınca kıtlık şehirleri gıda için kervana el koymak ister (zorla satın alma, düşük fiyat).
   - Dolu bir kese haydutu ve haraççıyı çeker.
   - Kalabalık kadroda kırgınlık ve hizipler büyür (bağlar, Y-C17).
   - Çok vagon, kıtlıkta çok ağız demek.
2. **Bir krizi çözmek öbürünü besler.** Örnekler:
   - erzağı stoklamak yükü ağırlaştırır, hız düşer, yol uzar;
   - kadroyu büyütmek savaşı kazandırır ama ağzı ve stresi artırır;
   - şehre buğday satmak şehrin hâlini düzeltir ama yolun erzağı gider.
   Tasarım sınaması: her yeni sistem için "bunu çözen hamle neyi bozuyor?" sorusunun cevabı yazılır.
3. **Ölçüm.** `simulate_career`'a "denge" raporu:
   - Bir kervanın kaç seferi hiç dert olmadan geçirdiği.
   - Ardışık sakin seferler dizisinin en uzunu.
   - Hedef: hiçbir politika uzun bir sakin diziye ulaşmasın; Campaign Rules'daki ölçüm disiplininin aynısı.
4. **Final de bir son değil.** Final sonrası serbest ticaret kuyruğu kıtlıkta rahat bir son olmamalı; dertler
   finalden sonra da büyümeye devam eder.

## Görsel dil (Y-C22'nin parçası)

Ders: umutsuzluk soluk, kontrastlı ve kirli bir paletle kurulur.

- Bugün `GrimGrade` ve kasvet kuralı (`docs/ui/STIL_REHBERI.md`, "Kasvet") zaten bu yönde: sıcak ışık dışında
  doygunluğu düşürüyor, gölgeyi soğutuyor.
- Uyarlama: kıtlığın derecesi palete bağlansın.
  - Şehrin hâli kötüleştikçe şehir resminin derecelendirmesi koyulaşsın (`CityFront.mood_for` zaten krizde
    doygunluğu düşürüyor; ölçeği kıtlığa bağla).
  - Yolda kıtlık bölgesine girildikçe zemin ve ağaç hattı solsun.
  - Kirli doku (pas, is, çamur) arayüz kitine değil dünyaya; arayüz okunaklı kalır.
- Erişilebilirlik sınırı: soluk palet okunabilirliği bozmaz (WCAG kontrast testleri sürüyor).

## Neye dokunur

| ders | mevcut sistem | yeni |
|---|---|---|
| ahlaki zorunluluk | EventQuality, LEAVE_BEHIND, yemek, varis, DiaryPanel | baskın seçenek raporu, feda kartları, şehre satma ikilemi |
| domino | RoadSignals, RoadDirector, Temperature, açlık, CampActionsPanel | zincir halkaları, yakılacak eşya eylemleri, dert cümleleri |
| çözülemeyen problem | POWER_SCALE, career_stage, bağlar, ağızlar | büyüme krizleri, simulate_career denge raporu |
| palet | GrimGrade, CityFront.mood_for, RoadStrips | kıtlık derecesine bağlı derecelendirme |
