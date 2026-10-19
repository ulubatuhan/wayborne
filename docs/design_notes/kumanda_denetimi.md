# Kumanda, Steam Deck ve Xbox denetimi (Y-H06)

Durum: denetim; uygulama sonra (P3, kullanıcı notu: "bu daha sonra eklememiz gereken bir şey değil mi? listeye
ekleyebiliriz yine de"). Kabul: bütün ekranlar kumandayla oynanıyor.

## Bugün olan

`GamepadCursor` (autoload): sağ çubuk sanal fare imleci; A sol tık, B Esc, X etkileşim (E), LB tempo (F2), RT/LT yolda
ileri/geri (`get_move_axis`). Sahte fare olayı ürettiği için fareyle çalışan her ekran kumandayla da çalışıyor. İlk
kumanda girdisinde gerçek imleç gizleniyor; fare oynayınca geri geliyor.

## Eksikler

| Alan | Eksik | Öneri |
|---|---|---|
| Menü gezinmesi | Odak (focus) yok; her şey imleçle | Ana menü, kayıtlar, ayarlar, oyun içi menüde D-pad ile odak sırası (`focus_neighbor_*`), A seçer |
| Tuş simgeleri | Ekranda klavye harfleri (E, F2, M, L) | Son kullanılan girdiye göre simge (Xbox/PlayStation/klavye); `UiIcon` ile çizilir |
| Pazar ve kargo | Sürükle-bırak imleçle yavaş | Satırda A = seç, RB/LB = vagon değiştir; her sürüklemenin zaten bir düğmesi var |
| Savaş | Beceri ve hedef seçimi imleçle | D-pad sol/sağ hedef, yukarı/aşağı beceri, A uygula |
| Harita | Yakınlaştırma tekerlek ile | Sağ çubuk tıkla + tetikler yakınlaştırır |
| Metin girişi | Kervan adı, karakter adı | Steam ekran klavyesi (Steamworks `ShowGamepadTextInput`) |

## Steam Deck

- Çözünürlük 1280x800: bütün ekranların ekran görüntüsü bu boyda alınmalı (`screenshot_screens.gd -- 1280 800`).
- En küçük metin: Deck'te 9 pt altı okunmaz; Y-H07'deki metin boyu ayarı 115% varsayılan olabilir.
- Performans: 60 FPS hedefi, Deck'te 40 FPS kabul (Steam Deck Verified ölçütü 30+).
- Dokunmatik: `test_touch_parity` zaten her tuşun ekranda karşılığı olduğunu denetliyor; Deck dokunmatiği bundan yararlanır.

## Xbox

- Tarayıcı (Web derlemesi) üzerinden oynanabilirlik bugünkü sanal imleçle var; yerel Xbox derlemesi (GDK) ayrı bir iş
  ve lisans gerektirir.

## Sıra (onaydan sonra)

1. Menülerde odak gezinmesi ve tuş simgeleri.
2. Savaş ve pazar için kumanda kısayolları.
3. 1280x800 ekran görüntüsü taraması ve Deck testi.
