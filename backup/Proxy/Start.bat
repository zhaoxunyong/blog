@echo off
"C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe" -s < D:\Developer\Proxy\MyScript.txt
reg import D:\Developer\Proxy\EnableProxy.reg
