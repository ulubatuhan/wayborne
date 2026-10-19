# Moral ve takat: kervanın nefesi, kişinin bedeni (Y-F01)

Durum: uygulandı (Y-F01). Onay soruları kullanıcı kararıyla kapandı: (1) yorgunluk savaşta küçük bir ceza, (2) kervanın takati en yorgun kişiye bağlı.

## Kullanıcı notu

"Takat aynı zamanda fiziksel bir durum olmalı ama."

## Bugün

| Değer | Sahibi | Nereden gelir | Ne yapar |
|---|---|---|---|
| Moral | Kervan (`CaravanState.morale`) | Sefer başında `get_departure_morale`, yolda günlük aşınma, olaylar | Varış ücretini çarpar, isyan kartını açar |
| Takat | Kervan (`CaravanState.stamina`) | Tempo, gece yürüyüşü (Y-C20), erken yola düşmek (Y-B05), kamp | Hızlı tempoyu sınırlar |
| Stres | Kişi (`CharacterData.stress`); kervanın ortalaması bir mercek | Yol günü, savaş, öncü olmak (Y-B12), dostluk ve husumet (R1) | Kırılma (Y-D06), ayrılma |
| Kırgınlık | Kişi (`grievances`) | Kararlar | Portrede iz, ayrılma payı, sohbet konusu |
| Dert | Kişi (`ailments`, Y-C05) | Savaş, açlık, veba | Türetilmiş değerleri büker |

## Öneri: hangi değer kimin

1. **Moral kervanda kalır.** Seferin ortak havası; tek kişiye bölünmesi (ör. "Ayşe'nin morali") stresle çakışır.
2. **Takat ikiye ayrılır:**
   - **Kervanın takati** (bugünkü sayı) **kişilerin yorgunluğunun en kötüsünden türetilir**, ayrı bir sayaç olmaz: kervan en yorgun yürüyenin hızında yürür.
   - **Kişinin yorgunluğu** (`CharacterData.fatigue`, 0-100, yeni, kayıtlı) fiziksel durum. Artırır: hızlı tempo, gece ışıksız yürüyüş, öncü olmak, savaşa girmek, ağır kıyafet (iri beden zaten çok yiyor; yorgunluk aynı eksende). Azaltır: kamp (ateş başında olan), şehir, kervanın ortasında yürümek.
   - Yorgunluk savaşta küçük bir isabet ve kaçınma cezası olur (yeni sistem değil: `_ailment_bonus_sum` gibi bir sarmalayıcı). Yorgun öncü gece arkaya alınır (Y-B12'nin bedeli zaten bu).
3. **Stres kişide kalır**, bugünkü gibi.
4. **Kırgınlık portrede görünür** (bugün karakter ekranında ikon; yol panelinin Kadro sekmesinde de).

## Arayüz (sadeleştirmeden okunur)

- Yol panelinin **Kadro** kartı: can, stres ve yeni yorgunluk çubuğu yan yana; kırgınlık ikonları kartın kenarında.
- **Durum** sekmesi: moral şişesi ve kervanın takati (en yorgun kişinin adıyla: "takat: Ayşe'ye bağlı").
- Sayılar göstergelerin yanında kalır (sayısal şeffaflık kuralı).

## Planlayıcı sözü

Yorgunluk yürüme hızını kişi başına değil kervan için (en yorgun) belirler. Planlayıcı bugünkü takat varsayımıyla çalışıyor; yorgunluk yalnızca gönüllü hızlı tempoyu sınırlarsa söz bozulmaz. Normal tempoda yorgunluk hızı **düşürmez**, yalnızca hızlı tempoyu kilitler.

## Onaydan sonra iş

1. `CharacterData.fatigue` + kayıt; `CaravanState.stamina` yerine `GameSession.get_caravan_stamina()` (en yorgun).
2. Kaynaklar ve iniş (kamp, şehir, orta bölge).
3. Kadro kartında çubuk; Durum'da "kime bağlı".
4. Testler: normal tempoda hız değişmez (erzak sözü), yorgun öncü cezası, kayıt.

## Onay için sorular

1. Yorgunluk savaşta ceza olsun mu, yoksa yalnızca yolda mı?
2. Kervan takati "en yorgun kişi" mi, "ortalama" mı?

## Ne yapıldı

- `CharacterData.fatigue` (0-100, kayıtlı; eski kayıt `.get("fatigue", 0)` ile dinlenmiş yüklenir). İri beden artışları %25 fazla yazar (`FATIGUE_HEAVY_GAIN_MULT`; kaynaklar 4'ün katı: 4 -> 5, 8 -> 10).
- Artıranlar (`GameSession`): hızlı tempo günü herkese +8, ışıksız gece saatte 0,5 (4'lük dilimlerle), öncü günde +4, erken yola düşmek +4, savaşa giren +8. İndirenler: kamp ateşi -30, şehir varışı -60, ortancı (kervanın ortasında yürüyen) günde -4.
- Kervanın takati `GameSession.get_caravan_stamina()` = min(`caravan.stamina`, 100 - en yüksek yorgunluk). Hızlı tempo kilidi ve tükenince normale dönüş `can_push_pace()` ile buna bakar; bağlayan kişi `get_stamina_binder()`. Yürüyüş hızına ve erzak formülüne yorgunluk hiç girmez: normal tempo yavaşlamaz (planlayıcı sözü, `tests/test_fatigue.gd`).
- Savaş cezası `_fatigue_bonus_sum` sarmalayıcısıyla `get_accuracy()`/`get_dodge()`'da: 60'tan itibaren -2, 85'ten itibaren -4; hasar ve can etkilenmez.
- Yol paneli: Kadro kartında Can ve Stres'in altında "Yorgunluk" çubuğu (sayı yanında), cezalıysa notta "Yorgun: isabet/kaçınma -N", başlıkta kırgınlık işaretleri. Kervanın hâli sütununda Takat türetilmiş değeri gösterir; bir beden bağlıyorsa altında "Takat en yorgun kişiye bağlı: <ad> (N)". Üst şeridin takat şişesinin ipucu da adı söyler.
