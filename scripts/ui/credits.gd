class_name Credits
extends RefCounted

## Oyunda kullanılan dış varlıkların atıfları. CC-BY lisansı ticari
## kullanıma açık ama yazarın anılmasını istiyor; CC0 paketler atıf
## istemiyor, yine de anılıyor. Kaynak tablolar: art_source/models/
## clothes/makehuman/LICENSES.md ve art_source/models/props/LICENSES.md.
## Kök dizindeki CREDITS.md aynı listeyi taşıyor. Adlar özel isim, çevrilmez.

## [kalem, yazar, kaynak] - MakeHuman topluluk giysileri, CC-BY 4.0.
const CC_BY: Array = [
	["culturalibre_cl_don_quixote_hat", "culturalibre", "http://www.makehumancommunity.org/node/3037"],
	["drednicolson_asymmetric_tunic_and_sash", "DredNicolson", "http://www.makehumancommunity.org/node/409"],
	["elvs_basic_felt_elf_shoes", "Elvaerwyn", "http://www.makehumancommunity.org/node/1279"],
	["elvs_caesar_sandals1", "Elvaerwyn", "http://www.makehumancommunity.org/node/1915"],
	["elvs_charity_veil1", "Elvaerwyn", "http://www.makehumancommunity.org/node/2610"],
	["elvs_male_boho_top1", "Elvaerwyn", "http://www.makehumancommunity.org/node/1808"],
	["elvs_male_trouser", "Elvaerwyn", "http://www.makehumancommunity.org/node/1796"],
	["elvs_ruffle_sleeve_peasant_blouse_1", "Elvaerwyn", "http://www.makehumancommunity.org/node/1256"],
	["elvs_slouchy_beanie1", "Elvaerwyn", "http://www.makehumancommunity.org/node/2088"],
	["maciekg_leather_boots", "MaciekG", "http://www.makehumancommunity.org/node/1461"],
	["maciekg_leather_helmet", "MaciekG", "http://www.makehumancommunity.org/node/1457"],
	["maciekg_wizard_robe", "MaciekG", "http://www.makehumancommunity.org/node/1482"],
	["maciekg_wizard_hat", "MaciekG", "https://static.makehumancommunity.org/assets/assetpacks/hats03.html"],
	["mindfront_cardigan_long_open_front", "Mindfront", "http://www.makehumancommunity.org/node/1528"],
	["mindfront_knitted_hat_01", "Mindfront", "http://www.makehumancommunity.org/node/745"],
	["mindfront_sherpa_hat", "Mindfront", "http://www.makehumancommunity.org/node/3172"],
	["punkduck_female_knee_boots", "punkduck", "http://www.makehumancommunity.org/node/817"],
	["punkduck_lace_up_blouse", "punkduck", "http://www.makehumancommunity.org/node/1775"],
	["punkduck_medieval_boots", "punkduck", "http://www.makehumancommunity.org/node/1381"],
	["punkduck_riding_boots", "punkduck", "http://www.makehumancommunity.org/node/1566"],
]

## CC0 paketler (atıf gerekmez).
const CC0_PACKS: Array = [
	"Quaternius - Medieval Village Pack, Medieval Village MegaKit, Fantasy Props MegaKit, Modular Medieval Pack, Farm Buildings, Ultimate RPG Items, Survival Pack, Medieval Weapons, Animated Knight, Modular Character Outfits (quaternius.com)",
	"Kenney - Castle Kit, Survival Kit, Particle Pack, Graveyard Kit, Impact Sounds, UI Pack RPG Expansion, Fantasy UI Borders (kenney.nl)",
	"Poly Haven - Lantern 01, Rajil Jose Macatangay (polyhaven.com)",
	"Kay Lousberg - KayKit Medieval Hexagon (kaylousberg.com)",
	"MakeHuman community - CC0 clothes by culturalibre, Donitz, javherre, MargaretToigo, RehmanPolanski, wdg",
	"Blender Studio - Human Base Meshes; MPFB2 (MakeHuman)",
	"ambientCG - Bricks097, Fabric085, Ground106, Metal041B, Metal063, Paper005, PavingStones119, Planks037A, Plaster001, Rock064 (ambientcg.com)",
	"Fonts (SIL OFL) - EB Garamond, IM Fell English SC, Grenze Gotisch, Noto Serif SC, Noto Serif JP",
]

## Ekranda gösterilen metin: önce CC-BY yazarlar (yazar başına kalemleri),
## sonra CC0 paketler.
static func text() -> String:
	var by_author: Dictionary = {}
	for row in CC_BY:
		var author := String(row[1])
		if not by_author.has(author):
			by_author[author] = []
		by_author[author].append(String(row[0]))
	var out := PackedStringArray()
	out.append(TranslationServer.translate("UI_CREDITS_CC_BY"))
	var authors := by_author.keys()
	authors.sort()
	for author in authors:
		out.append("  %s: %s" % [author, ", ".join(PackedStringArray(by_author[author]))])
	out.append("")
	out.append(TranslationServer.translate("UI_CREDITS_CC0"))
	for pack in CC0_PACKS:
		out.append("  " + String(pack))
	return "\n".join(out)
