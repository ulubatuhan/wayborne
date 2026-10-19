# Yerelleştirme sırası ve terim sözlüğü (Y-J13)

## Çeviri sırası

Kaynak dil Türkçe, yedek dil İngilizce (`locale/fallback="en"`). Diller şu sırayla doldurulur:

1. **Türkçe** ve **İngilizce:** her zaman eksiksiz (`test_localization.gd` iki sütunun boş kalmasına izin vermez).
2. **Basitleştirilmiş Çince** (`zh_CN`): Steam'in en büyük ikinci dil kitlesi; CJK yazı tipi alt kümesi doldurulunca
   yeniden kesilir (`tools/cjk_font_subset.py`).
3. **Almanca** (`de`).
4. **Rusça** (`ru`).
5. Sonra: Fransızca, İspanyolca, İtalyanca, Brezilya Portekizcesi, Lehçe, Japonca. Boş hücre İngilizceye düşer, oyun
   eksik dille de çalışır.

Kurallar: anahtar değil metin çevrilir; `%s` ve `%d` yer tutucuları aynı sayıda ve aynı sırada kalır (test bunu
denetler). Özel adlar (yerleşimler, kişi adları) çevrilmez.

## Terim sözlüğü

Metin hacmi büyümeden önce sabitlenen terimler. Bir terim burada değişirse bütün CSV'lerde birlikte değişir. Boş
hücre: henüz karar verilmedi, çevirmen önerir.

| Kavram | Türkçe | İngilizce | Not |
|---|---|---|---|
| Kervanın kendisi | kervan | caravan | |
| Kervanın başı | kervanbaşı | caravan master | Lider, oyuncu karakteri |
| Savaşan kadro | kadro, parti | company | En fazla dört kişi; tayfa değil |
| İsimsiz sürücüler | tayfa | crew | Savaşmaz; vagon başına iki kişi |
| Defter | defter | ledger | Ölenler çizili kalır |
| Soy, kuşak | soy, kuşak | lineage, generation | |
| Moral | moral | morale | Seferin havası |
| Stres | stres | stress | Kişi başına, kalıcı |
| Takat | takat | stamina | Tempo zorlanınca tükenir |
| Kırılma | kırılmak | to break | Stres eşiği aşılınca |
| Kırgınlık | kırgınlık | grievance | Bir kişiye yapılan; unutulmaz |
| Ölümün Kıyısı | Ölümün Kıyısı | Death's Door | |
| Huy | huy | trait | Erdem ya da illet |
| Görev (kervan işi) | görev | duty | Muhafız, İzci, Levazımcı, Arabacı, Tellal, Otacı |
| Muhafız | Muhafız | Guard | |
| İzci | İzci | Scout | |
| Levazımcı | Levazımcı | Quartermaster | |
| Arabacı | Arabacı | Wagoner | |
| Tellal | Tellal | Crier | |
| Otacı | Otacı | Herbalist | |
| Sınıf | sınıf | class | |
| Sıra Neferi | Sıra Neferi | Rank Soldier | |
| Sekban | Sekban | Sekban | Özel ad gibi çevrilmez |
| Kırıkçı | Kırıkçı | Breaker | |
| Kalem Efendisi | Kalem Efendisi | Clerk | |
| Kontrat | kontrat | contract | Lonca verir |
| Lonca | Tüccar Loncası | Merchants' Guild | |
| Kervan avlusu | Kervan Avlusu | Caravan Yard | |
| Pazar | Pazar Meydanı | Market Square | |
| Taverna | Taverna | Tavern | |
| Kilise | Kilise | Church | Gerçek bir dinin adı geçmez |
| Kervansaray | kervansaray | caravanserai | |
| Erzak | erzak | provisions | |
| Kese | kese | purse | Altın |
| Altın birimi | GG | gold (GG) | |
| İtibar | itibar | reputation | |
| Borç | borç | debt | |
| Söylenti | söylenti, dedikodu | rumour | |
| Yol işareti | işaret | sign | Gıcırdayan tekerlek gibi |
| Dikkat bölgesi | kolonun önü, vagonlar, artçı | head, wagons, rear | |
| Kamp | kamp | camp | |
| Sofra | sofra | supper | Kim yesin kararı |
| Bozkır | bozkır | steppe | Biyom |
| Çayır | çayır | meadow | Biyom (vadi) |
| Orman | orman | forest | Biyom |
| Göl kıyısı | göl kıyısı | lakeshore | Biyom |
| Dağ yolu | dağ yolu | mountain road | Biyom |
| Bataklık | bataklık | marshland | Biyom |
| Köy (durak) | Köy | Village | |
| Askeri Karakol | Askeri Karakol | Military Outpost | |
| Geçit | Geçit | Mountain Pass | |
| Yol Sunağı | Yol Sunağı | Roadside Shrine | |

## Kültür adları

| Türkçe | İngilizce |
|---|---|
| Göçebe Boyları | Nomad Clans |
| Vadi Loncaları | Valley Guilds |
| Dağ Kabilesi | Mountain Tribe |
| Liman Şehri | Port City |
| Balıkçı Kasabası | Fishing Town |
