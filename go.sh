#!/bin/bash

source setup.cfg
ver=0.8

LOCKFILE="$DEYEDIR/deye.lock"
# Funkcja czyszcząca plik blokady
cleanup() {
    rm -f "$LOCKFILE"
}

# Sprawdzanie, czy plik blokady istnieje
if [ -e "$LOCKFILE" ]; then
    # Odczytaj PID z pliku blokady
    LOCK_PID=$(cat "$LOCKFILE")

    # Sprawdzenie, czy odczytany PID jest liczbą
    if ! [[ "$LOCK_PID" =~ ^[0-9]+$ ]]; then
        echo "Nieprawidłowy PID w pliku blokady. Usuwam plik."
        rm -f "$LOCKFILE"
    else
        # Sprawdź, czy proces o tym PID jeszcze działa
        if ps -p "$LOCK_PID" > /dev/null; then
            echo "Skrypt już działa (PID: $LOCK_PID). Zakończono."
            exit 1
        else
            # Proces nie istnieje, więc usuwamy plik blokady
            echo "Proces zakończony, usuwam plik blokady."
            rm -f "$LOCKFILE"
        fi
    fi
fi

# Utwórz plik blokady i zapisz PID
echo $$ > "$LOCKFILE"

# Ustawienie mechanizmu czyszczenia pliku blokady
trap cleanup EXIT


source setup.cfg

reload_config() {
  source $DEYEDIR/setup.cfg
  }


read_sensor()   {
		local sensor=$1
		local value
		value=$(curl -s --max-time 3 -X GET "http://$HA_ADDR/api/states/$sensor" -H "Authorization: Bearer $APIKEY" | jq -r .state)
		echo "${value%.*}"
		}



