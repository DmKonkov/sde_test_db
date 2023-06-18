#!/bin/bash

docker run --name possql -d -p 5432:5432 -v ~/sde/sde_test_db/sql/init_db:/var/backups -e POSTGRES_PASSWORD=@sde_password012 -e POSTGRES_USER=test_sde -e POSTGRES_DB=demo postgres
echo "possql started! Wait ..."
sleep 5 
docker exec -it possql psql -U test_sde -d demo -f /var/backups/demo.sql
echo "DB load Finish!"
