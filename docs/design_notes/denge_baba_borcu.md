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

Yeni değerlerin ölçümü `simulate_career` ile: bölüm kapanışları 8/8'e dönmeli, borç sınırlı kalmalı.
