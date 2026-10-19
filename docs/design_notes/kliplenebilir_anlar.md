# Kliplenebilir anlar (Y-J09)

Her biri net başlangıcı ve sonu olan, 15-45 saniyelik, sesi kapalıyken de anlaşılan bir sahne. Fragman (Y-J03),
mağaza görüntüleri (Y-J14) ve yayıncı anları bunlardan çıkar. Kayıt: her an için bir kayıt dosyası (sefer ortası
kaydı) hazırlanır; video Aralık'ta (kullanıcı notu: pazarlama işleri Aralık'ta).

| An | Başlangıç | Son | Nasıl tetiklenir | Neyi gösterir |
|---|---|---|---|---|
| Kırılma | Stresi eşikteki yoldaş kamp ateşinde ayağa kalkar | Arkadaşına saldırır ya da öne atılır; deftere satır | Stres 80+ bir kadro, yolda `evt_broken_outburst`; savaşta kırılma kipi (Y-D06) | İnsanlar aşınır: davranışla yaşanan kırılma, ekran efekti yok |
| Varis devralma | Lider savaşta ölümün kıyısından düşer | `SuccessionPanel`: ad, kuşak, kıdemliyi geçmenin mühür çatlağı | Lideri öne koy, yüksek tehlikeli yolda haydut pususu | Defter unutmaz: ad yaşar, insan ölür |
| Alacaklı atlısı | Ufukta tek atlı, defterdeki borcun vadesi | Ayni ödeme ya da reddin bedeli | Vadesi geçmiş babanın borcu (Y-C14), `evt_creditor_rider` / `evt_bailiffs_at_camp` | Ticaret bilgi oyunudur: borç bir sahne |
| Kurt sürüsü | Gece ışıksız yürüyüş, arkada uluma (`evt_wolves_follow`) | Sürünün saldırısı ya da meşaleyle uzak tutulması (`evt_wolf_pack`) | Gece yürüyüşü, fener yağı yok | Yol yaşar: zincir, ışık kararı |
| Açlık gecesi | Sofra paneli: yetmeyen erzak, kimin yiyeceği | Aç kalanın kırgınlığı, sabah portrede iz | Erzağı bilerek eksik al (planlayıcı iki basışlı onay) | İnsanlar aşınır: seçimin bedeli bir yüzde |

## Kayıt hazırlığı (akşam ya da Aralık)

- Her an için `user://saves/slot_N.json` (sefer ortası kaydı, aynı zar): oyuncu yükleyip anı tekrar oynar.
- Kayıt aracı: 1080p, Reduce Motion kapalı, oyun içi ses açık; arayüz ipuçları (FirstTimeHint) bayraklı kapalı.
- Fragmanda sıra: kurt sürüsü → açlık gecesi → kırılma → varis devralma → alacaklı atlısı (gerilim artarak, defterle biter).
