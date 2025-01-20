Dostępna jest również wersja pod Node-Red wymagająca Home Assistant + Node Red

Ten skrypt ma na celu regulować moc ładowania i rozładowana magazynu w celu ograniczenia oddawania energii do sieci.
Celem jego jest ograniczenie oddawania energii do sieci do minimum.
Jest to ulepszenie działania trybu AC Couple on Grid side/load.

UWAGA: Twój harmonogram pracy w Deye zostanie zmieniony. Godziny nie zmienią się, zmieni się tryb grid charge i jego moc.

Wymagane jest ustawienie grid charge w ustawieniach Deye. Możemy ustawić GRID CHARGE na 0A

Nie ma znaczenia ile i jakie mamy inwertery przed lub za Deye.
Skrypt nie będzie zapewne przydatny dla osób które posiadają tylko sam falownik Deye.

Na tą chwilę skrypt działa opierając się na procentach naładowania magazynu. 

Jak to działa ?

Ustalamy progi dolnego rozładowania i górnego naładowania magazynu. Skrypt pobiera dane o produkcji i konsumpcji i wzorując się na wyniku
ustala moc ładowania magazynu lub pozwala go rozładowywać. W uproszczeniu skrypt reguluje moc GRID CHARGE w Deye celem wykożystania maksymalnie
całej produkcji PV z wszystkich źródeł. Gdy produkcja jest zbyt mała a naładowanie magazynu pozwala na pobory, wówczas automatycznie zmienia
się profil harmonogramu i magazyn wspomaga pobory.

Q: Czemu jest to lepsze niż zwykły harmonogram ?
A: Zwykłych harmonogramów możemy mieć 6 i nie są one zawsze optymalne pod panujące warunki. Tu ilość harmonogramów nas nie ogranicza bo są generowane dynamicznie w zależności
od sytuacji.

Dodatkowo możemy ustalić stan naładowania krytycznego, gdy magazyn znajdzie się poniżej tej wartości (np. w skutek braku zasilania sieciowego)
zostanie uruchomione ładowanie magazynu wymuszone aż do momentu gdy osiągnie on procent dolnego naładowania.

Do działania potrzebujemy Home Assistant wraz z obsługą Deye https://github.com/davidrapan/ha-solarman
Potrzebujemy opomiarowaną produkcję PV, opomiarowanie odczytywane z opuźnieniem np. z chmury nie koniecznie sprawdzi się.
Zalecam podlicznik Zamela lub Shelly, ewentualnie odczyt z modbusa na żywo celem szybkiej reakcji na zmiany.

Kolejnym wymaganiem jest opomiarowanie poborów przed Deye, tzw. non essential, zwykle są to urządzenia wysokiej mocy jak ładowarka EV czy pompa ciepła.
Cel jest taki żeby mieć wartość wszystkich poborów w jednej encji, tj. LOAD + przed Deye. Odczyt (deye external power + ups power) nie sprawdzi się.
Idealnie jest mieć podlicznik na external power i sumować z ups power.

Dodatkowo mamy możliwość ustalenia maksymalnej mocy ładowania magazynu. Ta wartość nie zignoruje ustawien BMS/magazynu w deye.

Q: Jaki ma to sens gdy mój magazyn i tak nie zmieści całej produkcji ?
A: Przyjmijmy taki scenariusz:
godzina 
9.30 jest nadprodukcja, ładujemy magazyn
10.20 zmienia się pogoda i nie ma wystarczającej produkcji, magazyn oddaje energię.
10.40 mamy nadprodukcję, ładujemy magazyn
11.05 brak wystarczającej produkcji, dobieramy z magazynu.
11.30 nadprodukcja, ładujemy magazyn
12.10 brak wystarczającej produkcji, dobieramy z magazynu.
itd.
Całośc dzieje się automatycznie w założonych ramach naładowania magazynu.

Q: Prosument ma przecież bilansowanie godzinowe.
A: Tak ale tylko godzinowe, a dzięki temu skryptowi czas bilansowania jest ograniczony tylko pojemnością magazynu.


Uruchomienie:

Wgrywamy na serwerek linuxowy do jakiegoś katalogu gdzie najlepiej mamy dostęp przez przeglądarkę. ustawiamy setup.cfg pod siebie. uruchamiamy go.sh
Możemy mieć podgląd/konfigurację poprzez web.