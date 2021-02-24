#!/bin/sh

url=""
table_id=""
filename=""

# ./scraper -u "https://gtfobins.github.io" -t "bin-table" -f "db"

missingParameter=false

printHelp() {
    echo "-u <url>          Page URL (mandatory flag)"
    echo "-t <tableid>      Table ID (mandatory flag)"
    echo "-f <file>         Output file (mandatory flag)"
    echo "-h                Print this helper message"
    exit 1
}

######################## OPTION PARSING ########################

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
counter=1


# Download page
page=$(curl -s -f -m 10 $url)
if [ ! "$?" -eq "0" ] ; then
    echo "Error: URL is unreachable"
    exit 1
fi

# Get table body
tableBody=$(echo $page | xmllint --html --xpath "//table[@id=\"$table_id\"]/tbody" - 2>/dev/null | xmllint --format - 2>/dev/null )
if [ ! "$?" -eq "0" ] ; then
    echo "Error: Table ID not found"
    exit 1
fi

# Clean file
> $filename

while true; do 

    # Search tr
	tr=$(echo $tableBody | xmllint --xpath "//tr[$counter]" - 2> /dev/null)

    # Exit if there are no more tr found
    if [ ! "$?" -eq "0" ] ; then
        exit 0
    fi

    anchor=$(echo $tr | xmllint --xpath //td[1]/a -)
    commandName=$(echo $anchor | xmllint --xpath "//text()" -)
    commandUrl=$url$(echo $anchor | xmllint --xpath "//@href" - | sed -e "s: ::g" | sed -e "s:\"::g" | sed "s/href=//")

    # Write to file
    echo $commandName $commandUrl >> $filename

    counter=$((counter+1))
done