#!/bin/bash

Main() {
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    MonitorMode
    exit 0

} # Main

MonitorMode() {
    # $1 is the time in seconds to pause between two prints, defaults to 5 seconds
    # This functions prints out endlessly:
    # - time/date
    # - average 1m load
    # - detailed CPU statistics
    # - Soc temperature if available
    # - PMIC temperature if available
    # - DC-IN voltage if available

    # Allow orangepimonitor to return back to orangepi-config
    trap "echo ; exit 0" 0 1 2 3 15

    # Try to renice to 19 to not interfere with OS behaviour
    renice 19 $BASHPID >/dev/null 2>&1

    SleepInterval=${interval:-5}

    Sensors="/etc/orangepimonitor/datasources/"
    CPUs=biglittle

	LastIdleStat=0
    LastTotal=0
    Display='CPU'
    while true; do

        if [ "$Display" = 'CPU' ]; then 
            #CPU
            LoadAvg=$(cut -f1 -d" " </proc/loadavg)
            BigFreq=$(awk '{printf ("%0.0f",$1/1000); }' </sys/devices/system/cpu/cpu4/cpufreq/cpuinfo_cur_freq) 2>/dev/null
            LittleFreq=$(awk '{printf ("%0.0f",$1/1000); }' </sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq) 2>/dev/null
            ProcessStats

            if [ "X${SocTemp}" != "Xn/a" ]; then
                read SocTemp <"${Sensors}/soctemp"
                if [ ${SocTemp} -ge 1000 ]; then
                    SocTemp=$(awk '{printf ("%0.1f",$1/1000); }' <<<${SocTemp})
                fi
            fi

            oledprint "CPU:$(printf "%2s"${CPULoad})%$(printf "%2s"${SocTemp})C" "Frq:$(printf "%4s" ${BigFreq})/$(printf "%4s" ${LittleFreq})MHz"
            
            Display='RAM'
        else
            #RAM
            TotalMem=$( free -h | awk '/Mem/{print $2}')
            UsedMem=$( free -h | awk '/Mem/{print $3}')   
            availableMem=$( free -h | awk '/Mem/{print $7}')

            oledprint "RAM: ${UsedMem}/${TotalMem}" "Free: ${availableMem}"
            
            Display='CPU'
        fi
        
        sleep ${SleepInterval}
    done
} # MonitorMode

ProcessStats() {

    procStatLine=($(sed -n 's/^cpu\s//p' /proc/stat))
    IdleStat=${procStatLine[3]}
    # UserStat=${procStatLine[0]}
    # NiceStat=${procStatLine[1]}
    # SystemStat=${procStatLine[2]}
    # IOWaitStat=${procStatLine[4]}
    # IrqStat=${procStatLine[5]}
    # SoftIrqStat=${procStatLine[6]}

    Total=0
    for eachstat in ${procStatLine[@]}; do
        Total=$((${Total} + ${eachstat}))
    done

    diffIdle=$((${IdleStat} - ${LastIdleStat}))
    diffTotal=$((${Total} - ${LastTotal}))
    diffX=$((${diffTotal} - ${diffIdle}))
    CPULoad=$((${diffX} * 100 / ${diffTotal}))

    LastIdleStat=${IdleStat}
    LastTotal=${Total}

} # ProcessStats

Main "$@"
