#!/bin/bash

#!/bin/sh

DEBUG=0

TRUE=0
FALSE=1

NAGIOS_OK=0
NAGIOS_WARNING=1
NAGIOS_CRITICAL=2

declare -a PARAMETER

if [ $1 ]; then
        DEVICE="$1"
else
        DEVICE="/dev/fct0"
fi

#Redir output of fio-status instead od using tmp file
#TMP_FILE="/tmp/fusionio_device_"$(echo $DEVICE | sed -e 's/\//_/g')

# media_status="Healthy"

# capacity_reserves_percent="100.00"
#Dynamically assigning
#CAPACITY_RESERVE_PERCENT_WARNING=20
#CAPACITY_RESERVE_PERCENT_CRITICAL=10

# board_degC="40"
#Dynamically assigning
#BOARD_DEGC_WARNING=85
#BOARD_DEGC_CRITICAL=95

# client_status="Attached"

# firmware_version="5.0.6"
# product_name="Fusion-io ioDrive Duo 640GB"
# product_number="7XVKM"
# serial_number="77827"
# board_name="Fusion-io ioDIMM 320GB"

if [ $DEBUG -gt 0 ]; then
        echo "DEVICE: "$DEVICE
fi

#JSON format
#Not using tmp file anymore
#/usr/bin/fio-status -d $DEVICE -fj > $TMP_FILE

while read line ; do
        if [ $DEBUG -gt 0 ]; then
                echo "line : "$line
        fi
        if expr index "$line" "\"" > /dev/null ; then
                name="$(echo $line | cut -d\" -f 2)"
                value="$(echo $line | cut -d\" -f 4 | sed -e 's/ /_/g' | sed -e 's/|/-/g' |tr -d "()")"
                if [ $DEBUG -gt 0 ]; then
                        echo "name: "$name
                        echo "value: "$value
                fi

                eval ${name}="${value}"
                if [ $DEBUG -gt 0 ]; then
                        echo "parameter: ${!name}"
                fi
        fi
#done < $TMP_FILE
done < <(/usr/bin/fio-status -d $DEVICE -fj)

#rm -f $TMP_FILE

echo -n "$DEVICE - product_name: "$product_name" - board_name: "$board_name" - firmware_version: "$fw_current_version

# Check device health
echo -n " - reserve_status: "$reserve_status
if [ "$reserve_status" != "Healthy" ]; then
        echo -n " ---> reserve_status is not Healthy !!!"
        exit $NAGIOS_CRITICAL
fi

# Check device attachement
echo -n " - iom_state: "$iom_state
if [ "$iom_state" != "Attached" ]; then
        echo -n " ---> iom_state is not Attached !!!"
        exit $NAGIOS_CRITICAL
fi

# Check capacity_reserves_percent
capacity_reserves_percent=$(echo "$reserve_space_pct" | sed -e 's/\..*//')
CAPACITY_RESERVE_PERCENT_CRITICAL=$(echo "$reserve_warning_threshold_percent" | sed -e 's/\..*//')
let CAPACITY_RESERVE_PERCENT_WARNING=($CAPACITY_RESERVE_PERCENT_CRITICAL * 2)
echo -n " - reserve_space_pct: "$capacity_reserves_percent"% (w:"$CAPACITY_RESERVE_PERCENT_WARNING"% - c:"$CAPACITY_RESERVE_PERCENT_CRITICAL"%)"
if [ $capacity_reserves_percent -lt $CAPACITY_RESERVE_PERCENT_CRITICAL ]; then
        echo -n "---> reserve_space_pct is warning !!!"
        exit $NAGIOS_WARNING
elif [ $capacity_reserves_percent -lt $CAPACITY_RESERVE_PERCENT_WARNING ]; then
        echo -n "---> reserve_space_pct is warning !!!"
        exit $NAGIOS_CRITICAL
fi

# Check board temperature
temp_internal_deg_c_int=$(echo "$temp_internal_deg_c" | sed -e 's/\..*//')
BOARD_DEGC_WARNING=$(echo "$temp_internal_warn_deg_c" | sed -e 's/\..*//')
BOARD_DEGC_CRITICAL=$(echo "$temp_setpoint_high_deg_c" | sed -e 's/\..*//')
echo -n " - board_degC: "$temp_internal_deg_c_int" (w:"$BOARD_DEGC_WARNING" - c:"$BOARD_DEGC_CRITICAL")"
if [ $temp_internal_deg_c_int -gt $BOARD_DEGC_CRITICAL ]  ; then
        echo -n "---> temp_internal_deg_c is critical !!!"
        exit $NAGIOS_CRITICAL
elif [ $temp_internal_deg_c_int -gt $BOARD_DEGC_WARNING ]; then
        echo "---> temp_internal_deg_c is warning !!!"
        exit $NAGIOS_WARNING
fi

exit $NAGIOS_OK

                                                                                                                                                                                                                                           
