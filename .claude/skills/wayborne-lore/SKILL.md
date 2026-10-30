---
name: wayborne-lore
description: Wayborne'un evrenini (Sideria) yazmak ve büyütmek için kurallar ve yöntem. Lore ya da tarihçe yazarken, kullanıcının lore cevaplarını işlerken, yer/kişi/kurum adı koyarken, oyun içi metin (olay kartı, NPC sözü, kitap, yazıt, haber) yazarken ve lore soru defteri hazırlarken kullan.
---

# Wayborne lore'u yazmak

Bu beceri iki işi birlikte yapar: kullanıcının koyduğu kanonu **kayıpsız ve tutarlı** işlemek ve onun üstüne
**yaratıcı bağlar** kurmak. İkisi birbirine karışmaz: kullanıcının sözü kanondur, senin kurduğun her şey onay
bekleyen bir öneridir.

## 1. Önce oku

Lore'a dokunmadan önce bunların güncel hâlini oku; ezberden yazma:

- `docs/lore/LORE.md` (dünya ne) ve `docs/lore/TARIHCE.md` (ne zaman ne oldu): **tek çalışmanın iki yarısı**.
  Biri değişirse öbürü de güncellenir; çelişirlerse ikisi de yanlıştır.
- `docs/lore/SORULAR.md` ve `docs/lore/LORE_OZET.txt`: açık sorular ve soru defterine gömülen özet.
- Harita ve oyun verisi: `data/config/settlements.json` (27 yerleşim, bölge, tür, sur, mal, komşular),
  `tools/worldmap/atlas/places_v3.json` (adı konmuş bütün yerler, bölgeleri), `docs/lore/sideria_harita.jpg`.
- Oyunda zaten yazılı olanlar: `data/locale/*.csv` (olay kartları, kültür metinleri, kilise ekranı, haberler),
  `scripts/character/culture_catalog.gd`, `scripts/events/event_catalog.gd`.

Kullanıcının cevabı haritayla ya da oyun verisiyle çelişiyorsa sessizce birini seçme: **çelişki** olarak yaz.

## 2. Değişmez kurallar

**Kaynak işareti.** Her bilgi kaynağıyla yazılır:

| işaret | anlamı |
|---|---|
| **[Yazar]** | Kullanıcının sözü. Kanon. Özünü değiştirmeden, onun sözcükleriyle yakın yaz. |
| **[Oyun]** | Bugün oyunda yazılı (kart, metin, kural, veri). Değiştirmek kod ya da çeviri işi. |
| **[Harita]** | Onaylı harita v3 ve atlas. |
| **[Türetme]** | Senin bağlantın ya da çıkarımın. **Onay bekler**; reddedilirse silinir. |
| **[Çelişki]** | İki kaynak tutmuyor; karar kullanıcının. |
| **[Boş]** | Henüz kimse bir şey söylemedi. |

Onay bekleyenler her zaman ayrı bir listede de toplanır; kullanıcı onları tek tek onaylar ya da reddeder.
Onaylanan öneri **[Yazar]** olur.

**Anlatıcı yok.** Oyunda yazarın ağzından tek satır yoktur. Her oyun içi metin dünyanın içinden biri tarafından
söylenmiş ya da yazılmıştır: bir NPC, bir kitabın yazarı, bir yazıtı kazıyan el. Belgedeki "hakikat"
(öbürküler, kadim uygarlığın sonu, büyünün doğası) oyunda asla doğrudan doğrulanmaz.

**Tanrılar kanıtsız.** İnanç insanların yorumu ve ihtiyacıdır. Doğaüstü çok nadirdir ve insanın idrak
edemediğidir. Bir mucizeyi gerçekmiş gibi yazma; birinin onu nasıl anlattığını yaz.

**Adlar.**
- Özel adlar uydurmadır. Gerçek bir yeri, hanedanı, kişiyi, tarikatı ya da savaşı çağırmaz.
- Başka fantastik eserlerden alınmaz.
- Birbirine çok benzeyen iki ad olmaz.
- ASCII yazılır ve her dilde aynı kalır.
- Her bölgenin adları kendi dil tadını taşır: Vaelghard'ın resmi, sert sesleri; vadinin yumuşak, akan sesleri;
  göçebe ve dağ halkının Türkçe sesli adları.
- Yeni bir ad koymadan önce `places_v3.json`'da ve lore'da benzerini ara.

**Gerçek dinî imge yok.** Gerçek bir kutsal kitabın, peygamberin, sembolün adı ya da biçimi kullanılmaz: haç,
hilal, kubbe, minare, "Ahit"/"Tevrat" gibi adlar. Kilise binası bir çan kulesidir; mimari ticaret kökenlidir
(sur, kapı, ambar). Mezarda dinî simge yok.

**Depo kuralları.**
- Depo metinlerinde türün referans oyununun ve onun yerleşim teriminin adı geçmez; `tests/test_naming_rule.gd` yakalar.
- Lore belgeleri Türkçe yazılır, oyun içi metin çeviri anahtarı olarak girer (CLAUDE.md, Localization Rules).

