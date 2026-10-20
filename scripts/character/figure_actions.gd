class_name FigureActions
extends RefCounted

## Yürüme dışındaki her insan pozu: elde silah, yay germe, darbe alma,
## savunma, ölü ve yerde yatan. `FigureRig.pose()` yürüyüşü çözüyor; bu dosya
## onun ölçüleriyle (`HIP_RATIO`, `TORSO_RATIO`, kol/bacak payları) ve aynı
## eklem adlarıyla anahtar kare pozları kuruyor - 3B kare hattı
## (`tools/figure_pipeline/godot/export_clips.gd`) ve eski parça çizimi aynı
## sözlüğü okuyor, iki yerde iki ayrı duruş olmasın diye.
##
## Bir poz parametrelerle tanımlı, yürüyüş gibi bir formülle değil:
##   hip_x, hip_y   kalçanın ötelemesi (boy cinsinden, + öne / + yukarı)
##   lean           gövde eğimi (derece, + öne)
##   foot_f/foot_b  [ayak bileğinin kalçaya göre x'i, yerden yüksekliği,
##                   ayak eğimi (derece, + parmak yukarı)]
##   arm_f/arm_b    [üst kol, önkol] açıları: aşağı sarkıktan öne doğru derece
##                   (0 = sarkık, 90 = öne yatay, 180 = yukarı, - = geriye)
##   weapon         elden silahın ucuna yön, aynı açı ölçüsünde (yayda yayın
##                   üst kolu: 180 = dik)
##   draw           yay kirişinin geri çekilmişliği (0..1; 1 = arka el kirişte)
##   body_rot       bütün figürün zemin üstünde dönüşü (derece, + = sırt üstü
##                   geriye düşüş) - ölü ve yerde yatan pozlar için
## Açılar dünyaya göre, gövdeye göre değil: el ne kadar eğilirse eğilsin
## yayın kirişi göze gelmeli.
##
## Klipler anahtar karelerden örneklenir: `frames` kare, kareler arası
## smoothstep. Tek kareli bir klip bir duruştur.

const NEUTRAL: Dictionary = {
	"hip_x": 0.0, "hip_y": 0.0, "lean": 0.0,
	"foot_f": [0.0, 0.0, 0.0], "foot_b": [0.0, 0.0, 0.0],
	"arm_f": [11.0, 20.0], "arm_b": [11.0, 20.0],
	"weapon": 0.0, "draw": 0.0, "body_rot": 0.0,
}

const _MELEE_STANCE: Dictionary = {
	"hip_y": -0.025, "lean": 6.0,
	"foot_f": [0.11, 0.0, 0.0], "foot_b": [-0.12, 0.0, 0.0],
	"arm_f": [35.0, 88.0], "arm_b": [18.0, 55.0], "weapon": 160.0,
}
const _BOW_LOW: Dictionary = {
	"foot_f": [0.05, 0.0, 0.0], "foot_b": [-0.06, 0.0, 0.0],
	"arm_f": [12.0, 28.0], "arm_b": [8.0, 22.0], "weapon": 165.0,
}
## Tam germe: ön kol omuz hizasında öne düz, arka el çenede.
const _BOW_DRAWN: Dictionary = {
	"lean": 3.0, "foot_f": [0.10, 0.0, 0.0], "foot_b": [-0.10, 0.0, 0.0],
	"arm_f": [88.0, 90.0], "arm_b": [-99.0, 112.0], "weapon": 180.0, "draw": 1.0,
}

## Oturan duruşlar: elde silah yok, ayakta durma testinden muaf.
const SEATED_CLIPS: Array[String] = ["sit_box"]

