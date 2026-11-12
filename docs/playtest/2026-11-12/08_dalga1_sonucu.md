# Dalga 1 sonrası ölçüm (IP-014)

Aynı sürücü, aynı beş profil, aynı üç tohum (101, 202, 303), aynı 4 saat. "Önce" sütunu bu turun ilk
ölçümü, "sonra" Dalga 1'in on dört işi uygulandıktan sonrası. Ham veri `build/playtest_son/`,
toplu tablo `build/playtest/toplam.txt`.

## Satışa hazırlık ölçütleri (`06_is_plani.md` §1)

| no | ölçüt | önce | sonra | durum |
|---|---|---|---|---|
| S-01 | İlk karar ≤ 240 sn | 404-677 | 429-702 | **tutmadı** (aşağıda) |
| S-02 | 4 saatte büyüme basamağı gören profil ≥ 3/4 | 0/4 (ölçüm hatalıydı) | 4/4 koşuların %87'sinde vagon 2'ye çıktı | tuttu |
| S-03 | Doğan iz ≥ 12, dönen ≥ 4, bedel ≥ 4, hâl geçişi ≥ 3 | 0-10 / 0-4 / 0-2 / 0-1 | 1-12 / 0-1 / 0-1 / 0-1 | **kısmen** |
| S-04 | En çok görülen kartın payı ≤ %10, farklı kart ≥ 35 | %20 · 17-33 | **%9,1** · 25-35 | payı tuttu, çeşit sınırda |
| S-05 | Çekilebilir kart ≥ 120 | 101 | 105 | açık (WP-04) |
| S-06 | "İyi şey" arası en uzun ≤ 18 gün | 12-32 | 11-42 | **tutmadı** |
| S-07 | Açlık ölümünde son 5 günde ≥ 2 karar | 0 | 3 açlık kartı (15 koşuda 15 kez) | tuttu |

## Ne değişti [Ölçüm]

| ölçü | önce | sonra |
|---|---|---|
| En çok görülen kartın payı | %20 | %9,1 |
| 60 saatte farklı kart | 66 | 67 |
| Koşu başına farklı kart (ortanca) | 19-32 | 25-35 |
| İsyan kartı (acemi, 12 saat) | 21 | sefer başına en çok 2 |
| Doğan iz (acemi / sert / sömürücü) | 7 / 2 / 6 | 12 / 6 / 9 |
| Bedel ödeyen | 0-1 | 0-1, üç profilde 1 |
| Aç gece (merhametli / sert) | 10 / 10 | 1 / 4 |
| Yeni kartların görülmesi | — | kapıdaki sayım 13, açlık kartları 15 |
| Meşale alımı | 0 | 86 |
| Vagon satışı / büyüme adımı | 31 / 26 | 33 / 27, hepsi gerçek baskı |

## Tutmayan iki ölçüt, dürüst hâliyle

**S-01 ilk karar.** Kapıdaki sayım kartı 15 koşunun 13'ünde çıkıyor ama ilk kararı öne çekmedi, çünkü
darboğaz yolda değil: karakter kurma 90 sn, şehir ekranları ve plan 225-240 sn sürüyor; kervan yola
315-330. saniyede çıkıyor. Yoldaki hiçbir kart 240 saniyeye yetişemez. İki yol var, ikisi de kullanıcı
kararı: (a) ölçünün tanımını düzeltmek - planlayıcıdaki "eksik erzakla çık" gerçek bir karardır ve
~255. saniyede alınıyor; (b) şehre ya da karakter kurmaya bir açılış kararı koymak. İkincisi yeni içerik
demek, o yüzden kendiliğinden yapılmadı.

**S-06 iyi şey arası.** 15 koşunun 7'sinde en uzun aralık 18 günün altında, 8'inde üstünde (en kötüsü 42).
Dalga 1 bunu hedeflemiyordu; WP-05 (kıtlık omurgası) ve WP-04 (kart hacmi) ile birlikte ölçülmeli.

**S-03 iz dönüşü.** Doğan iz belirgin arttı (acemi 7→12) ama **dönen** iz hâlâ 0-1. Sebep vade: kısa izler
bile birkaç haftada dönüyor ve dört saat 85-150 oyun günü. Dönüşü görmek için ya daha çok iz doğmalı
(Y-R01'in kalan satırları, WP-02) ya da ölçü daha uzun koşuya bakmalı. Mekanizma çalışıyor - `simulate_career`
40 seferde 2,5 dönüş gösteriyordu; eksik olan hâlâ hacim.
