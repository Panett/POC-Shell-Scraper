#!/bin/sh

url=""
table_id=""
filename=""

missingParameter=false

printHelp() {
    echo "-u <url>          Page URL (mandatory flag)"
    echo "-t <tableid>      Table ID (mandatory flag)"
    echo "-f <file>         Output file (mandatory flag)"
    echo "-h                Print this helper message"
    exit 1
}

######################## OPTIONS HANDLING ########################

while getopts ":hu:t:f:" opt; do
	case $opt in
        h) printHelp ;;
        u) url=${OPTARG} ;;
        t) table_id=${OPTARG} ;;
        f) filename=${OPTARG} ;;
        \?) echo "Invalid option -${OPTARG}" ; exit 1;;
	esac
done
shift $((OPTIND-1))


if [ -z "$url" ]; then
    echo "Error: Missing -u"
    missingParameter=true
fi
if [ -z "$table_id" ]; then
    echo "Error: Missing -t"
    missingParameter=true
fi
if [ -z "$filename" ]; then
    echo "Error: Missing -f"
    missingParameter=true
fi
if [ "$missingParameter" = true ]; then
    echo "Use flag -h for help"
    exit 2
fi


######################## MAIN BODY ########################

# Index for tr xpath
counter=0

# Download page. Exit if curl fails.
if ! page=$(curl -s -f -m 10 $url) ; then
    echo "Error: URL is unreachable"
    exit 1
fi

# Get table body. Exit if table id is not found.
if ! tableBody=$(echo $page | xmllint --html --xpath "//table[@id=\"$table_id\"]/tbody" - 2>/dev/null | xmllint --format - 2>/dev/null ) ; then
    echo "Error: Table ID not found"
    exit 1
fi

# Clean file
echo "" > $filename

while true; do 

    counter=$((counter+1))

    # Search for tr. Exit if there are no more tr found.
    if ! tr=$(echo $tableBody | xmllint --xpath "//tr[$counter]" - 2> /dev/null) ; then
        exit 0
    fi

    anchor=$(echo $tr | xmllint --xpath //td[1]/a -)
    commandName=$(echo $anchor | xmllint --xpath "//text()" -)
    commandUrl=$url$(echo $anchor | xmllint --xpath "//@href" - | sed -e "s: ::g" | sed -e "s:\"::g" | sed "s/href=//")

    # Write to file
    echo $commandName $commandUrl >> $filename
done