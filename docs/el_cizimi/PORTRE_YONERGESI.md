# Portre yönergesi (görev Y-G19)

Kullanıcı notu (2026-10-31): "Karakter portreleri direkt bu şekilde çizilmeli, zaten aşınmış, yorgun olmalı."

Portre bir duruma göre aşınmaz; her portre baştan yorgun çizilir. Açlık, hastalık ve yara oyunun verisinde durur ve
başka yerde söylenir; yüz, yolda geçmiş yılları taşır.

- **Yüz:** çökük yanak, göz altında koyu halka, kuru ve çatlak dudak, rüzgârdan kızarmış değil solmuş ten. Gülümseme
  yok; bakış yorgun ya da uzakta.
- **Saç ve sakal:** taranmamış, tozlu; başörtüsü ve başlık eskimiş.
- **Giysi:** yaka yıpranmış, dikiş yeri görünür, renk solmuş. Yeni görünen kumaş yok.
- **Işık:** soğuk ve soluk (tek sıcak kaynak kuralı, `kurallar-sanat`): portrenin ışığı bir ateş değil. Sıcak renk
  yalnızca çizimde bir ateş ya da fener varsa onun düştüğü yerde.
- **Gölge:** yüzün gölgeli yarısı derin; mürekkep tarama gölgede yoğun, ışıkta yok.
- **Kültür farkı yorgunluğu silmez:** Gokyurtlu biri daha sağlıklı görünebilir (kıtanın en sağlıklı yeri) ama yine
  yoldan yorgun.

**Ara çözüm (2026-10-31):** el çizimi gelene kadar mevcut portreler `bust_ink.gdshader`'ın `weariness` ayarıyla
soluklaşır, ışıkları soğur ve gölgeleri derinleşir (0 eski, 1 yorgun; varsayılan 1).
