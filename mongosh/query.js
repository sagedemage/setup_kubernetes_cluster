rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo-sfs-0.mongo-sfs-service.development.svc.cluster.local:27017", priority: 2 },
    { _id: 1, host: "mongo-sfs-1.mongo-sfs-service.development.svc.cluster.local:27017", priority: 1 },
    { _id: 2, host: "mongo-sfs-2.mongo-sfs-service.development.svc.cluster.local:27017", priority: 1 }
  ]
})