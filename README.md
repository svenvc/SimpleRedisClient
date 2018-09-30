# SimpleRedisClient
A minimal Redis client for Pharo

[![Build Status](https://travis-ci.org/svenvc/SimpleRedisClient.svg?branch=master)](https://travis-ci.org/svenvc/SimpleRedisClient)

Redis is a networked, in-memory key-value store with optional durability, supporting different kinds of abstract data structures. Redis can be used to implement various server side architectural patterns.

- https://redis.io
- https://en.wikipedia.org/wiki/Redis
- https://redis.io/topics/protocol

The following Medium article in the Concerning Pharo publication explains SimpleRedisClient and its unit tests in detail:

- TITLE Quick write me a Redis client
- SUBTITLE A beautiful protocol makes implementation easy
- URL https://medium.com/concerning-pharo/quick-write-me-a-redis-client-5fbe4ddfb13d

To load the code in Pharo 6.1 or later, open World > Tools > Iceberg, click + to add a repository, select the option Clone From github.com and enter svenvc as owner name and SimpleRedisClient as project name. With the new repository selected, select Metacello > Install baseline of SimpleRedisClient.
