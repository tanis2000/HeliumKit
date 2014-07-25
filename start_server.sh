#!/bin/sh
cd Server
npm install
node bin/www&
sleep 10
curl http://localhost:4567/

