# Wayborne — Evren (Lore)

Bu belge oyunun içinde **bugün var olan** evren bilgisinin dökümüdür: kod, çeviri
dosyaları (`data/locale/*.csv`), olay kartları ve tasarım kuralları taranarak
çıkarıldı. Amaç, haritayı ve mekanikleri oturtmak için evreni tamamlarken neyin
zaten sabit olduğunu, neyin yalnızca ima edildiğini ve neyin hiç yazılmadığını
görmek.

Her bölümde üç işaret var:

- **[Kanon]** Oyunda oyuncunun gördüğü bir metin ya da kural. Değiştirmek kod/metin değişikliği ister.
- **[İma]** Oyunda doğrudan yazmıyor ama metinlerden ya da mekaniklerden çıkıyor. Senin onayını bekliyor.
- **[Boş]** Oyunun bu konuda hiçbir şey söylemediği yer. Doldurman gereken alan.

Zaman çizelgesi ayrı belgede: [TARIHCE.md](TARIHCE.md).

---

## 1. Tez: oyunun neyi anlattığı

**[Kanon]** Codex'in açılış cümlesi: *konu kervan değil, kervanı çeken insanlar ve onların aşınması.*
Bunu taşıyan kurallar:

- Oyuncu bir kervanı değil, bir kervanın **adını** taşır. Lider ölünce ad kıdemliye (ya da oyuncunun seçtiği kişiye) geçer; kervan dağılmaz. Ad kuşaktan kuşağa geçer (`lineage_generation`).
- Tek gerçek son, adı taşıyacak kimsenin kalmamasıdır. Zenginlik hiçbir şeyi bitirmez; eski "5000 altın" hedefi bu yüzden kaldırıldı.
- Kervanın defteri (`CaravanLedger`, oyunda "Waybook") hiçbir satırı silmez. Ölen ya da ayrılan kişinin adının üstü çizilir. Silinmiş ad hiç yaşamamış gibi okunur; üstü çizili ad oyuncunun kendi geçmişidir.
- Defterin ilk satırı hep **kurucudur**: oyuncunun devraldığı ad zaten başka birinin üstü çizili adıdır. Kampanyanın ilk metni bunu "babandan kalan tek vagon" diye anlatır.

**[Boş]** Kervan adlarının nasıl konduğu (aile adı mı, lakap mı, kurucunun adı mı) bir kural olarak yazılmadı.

## 2. Dünyanın adı ve ölçeği

- **[Boş]** Dünyanın, kıtanın ya da bölgenin adı yok. "Wayborne" oyunun adı, oyun içinde bir yer adı olarak geçmiyor.
- **[Kanon]** Harita beş şehir ve yedi yoldan oluşuyor (bkz. §4). Yolculuklar 3–8 gün sürüyor.
- **[İma]** Beş şehir daha büyük bir dünyanın bir köşesi: haber kartları "önünüzdeki bölgede iki beylik", liman tüccarları "her geminin taşıdığı dedikodu", mülteci kolonları başka yerlerden geliyor. Limanlar ve deniz var ama haritada liman şehri yok (bkz. §6, Liman kültürü).
- **[Boş]** Haritanın dışında ne olduğu, denizin nerede olduğu, kuzey/güney yönleri.

## 3. Coğrafya

**[Kanon]** Yollar beş arazi tipinden geçiyor ve arazi sırayla değişiyor (bozkırdan bir anda dağa atlamıyor):

| arazi | oyundaki adı |
|---|---|
| steppe | bozkır |
| forest | orman |
| lake | göl kıyısı |
| mountain | dağ yolu |
| marsh | bataklık |

**[Kanon]** Yol kenarında altı tür durak var, her birinin kendi olay kartı:

| durak | kart | ne anlatıyor |
|---|---|---|
| Köy (mezra) | Köyün Kapısında | Yaralı birini köyde bırakma kararı |
| Askeri Karakol | Sınır Karakolu | Belgelerinde "eksik bulmak isteyen" komutan |
| Maden | Göçük | Çöken galeri, ağızda bağıran kadınlar |
| Geçit | Güç Sınavı | Dağ kabilesinin bilek güreşi daveti |
| Yol Sunağı | Yol Kenarı Türbesi | Yosunlu taşlar, eski yolcuların adakları |
| Köprü | Çürük Köprü | Kararmış tahtalar, hızlı ırmak |

**[Kanon]** Hava: açık, yağmur, sis, fırtına; mevsimler fiyatları ve yürüyüşü etkiliyor (bal ve şarap hasadı sonbaharda, kışın kıtlık).

**[İma]** "Sınır karakolu" adı bir sınırın varlığını söylüyor ama hangi iki gücün sınırı olduğu yazılmadı.

