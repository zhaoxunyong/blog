#!/usr/bin/expect

set timeout -1
#set PWD vagrant
#spawn passwd
spawn openconnect -u zhao --script=/etc/vpn/vpnc-script --no-dtls 1.1.1.1
expect "确定"
send "确定\r"
expect "Password:"
send "xxx\r"
interact
#expect eof

