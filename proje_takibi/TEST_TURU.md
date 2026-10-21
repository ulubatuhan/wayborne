# Test turu: ekran ekran kontrol listesi

Bu liste `gorevler.json`'daki **test bekliyor** görevlerinden üretildi (`proje_takibi/referans/test_turu_uret.py`).
Kod yazıldı ve otomatik testlerden geçti; eksik olan **sizin gözünüzün** onayı. Her madde: nereye gidilir, ne görülmeli, bozuksa ne not edilir.

**Nasıl çalıştırılır:** depoyu klonlayın (Git LFS kurulu olsun), `project.godot`'u Godot 4.2.2'de açın, ilk açılışta içe aktarma bitince
editörü kapatıp bir kez daha açın, Play'e basın. Geliştirici paneli: **F1** (saat/soy gibi şeyleri değiştirir). Defter: **L**, harita: **M**,
emir paneli: **F2**, yardım: **F3**, Durum sekmesi: **Tab**.

Bir maddeyi onayladığınızda bana 'X tamam' demeniz yeter; ben kaydı 'bitti' yaparım. Bozuksa maddenin yanına ne gördüğünüzü yazın.

## 1. Ana menü ve yeni oyun

- [ ] **Y-D01** Kader Modu (ironman) ve açık zorluk ayarları
  - Nereye: Ana menü → Yeni Soy. Açılan ekranda zorluk bölümüne bak.
  - Görmeli: Kader Modu seçeneği ve üç açık ayar (ölümcül vuruş direnci, açlık hasarı, olay sertliği) yazıyla görünür; Standart seçiliyken eskisi gibi oynanır. Kader Modunda oyun içi menüde elle kayıt kapalı ve nedeni yazıyor.
  - Bozuksa: Gizli bir zorluk ya da nedensiz kilitli düğme
- [ ] **Y-D03** Soy mirası: kervan bitince ne kalır
  - Nereye: Bir oyunu bitir (ya da DevPanel F1 ile soyu bitir) → yeni oyun.
  - Görmeli: Önceki soyun mezarları yola/haritaya soluk döner, itibarın bir payı gelir, deftere eski soyun adı yazılır. `user://lineage_archive.json` oluşur.
  - Bozuksa: Mezarlar hiç görünmüyor ya da itibar sıfırlanmıyor
- [ ] **Y-A01** Oyun vaadini yaz ve belgelere işle
  - Nereye: Doküman kontrolü: `CLAUDE.md` en üstü.
  - Görmeli: Vaat cümlesi ve dört sütun yazılı. Cümle sizin sesinizle uyuşuyor mu? Uyuşmuyorsa değiştirin (kutu 'öneri, onay bekliyor' diyor).
  - Bozuksa: Cümle size yabancı geliyor

## 2. Şehir ekranı ve mekânlar

- [ ] **9.3** CityFront durum varyantları
  - Nereye: Bir şehre gir; sabah/gündüz/akşam/gece için DevPanel F1 ile saati değiştir.
  - Görmeli: Şehir önü resmi saate göre değişiyor, şehir adı ve ihtiyaç levhaları okunuyor.
  - Bozuksa: Saat değişse de resim aynı
- [ ] **N33** Yerleşim menülerinin gün evresi varyantları: sabah, gündüz, akşam, gece
  - Nereye: Pazar, lonca, taverna, han, kilise ekranlarını sırayla aç (saat değiştirerek).
  - Görmeli: Her mekânın arka planı günün evresine uyuyor; geçişte kesilme/titreme yok.
  - Bozuksa: Bir mekân hep aynı evrede kalıyor
- [ ] **9.4** Mekân ekranları
  - Nereye: Şehirden sırayla: Pazar, Lonca, Taverna, Han, Kilise, Terzi, Kıyafet Dolabı.
  - Görmeli: Hepsi aynı görsel dilde (koyu masa, ince çizgili paneller); metin okunur; geri düğmesi her zaman görünür.
  - Bozuksa: Gri/kutu ekran, taşan yazı, ulaşılamayan geri düğmesi
