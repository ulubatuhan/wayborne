# Moral ve takat: kervanın nefesi, kişinin bedeni (Y-F01)

Durum: tasarım notu, kullanıcı onayı bekliyor. Kod henüz değişmedi.

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