## Klip adı -> {frames, keys: [[t, poz]]}. Pozlar NEUTRAL'ın üstüne yazılır.
const CLIPS: Dictionary = {
	"stance_melee": {"frames": 1, "keys": [[0.0, _MELEE_STANCE]]},
	"stance_bow": {"frames": 1, "keys": [[0.0, _BOW_LOW]]},
	"aim_bow": {"frames": 1, "keys": [[0.0, _BOW_DRAWN]]},
	# Tepeden savuruş: kılıç, satır, gürz, asa.
	"attack_swing": {"frames": 8, "keys": [
		[0.0, _MELEE_STANCE],
		[0.22, {"hip_y": -0.02, "lean": -6.0, "foot_f": [0.10, 0.0, 0.0], "foot_b": [-0.13, 0.0, 0.0],
			"arm_f": [165.0, 215.0], "arm_b": [30.0, 70.0], "weapon": 230.0}],
		[0.45, {"hip_x": 0.04, "hip_y": -0.04, "lean": 12.0, "foot_f": [0.20, 0.0, 0.0], "foot_b": [-0.12, 0.0, 0.0],
			"arm_f": [120.0, 130.0], "arm_b": [10.0, 40.0], "weapon": 125.0}],
		[0.62, {"hip_x": 0.06, "hip_y": -0.06, "lean": 22.0, "foot_f": [0.22, 0.0, 0.0], "foot_b": [-0.13, 0.0, 0.0],
			"arm_f": [72.0, 62.0], "arm_b": [-10.0, 25.0], "weapon": 68.0}],
		[0.80, {"hip_x": 0.05, "hip_y": -0.06, "lean": 18.0, "foot_f": [0.22, 0.0, 0.0], "foot_b": [-0.13, 0.0, 0.0],
			"arm_f": [40.0, 22.0], "arm_b": [-5.0, 25.0], "weapon": 25.0}],
		[1.0, _MELEE_STANCE],
	]},
	# Saplama: mızrak.
	"attack_thrust": {"frames": 6, "keys": [
		[0.0, _MELEE_STANCE],
		[0.25, {"hip_x": -0.03, "hip_y": -0.03, "lean": -4.0, "foot_f": [0.10, 0.0, 0.0], "foot_b": [-0.14, 0.0, 0.0],
			"arm_f": [-15.0, 70.0], "arm_b": [20.0, 60.0], "weapon": 95.0}],
		[0.5, {"hip_x": 0.07, "hip_y": -0.05, "lean": 16.0, "foot_f": [0.26, 0.0, 0.0], "foot_b": [-0.20, 0.0, 0.0],
			"arm_f": [80.0, 90.0], "arm_b": [40.0, 80.0], "weapon": 92.0}],
		[0.7, {"hip_x": 0.07, "hip_y": -0.05, "lean": 16.0, "foot_f": [0.26, 0.0, 0.0], "foot_b": [-0.20, 0.0, 0.0],
			"arm_f": [80.0, 90.0], "arm_b": [40.0, 80.0], "weapon": 92.0}],
		[1.0, _MELEE_STANCE],
	]},
	# Yay: aşağıdan kaldır, ok tak, ger, tut (nişan), bırak, indir.
	"attack_bow": {"frames": 8, "keys": [
		[0.0, _BOW_LOW],
		[0.15, {"foot_f": [0.08, 0.0, 0.0], "foot_b": [-0.08, 0.0, 0.0],
			"arm_f": [62.0, 72.0], "arm_b": [20.0, 50.0], "weapon": 178.0}],
		[0.3, {"lean": 2.0, "foot_f": [0.10, 0.0, 0.0], "foot_b": [-0.10, 0.0, 0.0],
			"arm_f": [86.0, 90.0], "arm_b": [55.0, 95.0], "weapon": 180.0, "draw": 0.0}],
		[0.45, {"lean": 3.0, "foot_f": [0.10, 0.0, 0.0], "foot_b": [-0.10, 0.0, 0.0],
			"arm_f": [88.0, 90.0], "arm_b": [-40.0, 110.0], "weapon": 180.0, "draw": 0.55}],
		[0.6, _BOW_DRAWN],
		[0.72, {"lean": 2.0, "foot_f": [0.10, 0.0, 0.0], "foot_b": [-0.10, 0.0, 0.0],
			"arm_f": [88.0, 90.0], "arm_b": [-115.0, 70.0], "weapon": 180.0, "draw": 0.0}],
		[0.86, {"foot_f": [0.08, 0.0, 0.0], "foot_b": [-0.08, 0.0, 0.0],
			"arm_f": [70.0, 78.0], "arm_b": [-30.0, 30.0], "weapon": 178.0}],
		[1.0, _BOW_LOW],
	]},
	# Darbe: geri savrulma, bir adım geri, toparlanma.
	"hit": {"frames": 4, "keys": [
		[0.0, _MELEE_STANCE],
		[0.33, {"hip_x": -0.03, "hip_y": -0.01, "lean": -18.0, "foot_f": [0.13, 0.0, 12.0], "foot_b": [-0.12, 0.0, 0.0],
			"arm_f": [-15.0, 30.0], "arm_b": [35.0, 70.0], "weapon": 200.0}],
		[0.66, {"hip_x": -0.05, "hip_y": -0.04, "lean": -8.0, "foot_f": [0.08, 0.0, 0.0], "foot_b": [-0.18, 0.0, 0.0],
			"arm_f": [15.0, 50.0], "arm_b": [20.0, 50.0], "weapon": 185.0}],
		[1.0, _MELEE_STANCE],
	]},
	# Delici darbe (ok, mızrak, hançer): göğse saplanan şey gövdeyi öne
	# büker, ön el yaraya gider; geri savrulma `hit`'ten az, sarsıntı içe doğru.
	"hit_pierce": {"frames": 4, "keys": [
		[0.0, _MELEE_STANCE],
		[0.33, {"hip_x": -0.025, "hip_y": -0.03, "lean": 14.0, "foot_f": [0.09, 0.0, 0.0], "foot_b": [-0.16, 0.0, 0.0],
			"arm_f": [32.0, 222.0], "arm_b": [30.0, 75.0], "weapon": 150.0}],
		[0.66, {"hip_x": -0.04, "hip_y": -0.045, "lean": 20.0, "foot_f": [0.08, 0.0, 0.0], "foot_b": [-0.18, 0.0, 0.0],
			"arm_f": [28.0, 228.0], "arm_b": [22.0, 60.0], "weapon": 140.0}],
		[1.0, _MELEE_STANCE],
	]},
	# Kesik darbe (kılıç, balta): vuruş yandan gelir, gövde dönerek geriye
	# atılır, kollar savrulur, baş geride.
	"hit_slash": {"frames": 4, "keys": [
		[0.0, _MELEE_STANCE],
		[0.33, {"hip_x": -0.04, "hip_y": -0.015, "lean": -26.0, "foot_f": [0.15, 0.0, 15.0], "foot_b": [-0.10, 0.0, 0.0],
			"arm_f": [-40.0, 5.0], "arm_b": [70.0, 125.0], "weapon": 215.0}],
		[0.66, {"hip_x": -0.07, "hip_y": -0.04, "lean": -12.0, "foot_f": [0.10, 0.0, 0.0], "foot_b": [-0.20, 0.0, 0.0],
			"arm_f": [5.0, 45.0], "arm_b": [40.0, 80.0], "weapon": 190.0}],
		[1.0, _MELEE_STANCE],
	]},
	# Kaçınma: darbe gelmeden geri sıçrama, gövde geriye çekik, ağırlık arka
	# ayakta; sonra duruşa dönüş.
	"dodge": {"frames": 4, "keys": [
		[0.0, _MELEE_STANCE],
		[0.4, {"hip_x": -0.10, "hip_y": -0.035, "lean": -16.0, "foot_f": [0.05, 0.0, 10.0], "foot_b": [-0.24, 0.0, 0.0],
			"arm_f": [60.0, 120.0], "arm_b": [-20.0, 30.0], "weapon": 150.0}],
		[0.7, {"hip_x": -0.09, "hip_y": -0.04, "lean": -10.0, "foot_f": [0.06, 0.0, 0.0], "foot_b": [-0.22, 0.0, 0.0],
			"arm_f": [50.0, 105.0], "arm_b": [-10.0, 35.0], "weapon": 155.0}],
		[1.0, _MELEE_STANCE],
	]},
	# Yanma: alevi söndürmeye çalışan çırpınma - kollar sırayla gövdeye
	# vuruyor, ayaklar yerinde sekiyor.
	"react_burn": {"frames": 6, "keys": [
		[0.0, _MELEE_STANCE],
		[0.2, {"hip_x": -0.03, "hip_y": -0.02, "lean": -12.0, "foot_f": [0.10, 0.0, 0.0], "foot_b": [-0.12, 0.0, 0.0],
			"arm_f": [150.0, 205.0], "arm_b": [40.0, 140.0], "weapon": 220.0}],
		[0.45, {"hip_x": -0.02, "hip_y": -0.05, "lean": 14.0, "foot_f": [0.08, 0.0, 0.0], "foot_b": [-0.14, 0.0, 0.0],
			"arm_f": [45.0, 150.0], "arm_b": [130.0, 190.0], "weapon": 160.0}],
		[0.7, {"hip_x": -0.04, "hip_y": -0.02, "lean": -6.0, "foot_f": [0.11, 0.0, 0.0], "foot_b": [-0.13, 0.0, 0.0],
			"arm_f": [140.0, 195.0], "arm_b": [35.0, 145.0], "weapon": 215.0}],
		[1.0, _MELEE_STANCE],
	]},
	# Donma: soğuk gövdeyi büzüyor - omuzlar düşük, kollar göğüste
	# kavuşmuş, dizler kırık. Titreme kalçanın küçük gidip gelmesi.
	"react_freeze": {"frames": 4, "keys": [
		[0.0, _MELEE_STANCE],
		[0.35, {"hip_x": 0.005, "hip_y": -0.05, "lean": 18.0, "foot_f": [0.06, 0.0, 0.0], "foot_b": [-0.07, 0.0, 0.0],
			"arm_f": [22.0, 232.0], "arm_b": [30.0, 225.0], "weapon": 120.0}],
		[0.7, {"hip_x": -0.005, "hip_y": -0.055, "lean": 20.0, "foot_f": [0.06, 0.0, 0.0], "foot_b": [-0.07, 0.0, 0.0],
			"arm_f": [24.0, 236.0], "arm_b": [28.0, 222.0], "weapon": 120.0}],
		[1.0, _MELEE_STANCE],
	]},
	# Zehirlenme: iki büklüm - gövde öne çökük, ön el karında, arka kol
	# dizine dayanmış.
	"react_poison": {"frames": 4, "keys": [
		[0.0, _MELEE_STANCE],
		[0.35, {"hip_x": -0.02, "hip_y": -0.06, "lean": 32.0, "foot_f": [0.10, 0.0, 0.0], "foot_b": [-0.14, 0.0, 0.0],
			"arm_f": [12.0, 208.0], "arm_b": [45.0, 30.0], "weapon": 110.0}],
		[0.7, {"hip_x": -0.03, "hip_y": -0.08, "lean": 40.0, "foot_f": [0.11, 0.0, 0.0], "foot_b": [-0.15, 0.0, 0.0],
			"arm_f": [8.0, 212.0], "arm_b": [50.0, 25.0], "weapon": 100.0}],
		[1.0, _MELEE_STANCE],
	]},
	# Büyü yapma: kol göğe kalkar, sonra avuç (ya da asa) hedefe doğru
	# uzanır; arka el göğüste büyüyü "örüyor".
	"attack_cast": {"frames": 6, "keys": [
		[0.0, _MELEE_STANCE],
		[0.3, {"hip_y": -0.02, "lean": -8.0, "foot_f": [0.10, 0.0, 0.0], "foot_b": [-0.12, 0.0, 0.0],
			"arm_f": [160.0, 175.0], "arm_b": [55.0, 120.0], "weapon": 180.0}],
		[0.6, {"hip_x": 0.04, "hip_y": -0.035, "lean": 10.0, "foot_f": [0.18, 0.0, 0.0], "foot_b": [-0.12, 0.0, 0.0],
			"arm_f": [88.0, 92.0], "arm_b": [60.0, 115.0], "weapon": 100.0}],
		[0.8, {"hip_x": 0.04, "hip_y": -0.035, "lean": 10.0, "foot_f": [0.18, 0.0, 0.0], "foot_b": [-0.12, 0.0, 0.0],
			"arm_f": [90.0, 92.0], "arm_b": [55.0, 110.0], "weapon": 100.0}],
		[1.0, _MELEE_STANCE],
	]},
	# Attan iniş (tersten oynatılınca biniş). Zemin gerçek zemin: eyer
	# boyun ~0.64'ünde (`MOUNT_SADDLE_HIP`). Öne eğilip arka bacağı sağrının
	# üstünden aşırıyor, üzengide ayağa kalkıyor, arka ayak yere iniyor,
	# öndeki üzengiden çıkıyor. Kök kalça (`build.json` root pelvis):
	# oyun kalçayı eyerden ayakta durana taşıyor.
	"dismount": {"frames": 8, "keys": [
		[0.0, {"hip_y": 0.10, "lean": 4.0, "foot_f": [0.10, 0.36, 0.0], "foot_b": [0.06, 0.36, 0.0],
			"arm_f": [40.0, 75.0], "arm_b": [35.0, 70.0]}],
		[0.28, {"hip_y": 0.12, "lean": 30.0, "foot_f": [0.06, 0.36, 0.0], "foot_b": [-0.26, 0.58, -10.0],
			"arm_f": [75.0, 40.0], "arm_b": [70.0, 35.0]}],
		[0.52, {"hip_y": 0.16, "lean": 10.0, "foot_f": [0.02, 0.36, 0.0], "foot_b": [-0.03, 0.14, -35.0],
			"arm_f": [115.0, 70.0], "arm_b": [105.0, 60.0]}],
		[0.76, {"hip_y": -0.02, "lean": 6.0, "foot_f": [0.13, 0.16, 10.0], "foot_b": [-0.04, 0.0, 0.0],
			"arm_f": [60.0, 40.0], "arm_b": [40.0, 30.0]}],
		[1.0, {}],
	]},
	# Vagon koltuğundan iniş (tersten: çıkış). Koltuk boyun ~0.5'inde
	# (`BENCH_HIP`), ayaklar basamakta; arka el koltuğu tutarken ön ayak
	# tekerlek göbeğine iniyor, sonra yere.
	"climb_down": {"frames": 8, "keys": [
		[0.0, {"hip_y": -0.04, "lean": 3.0, "foot_f": [0.20, 0.24, 0.0], "foot_b": [0.16, 0.24, 0.0],
			"arm_f": [35.0, 80.0], "arm_b": [30.0, 75.0]}],
		[0.3, {"hip_y": -0.03, "lean": 22.0, "foot_f": [0.15, 0.10, -15.0], "foot_b": [0.12, 0.24, 0.0],
			"arm_f": [60.0, 30.0], "arm_b": [-25.0, 0.0]}],
		[0.6, {"hip_y": 0.05, "lean": 8.0, "foot_f": [0.04, 0.10, 0.0], "foot_b": [-0.07, 0.03, -20.0],
			"arm_f": [130.0, 100.0], "arm_b": [120.0, 90.0]}],
		[0.85, {"hip_y": -0.04, "lean": 8.0, "foot_f": [0.07, 0.0, 0.0], "foot_b": [-0.07, 0.0, 0.0],
			"arm_f": [30.0, 40.0], "arm_b": [25.0, 35.0]}],
		[1.0, {}],
	]},
	# Savunma: çömel, ön kol yüzün önünde, silah yatay.
	"defend": {"frames": 4, "keys": [
		[0.0, _MELEE_STANCE],
		[0.45, {"hip_y": -0.06, "lean": 10.0, "foot_f": [0.13, 0.0, 0.0], "foot_b": [-0.15, 0.0, 0.0],
			"arm_f": [95.0, 160.0], "arm_b": [40.0, 110.0], "weapon": 100.0}],
		[1.0, {"hip_y": -0.07, "lean": 12.0, "foot_f": [0.13, 0.0, 0.0], "foot_b": [-0.15, 0.0, 0.0],
			"arm_f": [100.0, 165.0], "arm_b": [45.0, 115.0], "weapon": 100.0}],
	]},
	# Ölü: sırt üstü, kollar açılmış, dizler hafif kırık.
	"dead": {"frames": 1, "keys": [[0.0, {
		# Gövde çerçevesinde: 0 = ayaklara doğru yerde, 180 = başın üstüne
		# atılmış, + = gökyüzüne. Bir kol yanında, öbürü başının üstünde.
		# Bacaklar yerde uzanık, ön diz hafif kalkık (ayak kalçaya çekilince diz
		# öne = yatınca yukarı kırılıyor). Ayak önde olursa yatınca havaya kalkar.
		"foot_f": [0.03, 0.03, 20.0], "foot_b": [0.0, 0.0, 25.0],
		"arm_f": [8.0, 14.0], "arm_b": [168.0, 176.0], "weapon": 120.0, "body_rot": 90.0,
	}]]},
	# Yerde yatan (Ölümün Kıyısı, yaşıyor): oturup arkaya düşmüş, arka kola
	# dayanıyor, bacaklar önde uzanık.
	"downed": {"frames": 1, "keys": [[0.0, {
		"hip_y": -0.40, "lean": -62.0,
		"foot_f": [0.40, 0.0, 25.0], "foot_b": [0.34, 0.0, 20.0],
		# Arka kol neredeyse düz, parmakları tam zeminde (el bileği az üstünde).
		"arm_f": [40.0, 80.0], "arm_b": [-58.0, -56.0], "weapon": 96.0,
	}]]},
	# Sandıkta, bankta, kütükte oturan yorgun biri (kullanıcı notu 2026-10-20:
	# at sırtı duruşu oturmak gibi okunmuyordu). Kalça diz hizasına iner, uyluk
	# yatay, baldır dik; ayaklar yerde dizin altında; gövde öne çökük; eller
	# dizlerin üstünde. Oturduğu şey çizilmez: altına sandık/bank konur.
	"sit_box": {"frames": 1, "keys": [[0.0, {
		"hip_y": -0.225, "lean": 17.0,
		"foot_f": [0.235, 0.0, 0.0], "foot_b": [0.215, 0.0, 0.0],
		"arm_f": [6.0, 44.0], "arm_b": [2.0, 38.0], "weapon": 0.0,
	}]]},
	# Yol tepkileri (görev N31d). Klip sözlüğünde baş yok: "bakmak" ön elin
	# alnına siper olduğu, gövdenin hafifçe geriye kalktığı bir duruş - yolda
	# bir işaret belirince en yakındaki ileri bakar.
	"look_ahead": {"frames": 1, "keys": [[0.0, {
		"lean": -4.0, "foot_f": [0.07, 0.0, 0.0], "foot_b": [-0.07, 0.0, 0.0],
		"arm_f": [125.0, 262.0], "arm_b": [6.0, 16.0], "weapon": 0.0,
	}]]},
	# Dur temposunda yorgun bekleyiş: gövde öne çökük, dizler hafif kırık,
	# kollar sarkık ve biraz önde.
	"idle_tired": {"frames": 1, "keys": [[0.0, {
		"hip_y": -0.018, "lean": 11.0, "foot_f": [0.05, 0.0, 0.0], "foot_b": [-0.06, 0.0, 0.0],
		"arm_f": [9.0, 16.0], "arm_b": [5.0, 12.0], "weapon": 0.0,
	}]]},
}