- [ ] **9.12** Kilise ve mezarlık arka planı
  - Nereye: Kilise → mezarlık bölümü; ölüm olmuşsa 'nöbet' hâli.
  - Görmeli: Mezarlık arka planı iki hâlde (sakin / nöbet) görünüyor.
  - Bozuksa: Arka plan boş ya da yanlış hâl
- [ ] **12.2a** Şehir kapısı görünümü çok kötü ("rezalet"), baştan tasarlanmalı
  - Nereye: Şehir kapısı: yola çıkarken ve şehre varırken kapıyı izle.
  - Görmeli: Kapı sur geçidi olarak çizili (düz renk kutu değil); kanat lider yaklaşınca kalkıyor.
  - Bozuksa: Düz dikdörtgen ya da kanat takılıyor
- [ ] **Y-C16** İşe almayı zorlaştır ve kişileştir
  - Nereye: Taverna/Meydan/Lonca → işe alım panosu (birkaç şehirde).
  - Görmeli: Pano çoğu zaman 1-2 kişi; her adayın neden geldiği yazıyor; savaş/veba haberinde bir kişi eksik; fiyatlar önceki sürümden pahalı.
  - Bozuksa: Pano hep dolu ya da adayın hikâyesi yok
- [ ] **Y-C10** Fiyat defteri: bilgi eskir, söylenti yanıltır
  - Nereye: Pazar: bir şehre ilk varışta ve 20+ gün sonra komşu fiyatlarına bak; taverna'da sohbet et.
  - Görmeli: Gördüğün fiyatların yanında 'kaç gün önce' yazıyor, 20 günden eskiler soluk. Söylenti bazen yalan çıkıyor.
  - Bozuksa: Tarihsiz fiyat ya da hep doğru söylenti
- [ ] **Y-C11** Gizli fiyat katmanlarını görünür kıl
  - Nereye: Pazar satırının üstüne gel.
  - Görmeli: Fiyat satırında kısa etiketler (mevsim, arz baskısı, haber vb.), üstüne gelince katman başına bir cümle.
  - Bozuksa: Fiyat değişti ama nedeni yazmıyor
- [ ] **Y-C19** Mal çeşitliliği: bozulan, kaçak, nadir
  - Nereye: Pazar: balık, kaçak tuz ve mühür alıp satmayı dene; 20+ adet toptan al; aldığın şeyi hemen geri sat.
  - Görmeli: Balık yolda bozuluyor; kaçak tuz yalnız han'da alınıyor; toptan alımda indirim; aynı ziyarette geri satış alış fiyatının en çok %90'ı.
  - Bozuksa: Alıp aynı yerde satarak kâr edebiliyorsun
- [ ] **Y-C02** Dinamik kontratlar ve yeni kontrat ekranı
  - Nereye: Tüccar Loncası → kontrat panosu (iki şehirde karşılaştır).
  - Görmeli: Pano her varışta farklı 4-7 ilan; teslimat, refakat, yolcu, kaçak yük türleri; acil olanlar kısa süreli ve daha yüksek ücretli.
  - Bozuksa: Her seferinde aynı ilanlar
- [ ] **Y-C05** Sakatlık, hastalık, hekim ve ilaç stoğu
  - Nereye: Kilise → hekim (yaralı/hasta bir yoldaşla; veba şehrine varış).
  - Görmeli: Hekim altın + şehrin ilaç stoğundan bir birim harcıyor; stok yoksa kilitli ve nedeni yazıyor. Veba şehrine varışta bulaşma olabiliyor.
  - Bozuksa: Stok bitince bile iyileştiriyor
