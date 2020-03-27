#!/bin/bash
#Bakirov A. R.
#email: turkin86@mail.ru
. /etc/init.d/functions
GetDevWiFiName(){
    DevName=$(iw dev |  grep Interface | cut -d " " -f2)
    ret=0
    if [ -n "$DevName" ]; then
	echo $DevName
    else
	ret=1
	echo
    fi
    return $ret
}
GetWiFiNetList(){
ret=0
list_wifi=""
DevName="$1";
    if [ -n "$DevName" ]; then
	list_wifi=$(iw $DevName scan | grep SSID: | cut -d " " -f 2)
        if [ -n "$list_wifi" ]; then
	    echo "$list_wifi"
	else
	    ret=1
	    echo 
	fi
    fi
    return $ret
}
WIFI_NAME=$(GetDevWiFiName)
EchoList(){
    count=0;
    list="$1"
    if [ -n "list" ];then 
	for i in $list; do
	    count=$((count+1));
	    echo -e "\t$count) $i";
	done
    else
	echo
    fi
    return $count;
}
GetCountWordsInStr(){
    echo "$1" | wc -w
}
SelectNumberList(){
    NumberList="$1"
    StartNum=1;
    EndNum=$(GetCountWordsInStr "$NumberList")
    read NUMBER
    if [ -n "$(echo "$NUMBER" | grep ^[0-9]*$)" ] && [ $NUMBER -ge $StartNum ] && [ $NUMBER -le $EndNum ]; then
	num=0
	for i in $NumberList; do
	    num=$((num+1));
	    if [ $num -eq $NUMBER ]; then
		echo "$i"
		return 0
	    fi
	done
    else
	echo "$NUMBER"
    fi
    return 1
}
if [ -n "$WIFI_NAME" ]; then
    if [ -z "$(ip link show $WIFI_NAME up)" ]; then
        ip link set "$WIFI_NAME" up
    fi
    echo "The search for accessible wi-fi of the wireless networks..."
    echo
    SSID_LIST=$(GetWiFiNetList "$WIFI_NAME")
    echo "The list of wi-fi wireless networks: "
    EchoList "$SSID_LIST"
    READING=true;
    SELECT_SSID=""
    #echo $READING
    while [ "$READING" == "true"  ]; do 
	COUNT=$(GetCountWordsInStr "$SSID_LIST")
	echo -n "Enter the number 1..$COUNT and press [Enter]: "
	SELECT_SSID=$(SelectNumberList "$SSID_LIST" "$COUNT")
	case "$SELECT_SSID" in 
	"Q" | "q" | "qiut" ) 
	    echo "Quit $(basename $0)"
	    exit 0
	;;
	"S" | "s" | "scan" ) 
	    echo "The search for accessible wi-fi of the wireless networks..."
	    echo
	    SSID_LIST=$(GetWiFiNetList "$WIFI_NAME")
	    echo "The list of wi-fi wireless networks: "
	    EchoList "$SSID_LIST"
	;;
	* )
	    if [ 0 -eq $?  ]; then
		READING=false;
	    else 
		echo
		echo "Please enter the number: 1..$COUNT" >&2
		echo "[S]can repiad search wireless networks | [Q]uit for exit."
		echo
	    fi
	;;
	esac
    done
    ####
    CONFIG_FILE="/tmp/$SELECT_SSID.conf"
    echo "Selected the wireless networks: $SELECT_SSID"
    for i in {1..3};do
	read -sp "Password ($i of 3): " PASSWORD
	echo
	echo -n "Connect the wireless networks $SELECT_SSID ..."
	wpa_passphrase "$SELECT_SSID" <<< "$PASSWORD" > "$CONFIG_FILE" 
	wpa_supplicant -B -D wext -i "$WIFI_NAME" -c "$CONFIG_FILE" $1 > /dev/null
	if [ $? -eq 0 ]; then
	    success
	    echo
	    echo -n "Get ip address the wireless $SELECT_SSID ..."
    	    dhclient "$WIFI_NAME"
    	    if [ $? -eq 0 ]; then
		success
		echo
		break;
	    else
		failure
		break;
	    fi
	else
	    failure
	fi
	echo
    done
    if [ -a "$CONFIG_FILE" ]; then
	rm -f "$CONFIG_FILE"
    fi
else
    exit 1;
fi