**[Boş]** Dağ sırasının, ırmakların, gölün, bataklığın adları. Hangi yolun hangi araziden geçtiği şu an tohumdan (seed) üretiliyor, yazılmış bir coğrafya değil.

## 4. Şehirler

**[Kanon]** Beş şehir; ne ürettikleri ve ne aradıkları ekonominin temeli:

| şehir | kod kimliği | üretir | arar | not |
|---|---|---|---|---|
| **Karakonak** | `test_loc_a` | buğday, baharat | kürk, balık, şarap | Kervan kavşağı; haritanın merkezi, dört şehre de yolu var. (Yeni oyun rastgele bir şehirde başlar.) |
| **Kurtboğazı** | `test_loc_b` | işlenmiş kürk, bal | demir, baharat | Dağ geçidi. Haydutları "Dağ Haydutu" (daha ağır). Dağ arıcılığı. |
| **İpekevi** | `test_loc_c` | top kumaş, ipek | otacı iksiri, bal | Adı ipek ticaretinden. |
| **Demirkapı** | `test_loc_d` | demir, mücevher | buğday, ipek | "Demir kapı" — demircilik ve ince işçilik. Bölge haydutları "Silahlı Eşkıya" (garnizon bölgesi). |
| **Yeşilova** | `test_loc_e` | otacı iksiri, balık, şarap | kumaş, mücevher | Verimli kıyı ovası; iki ihracat malı. |

**[Kanon]** Yollar (gün, tehlike):

| yol | gün | tehlike |
|---|---|---|
| Karakonak – Kurtboğazı | 3 | %20 |
| Karakonak – İpekevi | 4 | %35 |
| Karakonak – Demirkapı | 6 | %50 |
| Karakonak – Yeşilova | 8 | %65 (en uzun, en tehlikeli) |
| Kurtboğazı – Demirkapı | 4 | %30 |
| İpekevi – Yeşilova | 5 | %40 |
| Demirkapı – Yeşilova | 3 | %25 |

**[Kanon]** Her şehirde aynı mekânlar: Pazar Meydanı, Tüccar Loncası, Taverna, Kervan Avlusu (Demirci dahil), Kilise, Terzi/Kıyafet Dolabı. Şehrin silüeti **ticaretten** doğmuş: sur, kapı, ambar, farklı yüksekliklerde bloklar.

**[Kanon — tasarım kuralı]** Ufukta ibadet yeri (kubbe, minare) yok. Denendi ve geri alındı: Wayborne'da böyle bir kurum tanımlanmadığı için oyunun kendi lore'unun dışından bir şey söylüyordu. Şehir ekranındaki kilise binası bu yüzden bir **çan kulesi**.

**[Boş]** Her şehrin kimin yönetiminde olduğu (beylik mi, lonca mı, serbest şehir mi), nüfusu, kuruluş hikâyesi, hangi kültürün ağırlıkta olduğu. Şehirler hiçbir kültüre bağlanmadı; beş kültür ile beş şehir arasında bire bir eşleşme yok.

## 5. Kurumlar ve güçler

**[Kanon]**

