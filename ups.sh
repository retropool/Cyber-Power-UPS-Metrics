#!/bin/bash
#Grab current UPS status
stats=$(sudo pwrstat -status | awk '{if(NR==11) print $2}')
battery=$(sudo pwrstat -status | awk '{if(NR==15) print $3 $4}' | sed 's/%//')
runtime=$(sudo pwrstat -status | awk '{if(NR==16) print $3 $4}' | rev | cut -c5- | rev)
load=$(sudo pwrstat -status | awk '{if(NR==17) print $2 $3 $4}' | rev | cut -c9- | rev)

stats=${stats//Normal/1}
stats=${stats//Power/2}

sudo cat << EOF > "/var/lib/prometheus/node-exporter/ups.prom"
# TYPE ups_stats gauge
ups_stats_state ${stats}
ups_stats_batterycap ${battery}
ups_stats_runtime ${runtime}
ups_stats_load ${load}
EOF
