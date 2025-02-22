#!/bin/bash

declare -A faulty_dimm

for mc in /sys/devices/system/edac/mc/mc*; do
    for row in "$mc"/csrow*; do
        ce_count=$(cat "$row/ce_count" 2>/dev/null || echo 0)
        ue_count=$(cat "$row/ue_count" 2>/dev/null || echo 0)
        
        if [[ "$ce_count" -gt 0 || "$ue_count" -gt 0 ]]; then
            dimm_label=$(basename "$row")
            faulty_dimm[$dimm_label]=1
        fi
    done
done

declare -A dimm_map
while IFS= read -r line; do
    slot=$(echo "$line" | awk -F': ' '/Locator/ {print $2}')
    size=$(echo "$line" | awk -F': ' '/Size/ {print $2}')
    
    if [[ "$size" != "No Module Installed" ]]; then
        dimm_map[$slot]="$size"
    fi
done < <(dmidecode -t memory | grep -E 'Locator|Size')

layout=$(cat << "EOF"
                [ Front of the Server ]                  
+-----------------------------+-----------------------------+
|          DIMM  0            |          DIMM 16           |
|          DIMM  1            |          DIMM 17           |
|          DIMM  2            |          DIMM 18           |
|          DIMM  3            |          DIMM 19           |
|          DIMM  4            |          DIMM 20           |
|          DIMM  5            |          DIMM 21           |
|          DIMM  6            |          DIMM 22           |
|          DIMM  7            |          DIMM 23           |
+-----------------------------+-----------------------------+
|           CPU 0             |           CPU 1            |
+-----------------------------+-----------------------------+
|          DIMM  8            |          DIMM 24           |
|          DIMM  9            |          DIMM 25           |
|          DIMM 10            |          DIMM 26           |
|          DIMM 11            |          DIMM 27           |
|          DIMM 12            |          DIMM 28           |
|          DIMM 13            |          DIMM 29           |
|          DIMM 14            |          DIMM 30           |
|          DIMM 15            |          DIMM 31           |
+-----------------------------+-----------------------------+
EOF
)

echo "$layout" | while read -r line; do
    for dimm in "${!faulty_dimm[@]}"; do
        line=$(echo "$line" | sed "s/\($dimm\)/\x1b[41m\1\x1b[0m/")
    done
    echo -e "$line"
done
