#!/bin/bash

#Made by Kaden M. S#200365413.
#This is a script to show a full system report that captures a range of specific system information with one command.

myhostname=$(hostname) #captures the host name associated with the linux system.

mydate=$(date) #captures the current date.

cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs) #grep -m1 'model name' /proc/cpuinfo finds the first occurence of the CPU model, cut -d: -f2 extracts everything after the colon, xargs trims the leading and trailing spaces.

uptime=$(uptime -p) #uptime shows how the long the system has been running and the -p stands for pretty which formats the uptime output for easier human reading.

source=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"') #/etc/os-release is the text file that contains the key value pairs about the operating system. grep searches for the line that starts with PRETTY_NAME=, the ^ ensure we extract the exact match. cut splits the line into fields using = as the delimiter (-d=) -f2 means get the sceond field. tr is the translate/delete command, -d '"' deletes the double quotes around the output.

ram=$(free -h |awk '/^Mem:/ {print $2}') #free displays memory statistics, -h means human readable showing values in Gigabytes instead of byte values. The awk process the output and looks for the line that starts with Mem: by using /^Mem:/ then prints the second column with $2 which is the total installed RAM.

disks=$(lshw -class disk 2>/dev/null | grep -E 'product:|size:' | paste - - | awk -F: '{print " - " $2}' | xargs) #lshw lists the hardware, -class disk restricts the output to disk-related hardware, 2>/dev/null suppresses error output (in case lshw isnt installed or has no permission), grep -E uses extended regular epression to filter the lines containing either product: or size: information. awk -F: '{print " - "$2}' formats each line with the "-" prepended reducing the need for a sed. paste - - joins pairs of lines (product and size in thids case) into one lone. 

video=$(lshw -class display 2>/dev/null | grep -E 'vendor:|product:' | awk -F: '{print $2}' | xargs) # lashw -class display gets information about diaply adapters(GPUS), grep 'vendor:|product:' filters the vendors and product lines. awk -F '{print $2}' extracts the model name. xargs trims the extra spaces.

defaultInterface=$(ip r | awk '/default/ {print $5}') #ip r shows the routing table, awk '/default/ {print $5}' looks at the loine that starts with default and prints the 5th word which is the interface, in my case ens33.
hostIP=$(ip -o -4 addr show $defaultInterface | awk '{print $4}' | cut -d/ -f1) #ip -o limits to a one line output per interface, -4 shows only ipv4 addresses, addr show $defaultInterface shows IP address for the interface, in my case it shows the ens33 address. awk '{print $4}' extracts the ip address with the mask, the cut -d/ -f1 removes the mask.

gateway=$(ip r | awk '/default/ {print $3}') # ip r shows inthe routing table, awk '/default/ {print $3}' looks and filters the line that start with default, then prints the 3rd word on the lne which is the gateway.

dns=$(resolvectl status | grep 'DNS Servers' | awk '{print $3}') #resolvectl status displays the dns servers, grep 'DNS Servers' filters the DNS Servers line, awk '{print $3}' displays the 3rd word in the line.

users=$(who | awk '{print $1}' | sort | uniq | paste -sd,) #who shows who is  currently logged into the system. awk '{print $1}' extracts the first column from each line of the who output. sort, sorts the name alphabetically. uniq removes duplicates. paste -sd, joins all lines into a single line using a comma as the seperator. 

diskspace=$(df -h --output=target,avail | grep -v 'Mounted' | awk '{print $1 " " $2}' | xargs -n2 | sed 's/^/ - /') #df displays disk pace usage for mounted filesystems. -h makes the output human readable for eg KB, MB, GB. --output=target,avail specifies that only the target (mount point) and available space columns should be shound in the output. grep searchs for lines matching a pattern. -v invert the match(so it excludes lines that match the pattern) 'Mounted' is the keyword we want to exclude from the output. awk text processing, {print $1 "" $2} tells awk to print the first field and the second field with a space between them. xargs reads items from input and executes a command for each item. -n2 tells xargs to process two items at a time(so it will take each line of input, which has two words: the mount point and the available spaces). sed a stream editor used for text tranformation. 's/^/ - /' this sed command adds a " - " at the beginning of each lonne and the ^ refers to the beginning of the line.

processcount=$(ps ax --no-heading | wc -l) #ps is a command to list running processes. a shows processes from all users. x shows process not attached to a terminal (like background services) --no-heading tells ps too omit the header line, this is important because we want tot count only the process lines not the title row. wc counts words -l counts the number of lines in the input.

loadavg=$(uptime | awk -F 'load average: ' '{print $2}') #uptime shows how long the system has been running, how many users are loggin in and the systems load averages. awk extracts data, -F'load average: ' sets the field delimiter to the text 'load average' that is it splits the line using this as a boundary. {print $2} tells awk to print the second part of the line, everything after 'load average: '.

listeningports=$(ss -tuln | awk '/LISTEN/ {print $5}' | awk -F: '{print $NF}' | sort -n | uniq | paste -sd,) #ss shows sockets statistics -tuln shows TCP, UDP, listening sockets only, raw port numbers, dont resolve names. awk '/LISTEN/ filters lines with the word LISTEN, {print $5} prints the 5th column which is the local address:Port field. awk -F: '{print $NF}' uses : as the delimited, and print $NF prints the last field whih is the port number. sort -n sorts the ports numerically, uniq removes duplicates, paste -sd, joins all linnes into a single comman-separated string.

ufwstatus=$(sudo ufw status 2>/dev/null | head -n 1 | awk '{print $2}') #ufw is a tool for managing the linux firewall, status shows whether the firewall is active or inactive. sudo is required because firewall operations need root privileges. 2>/dev/null redirects an errors messages so essentially suppressing them. this is useful in case ufw is not installed or the user doesnt have perms. head -n 1 takes only the first line of the ufw status output.



cat <<EOF


System Report for $myhostname generated by $USER, on $mydate
 
System Information
------------------
OS: $source
Uptime: $uptime
CPU: $cpu
RAM: $ram
Disk(s): $disks
Video: $video
Host Address: $hostIP
Gateway IP: $gateway
DNS Server: $dns
 
System Status
-------------
Users Logged In: $users
Disk Space: $diskspace
Process Count: $processcount
Load Averages: $loadavg
Listening Network Ports: $listeningports
UFW Status: $ufwstatus


EOF




