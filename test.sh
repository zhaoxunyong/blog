#!/bin/bash

for f in `ls source/_posts/*.md`
do 
    if [[ -f "$f" ]]; then
        folder=`echo $f | awk  -F '/' '{print $3}' | sed 's/\.md//g' | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}-//g'`
        if [[ "$folder" != "" ]]; then
            mkdir -p "source/images/$folder"
            # ![jenkins-config1](/images/jenkins-config1.png)
            for img in `grep "](/images/" "$f" | sed 's;.*](;;g' | sed 's;);;g' | sed 's;^/;;g'`
            do
                destFile=`echo "$img" | sed "s;images/;images/$folder/;g"`
                mv "source/$img" "source/$destFile"
            done
            sed -i "s;/images/;/images/$folder/;g" $f
        fi
    fi
done


for f in `ls source/_posts/*.md`
do 
    if [[ -f "$f" ]]; then
        folder=`echo $f | awk  -F '/' '{print $3}' | sed 's/\.md//g' | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}-//g'`
        if [[ "$folder" != "" ]]; then
            mkdir -p "source/files/$folder"
            # ![jenkins-config1](/images/jenkins-config1.png)
            for img in `grep "](/files/" "$f" | sed 's;.*](;;g' | sed 's;).*;;g' | sed 's;^/;;g'`
            do
                destFile=`echo "$img" | sed "s;files/;files/$folder/;g"`
                mv "source/$img" "source/$destFile"
            done
            sed -i "s;/files/;/files/$folder/;g" $f
        fi
    fi
done