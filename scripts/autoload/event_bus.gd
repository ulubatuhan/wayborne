extends Node

## Autoload: sistemlerin birbirine doğrudan bağlanmadan haberleşmesi için
## global sinyal veriyolu. Yalnızca sistem sınırlarını aşan olaylar burada
## duyurulur; sistem içi haberleşme kendi sinyalleriyle kalır.

signal road_event_fired(event: GameEvent)
signal road_event_resolved(event: GameEvent, choice: EventChoice)
signal caravan_changed()
signal journey_finished(days_taken: int)
