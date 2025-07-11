# mongosh commands

Show all the databases on the server
```
show dbs
```

Retrieve all of the collections in the currently selected database
```
show collections
```

Show a list of all the objects in the movies collection
```
db.movies.find()
```

Delete only one document that matches a condition
```
db.movies.deleteOne({_id: ObjectId('686dcf1831ecc5d86abaa8bb')})
```

Remove a collection called movies1
```
db.movies1.drop()
```

Remove the current database
```
db.dropDatabase()
```