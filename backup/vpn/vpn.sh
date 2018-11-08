#!/usr/bin/expect

set timeout -1
#set PWD vagrant
#spawn passwd
spawn openconnect -u dave.zhao --script=/etc/vpn/vpnc-script --no-dtls 14.118.132.74
expect "确定"
send "确定\r"
expect "Password:"
send "xxx\r"
interact
#expect eof

