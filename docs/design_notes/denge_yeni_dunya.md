# Yeni dünyada denge ölçümü (görev N8, 2026-10-18)

Yer tutucu beş şehirden harita v3'ün 27 yerleşimine geçince yollar uzadı (2-38 gün, ortanca 8; eskiden 3-8). Ölçüm
`tests/simulate_career.gd` (8 kervan × 40 sefer, üç politika) ve `tests/simulate_journeys.gd` ile.

## Bulgular ve yapılan ayarlar

1. **Kontrat günlük ücreti erzağı karşılamıyordu.** Tek vagonluk kontrat `30 + 8 × gün` ödüyordu; kontratın getirdiği
   tüccar kendi ağzıyla günde ~4 GG erzak yiyor. Kısa yollarda sabit 30 bunu örtüyordu, 20-38 günlük yolda örtmüyordu.
   Ücret `30 + 14 × gün` (büyük kontrat `70 + 24 × gün`, eşekli `18 + 9 × gün`) oldu
   (`WorldMapData.CONTRACT_DAY_PAY_*`). 10. seferdeki ortalama kese 20 → 28-132 GG; bölümler daha erken kapanıyor.
2. **Uzak başlangıç kervanı batırıyordu.** Vorgat'ta (komşuları 15-38 gün) başlayan bir kervan ilk yolunu 250 altınla
   karşılayamadı, 40 seferde tek kontrat teslim edemedi. Başlangıç adayları artık en az bir komşusu 10 gün içinde olan
   yerler (`build_settlements.py START_MAX_FIRST_LEG`); öyle aday yoksa bölgedeki hepsi.
3. Ölçülen son tablo (40 sefer, 8 kervan):

| Politika | 1. sefer günü | 10. sefer kese | 40. sefer kese | Final (Kendi Hanın) | Final ortanca sefer |
|---|---|---|---|---|---|
| genişleyen | 12 | 6 | 2487 | 6/8 | 19 |
| kontratçı | 12 | 63 | 3811 | 6/8 | 21 |
| kampanyacı | 12 | 13 | 3568 | 6/8 | 21 |

   40 sefer ~550 gün (eskiden ~800 gün, 16 günlük ilk yolla). Final eskiden 12-16. seferde kapanıyordu; şimdi ~20.
   seferde, yaklaşık 380 günde: yollar uzun, oyun daha uzun - kullanıcının "yol hemen bitmesin" isteğiyle uyumlu.
4. **Bir kervan (8'de 1) ilk bölümü kapatamıyor.** Dağ kültürüyle Brazdun'da başlayıp 40 seferde kontrat teslim edemeyen
   bir kervan: genişleme politikası vagona para yatırıyor, kese ve itibar eksiye düşüyor, kontrat alamıyor. Bu bir dünya
   hatası değil, politikanın batışı; "kervan batabilir" tezine uygun. İzlenecek.
5. `simulate_journeys.gd` sentetik 8 günlük yol kullanıyor, dünyadan etkilenmiyor; savaş tablosu değişmedi.

## Sonraki ölçüm

- Gerçek ekran oyunu: 1x hızda bir gün 45 sn, ortanca yol 8 gün ≈ 6 dakika; en uzun yol 38 gün ≈ 28 dakika. Yol
  paneli (P18) ve olay yoğunluğu (Y-B02 yol yönetmeni) uzun yolun dolu geçmesi için önemli.
- Kasabanın yarı ticaret payı ve kervansarayın alış/satış çarpanı simülatörde ayrıca ölçülmedi (simülatör her yerden
  aynı politikayla alıp satıyor).
