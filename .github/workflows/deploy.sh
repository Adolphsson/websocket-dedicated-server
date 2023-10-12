#!/bin/sh

cd /home/apps/mystack/websocket-dedicated-server
git pull
cd database
npm install
supervisorctl restart database:
cd ../server
npm install
supervisorctl restart server:
cd ../website
npm install
supervisorctl restart website:
exit 0
