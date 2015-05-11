#!/bin/bash

PROC=''
DOWN_REST_TIMER=20
UP_REST_TIMER=20
ON_INIT=''
ON_UP=''
ON_DOWN=''
RAISINGBACK_REST=3
FALLINGDOWN_REST=3

SUCCEEDS_NEEDED_FOR_RAISEBACK=5
FAILURES_NEEDED_FOR_FALLDOWN=3

STATE_DOWN=1
STATE_RAISING_BACK=2
STATE_UP=3
STATE_FALLING_DOWN=4
STATE_NAME[$STATE_DOWN]='DOWN'
STATE_NAME[$STATE_RAISING_BACK]='RAISINGBACK'
STATE_NAME[$STATE_UP]='UP'
STATE_NAME[$STATE_FALLING_DOWN]='FALLINGDOWN'

print_help() {
echo "usage: $0 [options] 'command_to_monitor'

Options:
	--on-init 'command'
		Command to execute on monitor start.

	--on-up 'command'
		Command to execute when service is brought up.

	--on-down
		Command to execute when service has gone down.

	--rest-time n_seconds
		Sets all rest timers to n_seconds.

	--rest-time-while-down n_seconds
		Sets the rest timer for the down state to n_seconds.

	--rest-time-while-up
		Sets the rest timer for the up state to n_seconds.

	--raising-back-rest
		Sets the rest timer for the raising back state to n_seconds.

	--falling-down-rest
		Sets the rest timer for the falling down state to n_seconds.

	--falling-down-attempts
		Sets the number of attempts for the falling down state.

	--raising-back-attempts
		Sets the number of attempts for the raising back state.

Command to monitor must return 0 on success or non-zero otherwise.

Monitor will start on the INIT state and assume the service is up. On a
failure, it will transit to the FALLINGDOWN state, which will repeat the task
N times to make sure this was not a temporary failure. If this is not the case,
monitor will go to the DOWN state. On a success it will transit to the
RAISINGBACK state and finally, if confirmed, reach back to the UP state.
"
}

until [ -z "$1" ]; do
	case "$1" in
		--on-init)
			ON_INIT=$2
			shift; shift;;
		--on-up)
			ON_UP=$2
			shift; shift;;
		--on-down)
			ON_DOWN=$2
			shift; shift;;
		--rest-time)
			UP_REST_TIMER=$2
			DOWN_REST_TIMER=$2
			RAISINGBACK_REST=$2
			FALLINGDOWN_REST=$2
			shift; shift;;
		--rest-time-while-down)
			DOWN_REST_TIMER=$2
			shift; shift;;
		--rest-time-while-up)
			UP_REST_TIMER=$2
			shift; shift;;
		--raising-back-rest)
			RAISINGBACK_REST=$2
			shift; shift;;
		--falling-down-rest)
			FAILINGDOWN_REST=$2
			shift; shift;;
		--falling-down-attempts)
			FAILURES_NEEDED_FOR_FALLDOWN=$2
			shift; shift;;
		--raising-back-attempts)
			SUCCEEDS_NEEDED_FOR_RAISEBACK=$2
			shift; shift;;
		--help)
			print_help;
			exit 0;
			;;
		*)
			PROC="$PROC $1"
			shift;;
	esac
done

down() {
	sh -c "$PROC" || {
		sleep $DOWN_REST_TIMER
		return $STATE_DOWN
	}
	return $STATE_RAISING_BACK
}

raising_back() {
	for ATTEMPT in $(seq 2 $SUCCEEDS_NEEDED_FOR_RAISEBACK); do
		sleep $RAISINGBACK_REST
		sh -c "$PROC" || return $STATE_DOWN
	done
	$ON_UP
	return $STATE_UP
}

up() {
	sh -c "$PROC" && {
		sleep $UP_REST_TIMER
		return $STATE_UP
	}
	return $STATE_FALLING_DOWN
}

falling_down() {
	for ATTEMPT in $(seq 2 $FAILURES_NEEDED_FOR_FALLDOWN); do
		sleep $FALLINGDOWN_REST
		sh -c "$PROC" && return $STATE_UP
	done
	$ON_DOWN
	return $STATE_DOWN
}

printf "%11s %s\n" INIT "$(date +'%Y-%d-%m %T %Z %a')"
sh -c "$ON_INIT"

# On INIT, test $PROC and go directly to UP or DOWN.
sh -c "$PROC" && {
	printf "%11s %s\n" UP "$(date +'%Y-%d-%m %T %Z %a')"
	NEXT_STATE=$STATE_UP
} || {
	printf "%11s %s\n" DOWN "$(date +'%Y-%d-%m %T %Z %a')"
	NEXT_STATE=$STATE_DOWN
}
while true; do
	STATE=$NEXT_STATE
	[ $STATE -eq $STATE_DOWN ] && state_action="down"
	[ $STATE -eq $STATE_RAISING_BACK ] && state_action="raising_back"
	[ $STATE -eq $STATE_UP ] && state_action="up"
	[ $STATE -eq $STATE_FALLING_DOWN ] && state_action="falling_down"
	$state_action
	NEXT_STATE=$?
	if [ "$STATE" != "$NEXT_STATE" ]; then
		printf "%11s %s\n" ${STATE_NAME[$NEXT_STATE]} "$(date +'%Y-%d-%m %T %Z %a')"
	fi
done
