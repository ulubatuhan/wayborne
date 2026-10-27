# AI-referanslı 2D sprite üretimi (hedef, kullanıcı kararı 2026-10-22)

> **Yerini aldı (2026-10-27):** bütün görsellerin el çizimi programı `docs/el_cizimi/SUREC.md`. Bu not aşağıdaki ilk planın kaydı olarak kalıyor.

Amaç: oyunun görselleri, mağaza sayfasında AI beyanı gerekmeyecek kadar elle üretilmiş olsun. AI çıktısı yalnızca
**referans** olarak kullanılır; oyuna giren her piksel tablette elle çizilir. Süreç ileride kurulacak; aşağıdaki metin
kullanıcının kendi tarifidir, değiştirilmeden alındı.

## 1. Aşama: AI referans isteme (Claude tarafı)

Claude'dan görsel üretmesi istenirken oyun motorlarının standartlarına uygun referanslar vermesi istenir.

- **Açı ve perspektif:** karakter tasarımlarında tutarlılık için net bir bakış açısı (örn. T-Pose, Front View, Side
  View veya Isometric) belirtilmelidir.
- **Çözünürlük ve ölçek:** çizgi takibini kolaylaştırmak için arka planı sade, kontrastı yüksek ve net hatlara sahip
  karakter konsept tasarımları üretilir.

## 2. Aşama: mobil "tracing" ve katman yönetimi (tablet tarafı)

Görsel Android tablete indirildikten sonra, örnek olarak ibis Paint X üzerinde:

- **Tuval kurulumu:** 2'nin katı olan kare bir tuval (örn. 1024x1024 veya 2048x2048 px).
- **Referans katmanı (Layer 1):** Claude'un ürettiği görsel alt katman olarak aktarılır, opaklığı %30-%40'a düşürülür.
- **Hat çizimi / lineart (Layer 2):** referansın üzerine boş bir katman; minimal efor için Simetri Cetveli açık,
  fırçayla ana hatların üzerinden geçilir.
- **Referansı eleme:** çizim bitince alttaki AI referans katmanı kapatılır ya da silinir.

## 3. Aşama: boyama ve saydamlaştırma (varlık oluşturma)

- **Düz boyama (Layer 3):** çizgi katmanının altına boş bir katman; kova aracıyla alanlar doldurulur.
- **Arka plan:** tuvalin arka planı kareli (saydam) moda alınır.
- **Şeffaf kayıt:** çalışma alfa kanalını korumak için mutlaka şeffaf PNG olarak dışa aktarılır.

## Projeye bağlanırken dikkat edilecekler (Claude notu)

- Elle çizilen PNG'ler bugünkü hatların aynı kapısından girer (`tools/waybook_assets.py`, `tools/gauge_icons.py`):
  kaynak `art_source/` altında, çıktı `data/assets/` altında, çıktı elle düzeltilmez.
- Hangi varlığın hâlâ AI çıktısı olduğu `docs/wayborne_gorsel_denetim.xlsx`'te bir sütunla izlenmeli; beyan gerekip
  gerekmediği o listenin boşalmasına bağlı.
- 3B render'lar (figürler, kıyafetler, kasabalar, yol) CC0 modellerden üretiliyor ve AI içermiyor; bu süreç yalnızca
  üretken görsel modelle yapılmış 2B varlıkları (Waybook arka planları, ikonlar, olay illüstrasyonları, gösterge
  resimleri) kapsar.
