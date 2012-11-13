#!/bin/bash
#
#
LOG_DIR=/home/pi/Logs/DHT
BIN_DIR=/home/pi/bin
SENSTYPE=22

SLEEP_TIME=5

#
# http://learn.adafruit.com/dht-humidity-sensing-on-raspberry-pi-with-gdocs-logging
# cf http://www.open.com.au/mikem/bcm2835/examples.html

function ReadSensor() {
   local sensorType="$1"
   local sensorId="$2"
   local WYNIK=""
   local SUCCESS=""

   ## zwiększyłem powtórzenia do 5 (sleep zmniejszony do 5s/było 10)
   for i in 1 2 3 4 5; do
      WYNIK=`sudo $BIN_DIR/Adafruit_DHT $sensorType $sensorId | tr '\n' ' '`
      SUCCESS=`echo $WYNIK | awk ' { if (NF > 10) {print "YES"} else { print "NO"}}'`

      if [ "$SUCCESS" = "YES" ] ; then
         echo "$sensorId=$i $WYNIK" >> $LOG_DIR/DHT22.log
         DHT_CURR_TEMP=`echo $WYNIK | awk '{print $13}'`
         DHT_CURR_HUM=`echo $WYNIK | awk '{print $17}'`
         break
      fi
      sleep $SLEEP_TIME;
      done

      ## Trzy próby okazały się nieudane
      if [ $SUCCESS = "NO" ] ; then
         echo "$sensorId=? $WYNIK" >> $LOG_DIR/DHT22.log
	 DHT_CURR_TEMP="999.9"
         DHT_CURR_HUM="999.9"
      fi 
}

echo "@`date "+%Y%m%d%H%M%S"`" >> $LOG_DIR/DHT22.log

## Czujnik w pokoju:
ReadSensor $SENSTYPE "24"
READINGS="$DHT_CURR_TEMP $DHT_CURR_HUM"
sleep 12

## Czujnik weranda
ReadSensor $SENSTYPE "25"
READINGS="$READINGS $DHT_CURR_TEMP $DHT_CURR_HUM"
sleep 12

## Czujnik na zewnątrz:
ReadSensor $SENSTYPE "22"
READINGS="$READINGS $DHT_CURR_TEMP $DHT_CURR_HUM"

#
/usr/bin/perl /home/pi/bin/dht2ht.pl > /var/www/stats/DHT22.html

# ** Wyślij na google **
/home/pi/bin/DHT_googledocs.ex.py $READINGS

