#!/bin/bash

./ping_check.sh  |& tee -a  ping_full_`date '+%Y%m%d%H%M%S'`.log