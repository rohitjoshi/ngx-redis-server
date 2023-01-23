# ngx-redis-server

ngx-redis-server allows to build a TCP/TLS server supporting REDIS protocol. 
In the server.lua, it has example of implementing `AUTH`, `PING`, `GET`, `SET`, `HGET`, `HMGET` etc.

TODO:
1. Enable support for TLS similar to HTTPs used for your server
2. In the `AUTH` command implementation, implement support to verify user using `user_name` and `password` from database/config or `client_id` and `secret` using OAuth Token intropsection
3. Implement business logic for each of the RESP commands
4. Enable DD/NR based stats
5. Set the connection readtime out based on your need
