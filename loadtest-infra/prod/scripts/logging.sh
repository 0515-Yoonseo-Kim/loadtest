#!/bin/bash

nohup /home/ec2-user/app/scripts/docker-log-basic.sh > /home/ec2-user/app/logs/docker-stats.log 2>&1 &
