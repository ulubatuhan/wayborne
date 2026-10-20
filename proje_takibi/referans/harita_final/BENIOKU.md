# Wayborne dünya haritası: son sürüm (v3, 2026-10-17)

Kullanıcı onaylı son hâl. Bulut oturumunda yarım kalan harita yerelde yeniden kuruldu. Ardından iki tur düzenleme işlendi:
- `d.docx` talepleri,
- kavşak halkaları, kuzeybatı ormanı ve köprünün kaldırılması.

Geçmiş: `../belgeler/HARITA_GECMISI.md`. Yapılacaklar: `../YAPILACAKLAR.md` §8.

## Bu klasörde

| Dosya | Ne |
|---|---|
| `goruntuleyici/index.html` | Yakınlaştırılabilir harita. Tam kalite (16012×16013 px), 1024 px karolar, 5 seviye. |
| `haritayi_ac.bat` | Görüntüleyiciyi yerel sunucuyla açar. Python gerekir. |
| `wayborne_harita.geojson` | Haritadaki tüm varlıklar, makine okunur (aşağıda). |
| `isaret_atli/` | Oyuncunun harita işareti: at ve binici, 8 yön (64–256 px) |
| `isaret/` | Eski işaret önerileri (kullanılmıyor) |
| `harita_onizleme_4096.jpg` | Hızlı bakış için küçük önizleme. |

Tam çözünürlüklü tek parça görüntü klasör dışında, çünkü 181 MB:
- `xx/Harita_Calismasi/cikti/v3_final/map_16384.png` (kayıpsız)
- `xx/Harita_Calismasi/cikti/v3_final/map_16384.jpg`

Not: Dosya adındaki 16384 render ölçeğidir. Kenar bandı kırpıldığı için görüntü 16012×16013 px.

## Görüntüleyici

- **Açma:** `goruntuleyici/index.html` dosyasını açın. Açılmazsa ya da karolar gelmezse `haritayi_ac.bat` ile açın.
- **İnternet:** OpenSeadragon kütüphanesi `cdnjs` üzerinden yükleniyor, bu yüzden internet bağlantısı gerekir.
- **Gezinme:** İki parmakla ya da tekerlekle yaklaşılır. Tam yakınlıkta tek bir kent ekranı doldurur ve yazılar net okunur.
- **Arama:** Sol üstteki kutuya Türkçe ya da İngilizce ad yazın, sonuca tıklayınca oraya gider.
- **Kervan işareti (atlı):** Başlangıçta Vastrevar'da durur. Taşındıkça gidiş yönüne döner.
  - **Taşı:** Bu düğme açıkken haritaya dokunduğunuz yere taşınır.
  - **Kervan:** İşaretin üstüne gider.
  - **Konum bilgisi:** Sol üstte en yakın yerin adı ve koordinat yazar.
  - **Kalıcılık:** Konum tarayıcıda saklanır (`localStorage`).
  - **Adresten verme:** `index.html?x=6433&y=3556` gibi görüntü pikseliyle de verilebilir.

## İşaret: atlı (`isaret_atli/`)

Oyuncunun (kervanın) harita işareti bir at ve binicisi.
- **Kaynak:** Depodaki 3D at modeli (`art_source/models/animals/quaternius_gltf/glTF/Horse.gltf`, CC0) ile aynı sahnede kurulan sade bir binici.
- **Kamera:** Haritadaki dağlarla aynı yukarıdan-yandan açı (35°).
- **Yönler:** 8 yönden render edilip haritanın mürekkep diline çevrildi: kâğıt dolgu, mürekkep hat, gölge tarafında tarama.
- **Binici:** Siyah pelerin omuzlardan sırta ve sağrıya dökülüyor, önü açık; başta yuvarlak bir kukuleta var. Sol el dizginde. Sağ el havada bir fener tutuyor; fenerin çevresinde sıcak bir ışıltı var. Işıltı saydam olduğu için haritanın üstüne yumuşakça biner.

| Dosya | Açıklama |
|---|---|
| `atli_<yön>_<px>.png` | Yön: `K`, `KD`, `D`, `GD`, `G`, `GB`, `B`, `KB` (ekranda gidiş yönü: K yukarı, D sağa, G aşağı/bize doğru). Boyut: 64, 96, 128, 256 px, kare, saydam. |
| `atli_sayfa.png` | 8 yön yan yana (256 px). |
| `atli_yonler.json` | Her yönün açısı (`heading_deg`: 0 = sağa, 90 = aşağı) ve bağlama noktası (`anchor`: görüntü içinde tırnakların ortası, 0–1). |
| `atli_onizleme_haritada.jpg` | Haritanın üstünde gerçek boyutta deneme. |