- [ ] **Y-F04T** Vagon atölyesi ekranını özelleştir
  - Nereye: Bir vagona yürü/tıkla (hub'da vagon etkileşimi) → atölye.
  - Görmeli: Vagonun kendi yükü ve tarif listesi; yapılamayan tarif nedeniyle kilitli; başka vagondaki malzeme sayılmıyor.
  - Bozuksa: Tarif başka vagonun malzemesini kullanıyor
- [ ] **Y-F03** Atölye ve vagon envanterini anlamlandır
  - Nereye: Atölyede her tarifi bir kez yap (sargı, branda onarımı, kürk şapka, balık yağı, meşale).
  - Görmeli: Her ürünün bir kullanım yeri var (sargı savaşta/kampta, yağ fenerde, meşale gece yürüyüşünde).
  - Bozuksa: Üretilip hiçbir işe yaramayan eşya

## 3. Karakter, kadro ve defter kartları

- [ ] **9.6** Karakter ve stat ekranı
  - Nereye: Karakter ekranı (kadrodan bir kişi).
  - Görmeli: Stat ve yetkinlik bölümü yeni görsel dilde; sekiz stat okunuyor; kıyafet önizlemesi yanında.
  - Bozuksa: Taşan satır, kesik yazı
- [ ] **9.7** Roster kartı ve seviye rozeti
  - Nereye: Kadro (party) ekranı ve yol altındaki Kadro sekmesi.
  - Görmeli: Kişi kartında seviye rozeti net; kart içeriği kesilmiyor.
  - Bozuksa: Rozet okunmuyor
- [ ] **Y-F09** Görevler: öncü, ortancı, artçı; sınıflar ayrı
  - Nereye: Karakter ekranı → görev ata (öncü / ortancı / artçı).
  - Görmeli: Üç rol var (altı eski görev bu rollerin altında etki olarak duruyor); sınıf görev gücünü çarpmıyor; eski kayıt yüklenince roller doğru dağılıyor.
  - Bozuksa: Eski kayıtta görev kaybolması
- [ ] **Y-C17** Yoldaşın kendi hikâyesi ve ilişkileri
  - Nereye: Yoldaşın karakter ekranı; kampta bağ yüksekse kamp hikâyesi.
  - Görmeli: Her yoldaşın geçmişi ve kişisel hedefi (tanıdıkça) yazıyor; kamp hikâyesi üç bölüm; üçüncüsü (sır) en ağır kırgınlığı hafifletiyor.
  - Bozuksa: Hikâye hiç açılmıyor
- [ ] **Y-F01** Moral ve takat: kervanın nefesi, ama takat bedende kalır
  - Nereye: Yolda hızlı tempo, gece yürüyüşü, kamp; karakter kartında takat.
  - Görmeli: Her kişinin yorgunluğu ayrı; en yorgun kişi kervanın takatini bağlıyor ve adı yazıyor; kamp -30, şehir -60.
  - Bozuksa: Yorgunluk hızı değiştiriyor (değiştirmemeli)

## 4. Planlayıcı ve dünya haritası

- [ ] **Y-F10** Tehlikenin dökümünü göster
  - Nereye: Şehirden yol seçip planlayıcıyı aç.
  - Görmeli: Tehlike yüzdesinin dökümü: taban, yol durumu, dünya olayı, zamanla büyüme satırları.
  - Bozuksa: Tek bir sayı, nedensiz
- [ ] **Y-B13** Aynı rotada farklı yol: mevsim ve kestirmeler
  - Nereye: Aynı rotayı farklı mevsimlerde planla; 5+ günlük rotada kestirme seç.
  - Görmeli: İlkbaharda bataklık, yazın kuruma, kışın dağda yavaşlama; kestirme -%20 gün ve tehlike +; erzak rezervi buna göre.
  - Bozuksa: Erzak kestirmede yetmiyor
- [ ] **8.5** Yazı ile yolun çakışmasını gider
  - Nereye: Haritayı aç (M) ve kenti/yolları gez.
  - Görmeli: Kent adlarının altında yol çizgisi okumayı bozmuyor; adlar IM Fell yazı tipinde ve okunur.
  - Bozuksa: Yazı yol çizgisine biniyor
- [ ] **8.7** Boğaza ad ver
  - Nereye: Haritada boğazı bul.
  - Görmeli: Boğazın kesin bir adı var (geçici 'Kesgrav Boğazı' kalmamış olmalı; ad lore'a uyuyor mu?).
  - Bozuksa: Yer tutucu ad
- [ ] **8.10** Harita saate göre kararıp aydınlansın (gündüz, akşam, gece)
  - Nereye: Haritayı gündüz/akşam/gece aç (saat değiştir).
  - Görmeli: Harita akşam sıcak, gece mavi-gri kararıyor; yazı her saatte okunuyor.
  - Bozuksa: Gece harita okunmaz oluyor
- [ ] **8.11** Şehirlerde ve yerleşimlerde küçük ışıklar; akşam ve gece hafifçe parıldasın
  - Nereye: Haritayı akşam/gece aç, yakınlaş.
  - Görmeli: Şehir ve yerleşimlerde küçük ışıklar akşam belirir (şehir 6-12, kasaba 3-5, köy 1-2, harabede yok); yakınlaşınca boyutları sabit.
  - Bozuksa: Işık harabelerde de var ya da hiç yok
- [ ] **Y-G09** Haritada kervanın mürekkep izi
  - Nereye: Bir sefer bitir, haritaya bak.
  - Görmeli: Bitmiş yolun ince mürekkep izi ve kamp yerleri haritada kalıyor.
  - Bozuksa: İz yok ya da kayıttan yüklenince kayboluyor
- [ ] **N29** Vadiye özgü yeşil çayır biyomu
  - Nereye: Vadi şehri çevresindeki yola çık.
  - Görmeli: Vadiye özgü yeşil çayır katmanı (kuru ot değil); biyom geçişi yumuşak.
  - Bozuksa: Vadi hâlâ kuru bozkır
- [ ] **N30** Bozkırda yol durakları arasını aç
  - Nereye: Bozkırdan geçen uzun bir yola çık.
  - Görmeli: Duraklar arası en az 6 gün; 35 günlük yolda 5 durak yok.
  - Bozuksa: Durak peş peşe

## 5. Yol: yürüyüş, figürler, kamp

- [ ] **10.1** Binici atın biraz fazla önünde oturuyor, çok az geriye alınmalı
  - Nereye: Yola çık, atlı lideri yandan izle.
  - Görmeli: Binici atın sırtında biraz geride, eğerin üstünde oturuyor; dönüşte de aynı.
  - Bozuksa: Binici atın boynunda/önünde
- [ ] **10.2** At üstündeki binici yürür gibi kol sallamaya devam ediyor
  - Nereye: Yürürken liderin kollarına bak.
  - Görmeli: Atlı lider yürür gibi kol sallamıyor; kollar sakin (oturma/ride dinlenme karesi).
  - Bozuksa: Kollar sallanıyor
- [ ] **10.4** Vagonu çeken hayvanlar vagona bağlı görünmüyor
  - Nereye: Vagonu çeken öküze bak.
  - Görmeli: Çeki oku öküzün boynuna uzanıyor, boyunduruk öküzün üstünde çizili; öküz vagona bağlı okunuyor.
  - Bozuksa: Öküz vagondan kopuk
- [ ] **12.2b** Yol üstündeki kule (durak), kamp kurulduktan sonra kadrajdan bir anda kaçıyor
  - Nereye: Bir yol durağının (kule vb.) yanında kamp kur.
  - Görmeli: Kamp başlayınca durak kadrajdan kaçmıyor, yerinde duruyor.
  - Bozuksa: Durak bir anda uçuyor
- [ ] **12.2c** Kamp: karakterler ateşe çok yavaş yürüyor (3x'te bile); ateşe varana kadar sabah oluyor; ateş ilk varan kişiyle yansın
  - Nereye: Akşam kamp kur; ateşe yürüyüşü izle (1x hızda).
  - Görmeli: Herkes en çok ~3 sn'de ateşe varıyor; kamp süresi herkes oturunca başlıyor; sabah olmadan ateşteler.
  - Bozuksa: Yürüyüş uzun sürüyor, sabah oluyor
- [ ] **12.2e** Yol sahnesi estetik olarak güzel değil; her detayı yeniden tasarla: çimen, yol, arka plan, güneş
  - Nereye: Yol sahnesini gündüz/akşam/yağmurda izle.
  - Görmeli: Çimen, yol, arka plan ve ışık tek prodüksiyon gibi; zemin kaymıyor, yol ortada.
  - Bozuksa: Yol 'Excel gibi' ya da zemin kayıyor (kararını yaz: yeniden tasarım gerekir mi?)
- [ ] **Y-B09** Yolu dolu yap, sonra hızlandırmayı kaldır
  - Nereye: Yolda bir süre bekle ve hızlandırma düğmesini ara.
  - Görmeli: Hızlandırma yok (yalnızca 0.5x ve 1x); yol boş gelmiyor: yaklaşık 60-90 sn'de bir karar ya da bilgi var.
  - Bozuksa: Boş sessiz dakikalar
- [ ] **N23** Eski HUD parçalarını kaldır
  - Nereye: Yolda eski HUD parçalarını ara.
  - Görmeli: Eski üst/alt bar kalıntısı yok; yalnızca gösterge plakası ve kontrol paneli var.
  - Bozuksa: Çift gösterge, üst üste binen yazı
- [ ] **5.1** `_process` döngülerinin gereksiz çalışmasını durdur
  - Nereye: Menüde, şehirde, yolda 2-3 dakika dur; kumanda ve sahne geçişlerini dene.
  - Görmeli: Ortam animasyonu görünmezken çizilmiyor; terazi dengedeyken titremiyor; kumandada her şey çalışıyor; sahne geçişi bozulmuyor.
  - Bozuksa: Kumanda ya da geçiş bozuldu

## 6. Yol: insanlar, işaretler, hava, gece

- [ ] **R0** Altyapı
  - Nereye: Lideri bir yoldaşın yanına yürüt ve bekle.
  - Görmeli: Yoldaşın başında kısa söz balonu; satır log'a da yazılıyor; aynı anda en çok iki balon.
  - Bozuksa: Balon çıkmıyor ya da üst üste biniyor
- [ ] **Y-B01** Yol önerilerini (R0–R1) ana iş olarak uygula
  - Nereye: Birkaç gün yürü; farklı yoldaşlarla yan yana ol.
  - Görmeli: Konu seçimi: kırgınlık > stres > geçmiş > görev > kültür > hava > sohbet; aynı konu birkaç gün dinleniyor.
  - Bozuksa: Hep aynı cümle
- [ ] **R1** İnsanlar
  - Nereye: Kampta hikâye (bağ yüksek) ve dostluk/rekabet.
  - Görmeli: Dostlar kolonda yakın yürür, rakipler uzak; sıkıntılı biri bazen kendi başına bir şey yapar (ekmeğini paylaşır, dua eder).
  - Bozuksa: Kimse hiç kendi kendine davranmıyor
- [ ] **Y-B02** Yol yönetmeni: gerilimi kervanın durumuna göre ayarla
  - Nereye: Uzun bir yolda 'sessiz' günler ve ağır bir karttan sonraki günü izle.
  - Görmeli: Sessiz günler birikince kart ihtimali artıyor; ağır karttan sonra rahatlık; gece işaretler sıklaşıyor (ateş/nöbet/fener bunu azaltıyor).
  - Bozuksa: Üç sessiz gün arka arkaya ya da iki ağır kart arka arkaya
- [ ] **Y-B03** İşaretleri bulmacaya çevir: belirsizlik ve bedel
  - Nereye: Yolda duman/gıcırtı/arkada kuş gibi işaretlere git ve görmezden gel (iki ayrı sefer).
  - Görmeli: Gidince gerçek yüzü ve küçük ödülü açılıyor; görmezden gelince o gerçeğin bedeli ödeniyor; bazı gerçekler bedelsiz.
  - Bozuksa: İşaretin türü cevabı veriyor
- [ ] **Y-B04** Dikkat bölgelerine yeri doldurulamaz roller ver
  - Nereye: Rol sahibi (öncü/ortancı/artçı) varken lideri başka bölgede tut.
  - Görmeli: Rol sahibi kendi bölgesindeki işareti liderin yerine yakalayabiliyor (saatlik ~%3.5).
  - Bozuksa: Rol hiçbir fark yaratmıyor
- [ ] **Y-B05** Havaya karşı küçük kararlar
  - Nereye: Farklı havalarda emir panelindeki küçük kararlar.
  - Görmeli: Her hava 1-2 tek tıkla karar (erken çık, yağmurdan önce it, çamur kestirmesi, fener, fırtınada sığın); sonuçları yazılı.
  - Bozuksa: Karar etkisiz ya da erzak sözü bozuluyor
- [ ] **Y-C20** Fener ya da meşaleyle gece yürüyüşü
  - Nereye: Geceye kadar yürü; fener/meşale yak ve yakma.
  - Görmeli: Işıksız gece takat ve tehlike bedeli; fener gece 1 yağ, meşale 2; liderde parıltı.
  - Bozuksa: Gece bedelsiz
- [ ] **R4** Risk
  - Nereye: Nehir geçidi olan bir yol (ford) ve gece yürüyüşü.
  - Görmeli: Su seviyesi (düşük/orta/yüksek) kartta; doğru geçiş seçeneği açık, yanlış olanlar nedenle kilitli; kimse ölmüyor, vagon kaybolmuyor.
  - Bozuksa: Geçişte ölüm/vagon kaybı
- [ ] **Y-B10** Başka kervanlarla karşılaşma
  - Nereye: Yolda başka kervanlarla karşılaş (birkaç sefer).
  - Görmeli: Askerî konvoy (borç/arama), mülteci (yoldaş), hacı, rakip tüccar (bilgi/iftira) kartları.
  - Bozuksa: Karşılaşma hiç olmuyor
- [ ] **Y-B06** Yolda erzak kaynağı: av, toplama, köy
  - Nereye: Yolda av, köy durağı ve toplama.
  - Görmeli: Vahşi hayvan zaferi +10 erzak; köyde birim fiyat şehirden pahalı; toplama +10 erzak ve +1 gün.
  - Bozuksa: Erzak bedava geliyor
- [ ] **Y-B07** Sofrayı anlamlı karar yap: erzak türleri
  - Nereye: Akşam sofra panelini aç (şarap/bal/balık varken).
  - Görmeli: Çeşni yalnızca panel açıkken teklif ediliyor; erzak payı ve planlayıcının sözü değişmiyor.
  - Bozuksa: Standing order çeşni harcıyor
- [ ] **Y-B12** Kampı karar anına çevir; ertesi günün dizilişi
  - Nereye: Kampta nöbet ve formasyon.
  - Görmeli: Öncü +1 stres/gün; nöbet ertesi günün tehlikesini düşürüyor; akşam en çok iki eylem.
  - Bozuksa: Kamp panelinde sıkışma
- [ ] **Y-B08** Günün satırı: akşam kampında defter cümlesi
  - Nereye: Akşam kampında 'günün satırı' (defter cümlesi).
  - Görmeli: O günün en ağır olayına göre üç cümle sunuluyor; birini seçiyorsun ya da hiçbirini; yazmıyorsun.
  - Bozuksa: Cümleler sayı içeriyor ya da yazı kutusu çıkıyor
- [ ] **Y-B11** Yolun hafızası: mezarlar, enkaz, eski kül
  - Nereye: Biri öldükten/vagon kaybından sonra o yoldan tekrar geç.
  - Görmeli: Mezar, kayıp vagonun enkazı, kamp külü yolda görünüyor; geçerken log'a satır (lider önde ise ad ve neden).
  - Bozuksa: Anıtlar yerinde değil/yönden bağımsız kayıyor
- [ ] **R2** Hafıza
  - Nereye: Yukarıdaki üç madde birlikte: mezar + gün satırı + kamp külü.
  - Görmeli: Defter ve yol aynı hafızayı gösteriyor.
  - Bozuksa: Defterde olup yolda görünmeyen
- [ ] **Y-F05** Tüccar mizacını yola bağla
  - Nereye: Tüccar refakat al; yolda kartlar.
  - Görmeli: Hırsız tüccar gece kaçıyor, çaresiz olan tehlikede dönmek istiyor, kinci kavga çıkarıyor, sadık erzak paylaşıyor.
  - Bozuksa: Tüccar hiç tepki vermiyor
- [ ] **Y-C15** Orta ve geç oyuna yeni tehditler
  - Nereye: Orta ve geç oyunda (10. ve 25. sefer sonrası) kart dağılımı.
  - Görmeli: Pusu, savaş/veba/haraç haberleri, rakip kervan ve gümrük sıklaşıyor.
  - Bozuksa: Oyun hiç sertleşmiyor
- [ ] **Y-F07T** Büyücüyü nadir olay düşmanı olarak bağla
  - Nereye: Nadir olay: haydut büyücü (zor bulunur).
  - Görmeli: Çok nadir ve bir kez çıkıyor; tehlikeli yolda; savaşta ilk yıkıcı büyü.
  - Bozuksa: Her sefer çıkıyor
- [ ] **Y-D06** Kırılma: davranışla yaşatılan olay
  - Nereye: Kırılmış bir yoldaşla bir sefer.
  - Görmeli: Dört kip (öne atılır, alay çeker, reddeder, yakındakine saldırır) son kötü huya göre; ekran efekti yok; yolda kırılma kartı.
  - Bozuksa: Kırılma sadece sayı
- [ ] **Y-H04** Hiçbir ekranda sıkışma kalmasın
  - Nereye: Her paneli aç ve Esc ile çık; karar panellerinde Esc'e bas.
  - Görmeli: Hiçbir ekranda sıkışma yok: paneller Esc'e yanıt veriyor; karar panelleri (devralma, kader) yutuyor.
  - Bozuksa: Çıkılamayan ekran

## 7. Savaş

- [ ] **Y-H05** Savaşa vuruş hissi
  - Nereye: Savaşta vuruş, kritik ve öldürme anları.
  - Görmeli: Kritikte sahne hedefe yaklaşıyor ve defter satırı çıkıyor; öldürme anında kısa duraklama sonra düşüş; vuruş/kritik/öldürme sesleri çeşitli ve perde oynuyor.
  - Bozuksa: Ses hep aynı ya da yakınlaştırma takılıyor
- [ ] **Y-C07** Savaştan bedelli geri çekilme
  - Nereye: Dar durumda geri çekil.
  - Görmeli: Savaş paneli geri çekilmeyi teklif ediyor: yükün üçte biri, bir vagon feda (enkaz yolda kalır) ya da artçı; savaş kaybı cezası yok, hafif moral kaybı.
  - Bozuksa: Geri çekilme bedelsiz ya da seçenek çıkmıyor
- [ ] **Y-C08** Düşmanlara kişilik ver
  - Nereye: Haydut reisi, kurt ve muhafızla birer savaş.
  - Görmeli: Reis liderine, kurt en yaralıya saldırıyor, muhafız ölümün kıyısındakini bitirmiyor.
  - Bozuksa: Hepsi aynı hedefi seçiyor
- [ ] **Y-C03** Ganimet: eşya, kıyafet, sarf, nadir bulgu
  - Nereye: Zaferden sonra ganimet ekranı.
  - Görmeli: Düşman türüne göre ganimet listesi; mal/kıyafet/ekipman ilgili depolara düşüyor.
  - Bozuksa: Ganimet hep aynı
- [ ] **Y-C04** Sarf malzemesi ve yolda tedavi
  - Nereye: Sargı ve iksirle savaş içi tedavi; kampta yara sarma.
  - Görmeli: Sargı +8 can ve kanamayı keser, iksir +12 can; kullanılanlar kargodan düşüyor; kamp sargısı çift bakım.
  - Bozuksa: Eşya düşmüyor

## 8. Defter ve paylaşım

- [ ] **9.11** Waybook ve defter
  - Nereye: L ile defter. 'Düşenler' sayfası.
  - Görmeli: Kurucu ve ölüler rütbeye göre mezar işaretiyle listeli; dinî simge yok.
  - Bozuksa: Çizgiler okunmuyor
- [ ] **DFT1** Defter sayfası okunur olsun (cetvel çizgileri)
  - Nereye: Defter sayfasında cetvel çizgilerini oku.
  - Görmeli: Sayfa metni cetvel çizgilerine oturuyor ve okunur.
  - Bozuksa: Satırlar çizgiye binmiş
- [ ] **Y-E07** Paylaşılabilir defter sayfası ve güncel Codex
  - Nereye: Defterde 'sayfayı kaydet' düğmesi.
  - Görmeli: Sol sayfa soyun özetine dönüyor ve PNG `user://defter_sayfalari/` altına yazılıyor; defter eski hâline dönüyor.
  - Bozuksa: Dosya yok ya da defter bozuk kaldı

## 9. Otomatik kanıtlı (gözle bakmanız gerekmeyen)

Bu görevlerin kabulü testle ya da belgeyle yapıldı. Onay vermeniz yeterli; itirazınız yoksa kapatırım.

- [ ] **1.4** Belgeleri temizle: Codex PDF Windows yazı tipleriyle yeniden üretildi; yasaklı sözcük taraması temiz.
- [ ] **1.5** Doğrulama: `git grep` yasaklı kelime taraması sıfır; kural `tests/test_naming_rule.gd` ile korunuyor.
- [ ] **4.3** Tekrarlanan yardımcıları birleştir: `reduce_motion` NodeUtil'de; autoload kopyaları bilerek bırakıldı.
- [ ] **4.4** Olay anahtarlarını açık yaz: Olay anahtarları açık yazılı (tarama testi geçiyor).
- [ ] **5.2** Mipmap'leri içe aktarma ayarıyla üret: Mipmap'ler `project.godot` içe aktarma ayarıyla üretiliyor (CI'de her doku için geçerli).
- [ ] **5.3** `BodyFrames` önbelleğine çıkarma politikası ekle: `BodyFrames` önbelleği LRU çıkarma politikalı (96 küme) ve ölçüm raporu var.
- [ ] **Y-A02** Dört tasarım sütununu yazıya dök: Görev şablonuna zorunlu 'Sütun' satırı eklendi.
- [ ] **Y-E03** Her kartta cazip ama riskli bir seçenek: 59 kart incelendi; 7 karta cazip-riskli zarlı seçenek eklendi.
- [ ] **Y-F11** CLAUDE.md'yi kayıpsız incelt: CLAUDE.md kayıpsız inceltildi; tarihçe `docs/history/` altında.
- [ ] **Y-J13** Yerelleştirme sırası ve terim sözlüğü: Çeviri sırası ve 50 terimlik sözlük yazıldı.
- [ ] **Y-G14** Tipografi birliği: IM Fell yazı tipi Türkçe harflerin hepsini taşıyor (ölçüldü).
- [ ] **Y-G15** Vagon ve kurt tek kaynaktan: Savaş kurdu kartın rengine çekildi; vagon zaten tek kaynak.
- [ ] **Y-K02** Otomatik ekran görüntüsü karşılaştırması: Otomatik ekran görüntüsü karşılaştırma aracı ve iş akışı hazır (rapor amaçlı).
- [ ] **N31** Oyun hissi incelemesi ve planı (6 alan): Oyun hissi incelemesi tamamlandı; alt görevler N31a-f açıldı.
- [ ] **N31a** Ölçüm: beat kaydı ve boş dakika raporu: Beat kaydı ve boş dakika raporu (`tests/simulate_road_beats.gd`); oyuncu ölçümü yalnız izinle.
- [ ] **N31b** Işık modeli ve sis şeridi koda: Işık modeli ve sis şeridi kodda.
- [ ] **N31c** Ses otobüsleri, çeşitleme, ayar kaydırıcıları: Ses otobüsleri, çeşitleme ve ayar kaydırıcıları: Ayarlar'dan müzik/efekt kaydırıcılarını deneyin (müzik yok, efektler ve rüzgâr var).

Toplam madde: 85.
