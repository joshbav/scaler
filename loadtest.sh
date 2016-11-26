#!/bin/bash

echo $1

for i in `seq 1 10000`; 
do 
   curl -LkS $1 
done 
