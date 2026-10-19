# Olay havuzunu büyütme düzeni (Y-E01)

Durum: altyapı hazır; kart yazımı lore (Y-E06) kapanınca başlar.

## Kullanıcı notu

"Sayıyı arttır demek kolay ama arttırabilecek misin?"

## Cevap: sayıyı değil kaliteyi koruyan bir düzen

1. **Önce lore kapanır (Y-E06).** Bölgelerin adı, halkı, tehlikesi belli olmadan yazılan kart, lore gelince yeniden yazılır.
2. **Kalite listesi koddadır, yazarın beyanında değil.** `EventQuality.problems(event)` her kartı dört maddeden geçirir:
   - en az iki seçenek (yalnızca tetiklenen zincir devamları muaf);
   - cazip ama riskli bir seçenek (zarlı ya da birden çok ağırlıklı sonuçlu);
   - bir beceri kontrolü;
   - yalnızca kaynak takası değil: en az bir seçenek altın, erzak, moral, stres ve itibar dışında bir şeye dokunur.
3. **Bölge bölge 10'luk partiler.** Her parti: 6-8 bölge kartı, 1-2 yoldaş kartı, en az bir zincir (Y-E02 `CHAIN_ADVANCE`).
   Her parti onaya ayrı gelir.
4. **Her partide ölçüm.**
   - `tests/report_event_quality.gd`: hangi kart listeden geçmiyor, çekilebilir kart sayısı / 120.
   - `tests/simulate_career.gd`: finale kadar çekiliş, farklı kart, tekrar oranı (politika başına).
   - `tests/simulate_journeys.gd`: hiç çıkmayan kartlar.

## Hedef

- En az 120 çekilebilir kart (bugün katalogda `EventQuality.drawable_count`).
- Finale kadar tekrar oranı ölçülmüş ve raporlanmış.
- Mevcut kartların listeden geçmeyenleri raporda görünür; eski kartlar onaylı partilerle sırayla düzeltilir.

## Onay için sorular

1. Bölge sırası: hangi bölgeden başlayalım (ilk demo rotası mı, yoksa en boş bölge mi)?
2. Yoldaş kartları için kişi başına kaç kart: backstory başına 2 mi?
