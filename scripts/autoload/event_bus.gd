extends Node

## Autoload: sistemlerin birbirine doğrudan bağlanmadan haberleşmesi için
## global sinyal veriyolu. Yalnızca sistem sınırlarını aşan olaylar burada
## duyurulur; sistem içi haberleşme kendi sinyalleriyle kalır.
##
## Sinyal parametreleri bilerek tipsiz: autoload'lar global script class
## cache hazır olmadan ayrıştırıldığı için buradan bir class_name'e ada
## göre başvurmak "Could not find type" hatası verip autoload'un
## tamamen yüklenmemesine yol açıyor. GDScript'te sinyal parametre
## tipleri zaten yalnızca belgeleme amaçlı, davranışa etkisi yok.

## event: GameEvent
signal road_event_fired(event)
## event: GameEvent, choice: EventChoice
signal road_event_resolved(event, choice)
signal caravan_changed()
signal journey_finished(days_taken)
