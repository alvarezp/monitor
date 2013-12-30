monitor
=======

Simple service monitor written in Bash. It just provides the monitoring logic.
All alerts, actions and monitor probes are on you.

Syntax
======
You can get the syntax on the command line by running `./monitor.bash --help`.

Usage: `monitor.bash [options] "command_to_monitor"`

Options:

    --on-init 'command'
        Command to execute on monitor start.

    --on-up 'command'
        Command to execute when service is brought up.

    --on-down 'command'
        Command to execute when service has gone down.

    --rest-time n_seconds
        Sets all rest timers to n_seconds.

    --rest-time-while-down n_seconds
        Sets the rest timer for the down state to n_seconds.

    --rest-time-while-up n_seconds
        Sets the rest timer for the up state to n_seconds.

    --raising-back-rest n_seconds
        Sets the rest timer for the raising back state to n_seconds.

    --falling-down-rest n_seconds
        Sets the rest timer for the falling down state to n_seconds.

    --falling-down-attempts n
        Sets the number of attempts for the falling down state.

    --raising-back-attempts n
        Sets the number of attempts for the raising back state.

Command to monitor must return 0 on success or non-zero otherwise.

Monitor will start on the INIT state and assume the service is up. On a
failure, it will transit to the FALLING_DOWN state, which will repeat the task
N times to make sure this was not a temporary failure. If this is not the case,
monitor will go to the DOWN state. On a success it will transit to the
RAISING_BACK state and finally, if confirmed, reach back to the UP state.

Examples
========

`./monitor.bash --on-down "mailx -s 'DOWN: ping 127.0.0.1' /dev/null" "ping 127.0.0.1"`

Notes
=====

This program is NOT considered stable. Option parameters may change without
notice until proper stabilization is reached. Feedback and patches welcome.

Help needed
===========

The following help is welcome:

* A prepared script to send e-mail in a friendly way from the command line.

* Feedback on option names.

* SMS scripts for different cellular phone providers.

* Command line tools to get the state of all running monitors.
