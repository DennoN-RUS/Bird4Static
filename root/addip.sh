#!/bin/sh

cut_local() {
	grep -vE 'localhost|^0\.|^127\.|^10\.|^172\.16\.|^192\.168\.|^::|^fc..:|^fd..:|^fe..:'
}

cat $1 | awk '{print $1}' | awk '/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/' | sed 's/^/route /' | sed  's/$/\/32 via "'$2'";/' > $3
cat $1 | awk '{print $1}' | awk '/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]{1,2}$/' | sed 's/^/route /' | sed  's/$/ via "'$2'";/' >> $3

until ADDRS=$(dig +short google.com @localhost -p 53) && [ -n "$ADDRS" ] > /dev/null 2>&1; do sleep 5; done

echo "$(cat $1 | awk '{print $1}' | awk '!/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/ && !/^#/')" | {
	while IFS= read -r line; do
		dig A +short $line @localhost -p 53 | awk '/^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/' | cut_local | awk '{print "route "$1"/32 via \"'$2'\";"}' >> $3
	done
}
