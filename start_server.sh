#!/bin/sh
cd Server
npm install
node bin/www&
curl http://localhost:3000/