**Yön seçimi:** Gidiş vektörünün açısı en yakın 45°'ye yuvarlanır:
- `index = round(atan2(dy, dx) / 45°) mod 8`
- sıra: `D, GD, G, GB, B, KB, K, KD`

Görüntüleyici bunu yapıyor: işaret taşındıkça at gidiş yönüne döner.

**Üreten betik:** `Harita_Calismasi/kod/cm/rider_marker.py`. Pelerin rengi (`CLOAK`) ve kamera açısı (`EL`) betiğin başında. Binicinin oranı, fenerin boyutu ve ışıltının yarıçapı `rider()` ve `ink()` içinde.

**Eski öneriler:**
- `isaret/eski_madalyon/`: ilk madalyonlu kervan işareti; kullanıcı beğenmedi.
- `isaret/isaret_secenekleri.jpg`: beş alternatif.

## Coğrafi veri (`wayborne_harita.geojson`)

Haritaya bakmadan "nerede ne var" sorusunu yanıtlamak ve oyun sistemlerini (seyahat, yol bulma, bölge kuralları) bunun üstüne oturtmak için hazırlandı.

**Koordinat sistemi:** Teslim edilen görüntünün pikseli. x sağa, y aşağı. Görüntü 16012×16013 px.

| Kaynak | Dönüşüm |
|---|---|
| Dünya ızgarası (4096) | `img = 4 * dünya - (186, 165)` |
| Render ızgarası (8192) | `img = 2 * render - (186, 165)` |

Aynı bilgi dosyanın `wayborne_crs` alanında da var.

**Katmanlar** (`properties.layer`; adet `counts` alanında):

| Katman | Geometri | Önemli alanlar |
|---|---|---|
| `yerleşim` (123) | Nokta | `id` (`place_<n>`), `name_tr`, `name_en`, `name_zh`, `proper`, `class` (kent/kasaba/köy/göçebe kampı/işletme/yapı-işaret), `kind` (kaynak kodu, ör. `ic_city`), `type_tr`, `culture`, `culture_tr`, `world_4096` |
| `kervansaray` (3) | Nokta | `name_tr`, `name_en` |
| `kervan_yolu` (1) | Çizgi | Kuzey başkentinden en güneydeki kente |
| `yol` (177) | Çizgi | `class` (ana yol/patika), `from_node`, `to_node`, `from_id`/`from_name`, `to_id`/`to_name` (uçtaki yerleşim, varsa), `length_px` |
| `yol_düğümü` (330) | Nokta | `class` (kavşak/yol ucu), `degree`, `at_id`/`at_name` (düğümdeki yerleşim) |
| `deniz`, `göl`, `kara` | Çokgen (delikli) | `area_world` |
| `orman` (254), `dağ` (101) | Çokgen | Alan maskelerinden, sadeleştirilmiş |
| `boğaz` (1) | Nokta | Kesgrav'ın doğusundaki boğazın ortası. Adı geçici. |
| `bölge` (11) | Çokgen | Kültür bölgeleri: `culture`, `culture_tr` |
| `etiket` (126) | Nokta | Haritada yazılı her ad: `text`, `font_px` |
| `gemi` (30) | Nokta | Süs gemileri |

**Yol ağı bir grafik:**
- Düğümler: `yol_düğümü`.
- Kenarlar: `yol`. Kenarlar `from_node` ve `to_node` ile birbirine bağlanır.
- Kenar ağırlığı olarak `length_px` kullanılabilir.
- Bir yerleşimin ağa bağlandığı yer, `at_id` alanı o yerleşimi gösteren düğümdür.

**Üreten betik:** `Harita_Calismasi/kod/cm/geo_export.py`.

## Yeniden üretme

Komut sırası `../YAPILACAKLAR.md` §8'de. Ortam `xx/Harita_Calismasi/_replay/` altında.

Son render ayarları:
- `CM_FIELDS=../kcd/out/vgf/fields_v2.npz`
- `CM_ARCH=` (boş: köprü yok)
- `CM_PEAKS=1`, `CM_RELIEF=0`, `CM_OUT=2`

Ardından:
1. `geo_export.py`
2. `marker.py`
3. `make_viewer.py`
