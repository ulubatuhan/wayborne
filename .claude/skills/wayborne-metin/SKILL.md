---
name: wayborne-metin
description: Wayborne'un oyun içi metinlerini (olay kartı, NPC sözü, diyalog, kamp hikâyesi, günlük cümlesi, haber, yazıt, kitap parçası), lore ve tarihçe düzyazısını ve mağaza sayfası metnini yazarken ya da düzenlerken kullan. Yapay zekâ izlerini temizler, Türkçe ve İngilizce için denetim listesi verir.
---

# Wayborne metni yazmak ve düzenlemek

Lore'un içeriği için önce `wayborne-lore` becerisi; bu beceri metnin **sesi ve temizliği** için. İkisi birlikte
kullanılır.

## 1. Kimin ağzından

- Oyunda anlatıcı yok. Her metnin bir söyleyeni var: bir NPC, bir yoldaş, bir kitabın yazarı, bir yazıtı kazıyan
  el, kervanın defteri. Yazmadan önce söyleyeni seç ve onun bilmediğini yazma.
- Ses kültüre göre (`docs/lore/LORE.md` §7–§11):
  - Vaelghard resmî, kanun ve kayıt diliyle konuşur.
  - Vadi gündelik ve alaycıdır, eleştiriye alınır.
  - Gokyurt doğadan ve törelerden imgeyle konuşur.
  - Dağlı kısa ve serttir, gücü tartar.
  - Orsian hesap ve sözleşme diliyle konuşur.
  - Avuçiçi Kitap'tan alıntılar.
- Bir haber ya da olay her kültürde başka okunur; aynı olguyu iki kişiye aynı cümleyle söyletme.

## 2. Oyun metninin kuralları

- Sayı değil söz: etki önce sözle, sayı ikinci satırda (`docs/design_notes/dil_kilavuzu.md`).
- Seçenek düğmesi kısa bir eylemdir; bedeli ve kime düştüğü düğmede yazar (Event Engine Rules).
- Olaylar öldürmez; metin ölümü vaat etmez.
- Gerçek dinî imge, gerçek kişi ve yer adı yok; özel adlar ASCII.
- Bütün oyuncu metni çeviri anahtarıyla `data/locale/*.csv`'ye girer. `%s`/`%d` sırası her dilde aynıdır.
- Günlük cümleleri (`DIARY_*`) edebîdir, sayı taşımaz, adları `args` ile alır.

## 3. Yapay zekâ izlerini temizle

Yazdıktan sonra metni bu listeye karşı oku. Bir iz bulursan cümleyi yeniden kur; kelimeyi eş anlamlısıyla
değiştirmek izi silmez.

**Yapı izleri (her dilde):**
- Her şeyi üçlü saymak ("hem X, hem Y, hem de Z").
- Kalın başlıklı madde listesiyle düzyazı taklidi.
- Paragraf sonunda dersi açıkça söylemek ("Bu da gösteriyor ki…").
- Yapay kapanış: her sahnenin bir umut ya da hikmet cümlesiyle bitmesi.
- Atmosfer cümlesiyle açılış ("Rüzgâr uğulduyordu…") ve her paragrafın aynı uzunlukta olması.
- Tek çizgili anlatım: hiçbir şey ters gitmiyor, kimse yanılmıyor, kimse bir şeyi yarım bırakmıyor.
- Uzun tire (—) ile cümle bağlamak. Türkçede virgül, iki nokta ya da yeni cümle kullan.

**Türkçe izler:**
- "Adeta", "bir nevi", "âdeta bir…", "derin bir nefes aldı", "gözleri parladı", "kalbi hızla çarpıyordu",
  "sessizlik çöktü", "unutulmamalıdır ki", "sonuç olarak", "şunu belirtmek gerekir".
- Sıfat yığını ("kadim, gizemli ve karanlık"), çeviri kokan ilgi zamiri zinciri ("…olan ve …olan…").
- Edilgen yığılması ("yapılmaktadır, görülmektedir"); konuşan biri bunu söylemez.
- Her cümlenin "ve" ile bağlanması; Türkçe cümle fiille biter, kısa cümle sert durur.

**İngilizce izler (çeviri ve mağaza sayfası için):**
- "delve", "tapestry", "testament to", "in a world where", "it's worth noting", "navigate", "embark",
  "a symphony of", "not just X but Y", "whispers of".

**Kendine sor:**
- Bu cümleyi o kişi gerçekten böyle söyler miydi?
- Bir ayrıntı yalnızca bu dünyaya mı ait (bir yer adı, bir mal, bir töre)? Değilse metin genel kalmıştır.
- Bir şey eksik, yarım ya da yanlış söylenmiş mi? Oyunda her anlatım yazarın hakikatinin eksik bir yorumudur.
  Çok derli toplu bir metin bu kurala aykırıdır.

## 4. Araç

`anti-ai-writing` eklentisi kuruluysa İngilizce metinlerde (çeviri, Steam sayfası, fragman metni) önce onun denetim
kipini çalıştır. Önerdiği değişikliği körü körüne uygulama: oyunun sesini ve lore'un kurallarını bozan öneri
atılır. Türkçe metinlerde bu becerinin listesi esastır; eklenti İngilizce odaklıdır.

## 5. Teslim

Metni kullanıcıya gösterirken yanına kimin ağzından olduğunu ve hangi anahtara gideceğini yaz. Kullanıcının onayı
gelmeden çok sayıda kartı CSV'ye işleme; kartlar 10'luk partilerle onaya gider (Y-E01).
