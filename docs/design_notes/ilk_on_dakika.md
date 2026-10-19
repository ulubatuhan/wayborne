# İlk on dakikanın çizelgesi (Y-H02)

Durum: çizelge ve ölçüm hazır; dış oyuncu testinde ölçülecek, kullanıcı onayı bekliyor.

## Hedef

| An | Hedef | Bugün nereden gelir |
|---|---|---|
| İlk anlamlı karar | 3 dk | Babadan devir (Y-C14), ilk şehirde pazar ve pano; ilk yol günündeki kart |
| İlk tehdit | 10 dk | İlk sefer yol kartları (haydut, kurt), yol yönetmeni (Y-B02) sessiz günde şansı artırır |
| İlk kayıp tehlikesi | 30 dk | Açlık, savaşta ölümün kapısı, babanın borcunun vadesi |
| İlk kârlı varış | 30 dk | İlk sefer kontrat ya da al-sat |

## İlk on dakikanın akışı (öneri)

1. **0:00-1:00** Kervanın adı ve devir sahnesi: borç ve vade (karar değil, yük).
2. **1:00-3:00** Şehir: pazarda ilk alım ya da panodan ilk iş (FirstTimeHint: ticaret, kontrat). İlk anlamlı karar
   burada: neyi alıp nereye götüreceğin.
3. **3:00-5:00** Planlayıcı: rota, erzak, kısayol (FirstTimeHint: planlayıcı). Yola çıkış.
4. **5:00-8:00** Yol: dikkat (lideri kervanda yürütmek), ilk sinyal, ilk akşam sofrası (FirstTimeHint: dikkat, sofra).
5. **8:00-10:00** İlk tehdit: yönetmen ilk seferde ilk tehdit kartını 3. günden önce öne çeker (öneri; bugün zarla).

## Ölçüm

- Oyun gerçek oyun süresini sayar (`GameSession.play_seconds`, kayıtta) ve dört ilki ilk yaşandığı saniyeyle
  işaretler (`mark_first`): olay kartında ilk seçim, savaş açan ilk etki, ilk aç gece, ilk kârlı varış.
- Gerçek oyunda her ilk `user://playtest_times.json`'a bir satır düşer (testler ve simülatörler yazmaz).
- `python -X utf8 tools/playtest_report.py` dosyayı okur ve hedeflerle karşılaştırır.

## Onay için sorular

1. Hedefler (3 / 10 / 30 dk) uygun mu?
2. İlk seferde ilk tehdidi zorla öne çekelim mi (yönetmene "ilk sefer" kuralı), yoksa zar kalsın mı?
