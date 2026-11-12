# Oyun testi 2026-11-12 — yönetici özeti

Dört sentetik profil, 15 koşu, her biri 4 saat eşdeğeri (60 saat). Oyunun kendi kuralları koştu; yol sahnesi
açılmadı, süre sayaçtır (`ALTYAPI.md`). Oyun kodu değişmedi.

1. **Büyüme oluyor ama tutmuyor; kadro hiç büyümüyor.** (IP-015 sonrası ölçüm.) 15 koşunun 13'ünde vagon 2'ye,
   üçünde 3'e çıkıyor; dört saatin sonunda yalnız dördünde 2'de kalıyor, kalanı 1'e düşüyor. Kadro ise hiç
   artmadı: 60 saatte **0 işe alım**, 102 kez "kese yetmiyor", 99 kez "vagonlarında yer yok". Vagon bir yere
   kadar alınabiliyor, insan alınamıyor.
2. **Acemi ilk yarım saatte açlıktan ölüyor ve nedenini gün olarak görmüyor.** 27 ölümün 23'ü açlık; 15 seferin 11'i
   33 günden uzun yola eksik erzakla çıkıldı. Planlayıcı eksiği birimle söylüyor.
3. **Erzak bitince karar da bitiyor.** 83 aç gece boyunca tek karar boş sofra; aynı isyan kartı 21 kez.
4. **İlk karar 7-11. dakikada** (hedef 3. dakika); ilk kâr iki profilde dört saatte hiç gelmedi.
5. **Ruh ve iz mimarisi kurulu ama oyuncuya ulaşmıyor.** 60 saatte 53 iz doğdu, 9'u döndü; 6 bedel ödendi; 24 kişinin
   21'i hiç hâl değiştirmedi. Tek çalışan kanal yankı (koşu başına 5-33). Sebep hacim: 101 kartın 14'ü iz bırakıyor.
6. **Borç büyüyor, hissi büyümüyor.** Sert profil 1006 borçla moral 100, stres 2. Kıtlığın kendisi ise geçiyor:
   okuyan her profil ilk çeyrek saatte dilenciliğe düştü ve her gece yiyecek aradı.
7. **Tekrar:** yol günlerinin %59-65'i olaysız (bu bilerek böyle), ama ardından gelen çoğu kez aynı pusu (%12-20).
   60 saatte kataloğun 66 kartı görüldü.
8. **Baskın bir sömürü bulunamadı.** Sömürücü profil 20-22 seferde 5-8 kârlı varış çıkarıyor ama borç 493-885
   arası; kese hiçbir koşuda kalıcı artıda değil. Zorluk yerinde; eksik olan zorluğun karşısında kazanılan bir
   şeyin görünmesi.
9. **Referanslarla açık yeni sistem değil, erişim.** Beş referansın his sütunlarının çoğu oyunda var; açıkların
   beşi "sistem var, ilk dört saatte görünmüyor" başlığında toplanıyor. Filmden tek yeni öneri çıktı.
10. **Kritik yol çizim.** 2058 saat (715 kalem, `envanter.py`'den sayıldı); haftada 15 / 30 / 45 saatle 1.0 sırasıyla
    2029, 2028 ortası, 2027 sonu. AI beyanını kaldıran öncelik 1 ise yalnız 292 saat: haftada 30 saatle Ocak 2027 sonu.
    Kod tarafı Dalga 1 olarak 14 iş kartına döküldü; üçü senin kararını bekliyor (K-03, K-04, K-05).

**Dalga 1 uygulandı (2026-11-12).** On dört iş bitti, yeniden ölçüldü: en çok görülen kartın payı %20'den
%9,1'e indi, doğan iz acemide 7'den 12'ye çıktı, açlıkta üç karar noktası oluştu, meşale ve büyüme bulguları
sürücü hatası çıktı. Tutmayan iki ölçüt ve nedenleri `08_dalga1_sonucu.md`'de.

Belgeler: `01` profiller ve günlükler · `02` retention · `03` umutsuzluk ölçümü · `04` referans açıkları ·
`05` hata listesi · `06` iş planı · `07` uygulama kartları · `08` Dalga 1 sonucu.

**Sınır.** Profiller sentetik; "bırakırdım" satırları ölçüm değil beyandır. Sekiz profil dörde indi, koşular
sırayla yapıldı. Ses, kumanda, yürüyüş ve dikkat işaretleri ölçülmedi; ekran olarak yalnız menü, yol, kart ve
savaş görüntülerine bakıldı.
