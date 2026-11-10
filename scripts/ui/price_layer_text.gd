class_name PriceLayerText
extends RefCounted

## Fiyatın **nedenini** söyleyen kısa metin: [etiketler, ipucu].
##
## P7 (kullanıcı kararı 2026-11-05): oyuncu **sayıyı değil nedeni** görür.
## Eskiden satır notunda yedi resmî katman `×1.24` gibi çarpanlarla
## yazılıyordu; on bir çarpan daha zaten gizliydi. Yani yüzey bir elektronik
## tabloydu ama eksik bir tablo: oyuncu çarpanları toplayıp doğru sayıya
## varamıyordu, yalnızca varabileceğini sanıyordu.
##
## Şimdi: **en çok üç kelime, hiç çarpan yok.** Gizli on bir çarpan yerinde
## duruyor - dünyanın derinliği onlar; kesilen tek şey, oyuncunun
## çözebileceği bir bilmece olduğu yanılsaması. Dördüncü sütun
## (*ticaret bilgi oyunudur*) "çarpanları çöz" değil, "nerede ne var
## bilmiyorsun" demek.

## Sapma eşiği %2 - yuvarlama gürültüsü işaret sayılmaz.
const LAYER_MARK_THRESHOLD: float = 0.02
## Satır notunda görünecek en fazla neden. Üç, çünkü dördüncüsü okunmuyor:
## göz satırı tarar, cümleyi değil.
const MAX_MARKS: int = 3
## Kıtlık bu derecenin üstündeyse fiyatın asıl nedeni odur ve ilk sırada
## yazılır. Kıtlığın kendisi bir fiyat çarpanı değil (arzı kesiyor), ama
## oyuncunun gördüğü sayıyı en çok o açıklıyor.
##
## Eşik `Scarcity.HUNGRY_CITY_FROM`'un ta kendisi, iki ayrı sayı olmasın
## diye: "aç şehir" oyunun her yerinde aynı şey demeli. 0.35 denendi ve
## ekran görüntüsünde düştü - bölgelerin tabanı 0.12-0.55 olduğu için
## "Kıtlık" birinci günden itibaren her malın altında yazıyordu, ve
## **her yerde olan bir söz hiçbir şey söylemez.**
const SCARCITY_SPEAKS_FROM: float = Scarcity.HUNGRY_CITY_FROM

const LAYER_TAG_KEYS: Dictionary = {
	"place": "UI_PRICE_TAG_PLACE", "settlement": "UI_PRICE_TAG_SETTLEMENT",
	"inflation": "UI_PRICE_TAG_INFLATION", "season": "UI_PRICE_TAG_SEASON",
	"pressure": "UI_PRICE_TAG_PRESSURE", "event": "UI_PRICE_TAG_EVENT", "world": "UI_PRICE_TAG_WORLD",
}
const LAYER_UP_KEYS: Dictionary = {
	"place": "UI_PRICE_WHY_PLACE_DEMAND", "settlement": "UI_PRICE_WHY_SETTLEMENT_UP",
	"inflation": "UI_PRICE_WHY_INFLATION", "season": "UI_PRICE_WHY_SEASON_UP",
	"pressure": "UI_PRICE_WHY_PRESSURE_UP", "event": "UI_PRICE_WHY_EVENT_UP", "world": "UI_PRICE_WHY_WORLD",
}
const LAYER_DOWN_KEYS: Dictionary = {
	"place": "UI_PRICE_WHY_PLACE_PRODUCE", "settlement": "UI_PRICE_WHY_SETTLEMENT_DOWN",
	"inflation": "UI_PRICE_WHY_INFLATION", "season": "UI_PRICE_WHY_SEASON_DOWN",
	"pressure": "UI_PRICE_WHY_PRESSURE_DOWN", "event": "UI_PRICE_WHY_EVENT_DOWN", "world": "UI_PRICE_WHY_WORLD",
}

## `scarcity` bölgenin kıtlık derecesi (`GameSession.scarcity_here`).
## Varsayılanı 0: kıtlığı bilmeyen bir çağıran yanlış bir şey söylemez,
## yalnız bir nedeni atlar.
static func marks(
	item: Item,
	location: Location,
	conditions: MarketConditions,
	day: int,
	scarcity: float = 0.0
) -> Array[String]:
	var found: Array[Dictionary] = []
	var seen := {}
	for selling in [false, true]:
		for layer in MarketPricing.price_layers(item, location, conditions, day, selling):
			var name := String(layer["layer"])
			var m := float(layer["multiplier"])
			# Satışın tabanı (yarı fiyat) bir sapma değil, satıcının payı.
			if name == MarketPricing.LAYER_PLACE and selling and is_equal_approx(m, MarketPricing.BASE_SELL_MULTIPLIER):
				continue
			if absf(m - 1.0) < LAYER_MARK_THRESHOLD or seen.has(name):
				continue
			seen[name] = true
			var key := String((LAYER_UP_KEYS if m > 1.0 else LAYER_DOWN_KEYS)[name])
			var line := String(TranslationServer.translate(key))
			var tag_key := String(LAYER_TAG_KEYS[name])
			if name == MarketPricing.LAYER_WORLD:
				line = line % String(TranslationServer.translate(String(layer["arg"])))
			# Sebebi olan olay şoku: iz dönüşü (§D-İ3 `fiyat`). "Olay" demek
			# oyuncuya bir şey söylemez; hesabın adı söyler.
			elif name == MarketPricing.LAYER_EVENT and not String(layer["arg"]).is_empty():
				tag_key = "UI_PRICE_TAG_TRACE"
				line = String(TranslationServer.translate(
					"UI_PRICE_WHY_TRACE_UP" if m > 1.0 else "UI_PRICE_WHY_TRACE_DOWN")
					) % String(TranslationServer.translate(String(layer["arg"])))
			found.append({
				"tag": String(TranslationServer.translate(tag_key)),
				"why": line,
				"weight": absf(m - 1.0),
			})

	# En güçlü neden başta: üç satır kalıyorsa en çok konuşanlar kalsın.
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["weight"]) > float(b["weight"]))

	# Yalnız yiyecekte: kıtlık fiyatı en çok orada çeviriyor
	# (`FOOD_PRICE_RISE` 0.6'ya karşı `GOODS_PRICE_RISE` 0.2). Mücevherin
	# altına "Kıtlık" yazmak sözü ucuzlatırdı.
	if scarcity >= SCARCITY_SPEAKS_FROM and item != null and Scarcity.is_food(item.item_id):
		# Kıtlık her şeyin önüne geçer: fiyatın nedeni artık mevsim ya da
		# mesafe değil, malın olmayışıdır.
		found.push_front({
			"tag": String(TranslationServer.translate("UI_PRICE_TAG_SCARCITY")),
			"why": String(TranslationServer.translate("UI_PRICE_WHY_SCARCITY")),
			"weight": 9.0,
		})

	var tags: Array[String] = []
	var why: Array[String] = []
	for entry in found.slice(0, MAX_MARKS):
		tags.append(String(entry["tag"]))
		why.append(String(entry["why"]))
	var out: Array[String] = [" · ".join(tags), "\n".join(why)]
	return out
