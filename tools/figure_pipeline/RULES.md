# RULES — her faz başında, her bağlam sıkıştırmasından sonra, "bitti" demeden önce oku
Önce `POSTMORTEM.md`. Eski kılavuz yalnızca teknik başvuru; bu dosyayla çelişirse bu dosya geçerli.

## Değişmez kurallar
1. Hakem önce gelir. İçerik üretmeden önce testi yaz; her testi bilinen hatalı örnekte
   (ör. fb_phase4_zoom.png) BAŞARISIZ olduğunu göstererek doğrula. Yakalamayan test geçersiz.
2. Göz kararı onay yok. Her sonuç = test sayısı + fark görüntüsü.
3. Görsel denetim yerel çözünürlükte. `qa/crops.py`: her eklem bölgesinden (boyun, omuzlar,
   dirsekler, bilek+el, kalçalar, dizler, ayak bilekleri) 2x, en çok 512 px kırpıntı.
   Her kırpıntı için ne gördüğünü bir cümleyle yaz, sonra karar ver.
4. Sayı ile görüntü çelişirse DUR. Çelişki hatadır. İki kanıtı + ayıracak testi raporla.
5. Semptom gizleme yasak (ağırlık yuvarlama, overlap, clamp, alfayla örtme). Önce kök neden
   yaz; bilinmiyorsa düzeltme, raporla.
6. Sessiz sapma yok. Prompt'taki karardan/kapsamdan/sayıdan sapmak kullanıcının kararıdır.
   "Kapsam kararı" alma yetkisi yok.
7. Kararlar makinece denetlenir: yapısal kararlar `config/*.json`; `qa/check_config.py` her
   çalıştırmanın başında doğrular (katmanlar tam: back_arm, back_leg, torso_head, front_leg,
   front_arm).
8. Ölçüm üretilen pikselden: render'dan ve aynı karede basılan eklem işaretlerinden.
   İskelet verisi yalnızca karşılaştırma içindir.
9. Tüm render'larda backface culling açık.

## Özerklik sözleşmesi
- Beklemeden yapabilirim: kod, test, render, ölçüm, kendi hatamı KÖK NEDENİYLE düzeltmek,
  `QUESTIONS.md`'ye soru eklemek.
- Durup kullanıcıya dönmem gerekir: faz kapısını geçti saymak; prompt'taki karardan sapmak;
  sanatsal seçim; test eşiği değiştirmek.
- "Beni bekleme" denirse: kapıya bağlı olmayan işe devam, kapıya bağlı soruları
  `QUESTIONS.md`'ye yaz; onaysız fazın üstüne sonraki fazı KURMA.
- Her rapor dört başlıkla başlar: Geçti (sayıyla) / Kaldı (sayı + fark görüntüsü) /
  Test edilmedi / Kullanıcıdan istenen tek karar.
