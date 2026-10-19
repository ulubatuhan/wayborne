# Olay kartı incelemesi: cazip ama riskli seçenek (Y-E03)

Kural (CLAUDE.md, Event Engine Rules): bir kart hikâyenin izin verdiği yerde, hikâyeye çeken ama mekanik olarak bedeli
olabilen bir seçenek sunar. "Olabildiğince", "her" değil: yalnızca kayıp olan bir kart yem istemez.

Tarama 2026-10-19, `scripts/events/event_catalog.gd` (59 kart). Kaba tarama zarı, çok sonuçlu seçeneği, savaşı ve olumlu
etkiyi aradı; zincirle gelen bedeli (`UNLOCK_EVENT`) göremediği için o kartlar elle sınıflandı.

## Özet

| Sınıf | Kart |
|---|---|
| Riskli ve cazip seçenek zaten var | 24 |
| Bedel zincirle gelir | 13 |
| Yalnızca kayıp, yem gerekmez | 15 |
| Y-E03 ile seçenek eklendi | 7 |

## Eklenen seçenekler

| Kart | Yeni seçenek |
|---|---|
| evt_sick_merchant | Kendi otacın baksın (Bilgelik): bedava şifa ve itibar ya da tüccarın ayrılması. |
| evt_traveling_tinker | Damgasız kılıç (Zeka, 40 GG): ikinci kademe silah ya da hurda. |
| evt_scouted_pass | İzcisiz patika (lider Sezgisi): iki gün kazanç ya da bir gün kayıp ve tehlike. |
| evt_culture_fisher_catch | Derin kol (Dayanıklılık): bol balık ya da en dayanıklının yaralanması (adı önce görünür). |
| evt_forage | Ormanın derini (Sezgi): bol erzak ya da zehirli meyve (en sezgilinin canı). |
| evt_military_convoy | Düşen sandık (Çeviklik): askerin maaşı ya da muhafızlarla savaş. |
| evt_refugee_column | Ucuza mücevher (Sezgi, 30 GG): gerçek gümüş ya da boyalı tunç; iki durumda da itibar yer. |

Her yeni seçenek `_check_choice` kalıbında: üç kademe (tam başarı, kıl payı, başarısızlık). Kişiye düşen bedelin
adı seçimden önce görünür (`EventEffectApplier.get_choice_target` artık sonuçları da okuyor).

## Riskli ve cazip seçeneği olan kartlar

evt_abandoned_wagon, evt_culture_highland_challenge, evt_culture_port_gossip, evt_culture_valley_dispute, evt_customs_checkpoint, evt_deserter_search, evt_failing_bridge, evt_forgotten_cache, evt_frontier_outpost, evt_grave_keeper, evt_hunting_trip, evt_kin_encounter, evt_landslide, evt_merchant_caravan, evt_mine_collapse, evt_mutiny, evt_party_investigation, evt_pilgrim_encounter, evt_road_patrol, evt_road_wanderer, evt_roadside_shrine, evt_stowaway, evt_troubled_night, evt_wild_animal

## Bedeli zincirle gelen kartlar

| Kart | Neden |
|---|---|
| evt_carcass_on_road | Leşi kesmek erzak verir, kokusu kurtları peşe takar (evt_wolves_follow). |
| evt_deserter_plea | Kaçakları saklamak kervanı sonradan aramaya açar (evt_deserter_search). |
| evt_grave_on_the_road | Mezara durmak bir gün yer, bekçiyi ve adağı açar (zincir). |
| evt_creditor_rider | Atlıyı kovmak icra memurlarını getirir (evt_bailiffs_at_camp). |
| evt_party_theft | Araştırmak hırsızı bulabilir ya da kadroyu birbirine düşürür (zincir). |
| evt_profiteer_recognized | Bakmadan geçmek defterde ve itibarda kalır; geri ödemek pahalı (vicdan kartı). |
| evt_leave_the_wounded | Bırakmak erzak getirir, yaralı sonradan döner ya da dönmez (evt_left_behind_return). |
| evt_deserter_debt | Zincir sonu: önceki kararın bedeli. |
| evt_stowaway_repay | Zincir sonu: önceki iyiliğin karşılığı. |
| evt_left_behind_return | Zincir sonu. |
| evt_grave_offering | Zincir sonu: adak bir huy kazandırır. |
| evt_wanderer_revenge | Zincir sonu: geri çevrilen yolcunun intikamı. |
| evt_spoiled_provisions | Tüccarların payını kesmek erzak kurtarır, itibar ve moral yer (cazip-riskli, zarsız). |

## Yalnızca kayıp ya da haber kartları

| Kart | Neden |
|---|---|
| evt_broken_axle | Kırık dingil: yalnızca kayıp, seçim hangi bedelin ödeneceği. |
| evt_storm | Fırtına: yalnızca kayıp; 'ilerle' seçeneği zarlı. |
| evt_bandit_ambush | Pusu: savaş ya da bedel; yem yok, çünkü pusu bir kayıptır. |
| evt_bandit_tribute_toll | Haraç: öde ya da savaş. |
| evt_bandit_tribute_zone_news | Haber kartı: dünya olayını başlatır. |
| evt_regional_war_news | Haber kartı. |
| evt_plague_outbreak_news | Haber kartı. |
| evt_trade_fair_news | Haber kartı (iyi haber). |
| evt_guard_patrol | Devriye: belge, rüşvet ya da savaş; kanunu dövmek zaferde bile itibar yer. |
| evt_bailiffs_at_camp | Borç zincirinin kapanışı: öde, kaç ya da savaş. |
| evt_wolf_pack | Kurt sürüsü: savaş ya da kaçış. |
| evt_wolves_follow | Zincir: leşin bedeli. |
| evt_stress_brawl | Kavga: yatıştırma zarlı; kazanç değil kaybı küçültme. |
| evt_route_diversion | Yön değiştirmenin bedeli: öde ya da itibar ver. |
| evt_pilgrim_blessing | Tek seçenekli zincir sonu (kutsama). |

Toplam: 59 kart.
