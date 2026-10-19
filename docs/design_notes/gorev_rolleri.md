# Görevler üç role iner (Y-F09, Y-B04, Y-B12): tasarım notu

Durum: uygulandı, kullanıcı onayı bekliyor (ONAY_PAKETI).

## Karar (kullanıcı notu)

Görevler öncü, ortancı, artçı diye üçe iner; sınıflar görevden tamamen bağımsız olur (masaüstü RPG usulü).

## Eşleme: hiçbir etki kaybolmadı

| Rol | Bölge | Kapsadığı eski görevler (etki kanalı) | Rol statı |
|---|---|---|---|
| Öncü | Ön | İzci (yol günü, tehlike bilgisi), Muhafız (savaş açılış isabeti), Tellal (pazar ve söylenti indirimi) | Sezgi |
| Ortancı | Vagonlar | Arabacı (vagon hasarı, onarım), Levazımcı (erzak) | Güç |
| Artçı | Arka | Otacı (kamp stres rahatlaması) | Bilgelik |

- Eski altı kimlik silinmedi: `DutyCatalog.get_duty(eski)` hâlâ kendi statıyla gücü ölçüyor; `GameSession.get_duty_holder(eski)` o etkiyi kapsayan rolün sahibini döndürüyor. Yani her sistem eskisi gibi okuyor.
- Atanabilen yalnızca üç rol (`DutyCatalog.get_duties()`); karakter ekranı ve kamp paneli bunları listeliyor.
- Sınıf eşleşmesi çarpanı (1.5 / 1.25) kaldırıldı. Güç = 1 + 0.05 × etkin stat × kondisyon.
- Eski kayıt: kayıtlı görev kimliği rolüne göçer (`DutyCatalog.role_of`).

## Bölgelerin yeri doldurulamaz rolleri (Y-B04)

- Lider bir bölgedeyken o bölgenin işaretini kesin çözer (eskisi gibi).
- Rol sahibi kendi bölgesindeki işarete lider orada değilken de bakabilir: saatlik `ROLE_RESOLVE_PER_HOUR × güç` (~%3.5). Çözülen işaret günlükte rol sahibinin adıyla yazılır.
- Sonuç: lider hep önde durursa ön kesin, vagonlar ve arka yalnızca rol sahipleriyle kapsanır. Rolsüz bölge açıkta kalır. Ölçüm: `tests/simulate_attention.gd` (akşam testi).

## Kampta diziliş ve akşam eylemleri (Y-B12)

- Kamp kurulunca panel: ertesi günün öncü, ortancı ve artçısı, ve en fazla iki akşam eylemi (nöbet, yaralı sarmak, tamir, av tuzağı, hikâye).
- Önde olmanın bedeli: öncü her yol günü +1 stres. Yorgun öncü gece arkaya alınabilir.

## Onay için sorular

1. Öncünün üç eski görevi (izci, muhafız, tellal) tek kişide toplanıyor; çok mu güçlü? Alternatif: tellal ortancıya.
2. Sınıf çarpanının kalkması savaş dışı denge sayılarını düşürüyor (en güçlü arabacı indirimi %20 → %11). Onaylanırsa simülatörle yeniden ölçülür.
3. Kamp paneli her kampta açılıyor; "akşam kampı" kalıcı emriyle her gece. Kalıcı bir "dünkü gibi" seçeneği istenir mi?
