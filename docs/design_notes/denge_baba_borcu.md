# Babadan kalan borcun dengesi (Y-C14 ölçümü)

Tarih: 2026-10-19. `tests/simulate_career.gd`, 8 kervan, 40 sefer, üç politika.

## Ölçüm: ilk değerler (240 altın, 60 gün, %15 faiz, itibar -3 / dönem)

Kervan borcu 60 günde ödeyemiyor (başlangıç parası 250, ilk seferler zarar yazıyor); gecikmede her 10 günde %15
faiz ve -3 itibar işleyince borç 20. seferde 22 bin, 40. seferde milyonlara çıktı, itibar -17'ye indi (loncanın
kapıları kapandı) ve kampanya bölümleri 8/8'den 1/8'e düştü. Önceki baz (borçsuz): her bölüm her politikada 8/8.

## Karar

Aile borcu yumuşatıldı (`Debt.interest_rate`, `Debt.reputation_penalty`, kayıtlı): tutar 180, vade 120 gün,
gecikme faizi %4, itibar bedeli -1 (alacaklı akraba). Loncaya olan borcun sertliği (%15, -3) aynı kaldı: aile
borcunu ihmal eden kervan hâlâ ceza alır ama kariyeri kilitlenmez.

## Yumuşatmadan sonra: bölümler hâlâ kapanmıyordu, sebep borç değildi

Borç 58-240 arasında kaldı ama "İlk Yol" 8 kervanın yalnızca 4'ünde, final 1-2'sinde kapandı (baz: 7/8 ve 6/8).
Kervan kervan bakınca üç ayrı sebep çıktı; ikisi oyunun, biri ölçüm düzeneğinin:

1. **Oyun: eşiksiz ilanlar itibar eksiye inince de kapanıyordu.** `reputation < required_reputation` 0 eşikli ilanı da
   itibar -7'de kilitliyordu; kervan bir daha tek kontrat alamıyor, itibarı düzeltecek işi kalmıyordu (itibar -20'de
   sabitlenen kervanlar). `MerchantOffer.is_open_to()`: eşiksiz ilan her itibarda açık, eşikli ilan eşikte açık
   (lonca ekranı ve simülatör aynı kapıdan geçiyor). Reputation Rules'un "en ucuz kapı hiç kapanmaz" cümlesinin
   kontrat tarafı.
2. **Düzenek: yol rastgele seçiliyordu.** Pano şehir başına 4-7 ilan taşıyor ve 27 yerleşimde rastgele bir yol çoğu
   zaman hiçbir ilanla eşleşmiyordu (kasaba ve kervansarayda pano zaten yok). Gerçek oyuncu işin olduğu yöne gider;
   simülatör artık eşleşen açık ilanı en çok olan yolu seçiyor (eşitlikte rastgele).
3. **Düzenek: kontrat malı pazar malıyla yarıştı.** Simülatör önce vagonları pazar malıyla dolduruyor, sonra
   kontrat alıyordu; emanet mal sığmıyor, "varışta yok" sayılıp her biri -3 itibar yiyordu (`cargo_room` hiç
   verilmemişti). Sıra kontrat → pazar malı oldu, kargo yeri ayrılıyor. Hasarlı vagon da hiç onarılmıyordu
   (`repair_wagons()` yardımda).

Sonuç (`simulate_career`, 8 kervan × 40 sefer, aile borcu 180 / 120 gün / %4 / -1 itibar):

| politika | İlk Yol | Bir Kadro | Ağ | Temiz Defter | Kendi Hanın | final ortancası |
|---|---|---|---|---|---|---|
| genişleyen | 8/8 | 8/8 | 8/8 | 8/8 | 8/8 | 29 |
| kontratçı | 8/8 | 8/8 | 8/8 | 8/8 | 5/8 | 11 |
| kampanyacı | 8/8 | 8/8 | 8/8 | 8/8 | 8/8 | 25 |

Borç 40. seferde 0-22. Baz (borçsuz, eski düzenek) final 6/8 idi; borç ve yeni sistemler eklendikten sonra 8/8,
yani aile borcu kariyeri kilitlemiyor. Kontratçı politikanın finali 5/8: kendine en çok iki vagon alıyor ve dördüncü
vagonu seviye/itibar eşiklerinden bekliyor (40. seferde ortalama 4 vagon), bu politikanın bedeli, bir hata değil.
Final ortancası N8'in 19-21'inden geç (25-29): göreceli olarak daha yavaş, ama 40 sefer içinde.
