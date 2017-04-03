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

db.traffic_single_index.find({"to":"google.com", "timestamp": {$gte: 1257375600, $lt: 1258239600}}).sort({"count": -1}).explain("executionStats")
db.traffic_esr.createIndex({"to": 1, "count": 1, "timestamp": 1})
db.traffic_esr.find({"to":"google.com", "timestamp": {$gte: 1257375600, $lt: 1258239600}}).sort({"count": -1}).explain("executionStats")

quit()

time mongoimport -d demo -c traffic_no_indexes insert-as-last.json
time mongoimport -d demo -c traffic_esr insert-as-last.json

//sharding
mkdir "C:/mongo-s0-data/log/"
mkdir "C:/mongo-cfg-data/log/"

mongod --configsvr --port 27100 --replSet szard --dbpath "C:/mongo-shard/cfg"
mongo --port 27100
rs.initiate(
  {
    _id: "szard",
    configsvr: true,
    members: [
      { _id : 0, host : "localhost:27100" }
    ]
  }
)
mongod --shardsvr --port 27020 --dbpath="C:/mongo-shard/s0"
mongod --shardsvr --port 27021 --dbpath="C:/mongo-shard/s1"
mongod --shardsvr --port 27022 --dbpath="C:/mongo-shard/s2"

mongos --configdb szard/localhost:27100 --port 27101

mongo --port 27101
sh.addShard("localhost:27020")
sh.addShard("localhost:27021")
sh.addShard("localhost:27022")

sh.enableSharding("demo")
use demo
db.traffic_esr.createIndex({"count": 1, "_id": 1})
sh.shardCollection("demo.traffic_esr", {"count": 1, "_id": 1})
