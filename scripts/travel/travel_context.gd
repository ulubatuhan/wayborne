class_name TravelContext
extends RefCounted

## Harita ekranı ile kervan planlayıcı arasında seçimi taşır.
## Autoload bir SceneManager gerekmemesi için static tutuluyor.

static var current_location_id: String = ""
static var selected_destination_id: String = ""