**Oyunun tezi ve ilkesi.**
- **Konu:** kervanı çeken insanlar ve onların aşınması.
- **Vaat:** "Her karar yola bir iz, her ölüm deftere bir satır olur."
- **Dört sütun:** Yol yaşar, İnsanlar aşınır, Defter unutmaz, Ticaret bilgi oyunudur.
- **Kullanıcının ilkesi:** derinleşme, asla sadeleştirme.

Lore bir sistemi kesmez, ona derinlik verir.

## 3. Yaratıcı yöntem: bağ kurmak

Kanonu işledikten sonra boşlukları **bağ kurarak** doldur. Bir şey uydurmak yetmez; her yeni parça var olan
parçalara bağlanmalı.

1. **Her yeni bilgi en az iki şeye bağlanır.** Bir yer bir kuruma, bir kurum bir olaya, bir olay bir mala ya da
   bir mekaniğe. Hiçbir şeye bağlanmayan bir ayrıntı süstür; ya bağla ya bırak.
2. **Sonucu sür.** Bir gerçeğin ekonomideki, yoldaki, inançtaki ve kişilerdeki yankısını yaz.
   Örnek: "Ezmerak'tan geçen kervan en az bir öküz değerinde ticaret yapmak zorunda" kanonu şunları doğurur:
   Ezmerak'ın yerleşim önü pazar ağırlıklı olur, gümrük kartı orada sık çıkar, borçlu vadi şehirleri o yükü taşır.
3. **Aynı olayı üç ağızdan dinle.** Bir olay her kültürde başka anlatılır. Haber kartlarının kültüre göre
   metinleri bunun oyundaki karşılığıdır. Bir tarihî olayı yazarken en az iki kaynağın (resmî tarih, halk,
   düşman) ona ne dediğini düşün. Hakikat belgede, oyunda yalnızca yorumlar.
4. **Bir gizemi koru.** Her konunun cevaplanmamış bir ucu kalsın: kimsenin bilmediği, yalnızca yazarın bildiği.
   Öbürkülerin, kadim uygarlığın sonunun, Bekçi Kadın'ın oyunda doğrulanmaması kuraldır.
5. **Oyuna kapı aç.** Her bağın oyunda nereye dokunabileceğini **[Türetme — oyuna bağlanışı]** başlığıyla yaz:
   olay kartı, yol durağı, NPC sohbeti, okunabilir kitap, yazıt, eşya (tılsımlı takılar), haber, fiyat
   katmanı. Bunlar öneri; kod işi ayrı karar.
6. **Ölçeği koru.**
   - Kervan dünyası küçük insanların dünyasıdır. Krallar ve büyük olaylar uzaktan, haber ve dedikodu olarak gelir.
   - Doğaüstü nadirdir. Büyücü görmek bir olaydır.
7. **Tonu koru.**
   - Aşınma, yas, hafıza; kahramanlık değil. Kasvetli ama insani.
   - Bir halkı kötü yapma; her halkın öfkesinin bir sebebi, onurunun bir kaynağı var.

## 4. Kullanıcının cevaplarını işlemek

1. Cevabı tam oku; yazım hatalı adları kullanıcının niyetine göre düzelt ve düzelttiğini not et:
   "Tolyarin" haritada Tolvarin, "Ezmarek" Ezmerak, "Droskol" Droskal.
2. Kullanıcının bir cevapta düzelttiği eski bilgiyi **sil**, işaretleyip bırakma. Örnek: "doğuda göçebe yok,
   o bilgiyi sil".
3. Bir cevap başka bir soruyu da cevaplıyorsa onu da işle; hangi soruyu kapattığını yaz.
4. Cevabın yarım kaldığı yeri (cümle bitmemiş, ad verilmemiş) **[Boş]** bırak ve yeniden sor.
5. Kullanıcı "sen bir öneri yaz" dediyse en az iki öneri ve gerekçesini sun; birini seçme.
6. Cevap bir oyun değişikliği istiyorsa ("haritada adı olan her yer oynanabilir olmalı") bunu
   CLAUDE.md'nin Ana Hedefler listesine ve `proje_takibi/`ye yaz; lore belgesine yalnızca kararı geç.
7. Oyun verisiyle çelişen kanonu (bir yerleşimin bölgesi, malı, duvarı) **[Çelişki]** olarak yaz ve neyin
   değişmesi gerektiğini belirt: veri mi değişecek, lore mu esneyecek.

## 5. Çıktı

- `LORE.md` ve `TARIHCE.md` birlikte güncellenir; `LORE_OZET.txt` yalnızca geçerli bilgiyi taşır (soru
  defterine gömülür).
- `SORULAR.md`: cevaplananlar düşer, açık kalanlar ve yeni sorular girer.
- Sorular kullanıcıya **soru defteri** sayfası olarak gider (`tools/lore_soru_sayfasi.py`, cevaplar sayfanın
  `answers/<soru kimliği>` deposuna). Her soru:
  - kısa ve tek bir şey sorar;
  - neden sorulduğunu ve neye dokunacağını bir satırla söyler;
  - mümkünse seçenek verir;
  - haritada bir yere bağlıysa o yeri gösterir.
  Onay bekleyen öneriler de ayrı bir bölüm olarak orada onaylanır.
- Bitince ne değiştiğini kullanıcıya kısa söyle: kaç cevap işlendi, kaç öneri onay bekliyor, hangi çelişkiler
  kaldı.
