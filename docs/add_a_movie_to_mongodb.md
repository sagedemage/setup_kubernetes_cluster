# Add a movie to MongoDB

## Via Mongo Express

1. Create a database called "imdb"

2. Create a collection called "movies"

3. Add document of a movie in the movies collection
```
{
      "_id": ObjectId(),
      "name": "Ghost in the Shell",
    	"year": "1995",
    	"rating": "7.9",
    	"director": "Mamoru Oshii",
    	"writers": ["Shirow MasamuneKazunori", "Kazunori Itô"]
}
```

## Via mongosh

Gain access to the mongodb shell
```
kubectl exec -it mongodb-deployment-6d9d7c68f6-58clf -- mongosh --username <your_username> --password <your_password>
```

Switch to the imdb database
```
use imdb
```

Add a document of the movie in the movies collection
```
db.movies.insertOne(
  {
    "name": "Ghost in the Shell",
    "year": "1995",
    "rating": "7.9",
    "director": "Mamoru Oshii",
    "writers": ["Shirow MasamuneKazunori", "Kazunori Itô"]
  }
)
```