- **Tüccar Loncası** — Kontrat panosu, borç verme (kredi itibara göre), özel görevler, vagon bağışları. "Loncanın defteri" oyunun kendi dilinde bir şeyin resmî kaydı demek. Kampanyanın amacı "loncanın defterindeki bir satır olmaktan çıkıp kendi hanını kurmak".
- **Kilise** — Huy arındırma (yalnızca "taze" huylar), iki yaratılış efsanesini anlatıyor (§7). İbadet edilen bir tanrı adı yok.
- **Taverna** — Rota dedikodusu, ziyafet, tayfa toplama, huy arındırma (Kilise'den pahalı).
- **Şehir muhafızları** — Muhafız ve Muhafız Çavuşu. Onları yenmek itibar *kaybettirir*: yasayla dövüşmek haydutla dövüşmekle aynı şey değil.
- **Gümrük ve devriyeler** — Yol bariyerlerinde evrak isteyen memurlar, eşkıya temizleyen mızraklı devriyeler, askeri konvoylar.
- **Beylikler** — Haber kartlarında "iki beyliğin savaşı". Dünyanın siyasi birimi beylik.
- **Haydut kralı** — Bir yolu ele geçirip her kervandan haraç alan, silahlı tahsildarları olan bir güç.
- **Alacaklılar ve icra memurları** — Borç vadesi geçince atlı gelir, sonra memurlar.

**[İma]** Lonca beylikler arası (şehirler arası) bir kurum gibi davranıyor: haberi şehirden şehre taşıyor, her şehirde aynı defteri tutuyor.

**[Boş]** Beyliklerin adları ve sayısı; hangi şehrin hangi beyliğe bağlı olduğu; loncanın merkezi; kilisenin bir dini kurum mu yoksa iki halkın inancını barındıran ortak bir yer mi olduğu; haydut kralının kim olduğu.

## 6. Halklar ve kültürler

**[Kanon]** Beş kültür. Her birinin bir stat eğilimi, on altı kişilik bir ad havuzu ve tek bir mekanik ayrıcalığı var:

| kültür | kendi tanımı (oyundaki metin) | ayrıcalık |
|---|---|---|
| **Göçebe Boyları** | "Bozkırda doğdun; yol senin evin, kervan senin obandır." | Yolda günlük erzak %30 az |
| **Vadi Loncaları** | "Taş köprüler ve lonca defterleri arasında büyüdün; rakam senin dilin." | Pazarda %10 indirim |
| **Dağ Kabilesi** | "Geçitleri koruyan bir kabiledensin; kavga senin için pazarlıktan kolaydır." | Savaşta %15 fazla hasar |
| **Liman Şehri** | "Rıhtımda beş dil öğrendin; her geminin taşıdığı dedikoduyu bilirsin." | Taverna dedikodusu %40 ucuz |
| **Balıkçı Kasabası** | "Ağ onarmayı yürümeden önce öğrendin; sabır ve tuz senin sermayen." | Erzak alımı %25 ucuz |

**[Kanon]** Aynı haberi her kültür farklı okuyor (haber kartlarının kültüre göre metni). Bu, her halkın dünya görüşünün en net kaydı:

| | Savaş haberini nasıl duyar | Vebayı nasıl duyar |
|---|---|---|
| Göçebe | Otlak ve su kavgası, kaçırılan sürüler | Sürüler bile şehre yaklaştırılmaz; duvarlar onların geleneği değil |
| Vadi | Karışan defterler, yol kesen vergi tahsildarları — "geçici bir masraf kalemi" | Karantina, aksayan tedarik |
| Dağ | Yeniden alevlenen eski bir kan davası; "dağın kanunu böyle çözülür" | Bir arınma sınavı |
| Liman | Omuz silkme: "mallar yalnızca yol değiştirir" | Gemiler limana yanaşmıyor; deniz ticareti alışık |
| Balıkçı | Bir fırtına: dua et, doğru rüzgârı bekle | Deniz tanrılarının uyarısı |

**[Kanon]** Kültür bilgisi olay kartlarında da var: dağ kabilesinin bilek güreşi daveti (reddetmek utanç), vadi tüccarlarının hesap kavgası, liman dedikodusu, balıkçının nehir görünce eliyle ağ araması, yolda kendi halkından bir obaya rastlamak.

**[Kanon]** Stat eğilimleri (kısaca): Göçebe Bilgelik +1 (arazi ve yıldız okuma), Vadi İnanç −1 (dünyevi lonca hesabı), Dağ İnanç +1 (ayine bağlı kabile), Liman Bilgelik +1 (rıhtımın gördüğü çeşitlilik), Balıkçı İnanç +1 (fırtınaya karşı dua).

**[İma]** "Liman Şehri" bir kültür ama haritada liman yok. Ya liman şehirleri haritanın dışında, ya da beş şehirden biri (Yeşilova "kıyı ovası") limandır.

**[Boş]** Kültürlerin nerede yaşadığı (hangi şehir/arazi), birbirleriyle tarihleri, dilleri, yönetim biçimleri, ad havuzlarının dil kökeni.

## 7. İnanç ve efsane

**[Kanon]** Kilise iki yaratılış efsanesini **birlikte** anlatıyor, birini seçmiyor (hiçbir kültür oyunun "resmî" kültürü değil):

- **Dağın İlk Nefesi** (Dağ Kabilesi): Dünya ilk soluğunu dağların doruğunda aldı ve o nefes hâlâ orada — rüzgârda, ayinde, gücün kendisinde. Güç sınavı bu yüzden yapılır: doruğa varmak o ilk nefese bir kez daha yaklaşmaktır.
- **Denizin İlk Gözyaşı** (Balıkçı Kasabası): Deniz ilk tanrının döktüğü gözyaşından doğdu ve hâlâ ağlar — dalgada, fırtınada, tuzda. Denize açılmadan dua edilir, çünkü sakinleştirilebilen tek şey budur: tanrının kederi.

**[Kanon]** Efsanelerin yoldaki karşılığı: **hacılar** doruğa ya da kıyıya yürür (kart: "Yolun Hacısı", sonra "Hacının Vedası" — kutsama). **Yol sunakları** yosunlu taşlar ve adaklardır. Balıkçılar "deniz tanrılarından" söz eder (çoğul).

**[Kanon]** İnanç bir stat: Ölümün Kıyısı'nda hayata tutunma iradesi. Huylar: Sarsılmaz İnanç / Sarsılmış İnanç.

**[İma]** İki efsane aynı dünyanın iki ucunu anlatıyor (doruk ve kıyı); "ilk tanrı" ifadesi tanrıların birden fazla olduğunu ima ediyor.

**[Boş]** Diğer üç kültürün (Göçebe, Vadi, Liman) inancı; tanrıların adları; kilisenin kuruluşu; ölülerin nasıl gömüldüğü (yalnızca yol kenarı mezarları ve bir mezar bekçisi kadın var — "bu yoldaki mezarları o sayarmış").

## 8. Kervan hayatı

**[Kanon]**

- **Tayfa ≠ parti.** Vagonları süren isimsiz tayfa (vagon başına iki kişi) savaşmaz ama ölünce deftere adıyla yazılır. Savaşan, isimli kişilerdir.
- **Görevler:** Muhafız, İzci, Levazımcı, Arabacı, Tellal, Otacı.
- **Savaş sınıfları:** Sıra Neferi, Sekban, Kırıkçı, Kalem Efendisi (tek şifacı).
- **Huylar:** her stat için bir erdem, bir kusur (Pazı Gücü / Cılız Kol, Basiretli / Saf, Güven Verici / İtici …).
- **Hayvanlar:** öküz (vagon çeker), at (lider biner), eşek ve yarım vagon, köpek (husky). Yolda kurt, ayı, yaban domuzu, geyik; kurt sürülerinin reisi Kırağı Kurdu (beyaz) ya da Zifir Kurdu (kara).
- **Ölümün kapıları:** savaş, açlık, vagonuyla birlikte kaybolmak. Olaylar öldürmez.
- **Kırgınlık:** aç bırakılmak, savaşın dışında tutulmak, ölüm görmek, liderlikte geçilmek — unutulmaz.
- **Defterin dili:** "katıldı", "ayrıldı", "öldü", "kervanı devraldı", "adı senden önce taşıdı"; ölüm sebepleri: haydutlara düştü, vahşi hayvanlara düştü, muhafızların elinde düştü, açlıktan öldü, vagonuyla birlikte kayboldu, yaralı hâlde bir köyde bırakıldı, kırgınlığını affetmeden gitti.

**[Kanon]** Mallar: buğday, top kumaş, demir, otacı iksiri, işlenmiş kürk, baharat, bal, ipek, mücevher, balık, şarap, erzak, bandaj. Para birimi oyunda **GG** kısaltmasıyla yazılıyor.

**[Boş]** GG'nin açılımı ve paranın kimin bastığı.

## 9. Dünyayı sallayan olaylar

**[Kanon]** Dört büyük dünya olayı yolda haber olarak duyuluyor ve haritayı haftalarca değiştiriyor:

| olay | etki |
|---|---|
| Bölgesel Savaş | Bir yolun tehlikesi artar; cepheden kaçan askerler, askeri konvoylar, mülteciler |
| Veba | Bir şehirde fiyatlar yükselir, halk tedirgin |
| Ticaret Fuarı | Bir şehirde mallar ucuzlar, tüccarlar akın eder |
| Haydut Haracı | Bir yolu haydut kralı tutar, tahsildarlar haraç ister |

**[Kanon]** Kıtlık zamanında pahalı satan kervanı mülteciler hatırlıyor ("Tanıyan Gözler") — dünya krizden kâr edeni unutmuyor.

**[Boş]** Bu olayların tarihsel örnekleri (geçmişte bilinen bir veba, bilinen bir savaş).

## 10. Görsel dil ve ton

**[Kanon]** Dünya mürekkep ve kâğıt diliyle çiziliyor: dört ton gölge, kervanın kendi hesap defteri gibi kurgulanmış arayüz (Waybook), deri cilt kapaklı bir defterle açılan ana menü. Mimari ticaret kökenli; sembol değil kütle. Ton: aşınma, yas, hafıza; kahramanlık değil.

---

## Doldurmak için açık sorular

Haritayı ve mekanikleri somut zemine oturtmak için en çok iş görecek sorular, öncelik sırasıyla:

1. Dünyanın / bölgenin adı ne, beş şehir bu dünyanın neresinde?
2. Kaç beylik var, beş şehir kime bağlı? (Haber kartlarındaki "iki beylik" kim?)
3. Beş kültür nerede yaşıyor? Her şehrin ağırlıklı halkı hangisi?
4. Liman ve deniz nerede? Liman kültürü haritada mı, dışında mı?
5. Tüccar Loncası ne zaman ve nerede kuruldu, kime hesap veriyor?
6. Kilise kimin kurumu? Göçebe, Vadi ve Liman halklarının inancı ne?
7. Haydut kralı bir kişi mi, bir unvan mı?
8. GG neyin kısaltması, parayı kim basıyor?
9. Arazinin adları: dağ sırası, ırmaklar, göl, bataklık.
10. Kurucunun ("babandan kalan tek vagon") kim olduğu her oyunda rastgele mi, yoksa sabit bir hikâyesi mi var?
