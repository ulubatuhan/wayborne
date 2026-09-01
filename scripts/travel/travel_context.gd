class_name TravelContext
extends RefCounted

## Harita ekranı ile kervan planlayıcı arasında seçilen hedefi taşır.
## Autoload bir SceneManager gerekmemesi için static tutuluyor.
## Kervanın mevcut konumu burada değil, kalıcı GameSession içinde durur.

static var selected_destination_id: String = ""
