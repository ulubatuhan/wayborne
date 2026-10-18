# Aşama 4 — İlk notlar (MakeClothes gerçek API'si)

Henüz bir giysi üretilmedi - bu, bir sonraki oturumun başlangıç noktası
olsun diye araştırmanın kaydı.

## MakeClothes gerçek yapısı (kaynaktan okundu, tahmin edilmedi)

MakeClothes **temiz bir servis API'si değil**, UI-property-group'una bağlı
operatörler zinciri:

- `mpfb.mark_makeclothes_clothes` - aktif nesneye `object_type="Clothes"`
  özel özelliğini yazar (`GeneralObjectProperties.set_value`).
- `mpfb.extract_makeclothes_clothes` - **gerçek, temiz bir servis
  fonksiyonuna sarılı**: `ObjectService.extract_vertex_group_to_new_object(
  active_object, vertex_group_names)`. Bu fonksiyon headless'tan
  **doğrudan** çağrılabilir - operatöre ya da UI özellik grubuna hiç
  gerek yok.
- `mpfb.check_makeclothes_clothes` / `mpfb.write_makeclothes_clothes` -
  henüz okunmadı.

## Sıradaki somut adım

`ObjectService.extract_vertex_group_to_new_object(basemesh, [...])` ile
gövdenin kendi bir bölgesini (ör. gömlek için govde+kol vertex gruplarının
kesişimi) ayrı bir mesh olarak çıkarıp, kılavuz 11.2'nin tarif ettiği
Solidify+kenar-kesme+UV ile gerçek bir "düz gömlek" üretmek - henüz
yapılmadı, bu oturumun kapsamı burada durdu.
