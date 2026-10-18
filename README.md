# Wayborne

Ortaçağ temalı, 2D, kervan ticareti ve sıra tabanlı taktiksel
savaş içeren bir Godot 4 oyunu. Oyuncu bir kervan lideri; şehirler arası
mal taşıyor, tüccarlara refakat ediyor, yolda EU4 tarzı olay kartlarıyla
karşılaşıyor ve gerektiğinde haydutlarla savaşıyor.

**Oyna:** yayındaki web derlemesi GitHub Pages üzerinde —
`Settings → Pages` etkinleştirildikten sonra bu deponun Pages adresinde.

## Oyun döngüsü

1. **Karakter oluştur** — kültür, sınıf (dördü var: Sıra Neferi/Sekban/
   Kırıkçı/Kalem Efendisi), isim, boy, ten rengi, 8 temel stata (altısı savaş, ikisi sivil: Bilgelik ve İnanç)
   dağıtılan puan ve tayfa büyüklüğü seçilir. Tayfa vagonları sürer ve kargo
   kapasitesini belirler (her vagonda 2 kişi, en fazla 6 vagon); savaşa
   giren **parti** ise ayrı bir kavramdır ve en fazla 4 kişidir.
2. **Şehirde hazırlan** — Pazar Meydanı'ndan mal al/sat, Tüccar
   Loncası'ndan kontrat kabul et, Taverna'dan rota dedikodusu satın al,
   Kervan Avlusu'ndan vagon onart/satın al, Kilise'de taze huyları
   arındır. Meydan, taverna ve lonca partine yeni kişiler de katabilir -
   adaylar oyuncunun seviyesine göre ölçeklenir (meydan hep acemi, lonca
   hep en az oyuncu kadar tecrübeli).
3. **Kervan planla** — kaç vagonla, hangi tüccarların refakatinde, hangi
   rotadan gideceğine karar ver.
4. **Yola çık** — her gün olay çıkma ihtimali var; EU4 tarzı kartlar
   kilitli seçenekleri sebepleriyle gösterir. Bazı seçenekler gerçek bir
   çarpışma açar (sıra tabanlı, mevki kilitli yetenekler, 4
   mevkilik iki saf). Olaylar ve seferler XP verir; karakterler seviye
   atlayınca stat ve yetkinlik puanı kazanır (otomatik ya da elle
   dağıtılır — parti ekranındaki karakter sayfası). Savaş, kayıp ve açlık
   parti stresini biriktirir; "Kamp Kur" bir günü feda edip stresi azaltır,
   biriken stres yüksek şehre varışta bazı yoldaşları kırabilir (huy
   kazanır, nadiren tam tersi güçlenir, ağır kırılan biri ayrılabilir).
5. **Şehre var** — escort ücreti moral ve hasara göre kırpılarak ödenir,
   karakterler tam cana döner, stres bir miktar dinlenir, ilerleme
   kaydedilir.

Tasarımın omurgası: **kervanın adı liderinden uzun yaşar.** Lider
ölürse en kıdemli yoldaş devralır, ad ve defter kalır, kuşak ilerler;
oyunun tek gerçek sonu adı taşıyacak kimsenin kalmamasıdır. Kervan
defteri (`CaravanLedger`) hiçbir satırı silmez - ayrılan bir ismin üstü
çizilir.

Yolda yürümek bir karar: liderin kolondaki yeri neye dikkat ettiğini
belirler (ön / vagonlar / arka), yol sürekli küçük işaretler verir ve
ihmal edilen işaret büyür, tempoyu zorlamak takat yakar.

Diğer değişmez kural: **kervan ağır kayıp yaşayabilir ama asla yok
olmaz.** Altın eksiye düşebilir (borç defteri vade ve faiz işletir), erzak
sıfırın altına inmez, oyuncunun son vagonu kaybedilmez. İnsanlar ölebilir:
savaşta Ölümün Kıyısı'na giren herkes bir zara tabidir, bilerek aç bırakılan
ölebilir; olaylar ise asla öldürmez (en fazla 1 cana indirir).

## Kod tabanı

