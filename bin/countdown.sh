#!/bin/sh
# Countdown from <unsigned integer> to 0 in seconds
# Usage: countdown.sh <unsigned integer>

[ "$#" -eq 1 ] || { printf "Usage: countdown.sh <unsigned integer>\n"; exit 1; }

printf '%s\n' "$1" | grep -q '^[0-9]\+$' || \
	{ printf 'Use valid unsigned integer!\n'; exit 1; }

[ "$1" -gt 0 ] || exit 0

{ sec=$(($1))

	while [ "$sec" -gt 0 ]; do
		printf '\r\033[KPress [Enter] to continue, %s seconds left ...' "$sec"
		sleep 1

		sec=$((sec - 1))
	done

	kill -TERM $$

} & pid=$!

trap 'kill $pid >/dev/null 2>&1; printf "\n"' TERM INT

read -r REPLY
kill $pid >/dev/null 2>&1