const HEAD_OFFSET: Vector2 = Vector2(0.012, 0.0)

## Yük taşıyan yürüyüş (heybe): gövde öne eğik, ön el askıyı tutuyor, yalnız
## arka kol sallanıyor.
const LADEN_LEAN: float = 0.10
const LADEN_HOLD: Array = [18.0, 115.0]

## Yürüyüş: `FigureRig.pose()`, üstüne bilek eklemi (yalın ayak 1, bot
## `FigureRig.BOOT_ANKLE_RANGE`) ve isteğe bağlı yük. `draw` her pozda olsun.
static func walk_pose(
	ground: Vector2, h: float, phase: float, motion: float, facing: float,
	ankle_range: float = 1.0, laden: bool = false, seated: bool = false, bulk: float = 1.0
) -> Dictionary:
	var j := FigureRig.pose(ground, h, phase, motion, facing,
		LADEN_LEAN if laden else 0.0, seated, bulk, ankle_range)
	if laden:
		var shoulder: Vector2 = j["shoulder"]
		var elbow := shoulder + _dir(float(LADEN_HOLD[0]), facing) * h * FigureRig.UPPER_ARM_RATIO
		var hand := elbow + _dir(float(LADEN_HOLD[1]), facing) * h * FigureRig.FOREARM_RATIO
		j["elbow_front"] = elbow
		j["hand_front"] = hand
		j["fingers_front"] = hand + (hand - elbow).normalized() * h * FigureRig.HAND_RATIO
	j["draw"] = Vector2.ZERO
	return j

