# Dil kılavuzu: sayı değil söz (Y-H03)

## Kullanıcı notu

"olabildiğince edebi ya da yazılı olarak yazsın, -10 moral yerine moral düşük yazsın gibi."

## Kural

1. **Önce söz, sonra sayı.** Bir değer ekranda bir kelimeyle okunur ("Moral düşük"); sayı ipucunun ikinci satırında ya
   da satırın sonunda parantez içinde durur. Sayısal şeffaflık kalkmaz, ikinci plana geçer.
2. **Söz nedenini söyler.** "Moral düşük: 2 gündür aç, vadesi geçmiş borç". Neden cümleleri kısa, öznesiz, şimdiki
   durum: "Ayşe kırılmak üzere", "Murat yeni toprağa verildi".
3. **Dört kademe.** Her değer dört kelimeyle anlatılır (`Wording.BAND_EDGES`: %25, %50, %75). Kademe kelimeleri
   `data/locale/game.csv` `WORD_*` satırlarında; yüksek olanın kötü olduğu değerlerde (stres, tehlike) sıra ters.
4. **Değişim yönle ve büyüklükle söylenir.** Etki satırları: "Moral sarsıldı (-10)", "Biraz soluklandılar (-3)".
   Büyük değişim eşiği `Wording.BIG_CHANGE` (8).
5. **Ton.** Defterin sesi: geçmişi kayda geçiren biri yazıyor. Abartı yok, ünlem yok, oyun terimi yok ("buff",
   "debuff", "proc" yazılmaz).
6. **Anahtarlar tam yazılı.** Kademe ve değişim anahtarları `Wording` içinde tablo olarak; çalışırken birleştirilmez
   (Localization Rules).

## Nerede

| Yer | Durum |
|---|---|
| Yol göstergeleri (moral, stres, tehlike, takat) ipucu | yapıldı |
| Olay etki satırları (moral, stres) | yapıldı |
| Defter satırları | zaten sebep ve yerle yazılıyor (`CaravanLedger.describe`) |
| Planlayıcının yola çıkış morali dökümü | sonraki adım: kalemler `Wording` diliyle |
| Şehir brifingi, karakter ekranı | sonraki adım |