time_to_seconds() {
		local time=$1
	        local h=$(echo $time | cut -d':' -f1)
	        local m=$(echo $time | cut -d':' -f2)
	        local s=$(echo $time | cut -d':' -f3)
	        echo $((10#$h * 3600 + 10#$m * 60 + 10#$s))
        }

check_schedule() {
    local current_seconds=$1
    local start_seconds=$2
    local end_seconds=$3
    if (( start_seconds > end_seconds )); then
        # Przedział obejmujący północ
        (( current_seconds >= start_seconds || current_seconds < end_seconds ))
    else
        # Normalny przedział czasowy
        (( current_seconds >= start_seconds && current_seconds < end_seconds ))
    fi
}

                    



sun() {
    sun=$(read_sensor sun.sun)
    if [[ "$sun" == "below_horizon" ]]; then
	echo "Noc"
    else
        echo "Dzień"
    fi

  source $DEYEDIR/setup.cfg
  }
  

state_check() {
    if ! [[ "$(read_sensor $GRID_POWER)" =~ ^-?[0-9]+$ ]]; then
	echo "GRID_POWER = Wartość nie jest liczbą."
        echo "$(date '+%Y-%m-%d %H:%M:%S') GRID_POWER - Wartość nie jest liczbą" >> $DEYEDIR/deye.log
    fi
    if ! [[ "$(read_sensor $BATTERY_CURRENT)" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
	echo "BATTERY_CURRENT = Wartość nie jest liczbą."
	echo "$(date '+%Y-%m-%d %H:%M:%S') BATTERY_CURRENT - Wartość nie jest liczbą" >> $DEYEDIR/deye.log
    fi
}


set_charge() {
  # Funkcja ustawiająca wartość ładowania baterii
  
  # Sprawdzenie, czy podano wartość jako argument
  if [ -z "$1" ]; then
    echo "Użycie: set_charge <wartość od 0 do $MAXAMPS>"
    echo "$(date '+%Y-%m-%d %H:%M:%S') set_charge nie podano argumentu" >> $DEYEDIR/deye.log
    return 1
  fi

  # Walidacja zakresu wartości
  REQUESTCHARGE="$1"
  if ! [[ "$REQUESTCHARGE" =~ ^[0-9]+$ ]] || [ "$REQUESTCHARGE" -lt 0 ] || [ "$REQUESTCHARGE" -gt $MAXAMPS ]; then
    echo "Błąd: wartość musi być liczbą całkowitą w zakresie od 0 do $MAXAMPS."
    echo "$(date '+%Y-%m-%d %H:%M:%S') set_charge argument nie jest w zakresie 0 do $MAXAMPS" >> $DEYEDIR/deye.log
    return 1
  fi

  # Pobranie aktualnej wartości encji
  READCHARGE=$(curl -s --max-time 2 -X GET "${HA_ADDR}/api/states/${GRID_CURRENT}" \
    -H "Authorization: Bearer ${APIKEY}" | jq -r .state)
        

  # Sprawdzenie, czy pobieranie wartości nie powiodło się
  if [ -z "$READCHARGE" ]; then
    echo "Błąd setcharge: Nie można pobrać aktualnej wartości."
    echo "$(date '+%Y-%m-%d %H:%M:%S') BRAK AKTUALNEJ WARTOŚCI." >> $DEYEDIR/deye.log
    return 1
  fi

  if [ "$READCHARGE" = "$REQUESTCHARGE" ]; then
    echo "Nie dokonuję zmian: Aktualna moc ładowania $READCHARGE A , Ustalana: $REQUESTCHARGE A"
    echo "$(date '+%Y-%m-%d %H:%M:%S') Nie dokonuję zmian, Aktualna moc ładowania $READCHARGE A Ustalana: $REQUESTCHARGE A" >> $DEYEDIR/deye.log
    return 1
  fi

  RESPONSE=$(curl -s --max-time 2 -X POST "${HA_ADDR}/api/services/number/set_value" \
    -H "Authorization: Bearer ${APIKEY}" \
    -H "Content-Type: application/json" \
    -d '{"entity_id": "'"${GRID_CURRENT}"'", "value": '"${REQUESTCHARGE}"'}')



  if [ -z "$RESPONSE" ]; then
    echo "Błąd: brak odpowiedzi od API USTALANA $REQUESTCHARGE."
    echo "$(date '+%Y-%m-%d %H:%M:%S') BRAK ODPOWIEDZI API, WYWOŁANO USTALENIE NA $REQUESTCHARGE." >> $DEYEDIR/deye.log
    return 1
  fi
  SETCHARGE=$(curl -s --max-time 2 -X GET "${HA_ADDR}/api/states/number.deye12kw_battery_grid_charging_current" \
    -H "Authorization: Bearer ${APIKEY}" \
    | jq -r '.state')

  if [ "$REQUESTCHARGE" = "$SETCHARGE" ]; then
    echo "Wartość ładowania ustawiona na $SETCHARGE."
    echo "$(date '+%Y-%m-%d %H:%M:%S') Wartość ustawiona na $SETCHARGE." >> $DEYEDIR/deye.log
    sed -i "s/^SETCHARGE=.*/SETCHARGE=$REQUESTCHARGE/" $DEYEDIR/data.txt
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') Błąd podczas ustawiania wartości. Odpowiedź API:  $RESPONSE." >> $DEYEDIR/deye.log
    return 1
  fi
}


set_mode_and_percent() {
  # Funkcja ustawiająca tryb działania i procent

  local setmode="$1"
  local setpercent="$2"

  # Sprawdzenie, czy podano argumenty
  if [ -z "$setmode" ]; then
    echo "Błąd: Musisz podać argument (Grid lub Disabled)."
    return 1
  fi

  if [ -z "$setpercent" ]; then
    echo "Błąd: Musisz podać drugi argument (dodatnia liczba)."
    return 1
  fi

  # Walidacja pierwszego argumentu
  if [ "$setmode" != "Grid" ] && [ "$setmode" != "Disabled" ]; then
    echo "Błąd: Pierwszy argument musi być Grid lub Disabled."
    return 1
  fi

CURRENT_TIME=$(date +"%H:%M:%S")
CURRENT_SECONDS=$(time_to_seconds "$CURRENT_TIME")

 check_home_assistant
  SCHEDULE1SECONDS=$(time_to_seconds "$(read_sensor $SCHEDULE1TIME)")
  SCHEDULE2SECONDS=$(time_to_seconds "$(read_sensor $SCHEDULE2TIME)")
  SCHEDULE3SECONDS=$(time_to_seconds "$(read_sensor $SCHEDULE3TIME)")
  SCHEDULE4SECONDS=$(time_to_seconds "$(read_sensor $SCHEDULE4TIME)")
  SCHEDULE5SECONDS=$(time_to_seconds "$(read_sensor $SCHEDULE5TIME)")
  SCHEDULE6SECONDS=$(time_to_seconds "$(read_sensor $SCHEDULE6TIME)")

  echo "Aktualny czas $CURRENT_TIME"
  
  local schedule
  local schedulepercent


    if check_schedule "$CURRENT_SECONDS" "$SCHEDULE6SECONDS" "$SCHEDULE1SECONDS"; then
        echo "Harmonogram SCHEDULE6TIME"
    schedule=$SCHEDULE6
    schedulepercent=$SCHEDULE6PERCENT

    elif check_schedule "$CURRENT_SECONDS" "$SCHEDULE1SECONDS" "$SCHEDULE2SECONDS"; then
        echo "Harmonogram SCHEDULE1TIME"
    schedule=$SCHEDULE1
    schedulepercent=$SCHEDULE1PERCENT

    elif check_schedule "$CURRENT_SECONDS" "$SCHEDULE2SECONDS" "$SCHEDULE3SECONDS"; then
        echo "Harmonogram SCHEDULE2TIME"
    schedule=$SCHEDULE2
    schedulepercent=$SCHEDULE2PERCENT

    elif check_schedule "$CURRENT_SECONDS" "$SCHEDULE3SECONDS" "$SCHEDULE4SECONDS"; then
        echo "Harmonogram SCHEDULE3TIME"
    schedule=$SCHEDULE3
    schedulepercent=$SCHEDULE3PERCENT

    elif check_schedule "$CURRENT_SECONDS" "$SCHEDULE4SECONDS" "$SCHEDULE5SECONDS"; then
        echo "Harmonogram SCHEDULE4TIME"
    schedule=$SCHEDULE4
    schedulepercent=$SCHEDULE4PERCENT

    elif check_schedule "$CURRENT_SECONDS" "$SCHEDULE5SECONDS" "$SCHEDULE6SECONDS"; then
        echo "Harmonogram SCHEDULE5TIME"
    schedule=$SCHEDULE5
    schedulepercent=$SCHEDULE5PERCENT

    else
        echo "Nie można dopasować czasu z harmonogramu"
        echo "$(date '+%Y-%m-%d %H:%M:%S') Nie można dopasować czasu harmonogramu" >> $DEYEDIR/deye.log
    exit 0
    fi


  echo "Ustalam $schedule na $setmode"
  echo "Ustalam $schedulepercent na $setpercent"
    
  # Pobranie aktualnych wartości encji
  local currentmode
  local currentpercent
  currentmode=$(curl -s --max-time 3 -X GET "${HA_ADDR}/api/states/${schedule}" -H "Authorization: Bearer ${APIKEY}" | jq -r .state)
  currentpercent=$(curl -s --max-time 3 -X GET "${HA_ADDR}/api/states/${schedulepercent}" -H "Authorization: Bearer ${APIKEY}" | jq -r .state)

  echo "Stan Aktualny Mode: $currentmode"
  echo "Stan Aktualny Procent: $currentpercent"

  # Aktualizacja trybu, jeśli wymaga zmiany
  if [ "$currentmode" != "$setmode" ]; then
    echo "Tryb wymagał zmiany"
    curl -s --output /dev/null -X POST -H "Authorization: Bearer $APIKEY" -H "Content-Type: application/json" \
      -d "{\"entity_id\": \"$schedule\", \"option\": \"$setmode\"}"  "$HA_ADDR/api/services/select/select_option"
    sed -i "s/^MODE=.*/MODE=$setmode/" $DEYEDIR/data.txt
    sed -i "s/^SCHEDULE=.*/SCHEDULE=$schedule/" $DEYEDIR/data.txt
  else
    echo "Tryb nie wymagał zmiany"
    sed -i "s/^MODE=.*/MODE=$setmode/" $DEYEDIR/data.txt
    sed -i "s/^SCHEDULE=.*/SCHEDULE=$schedule/" $DEYEDIR/data.txt
    
  fi

  # Aktualizacja procentu, jeśli wymaga zmiany
  if [ "$currentpercent" != "$setpercent" ]; then
    echo "Procent wymagał zmiany"
    curl -s --output /dev/null -X POST -H "Authorization: Bearer $APIKEY" -H "Content-Type: application/json" \
      -d '{"entity_id": "'"$schedulepercent"'", "value": '"$setpercent"'}' "$HA_ADDR/api/services/number/set_value"
  else
    echo "Procent nie wymagał zmiany"
  fi
}


charge_comp() {
    if [ -z "$1" ]; then
        echo "Użycie: $0 <wartość zadana>"
        exit 1
    fi

    zadana=$1
    skompensowane=$(echo "scale=2; ($zadana + 1.2) / 0.92" | bc)
    skompensowane_rounded=$(echo "($skompensowane + 0.5)/1" | bc)
    laduj=$(echo "scale=2; 0.92 * $skompensowane_rounded - 1.2" | bc)
    echo "$skompensowane_rounded"
}


check_home_assistant() {

    while true; do
        if curl -s -o /dev/null -w "%{http_code}" "$HA_ADDR" | grep -q "^2"; then
            break
        else
            echo "Home Assistant nie działa. Ponawianie sprawdzania za $HADOWN sekund..."
            sleep $HADOWN
        fi
    done
}

#########################################################################
#########################START ##########################################
#########################################################################
echo "Uruchamiam......."

if [[ "$(read_sensor "$DEYEONOFF")" == "on" ]]; then
    echo "Deye działa..."
        else
        echo "Deye nie działa albo nie można pobrać danych z Home Assistant"
        exit 0
fi

check_home_assistant
set_charge 0
sed -i "s/^SETCHARGE=.*/SETCHARGE=0/" $DEYEDIR/data.txt
set_mode_and_percent Grid $MAXBAT
echo Czekamy na stabilizację $SLEEP sekund
sleep $SLEEP

while true; do
    echo "###### Deye prosument $VER ######"
    echo "$(date '+%Y-%m-%d %H:%M:%S') ####### URUCHAMIAM ########" >> $DEYEDIR/deye.log
    sun
    UPDATE=$(date '+%Y-%m-%d %H:%M:%S')
    sed -i "s/^UPDATE=.*/UPDATE=$UPDATE/" $DEYEDIR/data.txt
    check_home_assistant
    BATTERYPOWER=$(read_sensor $BATTERY_POWER)
    GRIDPOWER=$(read_sensor $GRID_POWER)
    echo "Aktualne pobory $(read_sensor $LOAD_POWER) W"
    echo "Aktualna produkcja $(read_sensor $PV_POWER) W"
    echo "Obciążenie batteri: $(read_sensor $BATTERY_POWER)W $(read_sensor $BATTERY_CURRENT)A"
    check_home_assistant
    state_check
    sed -i "s/^LOAD=.*/LOAD=$(read_sensor $LOAD_POWER)/" $DEYEDIR/data.txt
    sed -i "s/^PV=.*/PV=$(read_sensor $PV_POWER)/" $DEYEDIR/data.txt
    sed -i "s/^MAXBAT=.*/MAXBAT=$MAXBAT/" $DEYEDIR/data.txt
    sed -i "s/^LOWBAT=.*/LOWBAT=$LOW_BATTERY/" $DEYEDIR/data.txt
    sed -i "s/^BATTCUR=.*/BATTCUR=$(read_sensor $BATTERY_CURRENT)/" $DEYEDIR/data.txt
    sed -i "s/^BATTWAT=.*/BATTWAT=$(read_sensor $BATTERY_POWER)/" $DEYEDIR/data.txt
    sed -i "s/^GRIDPOWER=.*/GRIDPOWER=$(read_sensor $GRID_POWER)/" $DEYEDIR/data.txt

################## START PROCEDUR ########
    echo "Magazyn naładowany w $(read_sensor $ACTUAL_BATTERY)% , wymuszone ładowanie nastąpi gdy spadnie poniżej $CRIT_BAT%"
    echo "Zakres pracy maksymalizacji autokonsumpcji od $LOW_BATTERY% do $MAXBAT%"
    sed -i "s/^BATCHARGE=.*/BATCHARGE=$(read_sensor $ACTUAL_BATTERY)/" $DEYEDIR/data.txt
    sed -i "s/^BATMIN=.*/BATMIN=$CRIT_BAT/" $DEYEDIR/data.txt

    if [ "$(read_sensor $LOAD_POWER)" -ge "$(read_sensor $PV_POWER)" ]; then
	echo "Brak pokrycia obciążenia z generacji PV"

	# JEZELI NAŁADOWANIE BATERI POZWALA NA ROZŁADOWYWANIE TO ##
	if [ "$LOW_BATTERY" -lt "$(read_sensor $ACTUAL_BATTERY)" ]; then
	    echo "Zadane naładowanie $LOW_BATTERY% mniejsze niz $(read_sensor $ACTUAL_BATTERY)% - pozwalamy rozładowywać"
	    check_home_assistant
	    set_charge 0
	    sed -i "s/^SETCHARGE=.*/SETCHARGE=0/" $DEYEDIR/data.txt
	    set_mode_and_percent Disabled $LOW_BATTERY
	    echo "Następna Aktualizacja za $SLEEP sekund"
	    reload_config
	    sleep $SLEEP
	    
	else
	    echo "Zadane naładowanie $LOW_BATTERY większe niż  $(read_sensor $ACTUAL_BATTERY)% - nie pozwalamy rozładowywać"
    	    check_home_assistant
	    set_charge 0
	    sed -i "s/^SETCHARGE=.*/SETCHARGE=0/" $DEYEDIR/data.txt
	    set_mode_and_percent Grid $MAXBAT
	    echo "Następna Aktualizacja za $SLEEP sekund"
	fi
	### KONIEC PROCEDURY DECYDUJACEJ CZY POZWALAMY ROZŁADOWYWAĆ ##
	
	### PROCEDURA KRYTYCZNEGO NAŁADOWANIA ###
	reload_config
	echo "Sprawdzam stan krytyczny"
	echo "Aktualne naładowanie $(read_sensor $ACTUAL_BATTERY) Krytyczne naładowanie $CRIT_BAT"
	if [ "$(read_sensor $ACTUAL_BATTERY)" -le "$CRIT_BAT" ]; then
	    echo "Wymuszone ładowanie mocą $GRIDAMPS A do poziomu $LOW_BATTERY"
	    echo "Bateria rozładowana do krytycznego poziomu, wymuszam ładowanie"
	    check_home_assistant
	    set_mode_and_percent Grid $MAXBAT
	    set_charge $GRIDAMPS
		    while (( $(read_sensor "$ACTUAL_BATTERY") < LOW_BATTERY + 1 )); do
	                echo "###########"
    	    		echo "Wymuszone ładowanie aktywne"
	    		echo "Bateria aktualnie naładowana $(read_sensor $ACTUAL_BATTERY)%"
	    		CHARGEFORCEDLIMIT=$((LOW_BATTERY + 1))
			echo "Koniec ładowania nastąpi gdy bateria osiągnie $CHARGEFORCEDLIMIT%"
			set_charge $GRIDAMPS
			sed -i "s/^UPDATE=.*/UPDATE=$UPDATE/" $DEYEDIR/data.txt
			sed -i "s/^CHARGEFORCE=.*/CHARGEFORCE=1/" $DEYEDIR/data.txt
			sed -i "s/^BATCHARGE=.*/BATCHARGE=$(read_sensor $ACTUAL_BATTERY)/" $DEYEDIR/data.txt
		        sed -i "s/^BATTCUR=.*/BATTCUR=$(read_sensor $BATTERY_CURRENT)/" $DEYEDIR/data.txt
		        sed -i "s/^BATTWAT=.*/BATTWAT=$(read_sensor $BATTERY_POWER)/" $DEYEDIR/data.txt
		        sed -i "s/^GRIDPOWER=.*/GRIDPOWER=$(read_sensor $GRID_POWER)/" $DEYEDIR/data.txt
			check_home_assistant
	                reload_config
	                sleep $SLEEP
	                sed -i "s/^CHARGEFORCE=.*/CHARGEFORCE=1/" $DEYEDIR/data.txt
        	    done
        	    
	fi
	sed -i "s/^CHARGEFORCE=.*/CHARGEFORCE=0/" $DEYEDIR/data.txt
	### KONIEC PROCEDURA KRYTYCZNEGO NAŁADOWANIA ###
	    reload_config
	    echo "Ponowne sprawdzenie za $SLEEP sekund"
	    sleep $SLEEP
	
	
    else
        echo "Generacja większa niż produkcja, możemy ładować baterię"
        PVDIFF=$(echo "$(read_sensor $PV_POWER) - $(read_sensor $LOAD_POWER)" | bc)
        echo "Nadprodukcja obecnie to $PVDIFF W"
        CHARGEAMP=$(echo "scale=0; $PVDIFF / $(read_sensor $BATTERY_VOLTAGE)" | bc)
        echo "Moc ładowania która pokryje różnice $CHARGEAMP"
        CHARGESUM=$((CHARGEAMP + EAMP))
        echo "Wyliczona moc ładowania $CHARGESUM"
	check_home_assistant
	CHARGECOMP=$(charge_comp "$CHARGESUM")
	if [ $CHARGECOMP -gt $MAXAMPS ]; then
	        CHARGECOMP=$MAXAMPS
	        echo Moc ładowania przekroczyła by maksymalną dozwoloną wartość, ustalam moc ładowania na $MAXAMPS
	fi
        echo "Skompensowana moc ładowania $CHARGECOMP"
        set_mode_and_percent Grid $MAXBAT
    	set_charge $CHARGECOMP
    	sed -i "s/^SETCHARGE=.*/SETCHARGE=$CHARGECOMP/" $DEYEDIR/data.txt
    	echo "Następna Aktualizacja za $SLEEP sekund"
    	reload_config
    	sleep $SLEEP
    fi
done