static func has_clip(clip: String) -> bool:
	return CLIPS.has(clip)

static func frame_count(clip: String) -> int:
	return int(CLIPS[clip].frames) if CLIPS.has(clip) else 0

## Klibin `i`. karesinin parametreleri: anahtar kareler arasında smoothstep.
static func params(clip: String, i: int) -> Dictionary:
	var spec: Dictionary = CLIPS[clip]
	var n: int = int(spec.frames)
	var t := 0.0 if n <= 1 else float(i) / float(n - 1)
	var keys: Array = spec["keys"]
	var a: Array = keys[0]
	var b: Array = keys[keys.size() - 1]
	for k in keys.size() - 1:
		if t >= float(keys[k][0]) and t <= float(keys[k + 1][0]):
			a = keys[k]
			b = keys[k + 1]
			break
	var span := float(b[0]) - float(a[0])
	var u := 0.0 if span <= 0.0 else smoothstep(0.0, 1.0, (t - float(a[0])) / span)
	return _mix(_full(a[1]), _full(b[1]), u)

static func _full(p: Dictionary) -> Dictionary:
	var out := NEUTRAL.duplicate(true)
	for k in p:
		out[k] = p[k]
	return out

static func _mix(a: Dictionary, b: Dictionary, u: float) -> Dictionary:
	var out := {}
	for k in a:
		if a[k] is Array:
			var arr: Array = []
			for j in (a[k] as Array).size():
				arr.append(lerpf(float(a[k][j]), float(b[k][j]), u))
			out[k] = arr
		else:
			out[k] = lerpf(float(a[k]), float(b[k]), u)
	return out

