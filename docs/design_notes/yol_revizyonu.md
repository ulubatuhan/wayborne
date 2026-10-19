# Yol görünümü: büyük revizyon (12.2, 12.2a, 12.2e, 9.9, 9.10)

Durum: tasarım notu, kullanıcı onayı bekliyor. Her adım önce bir taslak kareyle onaya gelir, sonra uygulanır.
İlk taslak: `TODO/taslaklar/y_122e_yol_isik.png` (dört gün evresi × çayır, orman, dağ), `yol_isik_taslak.py`
yeniden üretir. Taslak oyunun kendi render şeritlerini TravelBand'in oranlarıyla diziyor; değişen yalnızca gök ve ışık.

## Kullanıcı notları

- "yol görünümü üzerine büyük bir overhaul çalışması yapacağız."
- "çimenler, yol, arka plan, hele ki güneş estetik olarak güzel bir sahne değil, buradaki her detayı yeniden tasarlamak lazım."
- Şehir kapısı "rezalet"; kervan şehre girmez, kapı önünde kalır (Y-G10T).

## 1. Görsel dil (tek sayfalık kural, STIL_REHBERI'ne eklenecek)

- Uzak katman soğuk, puslu ve düşük kontrastlı; ön plan sıcak ve koyu. Derinlik pustan gelir, mürekkep yalnızca
  kervanın düzleminde (Rendered Road Rules korunur).
- Evre başına tek renk derecelendirmesi bütün katmanlara: şafak gül-kehribar, gündüz soluk mavi, akşam bakır, gece
  çivit. Hava (kapalı, yağmur, sis) paleti griye çeker, evreyi silmez.
- Sınırlı palet: harita ve arayüzün mürekkep-parşömen + karanlık arayüz diliyle aynı aileden.

## 2. Gökyüzü ve güneş (taslakta)

- Güneş disk değil **ışık**: ufukta sıcak bant (evrenin rengi), güneşe bakan bulut kenarlarında ışık, haleli küçük bir
  çekirdek. Gece ay, soğuk ve küçük.
- Kod: `TravelBand._draw_sky` gradyanına ufuk bandı (Gauss), güneş/ay yayı yerine ışınsal hale (`ArtDraw` fırçası,
  önbellekli doku), bulut şeritleri ışık yönünü okur. Dört palet anahtarı `ArtPalette`'te.

## 3. Uzak ve orta katmanlar

- Y-G07'nin biyom şeritleri kalır. Eklenen: uzak ile orta arasında **ayrı sis şeridi** (taslakta), uzak katmanın pusu
  evreden.
- Prosedürel sırtlar yalnızca şeridi olmayan biyomlar için yedek.

## 4. Zemin, çimen ve yol

- Uzakta tonal düzlük, yakında seçici detay (tutam, taş, iz); kervan bandı sade (12.2d).
- Yol: tekerlek izi ve çamur, biyoma göre toprak, taş ya da kar; bank çizgisi yerine organik geçiş. Okunurluk: yol
  zeminden en az %42 ayrışır (ölçülmüş ders).
- Üretim: `road_scene.py` zemin katmanına iz ve kenar geçişi, render + `road_post.py`.

## 5. Yol kenarı nesneleri

- Biyomun ağaç, çalı, kaya seti; derinliğe göre ölçek ve pus. Yarım kesik nesne yok. Kervan enkazı (Quaternius
  `Broken Cart`) nadir bir yol kenarı nesnesi (9.10).

## 6. Işık ve atmosfer

- Gece: kervanın feneri yolda sıcak bir daire (taslakta), haritadaki atlı işaretle aynı dil; kamp ateşi ve fener
  ışığı ön plana düşer.

## 7. Şehir kapısı (12.2a)

- Render edilmiş, katmanlı kapı sahnesi: sur, kapı kemeri, kuleler; şehrin kendi mimari dili (CityFront kasabasının
  aynı seti, `settlement_towns.py` stili). Kenney Castle Kit + Fantasy Town Kit (CC0).
- Varışta kervan kapıya yaklaşırken kapı büyür, kanat kalkar (PropArt `gate` katmanı), kervan **kapı önünde durur**.
  Ses: Freesound CC0 kapı, zincir, makara katmanları.
- İlk adım: bir şehir için tek kare kapı render'ı onaya.

## 8. Yol HUD'u (9.9)

- `SurvivalGauge` ince çubuk, amblem ve çentik; çatlak efekti yok. Alt panel (P18) zaten sekmeli: harita ve envanter
  orada.

## 9. Performans

- PC'de 60 FPS (orta sınıf ekran kartı); katmanlar önbellekli doku, kare başına yeniden çizim en az. Web ölçüt değil.

## Sıra

1. Bu not ve gök/ışık taslağı onaya (şimdi).
2. Gök ve ışık kodu + 4 evre × 6 biyom ekran görüntüsü (akşam testi).
3. Zemin ve yol render'ı, tek biyom taslak kare.
4. Kapı sahnesi tek kare.
5. Yol kenarı seti ve enkaz.

## Onay için sorular

1. Güneşi ışık olarak göstermek (bant + hale + bulut kenarı) doğru yön mü?
2. Gece fener dairesi bu sıcaklıkta mı, daha kısık mı?
3. Sis şeridi her biyomda mı, yalnız orman ve bataklıkta mı?
4. Kapı sahnesinde kervan kapıdan geçmesin, önünde dursun: onaylı karar, böyle kalsın mı?
