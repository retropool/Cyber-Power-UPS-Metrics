# Cyber Power UPS Metrics
How to grab Cyber Power UPS Metrics and manipulate them for use with Prometheus Text Collector. In this example I was running Ubuntu 20.04 LTS.

Power Panel will echo the below UPS stats which aren't JSON friendly (sudo pwrstat -status)

        The UPS information shows as following:
        
        Properties:
                Model Name................... VP1600ELCD
                Firmware Number.............. BF01912BCV1.x
                Rating Voltage............... 230 V
                Rating Power................. 960 Watt

        Current UPS status:
                State........................ Normal
                Power Supply by.............. Utility Power
                Utility Voltage.............. 238 V
                Output Voltage............... 238 V
                Battery Capacity............. 78 %
                Remaining Runtime............ 238 min.
                Load......................... 38 Watt(4 %)
                Line Interaction............. None
                Test Result.................. Unknown
                Last Power Event............. None
                
The goal here is to use a series of awk, sed and rev commands to grab the neccesary values and send them to prometheus. Note: Prometheus won't accept text strings so we must convert text based values such as the "state" metric to values, then use the "Value Mapping" feature in Grafana to change the values back to text.

Steps:

1) Install PowerPanel® Personal Linux https://www.cyberpowersystems.com/product/software/power-panel-personal/powerpanel-for-linux/ 

        sudo wget https://dl4jz3rbrsfum.cloudfront.net/software/PPL_64bit_v1.4.1.deb
        sudo dpkg -i PPL_64bit_v1.4.1.deb

2) Ensure pwrstatd.service is running:

        sudo systemctl status pwrstatd.service
   
3) Create empty Prometheus node exporer file in /var/lib/prometheus/node-exporter/

        sudo nano /var/lib/prometheus/node-exporter/upsmetrics.prom
   
4) Create script file
   
        sudo nano upsmetrics.sh
   
5) Save the below into script file upsmetrics.sh

           #!/bin/bash
           #Grab current UPS status
           stats=$(sudo pwrstat -status | awk '{if(NR==11) print $2}')
           battery=$(sudo pwrstat -status | awk '{if(NR==15) print $3 $4}' | sed 's/%//')
           runtime=$(sudo pwrstat -status | awk '{if(NR==16) print $3 $4}' | rev | cut -c5- | rev)
           load=$(sudo pwrstat -status | awk '{if(NR==17) print $2 $3 $4}' | rev | cut -c9- | rev)

           stats=${stats//Normal/1}
           stats=${stats//Power/2}

           sudo cat << EOF > "/var/lib/prometheus/node-exporter/upsmetrics.prom"
           # TYPE ups_stats gauge
           ups_stats_state ${stats}
           ups_stats_batterycap ${battery}
           ups_stats_runtime ${runtime}
           ups_stats_load ${load}
           EOF
   
   6) Create a cronjob to send the metrics to the node expoter file every 10min 

        crontab -e_
        */5 * * * * sudo bash -l /home/scripts/ups.sh
      
   7) If you go to your prometheus metrics page you should now see UPS stats at the bottom
        
        http://192.168.1.100:9100/metrics
      