## Eklemler `FigureRig.pose()`'unkiyle aynı adlarla, ek olarak `draw`
## (kirişin çekilmişliği) ve yaydaki kiriş uçları için `weapon_tip`.
static func pose(clip: String, i: int, ground: Vector2, h: float, facing: float, bulk: float = 1.0) -> Dictionary:
	return pose_from(params(clip, i), ground, h, facing, bulk)

static func pose_from(p: Dictionary, ground: Vector2, h: float, facing: float, bulk: float = 1.0) -> Dictionary:
	var j := {}
	var leg_len := h * FigureRig.HIP_RATIO
	var hip := ground + Vector2(float(p.hip_x) * h * facing, -(FigureRig.HIP_RATIO + float(p.hip_y)) * h)
	# Bacak uzamaz: açık duruşta ayağa uzanamayan kalça iner, ayak kalkmaz.
	# (Önce ayak kalçaya çekiliyordu - yay duruşunda ayak yerden 2 px havada
	# kaldı, test yakaladı.)
	for side in ["f", "b"]:
		var foot: Array = p["foot_" + side]
		var dx := float(foot[0]) * h
		var reach := sqrt(maxf(0.0, pow(leg_len * 0.998, 2.0) - dx * dx))
		hip.y = maxf(hip.y, ground.y - float(foot[1]) * h - reach)
	j["hip"] = hip
	for side in ["front", "back"]:
		var foot: Array = p["foot_" + side.substr(0, 1)]
		var ankle := Vector2(hip.x + float(foot[0]) * h * facing, ground.y - float(foot[1]) * h)
		# Bacaktan uzak hedef: ayak kalçanın altında bacak boyuna çekilir.
		var to_ankle := ankle - hip
		if to_ankle.length() > leg_len * 0.999:
			ankle = hip + to_ankle.normalized() * leg_len * 0.999
		j["knee_" + side] = FigureRig.solve_joint(
			hip, ankle, leg_len * FigureRig.THIGH_SHARE, leg_len * FigureRig.SHIN_SHARE, -facing
		)
		j["ankle_" + side] = ankle
		var pitch := deg_to_rad(float(foot[2]))
		j["toe_" + side] = ankle + Vector2(cos(pitch) * facing, -sin(pitch)) * h * FigureRig.FOOT_RATIO
	var lean := deg_to_rad(float(p.lean))
	var shoulder := hip + Vector2(sin(lean) * facing, -cos(lean)) * h * FigureRig.TORSO_RATIO
	j["shoulder"] = shoulder
	var radius := FigureRig.head_radius(h, bulk)
	var up := Vector2(sin(lean) * facing, -cos(lean))
	j["head"] = shoulder + up * radius * 1.35 + Vector2(HEAD_OFFSET.x * h * facing, 0.0)
	for side in ["front", "back"]:
		var arm: Array = p["arm_" + side.substr(0, 1)]
		var elbow := shoulder + _dir(float(arm[0]), facing) * h * FigureRig.UPPER_ARM_RATIO
		var hand := elbow + _dir(float(arm[1]), facing) * h * FigureRig.FOREARM_RATIO
		j["elbow_" + side] = elbow
		j["hand_" + side] = hand
		j["fingers_" + side] = hand + (hand - elbow).normalized() * h * FigureRig.HAND_RATIO
	j["weapon_tip"] = j["hand_front"] + _dir(float(p.weapon), facing) * h * FigureRig.WEAPON_RATIO
	j["draw"] = Vector2(float(p.draw), 0.0)
	var rot := deg_to_rad(float(p.body_rot))
	if rot != 0.0:
		_lay_down(j, ground, -rot * facing)
	return j

