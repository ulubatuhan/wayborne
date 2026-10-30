---
name: ekran-dogrula
description: Wayborne'da oyuncunun gördüğü bir şey (ekran, panel, figür, sahne, harita, metin yerleşimi) değiştiğinde "bitti" demeden önce gerçek ekranın görüntüsünü alıp bakmak için kullan. Görev Y-K01'in kuralı: bir iş ekranda görününce biter.
---

# Ekranda doğrula

Yapısal testler yerleşimi doğrular, görünüşü asla. "Düzeldi" demeden önce değişen ekranın gerçek görüntüsü alınır ve
bakılır (CLAUDE.md, Testing; ayrıntı `kurallar-test`). Yalnızca **değişen** ekranın görüntüsü çekilir (Çalışma düzeni).

## 1. Aracı seç

`tests/screenshot_*.gd` test değildir, PNG basar. Değişikliğe en yakın olanı seç (`ls tests/screenshot_*.gd`):

| değişen | araç |
|---|---|
| yönetim ekranları (pazar, lonca, kadro, karakter...) | `screenshot_screens.gd` (`-- genişlik yükseklik` alır) |
| yol ekranı düzeni, HUD, kontrol paneli | `screenshot_journey_screen.gd` |
| yol manzarası, ışık, biyom görünüşleri | `screenshot_road.gd`, `screenshot_road_light.gd`, `screenshot_road_looks.gd` |
| kamp, dönüş, karşılaşma | `screenshot_camp.gd`, `screenshot_turnaround.gd`, `screenshot_road_encounter.gd` |
| savaş ve efektler | `screenshot_combat.gd`, `screenshot_combat_fx.gd`, `screenshot_reactions.gd` |
| şehir, kapı, yerleşim resimleri | `screenshot_city_moods.gd`, `screenshot_arrival_gate.gd`, `screenshot_settlements.gd`, `screenshot_hub_scene.gd` |
| defter, varis, ana menü | `screenshot_waybook.gd`, `screenshot_menu.gd` |
| figür, giysi, saç, poz, yürüyüş | `screenshot_outfits.gd`, `screenshot_hair.gd`, `screenshot_poses.gd`, `screenshot_mannequin_walk.gd`, `screenshot_walk_cadence.gd`, `screenshot_body_range.gd` |
| harita | `screenshot_map_tiles.gd`, `screenshot_map_popup.gd` |
| vitrin görüntüleri | `screenshot_showcase.gd` |

Uygun araç yoksa yenisini yaz: oyunun **kendi** sahnesini ve çerçevesini kur (el yapımı bir bant başka bir oyunu
fotoğraflar; `kurallar-test`'teki beşinci ölçüm hatası).

## 2. Çalıştır

Ortamda Vulkan yok; sanal ekran ve yazılım çizici:

```bash
godot --headless --import > /tmp/import.log 2>&1          # atlas değiştiyse iki kez
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
  godot --path . --rendering-driver opengl3 --script res://tests/screenshot_X.gd > /tmp/shot.log 2>&1
grep -E "SCRIPT ERROR|Parse Error|saved|kaydedildi" /tmp/shot.log | head
```

Çıktı `user://<aracın SHOT_DIR'i>`: Linux'ta `~/.local/share/godot/app_userdata/<proje adı>/`. Uzun günlük ekrana
basılmaz, dosyaya yazılıp `grep` edilir.

## 3. Bak

- PNG'yi Read ile aç ve **raporun işaret ettiği yere** bak. "Gri şerit" denmişse o kenarı ölç; üç düzeltme bu yüzden
  yanlış ilan edildi (Art Rules).
- Hareket içeren her şey tek karede değil döngü boyunca kontrol edilir (yürüyüş, kesik giysi: `Wardrobe & Rig`).
- Telefon ve masaüstü ölçüsü gerekiyorsa iki ölçüde çek.

## 4. Raporla

Kullanıcıya hangi görüntüye bakıldığını söyle; değişiklik önemliyse görüntüyü `SendUserFile` ile gönder. Görüntü
alınamadıysa "doğrulanmadı" de ve nedenini yaz; testlerin geçmesi bunun yerine geçmez.