```
wayborne/
├── scenes/                # Sahne dosyaları (*.tscn)
├── scripts/
│   ├── economy/           # Pazar, cüzdan, envanter, fiyatlandırma
│   ├── travel/             # Harita, rotalar, kervan/vagon mantığı
│   ├── events/             # EU4 tarzı olay motoru
│   ├── character/          # Statlar, kültürler, sınıflar, tayfa toplama
│   ├── combat/             # Sıra tabanlı çarpışma motoru
│   ├── world/              # 2D dünya, sahne navigasyonu
│   ├── ui/                 # Ekranlar ve yeniden kullanılabilir paneller
│   ├── campaign/           # Kampanya bölümleri + kervan defteri
│   ├── util/               # Ortak yardımcılar (NodeUtil, TextureLoader)
│   └── autoload/           # GameState, DevPanel, SaveManager, AudioManager
├── data/
│   ├── assets/audio/       # Müzik (ana menü+yol, şehir)
│   ├── locale/             # Çeviri metinleri (tr/en)
│   └── config/             # JSON yapılandırma (harita yerleri vb.)
└── tests/                  # Headless GDScript testleri + denge simülatörü
```

Mimarinin dayandığı birkaç kural — tam gerekçeleriyle `CLAUDE.md`'de:

- **Olay motoru yalnızca yolda çalışır.** Şehir etkileşimi kart tabanlı
  değil; her lokasyon kendi ekranını açar.
- **`EventEffect` dünyaya dokunmanın tek yolu.** Yeni bir etki hem enum'a
  hem `EventEffectApplier`'a eklenmeden sessizce hiçbir şey yapmaz.
- **Autoload'larda `class_name`'e asla başvurulmaz.** Autoload'lar global
  script sınıf önbelleği hazır olmadan ayrıştırılıyor; ihlal, betiğin
  sessizce hiç örneklenmemesine yol açar (CI artık bunu yakalıyor).
- **Parti kapasitesi vagon sayısına bağlı**, savaş partisi (adı olan en
  fazla 4 kişi) tayfa sayısından (kargo/vagon) ayrı bir kavramdır.
- **Oyuncunun kimliği sıradan değil `CharacterData.is_player`
  bayrağından okunur** — parti sırası aynı zamanda savaş mevki sırası
  olduğu için oyuncu arkaya geçebilir.

## Geliştirme

Godot 4.2+ ve GDScript. Editörde `project.godot`'u açman yeterli;
`scripts/autoload/dev_panel.gd` oyun içinde F1 ile açılan bir geliştirici
menüsü sağlıyor (pazarlık, olay, savaş, harita gibi sistemleri kalıcı
kayda dokunmadan tek tek test etmek için).

### Testler

```bash
godot --headless --script res://tests/run_tests.gd        # exit 1 hata varsa
godot --headless --script res://tests/simulate_journeys.gd  # denge raporu
```

`run_tests.gd` eklenti gerektirmeyen düz bir `SceneTree` koşucusu; elli
altı paket ve 18.000'den fazla doğrulama, çekirdek sistemlerin (statlar,
kültürler, savaş, olay motoru, oturum) sözleşmelerini kilitliyor.
`simulate_journeys.gd` test değil — yüzlerce tohumla sefer koşturup net
kazanç/moral/açlık/savaş kazanma oranı dağılımı basıyor; oyunu
oynamadan dengeye yaklaşmanın tek yolu bu.

### CI/CD

Her push ve PR `tests.yml`'i tetikler: içe aktarım, testler, ve Godot'un
bastığı ama sessizce geçtiği ayrıştırma hatalarını (`SCRIPT ERROR`,
`Parse Error`, `Failed to create an autoload` vb.) arayan bir kapı.
`main`'e giden her şey bu kapıdan geçmiş olur.

`main`'e push, `deploy.yml`'i tetikler: aynı testler ve kapı, ardından
Web (HTML5) dışa aktarımı ve GitHub Pages'e dağıtım. Web derlemesi
`crossOriginIsolated`/`SharedArrayBuffer` gerektirdiği ve GitHub Pages
özel başlık desteklemediği için `web/coi-serviceworker.js` istemci
tarafında bu başlıkları enjekte ediyor.

## Yol haritası

Geliştirme fazlar hâlinde ilerliyor. Kapanmış fazların kapsamı, gerekçesi ve
ölçümleri `docs/history/FAZ_ANLATILARI.md`'de; geçerli kurallar ve açık hedefler
`CLAUDE.md`'de. Faz 27'ye kadar tamam: oyun döngüsü, karakter ve savaş, ilerleme,
ekipman ve kuşam, borç ve hafıza, hareket katmanı, render edilmiş yol, karanlık
arayüz (yarısı ekranlara bağlı). Sıradaki iş listesi depo dışında tutulan
yapılacaklar klasöründe; açık hedefler `CLAUDE.md`'nin "Ana Hedefler" bölümünde.