## Aşağı sarkıktan öne doğru `deg` derece: sağa bakan figürde (sin, cos).
static func _dir(deg: float, facing: float) -> Vector2:
	var a := deg_to_rad(deg)
	return Vector2(sin(a) * facing, cos(a))

## Bütün figürü kalçanın altındaki zemin noktası etrafında döndürür, sonra en
## alçak eklemi zemine indirir ve bedeni zemin noktasında ortalar. `draw` bir eklem değil, dokunulmaz.
static func _lay_down(j: Dictionary, ground: Vector2, angle: float) -> void:
	var pivot := Vector2(j["hip"].x, ground.y)
	var lowest := -INF
	for k in j:
		if k == "draw":
			continue
		j[k] = pivot + (Vector2(j[k]) - pivot).rotated(angle)
		lowest = maxf(lowest, j[k].y)
	var drop := ground.y - lowest
	# Yatan beden zemin noktasının üstünde ortalanır: kalça etrafında dönünce
	# baş bir yana yarım boy kayıyordu ve render tuvalinden taştı (ölçüldü).
	var lo := INF
	var hi := -INF
	for k in j:
		if k != "draw" and k != "weapon_tip":
			lo = minf(lo, j[k].x)
			hi = maxf(hi, j[k].x)
	var shift := ground.x - (lo + hi) * 0.5
	for k in j:
		if k != "draw":
			j[k] = Vector2(j[k]) + Vector2(shift, drop)

## Bir silah ailesinin savaş klipleri. Kılıç/satır/gürz/asa savurur, mızrak
## saplar, yay gerer; hepsi aynı darbe/savunma/ölüm kliplerini paylaşır.
static func clips_for_weapon(weapon: String) -> Dictionary:
	match weapon:
		"bow":
			return {"stance": "stance_bow", "attack": "attack_bow", "aim": "aim_bow"}
		"spear_shield":
			return {"stance": "stance_melee", "attack": "attack_thrust", "aim": "stance_melee"}
		_:
			return {"stance": "stance_melee", "attack": "attack_swing", "aim": "stance_melee"}
