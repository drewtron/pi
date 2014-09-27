sh.addShard("localhost:28000");
sh.addShard("localhost:28001");
sh.addShard("localhost:28002");
sh.addShard("localhost:28003");
sh.enableSharding("import");
sh.shardCollection("import.people", { "hashkey": "hashed" } );
