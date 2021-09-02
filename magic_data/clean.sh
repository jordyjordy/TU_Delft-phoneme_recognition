#!/bin/bash

#Backup the current data folder and delete it.

cp -r data/ data_backup_$(date +%d-%m-%y_%H-%M-%S)/
rm -rf data/