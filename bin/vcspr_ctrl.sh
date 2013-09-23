#!/bin/bash

LANG=C
export LANG

run_type='all' # all | publisher | receiver

base_dir='/opt/VCSPR'

log_dir="$base_dir/log"

psgi_dir="$base_dir/bin"

listen_host='0.0.0.0'

old_pwd=$(pwd)

worker=5

starman_prog="$base_dir/bin/starman"

webctrl_host=$listen_host
webctrl_port=5004
webctrl_pid="$log_dir/webctrl.pid"
webctrl_log="$log_dir/webctrl.log"
webctrl_prog="$base_dir/share/vcsprweb/bin/app.pl"
webctrl_worker=$worker


webctrl1_host=$listen_host
webctrl1_port=5003
webctrl1_pid="$log_dir/webctrl1.pid"
webctrl1_log="$log_dir/webctrl1.log"
webctrl1_prog="$base_dir/share/vcsprwebconsole/bin/app.pl"
webctrl1_worker=$worker


publisher_host=$listen_host
publisher_port=5001
publisher_pid="$log_dir/VCSPublisher.pid"
publisher_log="$log_dir/VCSPublisher.log"
publisher_prog="$psgi_dir/VCSPublisher.psgi"
publisher_worker=$worker

receiver_host=$listen_host
receiver_port=5002
receiver_pid="$log_dir/VCSReceiver.pid"
receiver_log="$log_dir/VCSReceiver.log"
receiver_prog="$psgi_dir/VCSReceiver.psgi"
receiver_worker=$worker

[[ ! -e $log_dir ]] && mkdir -p $log_dir

start() {
    echo "start VCSPR ..."
    #plackup --daemonize --port 5001 --host ${listen_host} --access-log /tmp/VCSPublisher.log  VCSPublisher.psgi 2>&1 >/dev/null &
    #plackup --daemonize --port 5002 --host ${listen_host} --access-log /tmp/VCSReceiver.log  VCSReceiver.psgi 2>&1 >/dev/null  &

    if [[ ($run_type == 'all') || ($run_type == 'publisher') ]];then
        echo "start publisher ..."
        cd $psgi_dir
        ${starman_prog} -l ${publisher_host}:${publisher_port} --workers ${publisher_worker}  -D --pid ${publisher_pid} --access-log ${publisher_log}  ${publisher_prog}
        cd $old_pwd
        echo "start webctrl ..."
        ${starman_prog} -l ${webctrl_host}:${webctrl_port} --workers ${webctrl_worker}  -D --pid ${webctrl_pid} --access-log ${webctrl_log}  ${webctrl_prog}
        ${starman_prog} -l ${webctrl1_host}:${webctrl1_port} --workers ${webctrl1_worker}  -D --pid ${webctrl1_pid} --access-log ${webctrl1_log}  ${webctrl1_prog}
    fi

    if [[ ($run_type == 'all') || ($run_type == 'receiver') ]];then
        echo "start receiver ..."
        cd $psgi_dir
        ${starman_prog} -l ${receiver_host}:${receiver_port} --workers ${receiver_worker}  -D --pid ${receiver_pid} --access-log ${receiver_log}  ${receiver_prog}
        cd $old_pwd
    fi

}

stop() {

    echo "stop VCSPR ... "
    if [[ ($run_type == 'all') || ($run_type == 'publisher') ]];then
        echo "stop publisher ..."
        if [[ -e  $publisher_pid ]];then
            pid1=$(cat $publisher_pid)
            kill -n TERM $pid1
        fi
        echo "stop webctrl ..."
        if [[ -e  $webctrl_pid ]];then
            pid1=$(cat $webctrl_pid)
            kill -n TERM $pid1
        fi

        if [[ -e  $webctrl1_pid ]];then
            pid1=$(cat $webctrl1_pid)
            kill -n TERM $pid1
        fi
    fi

    if [[ ($run_type == 'all') || ($run_type == 'receiver') ]];then
        echo "stop receiver ..."
        if [[ -e $receiver_pid ]];then
            pid2=$(cat $receiver_pid)
            kill -n TERM $pid2
        fi
    fi

}



status() {
    ps -Af|grep VCS|grep -v grep|grep -v "$0"

}

lock='VCSPR.lock'

case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart|reload)
        stop
        sleep 3
        start
        RETVAL=$?
        ;;
  condrestart|try-restart|force-reload|force-restart)
        stop
        pkill 'starman'
        sleep 3
        start
        RETVAL=$?
        ;;
  status)
        status
        RETVAL=$?
        ;;
  *)
        echo $"Usage: $0 {start|stop|restart|force-restart|try-restart|force-reload|status}"
        exit 1
esac
