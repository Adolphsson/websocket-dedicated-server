#!/bin/sh

pkill -f "node db" --signal SIGHUP
pkill -f "node server" --signal SIGHUP
pkill -f "node website" --signal SIGHUP
cd /home/apps/mystack/websocket-dedicated-server
git pull
cd database
npm install
nohup node db > nohup-db.out 2> nohup-db.err < /dev/null &
cd ../server
npm install
nohup node server > nohup-server.out 2> nohup-server.err < /dev/null &
cd ../website
npm install
nohup node website > nohup-website.out 2> nohup-website.err < /dev/null &