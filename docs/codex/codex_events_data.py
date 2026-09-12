# -*- coding: utf-8 -*-
"""Yirmi yedi yol olayının tam ağacı. Kaynak: scripts/events/event_catalog.gd"""

EVENTS = [
# ---------------------------------------------------------------- ÇATIŞMA
{
 "id": "evt_bandit_ambush", "title": "Haydut Pususu", "weight": "1.4",
 "cooldown": 2, "kind": "Yol · çatışma",
 "flavor": "Yolun daraldığı yerde önünüzü kestiler. Sayıları belli değil, niyetleri belli.",
 "trigger": "Koşulsuz - her gün havuzda. <b>Tehlike ≥ %50 olan yollarda ağırlığı ikiye katlanır</b> "
            "(1.4 → 2.8), yani tehlikeli bir yolda pusuya düşme ihtimali iki katına çıkar.",
 "options": [
   {"label": "Fidyeyi öde (120 GG)", "condition": "kese ≥ 120",
    "locked": "Yeterli altının yok",
    "effects": [("GOLD", -120), ("MORALE", -5)]},
   {"label": "Direnç göster",
    "effects": [("TRIGGER_COMBAT", 0, "haydut kadrosu")]},
   {"label": "Pazarlığa otur",
    "effects": [("TRIGGER_HAGGLING", 200, "liste fiyatı 200 GG")]},
 ],
 "note": "Üç seçenek üç ayrı sistemi açıyor: kese, savaş paneli, pazarlık mini-oyunu. "
         "“Direnç göster” eskiden zar atıyordu; artık gerçek savaşı açıyor - olayın sonucu "
         "şansın değil, kadronun dizilişinin ve yeteneklerinin işi. Pazarlıkta masadan "
         "kalkarsan yol haydutunun öfkesi şehirde duyulmaz (itibar cezası yok) ama haracın "
         "tamamını <b>spend_or_owe</b> ile ödersin - kese boşsa borca yazılır, kaçış yok.",
},
{
 "id": "evt_wild_animal", "title": "Yol Kesen Vahşi", "weight": "1.0",
 "cooldown": 3, "kind": "Yol · çatışma",
 "flavor": "Çalılıkta bir hareket. Ne olduğunu anlamadan kervan durdu.",
 "trigger": "Koşulsuz. Kadro <b>EnemyCatalog.build_wildlife_squad</b>'tan gelir: kurt sürüsü "
            "(hızlı, kalabalık), ayı (tek ve ezici, 62 HP), yaban domuzu (ortada, saldırgan).",
 "options": [
   {"label": "Kovala, gerekirse dövüş",
    "effects": [("TRIGGER_COMBAT", 0, "vahşi hayvan kadrosu")]},
   {"label": "Biraz erzak bırak, sakince uzaklaş",
    "effects": [("PROVISIONS", -3), ("MORALE", 2)]},
   {"label": "Aceleyle etrafından dolaş",
    "effects": [("DANGER", 8), ("MORALE", -3)]},
 ],
 "note": "Savaşsız iki çıkış var ama ikisi de bedelli: beslemek erzak yer, kaçmak tehlikeyi "
         "artırır - ürkütülen hayvanlar iz bırakır. Bedava çıkış yok kuralının tipik hali.",
},
{
 "id": "evt_guard_patrol", "title": "Muhafız Devriyesi", "weight": "0.9",
 "cooldown": 5, "kind": "Yol · çatışma",
 "flavor": "Kervanın adı önden gitmiş. Devriye sizi bekliyordu.",
 "trigger": "<b>İtibar ≤ 10</b>. Düşük itibarlı bir kervan şehir muhafızlarının dikkatini çeker - "
            "yani kendi geçmişinin sonucu olarak çıkan tek çatışma olayı bu.",
 "options": [
   {"label": "Rüşvet ver, sessizce geç (100 GG)", "condition": "kese ≥ 100",
    "locked": "Yeterli altının yok",
    "effects": [("GOLD", -100), ("REPUTATION", -2)]},
   {"label": "Aralarından zorla geç", "outcomes": [
     {"label": "Sıyrılıyorsun", "weight": "1.0", "effects": [("DANGER", 10)]},
     {"label": "Yakalanıyorsun", "weight": "1.3",
      "effects": [("GOLD", -120), ("REPUTATION", -10), ("DOCUMENT_LOSE", 1)]},
   ]},
   {"label": "Direniş göster",
    "effects": [("TRIGGER_COMBAT", 0, "muhafız kadrosu")]},
 ],
 "note": "Bu savaşı <b>kazanmak bile itibar kaybettirir</b> (bkz. road_journey.gd, "
         "GUARD_VICTORY_REPUTATION). Kanunla çatışmanın haydutla çatışmadan farkı burada: "
         "haydutu yenmek adını duyurur, muhafızı yenmek adını kirletir. Bu da bir kısır döngü "
         "kurar - itibar düştükçe devriye daha sık çıkar, direndikçe itibar daha da düşer.",
},
# ---------------------------------------------------------------- KERVAN
{
 "id": "evt_customs_checkpoint", "title": "Gümrük Kontrolü", "weight": "1.2",
 "cooldown": 0, "kind": "Yol · idare",
 "flavor": "Bariyerin ardındaki memur, defterini açmadan önce kervana uzun uzun baktı.",
 "trigger": "Koşulsuz, beklemesiz - havuzun en sık çıkan kartlarından biri.",
 "options": [
   {"label": "Evrakları göster", "condition": "evrak ≥ 1",
    "locked": "Geçerli evrakın yok",
    "effects": [("REPUTATION", 3), ("TRAVEL_DAYS", 1)]},
   {"label": "Rüşvet ver (80 GG)", "condition": "kese ≥ 80",
    "locked": "Yeterli altının yok",
    "effects": [("GOLD", -80), ("REPUTATION", -2)]},
   {"label": "Bariyeri zorla geç", "outcomes": [
     {"label": "Kervan bariyeri devirip uzaklaştı", "weight": "1.0",
      "effects": [("DANGER", 15), ("MORALE", 5)]},
     {"label": "Bir sonraki köyde yakalandınız", "weight": "1.4",
      "effects": [("DOCUMENT_LOSE", 2), ("GOLD", -150), ("REPUTATION", -8)]},
   ]},
 ],
 "note": "Üç seçenek üç farklı kaynağı harcıyor: zaman (dürüstlük bir gün yer), para, risk. "
         "Kaçmanın kötü sonucu daha ağırlıklı (1.4 / 1.0), yani beklenen değeri negatif - "
         "kumar, kârlı bir kaçamak değil.",
},
{
 "id": "evt_broken_axle", "title": "Kırılan Aks", "weight": "1.0",
 "cooldown": 0, "kind": "Yol · kervan",
 "flavor": "Çatırtıyı herkes duydu. Vagon eğildi ve kervan durdu.",
 "trigger": "<b>Vagon sayısı ≥ 2</b>. Tek vagonlu bir kervanda bu kart hiç çıkmaz - "
            "koşul, olayın anlatısının doğru olmasını sağlıyor.",
 "options": [
   {"label": "Düzgün tamir ettir (60 GG, 1 gün)", "condition": "kese ≥ 60",
    "locked": "Yeterli altının yok",
    "effects": [("GOLD", -60), ("TRAVEL_DAYS", 1)]},
   {"label": "Böyle devam et",
    "effects": [("WAGON_DAMAGE", 1), ("MORALE", -8)]},
   {"label": "Yükü hafiflet",
    "effects": [("ITEM_REMOVE", 3, "Top Kumaş"), ("MORALE", -4)]},
 ],
 "note": "Klasik üçlü: parayla çöz, sorunu ertele (hasar birikir, varışta ödeme kesilir), "
         "ya da malı at. Üçüncü seçenek envanterinde kumaş yoksa hiçbir şey almaz - "
         "ITEM_REMOVE var olmayan malı silemez, yani o durumda ucuz bir çıkış olur.",
},
{
 "id": "evt_storm", "title": "Fırtına", "weight": "1.1",
 "cooldown": 3, "kind": "Yol · doğa",
 "flavor": "Gökyüzü öğleden sonra karardı. Rüzgâr çadır bezini yırtacak gibi.",
 "trigger": "Koşulsuz.",
 "options": [
   {"label": "Sığınak ara ve bekle",
    "effects": [("TRAVEL_DAYS", 1), ("PROVISIONS", -3)]},
   {"label": "Fırtınaya rağmen ilerle", "outcomes": [
     {"label": "Islanıp üşüdünüz ama kervan bütün halinde geçti", "weight": "1.0",
      "effects": [("MORALE", -5)]},
     {"label": "Bir vagon çamura saplanıp devrildi", "weight": "1.0",
      "effects": [("WAGON_DAMAGE", 1), ("PROVISIONS", -4), ("MORALE", -12)]},
     {"label": "Sel suyu bir vagonu söküp götürdü", "weight": "0.4",
      "effects": [("WAGON_LOSE", 1), ("PROVISIONS", -6), ("MORALE", -16), ("STRESS", 10)]},
   ]},
 ],
 "note": "Kervanın gerçekten <b>vagon kaybedebildiği iki kapıdan biri</b> (diğeri Heyelan). "
         "Ağırlığı bilerek düşük (0.4 / toplam 2.4 ≈ %17): kayıp bir ceza değil, hatırlanacak "
         "bir felaket olmalı. Ölçüm: ~40 seferde bir vagon. Kayıp <b>MIN_WAGONS</b>'a kenetli, "
         "yani oyuncunun kendi vagonu asla gitmez.",
},
{
 "id": "evt_landslide", "title": "Heyelan", "weight": "0.7",
 "cooldown": 12, "kind": "Yol · doğa · rota",
 "flavor": "Yamaç gece kaymış. Geçit yarıya kadar toprakla dolu.",
 "trigger": "Koşulsuz ama <b>12 günlük bekleme</b> - havuzun en uzun beklemesi. Aynı geçidin "
            "iki kez üst üste kapanması dünyayı inandırıcı olmaktan çıkarırdı.",
 "options": [
   {"label": "Enkazın kenarından sıyrılıp geç", "outcomes": [
     {"label": "Tekerlekler uçurumun kıyısını sıyırdı", "weight": "3.0",
      "effects": [("ROUTE_CHANGE", 14, "bu yol 14 gün KAPALI"), ("TRAVEL_DAYS", 1),
                  ("WAGON_DAMAGE", 1), ("STRESS", 4)]},
     {"label": "Kayan toprak bir vagonun altını boşalttı", "weight": "1.0",
      "effects": [("ROUTE_CHANGE", 14, "bu yol 14 gün KAPALI"), ("TRAVEL_DAYS", 1),
                  ("WAGON_LOSE", 1), ("MORALE", -10), ("STRESS", 8)]},
   ]},
   {"label": "Tayfayı indir, yolu bir nebze aç",
    "effects": [("ROUTE_CHANGE", 8, "bu yol 8 gün YAVAŞ"), ("TRAVEL_DAYS", 2),
                ("MORALE", -4), ("REPUTATION", 1)]},
 ],
 "note": "Bu olayın asıl etkisi kendi seferinde değil <b>sonraki seferlerde</b>. ROUTE_CHANGE "
         "coğrafyaya dokunmaz - yedi kenarlık harita sabit kalır - ama üstündeki ağı oynatır: "
         "iki hafta o yoldan dönemezsin. İkinci seçenek yolu kapatmak yerine yavaşlatır ve "
         "itibar kazandırır: arkadan gelen kervanlar geçebilsin diye harcanan iki gün.",
},
{
 "id": "evt_spoiled_provisions", "title": "Bozulan Erzak", "weight": "0.9",
 "cooldown": 0, "kind": "Yol · kervan",
 "flavor": "Çuvalın dibi ıslak. Koku çoktan yayılmış.",
 "trigger": "<b>Erzak ≥ 5</b>. Zaten aç bir kervanda bozulacak erzak yoktur.",
 "options": [
   {"label": "Levazımcı çuvalları erkenden yokladı", "condition": "kervanda Levazımcı var",
    "locked": "Levazımcın yok",
    "effects": [("PROVISIONS", -1), ("MORALE", 2)]},
   {"label": "Otacı bozulanı yahniye çevirsin", "condition": "kervanda Otacı var",
    "locked": "Otacın yok",
    "effects": [("PROVISIONS", -2), ("MORALE", -4)]},
   {"label": "Kalanı herkese eşit paylaştır",
    "effects": [("PROVISIONS", -4), ("MORALE", -5)]},
   {"label": "Tüccarların payını kes",
    "effects": [("PROVISIONS", -4), ("MORALE", -15), ("REPUTATION", -3), ("PROVISIONS", 2)]},
 ],
 "note": "Görev sisteminin en net örneği: aynı olay, kervanında kim varsa ona göre farklı "
         "kapılar açıyor. Levazımcı kaybı 4'ten 1'e indiriyor <b>ve</b> moral veriyor - "
         "bozulmayı erken fark etmek bir başarıdır. Görevin olmaması bir ceza değil, "
         "yalnızca o kapının kapalı olması; kilitli seçenek gizlenmiyor, sebebiyle gösteriliyor.",
},
{
 "id": "evt_sick_merchant", "title": "Hasta Tüccar", "weight": "0.9",
 "cooldown": 0, "kind": "Yol · kervan",
 "flavor": "Ateşi sabaha düşmedi. Yürüyecek hali yok.",
 "trigger": "<b>Kervanda en az 1 tüccar</b> (kontrat escortu) olmalı.",
 "options": [
   {"label": "Hekim çağır (90 GG, 1 gün)", "condition": "kese ≥ 90",
    "locked": "Yeterli altının yok",
    "effects": [("GOLD", -90), ("TRAVEL_DAYS", 1), ("MORALE", 10), ("REPUTATION", 5)]},
   {"label": "Bir handa bırak",
    "effects": [("MERCHANT_LEAVE", 1), ("MORALE", -18), ("REPUTATION", -6)]},
 ],
 "note": "Havuzun en pahalı ihmali. Tüccarı bırakmak yalnızca o anki morali kırmaz: "
         "kontrat teslim edilemez sayılır ve varışta <b>ayrıca</b> itibar cezası kesilir "
         "(REPUTATION_PENALTY_PER_LOST_CONTRACT = 5). Yani ihmalin faturası iki kere gelir.",
},
{
 "id": "evt_traveling_tinker", "title": "Gezgin Demirci", "weight": "0.7",
 "cooldown": 6, "kind": "Yol · ticaret",
 "flavor": "Katırının sırtındaki takırtıyı duyduğunuzda daha kendisini görmemiştiniz.",
 "trigger": "Koşulsuz.",
 "options": [
   {"label": "Bir silah satın al (120 GG)", "condition": "kese ≥ 120",
    "locked": "Yeterli altının yok",
    "effects": [("GOLD", -120), ("GRANT_EQUIPMENT", 0, "Kervan Kılıcı (tier 1)")]},
   {"label": "Hasarlı vagonu onart (60 GG)",
    "condition": "kese ≥ 60 <b>ve</b> hasarlı vagon ≥ 1",
    "locked": "Onarılacak vagon ya da yeterli kese yok",
    "effects": [("GOLD", -60), ("WAGON_REPAIR", 1), ("MORALE", 4)]},
   {"label": "Yedek parça al (35 GG)", "condition": "kese ≥ 35",
    "locked": "Kese yetmiyor",
    "effects": [("GOLD", -35), ("SET_FLAG", 0, "yedek parça bayrağı"), ("MORALE", 2)]},
   {"label": "İlgilenmiyorsun", "effects": [("MORALE", 1)]},
 ],
 "note": "Şehirdeki Kervan Avlusu'nun yol karşılığı, biraz daha pahalı. Onarım seçeneği "
         "<b>iki koşullu</b>: para <i>ve</i> onarılacak vagon. Bu, kilitli seçeneğin "
         "tek bir sebebe bağlı olmadığı tek örnek; kilit metni de ikisini birden anlatıyor.",
},
# ---------------------------------------------------------------- İNSAN
{
 "id": "evt_road_wanderer", "title": "Yol Kenarındaki Yolcu", "weight": "0.9",
 "cooldown": 6, "kind": "Yol · insan · mizaç",
 "flavor": "Taşın üstünde oturuyordu. Ne kaçmaya çalıştı ne de yaklaştı.",
 "trigger": "Koşulsuz.",
 "immediate": [("ROLL_ENCOUNTER", 0, "önek: wanderer")],
 "immediate_note": "Yolcunun gizli mizacı <b>kart açılır açılmaz</b> yuvarlanır: sadık %42, "
                   "çaresiz %24, hırsız %18, kinci %16. Sonuçlar bu bayrağa dallanır. "
                   "Aynı anda kültür yakınlığı da yuvarlanır - kendi boyundan çıkarsa "
                   "<b>wanderer_kin</b> bayrağı kurulur.",
 "options": [
   {"label": "Konuş, partine katmayı düşün", "condition": "boş parti yeri ≥ 1",
    "locked": "Vagonlarında yer yok",
    "effects": [("TRIGGER_RECRUIT", 0, "tayfa ekranı açılır")]},
   {"label": "Erzak ver, yoluna gönder", "outcomes": [
     {"label": "Kendi boyunun türküsü döküldü ağzından", "weight": "4.0",
      "condition": "wanderer_kin bayrağı",
      "effects": [("PROVISIONS", -3), ("MORALE", 10), ("REPUTATION", 3)]},
     {"label": "Sabah erzak çuvalının ağzı gevşek bulundu", "weight": "4.0",
      "condition": "mizaç = hırsız",
      "effects": [("PROVISIONS", -5), ("MORALE", 2)]},
     {"label": "Karnını doyurdu, yoluna gitti", "weight": "1.0",
      "effects": [("PROVISIONS", -3), ("MORALE", 5)]},
   ]},
   {"label": "Görmezden gel", "outcomes": [
     {"label": "Yüzündeki ifade değişti - bu yüzü bir daha göreceksiniz", "weight": "4.0",
      "condition": "mizaç = kinci",
      "effects": [("MORALE", -2), ("SET_FLAG", 0, "wanderer_scorned"),
                  ("UNLOCK_EVENT", 0, "evt_wanderer_revenge")]},
     {"label": "Omuz silkip yoluna döndü", "weight": "1.0",
      "effects": [("MORALE", -2)]},
   ]},
 ],
 "note": "Oyunun karakter-duyarlı olay mimarisinin ana örneği. Aynı seçenek, karşındakinin "
         "kim olduğuna göre bambaşka sonuç verir - ve oyuncu kim olduğunu <b>bilmez</b>. "
         "Sezgisi kuvvetli (etkin Sezgi ≥ 2) bir parti üyesi yalnızca bir <i>ipucu</i> alır. "
         "Koşullu sonuçların ağırlığı 4.0, düz sonucunki 1.0: mizaç tuttuğunda neredeyse "
         "kesin o dal çekilir, ama garanti değil.",
},
{
 "id": "evt_wanderer_revenge", "title": "Tanıdık Bir Yüz", "weight": "3.0",
 "cooldown": 0, "kind": "ZİNCİR · yalnızca tetiklenir",
 "repeat": "ömürde bir kez",
 "flavor": "Yolun ortasında duruyor. Yanında da yalnız değil.",
 "trigger": "<b>Havuzdan rastgele çekilmez.</b> Yalnızca <b>wanderer_scorned</b> bayrağı kurulmuşsa "
            "ve UNLOCK_EVENT onu açtıysa uygun hale gelir. Açıldığında ağırlığı 3.0'dır - "
            "yani açıldığı gün çekilme ihtimali yüksektir.",
 "options": [
   {"label": "Hesabı burada kapat",
    "effects": [("TRIGGER_COMBAT", 0, "haydut kadrosu"), ("CLEAR_FLAG", 0, "wanderer_scorned")]},
   {"label": "İstediğini ver, geç git",
    "effects": [("GOLD", -120), ("MORALE", -6), ("CLEAR_FLAG", 0, "wanderer_scorned")]},
 ],
 "note": "“Kararın faturası hemen kesilmez” deseninin tek canlı örneği. Kinci bir yolcuyu "
         "görmezden gelmek o gün yalnızca -2 moral - ucuz görünür. Bedel <b>günler sonra</b>, "
         "bambaşka bir yolda gelir. Denge simülatörü bu olayı “hiç ateşlenmiyor” diye raporlar; "
         "bu simülatörün sınırı, oyunun hatası değil - politikası hep ilk seçeneği aldığı için "
         "yolcuyu asla görmezden gelmez ve zinciri hiç açmaz.",
},
{
 "id": "evt_stowaway", "title": "Kaçak Yolcu", "weight": "0.7",
 "cooldown": 0, "kind": "Yol · insan · mizaç",
 "repeat": "ömürde bir kez",
 "flavor": "Çuvalların arasında kıvrılmış uyuyordu. Ne zamandır orada olduğu belli değil.",
 "trigger": "Koşulsuz ama <b>oyun boyunca yalnızca bir kez</b> çıkar.",
 "immediate": [("ROLL_ENCOUNTER", 0, "önek: stowaway")],
 "options": [
   {"label": "Kervanda kalmasına izin ver", "outcomes": [
     {"label": "Sabaha kese hafiflemişti", "weight": "4.0", "condition": "mizaç = hırsız",
      "effects": [("PROVISIONS", -2), ("GOLD", -90), ("MORALE", -8)]},
     {"label": "Gözlerindeki bakış borcunu unutmayacağını söylüyor", "weight": "1.0",
      "effects": [("PROVISIONS", -2), ("MORALE", 4), ("SET_FLAG", 0, "stowaway_helped"),
                  ("UNLOCK_EVENT", 0, "evt_stowaway_repay")]},
   ]},
   {"label": "İlk karakolda teslim et", "outcomes": [
     {"label": "Götürülürken size döndü ve hiçbir şey söylemedi", "weight": "4.0",
      "condition": "mizaç = kinci",
      "effects": [("GOLD", 30), ("REPUTATION", -3), ("MORALE", -6),
                  ("SET_FLAG", 0, "wanderer_scorned"), ("UNLOCK_EVENT", 0, "evt_wanderer_revenge")]},
     {"label": "Kese doldu ama kadro bir süre yüzünüze bakmadı", "weight": "1.0",
      "effects": [("GOLD", 30), ("REPUTATION", -3), ("MORALE", -6)]},
   ]},
 ],
 "note": "İki zincirin de başlangıcı: merhamet <b>evt_stowaway_repay</b>'i, ihanet "
         "<b>evt_wanderer_revenge</b>'i açar. Aynı intikam zinciri iki ayrı olaydan "
         "beslendiği için oyuncu onu kimin gönderdiğini bilmez - yol kenarında kovduğun "
         "yolcu mu, karakola verdiğin kaçak mı.",
},
{
 "id": "evt_stowaway_repay", "title": "Bir Borcun Karşılığı", "weight": "3.0",
 "cooldown": 0, "kind": "ZİNCİR · yalnızca tetiklenir",
 "repeat": "ömürde bir kez",
 "flavor": "Elinde bir keseyle bekliyordu. Yüzü tanıdık.",
 "trigger": "Yalnızca <b>stowaway_helped</b> bayrağı varsa ve zincir açıldıysa.",
 "options": [
   {"label": "Keseyi kabul et (200 GG)",
    "effects": [("GOLD", 200), ("MORALE", 8)]},
   {"label": "Parayı reddet",
    "effects": [("REPUTATION", 8), ("MORALE", 12)]},
 ],
 "note": "Havuzdaki en saf “para mı itibar mı” kararı. 200 altın erken oyunda büyük paradır; "
         "8 itibar ise kampanyanın üçüncü bölümünün kapısının yarısı ve lonca kredisinin "
         "200 GG hat genişlemesi demektir. Ölçüm itibarın oyunun en kıt kaynağı olduğunu "
         "gösterdi - bu yüzden reddetmek göründüğünden daha güçlü bir hamle.",
},
{
 "id": "evt_kin_encounter", "title": "Yolda Bir Oba", "weight": "0.8",
 "cooldown": 8, "kind": "Yol · insan · kültür",
 "flavor": "Ateşin dumanı uzaktan göründü. Çadırların dizilişi tanıdık geldi.",
 "trigger": "Koşulsuz - <b>her kültüre açık</b>. Fark, karşılaştığın obanın seninle aynı "
            "kültürden çıkıp çıkmamasında.",
 "immediate": [("ROLL_ENCOUNTER", 0, "önek: kin")],
 "options": [
   {"label": "Erzak için pazarlık et", "outcomes": [
     {"label": "Ölçüyü bol tuttu, üstüne yol azığı kattı", "weight": "4.0",
      "condition": "kin_kin bayrağı (aynı kültür)",
      "effects": [("GOLD", -20), ("PROVISIONS", 8), ("MORALE", 4)]},
     {"label": "Dürüst bir alışveriş", "weight": "1.0",
      "effects": [("GOLD", -20), ("PROVISIONS", 4)]},
   ]},
   {"label": "Selam ver, ateşlerine otur", "outcomes": [
     {"label": "Sabaha kadar türkü söylendi", "weight": "4.0",
      "condition": "kin_kin bayrağı",
      "effects": [("MORALE", 10), ("REPUTATION", 4), ("STRESS", -6)]},
     {"label": "Bir tas çorba içirildi", "weight": "1.0",
      "effects": [("MORALE", 4), ("REPUTATION", 1)]},
   ]},
 ],
 "note": "Eskiden yalnızca Göçebe oyunculara açıktı; bu, dört kültürü olaydan dışlıyordu. "
         "Artık kültür yakınlığı <b>ROLL_ENCOUNTER</b>'ın ikinci işi: hangi kültürü seçersen "
         "seç, kendi boyunla karşılaşmak ayrı bir kapı açar. Aynı erzak 20 altına 4 yerine "
         "8 gelir - yani kültür, perkinin dışında da oyunda görünür.",
},
# ---------------------------------------------------------------- İÇ DÜNYA
{
 "id": "evt_mutiny", "title": "Kervanda Huzursuzluk", "weight": "2.0",
 "cooldown": 4, "kind": "Yol · kriz",
 "flavor": "Akşam ateşinin başında sesler alçaldı. Sen yaklaşınca büsbütün sustular.",
 "trigger": "<b>Moral ≤ 40</b> <b>ve</b> kervanda en az 1 tüccar. Ayrıca moral eşiğin altındayken "
            "ağırlığı <b>×24</b> ile çarpılır (2.0 → 48.0).",
 "options": [
   {"label": "Fazladan pay dağıt (100 GG)", "condition": "kese ≥ 100",
    "locked": "Yeterli altının yok",
    "effects": [("GOLD", -100), ("MORALE", 30)]},
   {"label": "Söz ver, oyala", "condition": "partide etkin Karizma ≥ 2 olan biri",
    "locked": "Bu kadroyu lafla yatıştıracak dilin yok",
    "effects": [("MORALE", 22), ("REPUTATION", -2), ("STRESS", 5)]},
   {"label": "Otoriteni göster", "outcomes": [
     {"label": "Homurdanma kesildi. Şimdilik.", "weight": "1.0",
      "effects": [("MORALE", 10)]},
     {"label": "Sabaha iki tüccar ve yükleri ortadan kaybolmuştu", "weight": "1.2",
      "effects": [("MERCHANT_LEAVE", 2), ("MORALE", -10), ("REPUTATION", -5)]},
   ]},
 ],
 "note": "Bu olay <b>×24 ağırlık çarpanı olmadan hiç ateşlenmiyordu</b>. Eşiği 25'ten 40'a "
         "çekmek yetmedi: moral eşiğin altına indiği 45 günde bile kart ~25 rakip arasında "
         "çekimi hiç kazanamadı. Ders: bir olayın uygun olması yetmez, çekimi de kazanması "
         "gerekir. Kriz kartları baskın ağırlık taşımalı - moral dibe vurduğunda kervanın "
         "o gün yaşayacağı şey isyandır, yol kenarındaki bir türbe değil.",
},
{
 "id": "evt_stress_brawl", "title": "Kamp Kavgası", "weight": "1.3",
 "cooldown": 4, "kind": "Yol · kriz",
 "flavor": "İki kişi arasında başlayan laf, yumruğa döndü. Kimse ayırmaya koşmadı.",
 "trigger": "<b>Parti stresi ≥ 40</b>. Stres bağlamda hazır olduğu için olayın kendi koşulu "
            "doğrudan ona bakar - ayrı bir ağırlık değiştiricisi gerekmez.",
 "options": [
   {"label": "Araya gir, ayır",
    "effects": [("MORALE", -5), ("STRESS", -15)]},
   {"label": "Kendi hallerine bırak", "outcomes": [
     {"label": "İkisi de yoruldu, gerginlik biraz dağıldı", "weight": "1.0",
      "effects": [("STRESS", -5)]},
     {"label": "Kavga büyüdü, bir vagonun malı dökülüp kırıldı", "weight": "1.3",
      "effects": [("MORALE", -12), ("STRESS", 10), ("GOLD", -30)]},
   ]},
 ],
 "note": "Stresin kendi olayı - Darkest Dungeon'daki gibi tükenmiş bir kadro birbirine düşer. "
         "Eşik 70'ten 40'a indi çünkü ölçüm varış stresinin ortalama ~25 olduğunu ve 70'in "
         "hiçbir zaman görülmediğini gösterdi. Müdahale etmek garantili iyi (-15 stres), "
         "bırakmak beklenen değeri negatif bir kumar.",
},
{
 "id": "evt_troubled_night", "title": "Sıkıntılı Gece", "weight": "0.8",
 "cooldown": 5, "kind": "Yol · iç dünya",
 "flavor": "Gece uzun. Ateş sönmek üzere ve gölgeler kıpırdıyor gibi.",
 "trigger": "Koşulsuz.",
 "options": [
   {"label": "Nöbet tut, uyumaya kalkma",
    "effects": [("PROVISIONS", -2), ("MORALE", -3), ("STRESS", 5)]},
   {"label": "Uyumaya çalış", "outcomes": [
     {"label": "Kâbussuz, dinlendirici bir uyku", "weight": "1.4",
      "effects": [("MORALE", 6), ("STRESS", -8)]},
     {"label": "Kâbuslar sabaha kadar sürdü", "weight": "1.0",
      "effects": [("MORALE", -10), ("STRESS", 12), ("GRANT_TRAIT", 0, "Beceriksiz Ayak")]},
   ]},
 ],
 "note": "<b>GRANT_TRAIT</b>'in ilk canlı kullanımı: kötü bir gece kervanın liderine kalıcı bir "
         "huy bırakabilir. Ama “kalıcı” mutlak değil - huy <b>taze</b> sayıldığı beş gün içinde "
         "Kilise'de ucuza, Tavernada pahalıya arındırılabilir. Yani olay bir kapı açıyor, "
         "şehirdeki iki mekân da onu kapatma imkânı satıyor.",
},
{
 "id": "evt_abandoned_wagon", "title": "Terk Edilmiş Vagon", "weight": "0.8",
 "cooldown": 0, "kind": "Yol · ahlak",
 "flavor": "Tekerleği kırık, örtüsü yırtık. Etrafta kimse yok - ne diri ne ölü.",
 "trigger": "Koşulsuz.",
 "options": [
   {"label": "Yükü al", "outcomes": [
     {"label": "Kimse bir şey demedi ama kimse de sevinmedi", "weight": "1.0",
      "effects": [("ITEM_ADD", 3, "İşlenmiş Kürk"), ("DANGER", 10), ("MORALE", -3)]},
     {"label": "Terk edilmiş vagonun malı uğur getirmez", "weight": "0.9",
      "effects": [("ITEM_ADD", 3, "İşlenmiş Kürk"), ("DANGER", 10), ("MORALE", -12), ("STRESS", 8)]},
     {"label": "Biri sesini yükseltti: bu mal birinin malı", "weight": "0.8",
      "effects": [("ITEM_ADD", 3, "İşlenmiş Kürk"), ("MORALE", -8), ("REPUTATION", -2)]},
   ]},
   {"label": "Dokunma, yoluna devam et", "effects": [("MORALE", 3)]},
   {"label": "Sahibini ara",
    "effects": [("TRAVEL_DAYS", 1), ("MORALE", 6), ("REPUTATION", 3)]},
 ],
 "note": "Yağma <b>her zaman</b> malı verir - üç sonucun üçünde de kürk gelir. Değişen, "
         "kadronun buna ne diyeceği. Yani bu bir şans kartı değil ahlak kartı: kazanç kesin, "
         "bedeli belirsiz. Üçüncü seçenek (sahibini aramak) bir gün yer ama hem morali hem "
         "itibarı yükselten tek yol.",
},
{
 "id": "evt_roadside_shrine", "title": "Yol Kenarı Türbesi", "weight": "0.8",
 "cooldown": 6, "kind": "Yol · curio",
 "flavor": "Taş yığınının üstüne bez bağlanmış. Birileri buraya bir şeyler bırakmış.",
 "trigger": "Koşulsuz, kültürden bağımsız.",
 "options": [
   {"label": "Dur, dua et", "effects": [("STRESS", -10), ("MORALE", 3)]},
   {"label": "Adakları al", "outcomes": [
     {"label": "Adaklar arasında birkaç sikke buluyorsun", "weight": "1.0",
      "effects": [("GOLD", 50)]},
     {"label": "Kervandan biri seni görüyor", "weight": "1.3",
      "effects": [("STRESS", 15), ("REPUTATION", -4)]},
   ]},
 ],
 "note": "Darkest Dungeon'ın curio'su: güvenli kullanım (dua) mütevazı ve garantili, "
         "açgözlü kullanım (adakları almak) beklenen değeri negatif bir kumar. "
         "Stresin ücretsiz düştüğü az sayıdaki yerden biri - kamp ve ziyafetin yanında "
         "üçüncü kol.",
},
{
 "id": "evt_forgotten_cache", "title": "Gömülü Stok", "weight": "0.7",
 "cooldown": 5, "kind": "Yol · curio",
 "flavor": "Toprak burada başka. Biri kazmış, sonra örtmüş.",
 "trigger": "Koşulsuz.",
 "options": [
   {"label": "Kaz, bak neymiş", "outcomes": [
     {"label": "İşlenmiş bir yüzük çıkıyor", "weight": "1.0",
      "effects": [("GRANT_EQUIPMENT", 0, "Nişancı Yüzüğü")]},
     {"label": "Eski bir muska çıkıyor", "weight": "1.0",
      "effects": [("GRANT_EQUIPMENT", 0, "Muska")]},
     {"label": "Kürek tahtaya değil kemiğe çarptı - burası mezar", "weight": "0.8",
      "effects": [("MORALE", -14), ("STRESS", 12), ("GRANT_TRAIT", 0, "Saf")]},
     {"label": "Yalnızca çürümüş erzak ve boşa geçen vakit", "weight": "1.2",
      "effects": [("PROVISIONS", -2), ("MORALE", -3)]},
   ]},
   {"label": "Otacı toprağı okusun", "condition": "kervanda Otacı var",
    "locked": "Toprağı okuyacak otacın yok",
    "effects": [("GRANT_EQUIPMENT", 0, "Muska"), ("MORALE", 3)]},
   {"label": "Dokunma, tuhaf bir his var", "effects": [("MORALE", 2)]},
 ],
 "note": "Trinket'lerin (Yüzük/Kolye) satın alınamadığı, yalnızca bulunduğu iki olaydan biri. "
         "Kazmak dört dallı bir kumar: %50 tılsım, %20 mezar (huy + ağır stres), %30 hiçbir şey. "
         "Otacı bu kumarı <b>garantiye çevirir</b> - toprağı okuyup mezar mı zula mı olduğunu "
         "kazmadan anlar. Görev sisteminin riski kaldırdığı en net örnek.",
},
# ---------------------------------------------------------------- YOL/ROTA
{
 "id": "evt_scouted_pass", "title": "Bilinmeyen Bir Kestirme", "weight": "0.9",
 "cooldown": 4, "kind": "Yol · rota",
 "flavor": "Ana yoldan ayrılan bir patika. Haritada yok.",
 "trigger": "<b>Kalan yol günü ≥ 2</b> - varışa bir gün kala kestirme teklif etmek anlamsız olurdu.",
 "options": [
   {"label": "İzci'nin bildiği kestirmeden git", "condition": "kervanda İzci var",
    "locked": "Kervanda bir İzci yok - kimse bu patikaya güvenmiyor",
    "effects": [("TRAVEL_DAYS", -1), ("DANGER", 5)]},
   {"label": "Ana yolda kal", "effects": [("MORALE", 2)]},
 ],
 "note": "Havuzdaki <b>tek negatif TRAVEL_DAYS</b>: yolu kısaltan başka hiçbir kart yok. "
         "İzci görevinin üç canlı bağlantısından biri (diğerleri: planlayıcıda sefer süresi "
         "kısaltma, dünya haritasında ücretsiz tehlike okuma). İzcisi olmayan oyuncu için bu "
         "kart bir ders: kilitli seçenek gizlenmiyor, bir dahaki sefere neye hazırlanacağını "
         "öğretiyor.",
},
{
 "id": "evt_road_patrol", "title": "Yol Devriyesi", "weight": "0.6",
 "cooldown": 10, "kind": "Yol · rota",
 "flavor": "Mızraklı bir bölük. Bu sefer size değil, yola bakıyorlar.",
 "trigger": "<b>Tehlike ≥ 0.25</b> (yani %25). Bağlamdaki tehlike 0-1 arası bir <i>oran</i>; "
            "koşula 25 yazmak olayın hiç ateşlenmemesi demekti - bunu denge simülatörü yakaladı.",
 "options": [
   {"label": "Devriyeye katıl, yolu temizlemelerine yardım et",
    "effects": [("ROUTE_CHANGE", 12, "bu yol 12 gün AÇIK"), ("DANGER", -10),
                ("REPUTATION", 2), ("TRAVEL_DAYS", 1)]},
   {"label": "Selam ver, kendi hızında devam et", "effects": [("MORALE", 2)]},
 ],
 "note": "ROUTE_CHANGE'in <b>ters yönü</b> ve havuzun tek tehlike düşürücüsü. Yolun hali "
         "yalnızca kötüye gitseydi dinamik rota katmanı bir ceza mekaniği olurdu; "
         "iyileştirilebildiği için gerçek bir dünya katmanı oluyor. Bir gün harcayıp "
         "yolu on iki gün açık tutmak, o hattı tekrar tekrak kullanacak bir oyuncu için yatırımdır.",
},
# ---------------------------------------------------------------- KÜLTÜR
{
 "id": "evt_culture_valley_dispute", "title": "Muhasebe Anlaşmazlığı", "weight": "0.8",
 "cooldown": 8, "kind": "Yol · kültür (Vadi)",
 "flavor": "İki tüccar defterlerini açmış bağrışıyor. Rakamlar tutmuyor.",
 "trigger": "<b>Vadi Loncaları kültürü</b> <b>ve</b> kervanda en az 1 tüccar.",
 "options": [
   {"label": "Defterleri iste, hakemlik yap",
    "effects": [("REPUTATION", 5), ("GOLD", 30)]},
   {"label": "Kendi aralarında halletsinler", "effects": [("MORALE", 1)]},
 ],
 "note": "Kültür olaylarının en cömerti - hem itibar hem para, bedelsiz. Sebebi: Vadi'nin "
         "mekanik perki (%10 ucuz alım) beş perkin en pasifi, bu kart onu dengeliyor.",
},
{
 "id": "evt_culture_highland_challenge", "title": "Güç Sınavı", "weight": "0.8",
 "cooldown": 8, "kind": "Yol · kültür (Dağ)",
 "flavor": "Kolunu masaya koydu ve sana baktı. Söze gerek yok.",
 "trigger": "<b>Dağ Kabilesi kültürü</b>.",
 "options": [
   {"label": "Meydan oku, kabul et", "outcomes": [
     {"label": "Bilek yere değmedi", "weight": "1.4",
      "effects": [("MORALE", 8), ("REPUTATION", 3)]},
     {"label": "Bu sefer sen yenildin ama iyi dövüştün", "weight": "1.0",
      "effects": [("STRESS", 5), ("MORALE", -3)]},
   ]},
   {"label": "Reddet, vaktin yok", "effects": [("MORALE", -2)]},
 ],
 "note": "Kazanma ağırlığı 1.4, kaybetme 1.0 - yani beklenen değer pozitif. Reddetmek kesin "
         "küçük bir kayıp. Dağ kabilesi için kavga davetini geri çevirmek bedava değil.",
},
{
 "id": "evt_culture_port_gossip", "title": "Rıhtım Dedikodusu", "weight": "0.8",
 "cooldown": 8, "kind": "Yol · kültür (Liman)",
 "flavor": "Meyhanede konuşulanlar limandan öteye gitmez, derler. Gitmesini sen sağlarsın.",
 "trigger": "<b>Liman Şehri kültürü</b>.",
 "options": [
   {"label": "Dinle, sonra bu haberi başkasına sat", "outcomes": [
     {"label": "Batan bir geminin yükünün nereye vurduğunu anlattı", "weight": "0.8",
      "effects": [("GOLD", 140), ("MORALE", 6)]},
     {"label": "Duyduğunuz şey bir mal değil bir isimdi", "weight": "1.0",
      "effects": [("REPUTATION", 6), ("MARKET_SHOCK", -25, "İpekevi'nde kumaş 18 gün %25 ucuz")]},
     {"label": "Kimsenin adını anmadığı bir şeyden söz ettiler", "weight": "0.7",
      "effects": [("GRANT_EQUIPMENT", 0, "Cesaret Muskası"), ("STRESS", 6)]},
     {"label": "İşinize yarar tek bir şey duymadınız", "weight": "1.2",
      "effects": [("GOLD", 20), ("REPUTATION", 1)]},
   ]},
   {"label": "Vaktin yok, geç", "effects": [("MORALE", 1)]},
 ],
 "note": "Havuzdaki <b>tek MARKET_SHOCK</b> - ve oyuncunun lehine olan tek fiyat şoku. "
         "İpekevi'nde kumaşı on sekiz gün %25 ucuzlatmak, o hattı bilen bir oyuncu için "
         "140 altınlık hazineden daha değerli olabilir: ucuz alıp talep eden şehre taşımak "
         "kârın asıl kaynağı. Dört dallı sonuç tablosuyla havuzun en zengin kartı.",
},
{
 "id": "evt_culture_fisher_catch", "title": "Şanslı Ağ", "weight": "0.8",
 "cooldown": 8, "kind": "Yol · kültür (Balıkçı)",
 "flavor": "Dere kenarında bir saat. Gözün ağa alışkın.",
 "trigger": "<b>Balıkçı Kasabası kültürü</b>.",
 "options": [
   {"label": "Ağı at, avlanmaya vakit ayır",
    "effects": [("PROVISIONS", 5), ("MORALE", 2)]},
   {"label": "Vakit kaybetme, devam et", "effects": [("MORALE", -1)]},
 ],
 "note": "Havuzun en sade kartı ve <b>erzağı ücretsiz artıran tek olay</b> (kin_encounter'da "
         "erzak parayla alınır). Balıkçı kültürünün perki zaten ucuz erzak; bu kart aynı "
         "temayı olay tarafında tekrarlıyor - kültür bir stat eğiliminden ibaret olmasın diye.",
},
]
