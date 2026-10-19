extends RefCounted

## Pazarın terazisi (Y-G11T): ağır olan taraf iner, parça sayısı mal ve altınla
## büyür ama sınırlı, yay hedefte durgun kalır, düşen parça yerine oturur.

func suite_name() -> String:
	return "MarketScale"

func run(t) -> void:
	t.eq(MarketScale.tilt_for(100, 100), 0.0, "eşit değer: denge")
	t.ok(MarketScale.tilt_for(246, 186) > 0.0, "mal değeri altından büyük: mal ağır (sol iner)")
	t.ok(MarketScale.tilt_for(150, 230) < 0.0, "altın büyük: altın ağır (sağ iner)")
	t.eq(MarketScale.tilt_for(1000, 1), 1.0, "eğim kenetlenir")
	t.eq(MarketScale.tilt_for(0, 0), 0.0, "boş terazi dengede")

	t.eq(MarketScale.coin_count(0), 0, "altın yoksa sikke yok")
	t.eq(MarketScale.coin_count(5), 1, "azıcık altın en az bir sikke")
	t.ok(MarketScale.coin_count(186) > MarketScale.coin_count(60), "altın çoğaldıkça sikke çoğalır")
	t.eq(MarketScale.coin_count(1000000), MarketScale.MAX_COINS, "sikke sayısı sınırlı")

	var small: Array[int] = [3, 1]
	var shares := MarketScale.item_shares(small)
	t.eq(shares[0] + shares[1], 4, "az mal: hepsi çizilir")
	t.ok(shares[1] >= 1, "her çeşit en az bir parça")
	var many: Array[int] = [40, 20, 1]
	var big := MarketScale.item_shares(many)
	t.eq(big[0] + big[1] + big[2], MarketScale.MAX_ITEMS, "çok mal: parça sayısı sınırlı")
	t.ok(big[2] >= 1, "küçük çeşit de görünür kalır")
	var none: Array[int] = [0, 0]
	t.eq(MarketScale.item_shares(none)[0], 0, "boş sepet: parça yok")

	var layout := MarketScale.pyramid(6, 40.0)
	t.eq(layout.size(), 6, "piramit istenen sayıda yer verir")
	t.ok(layout[0].y >= layout[layout.size() - 1].y, "alt sıra üstten aşağıda")

	var pos := 1.0
	var vel := 0.0
	for _i in 600:
		var step := MarketScale.spring_step(pos, vel, 0.0, 1.0 / 60.0)
		pos = step.x
		vel = step.y
	t.ok(absf(pos) < 0.001 and absf(vel) < 0.001, "yay hedefte durgun")

	t.eq(MarketScale.drop_offset(0.0), -MarketScale.DROP_HEIGHT, "düşen parça yukarıdan başlar")
	t.eq(MarketScale.drop_offset(MarketScale.DROP_SECONDS), 0.0, "düşen parça yerine oturur")
	t.ok(MarketScale.drop_offset(MarketScale.DROP_SECONDS * 0.3) < 0.0, "düşüş sürerken yerin üstünde")

	var scale := MarketScale.new()
	var wine: Array[Dictionary] = [{"texture": null, "quantity": 6}]
	scale.set_basket(wine, 186, 246)
	scale.settle_now()
	t.ok(scale.get_tilt() > 0.0, "sepet kârlıyken kol mal tarafına eğik")
	scale.set_basket(wine, 300, 246)
	scale.settle_now()
	t.ok(scale.get_tilt() < 0.0, "altın artınca kol altın tarafına döner")
	scale.free()
