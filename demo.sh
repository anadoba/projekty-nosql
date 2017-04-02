mkdir "C:/mongo-data"
mongod --dbpath="C:/mongo-data"

mkdir "C:/mongo-demo-dl"
cd "C:/mongo-demo-dl"

curl http://carl.cs.indiana.edu/data/websci2014/web-clicks-nov-2009.tgz -o web-traffic.tgz
tar -xvzf web-traffic.tgz
mv 2009-11-22.json insert-as-last.json

cat 2009-*.json | mongoimport --db demo --collection traffic_no_indexes
cat 2009-*.json | mongoimport --db demo --collection traffic_single_index
cat 2009-*.json | mongoimport --db demo --collection traffic_esr

mongo demo
//var exp = db.traffic.explain("executionStats")
db.traffic_no_indexes.find({"to":"google.com"}).explain("executionStats")
db.traffic_single_index.createIndex({"to": 1})
db.traffic_single_index.find({"to":"google.com"}).explain("executionStats")

db.traffic_single_index.find({"to":"google.com"}).explain("executionStats")
db.traffic_esr.createIndex({"to": 1, "count": 1, "timestamp": 1})
db.traffic_esr.find({"to":"google.com"}).sort({"count": -1}).explain("executionStats")

quit()

time mongoimport -d demo -c traffic_no_indexes insert-as-last.json
time mongoimport -d demo -c traffic_esr insert-as-last.json

// dodac sharding
// https://coderwall.com/p/bzz1ra/set-up-mongodb-shard-windows-local
