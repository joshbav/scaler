#!/usr/bin/expect 
spawn dcos auth login
expect "username:"
send bootstrapuser\n;
expect "password:"
send deleteme\n;
interact
