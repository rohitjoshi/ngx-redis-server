# ngx-redis-server

ngx-redis-server allows to build a TCP/TLS server supporting REDIS protocol. 
In the server.lua, it has example of implementing `AUTH`, `PING`, `GET`, `SET`, `HGET`, `HMGET` etc.

## Dependencies:
Use luarocks to install lua-resp e.g. `luarocks install lua-resp`. Make sure it is installed using  OpenResty/Mithril `Luajit` as it may not compile default lua.
NOTE: I had manually copied under `openresty/luajit/lib/lua/5.1` for this test

## TODO:
1. Enable support for TLS similar to HTTPs used for your server
2. In the `AUTH` command implementation, implement support to verify user using `user_name` and `password` from database/config or `access_token` using OAuth Token intropsection
3. Implement business logic for each of the RESP commands
4. Enable DD/NR based stats
5. Set the connection readtime out based on your need


## Performance:

/Users/rjoshi/projects/ngx-redis-server〉redis-benchmark -h 127.0.0.1 -p 4343 -n 1000000 -c 20  -t set,get -P 100

### Summary:
#### SET:

```
Summary:
  throughput summary: 526870.38 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        3.419     0.592     4.143     7.631     8.375    17.695
```

#### GET:

```
Summary:
  throughput summary: 548546.38 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        3.281     0.104     3.263     5.935     6.407     6.583
```
### Details:

```
====== SET ======
  1000000 requests completed in 1.90 seconds
  20 parallel clients
  3 bytes payload
  keep alive: 1
  multi-thread: no

Latency by percentile distribution:
0.000% <= 0.599 milliseconds (cumulative count 100)
50.000% <= 4.143 milliseconds (cumulative count 500600)
75.000% <= 4.503 milliseconds (cumulative count 750900)
87.500% <= 6.271 milliseconds (cumulative count 875100)
93.750% <= 7.439 milliseconds (cumulative count 937700)
96.875% <= 7.895 milliseconds (cumulative count 968800)
98.438% <= 8.239 milliseconds (cumulative count 984600)
99.219% <= 8.447 milliseconds (cumulative count 992500)
99.609% <= 10.135 milliseconds (cumulative count 996100)
99.805% <= 11.559 milliseconds (cumulative count 998100)
99.902% <= 13.919 milliseconds (cumulative count 999100)
99.951% <= 15.511 milliseconds (cumulative count 999600)
99.976% <= 16.207 milliseconds (cumulative count 999800)
99.988% <= 16.671 milliseconds (cumulative count 999900)
99.994% <= 17.695 milliseconds (cumulative count 1000000)
100.000% <= 17.695 milliseconds (cumulative count 1000000)

Cumulative distribution of latencies:
0.000% <= 0.103 milliseconds (cumulative count 0)
0.010% <= 0.607 milliseconds (cumulative count 100)
11.680% <= 1.207 milliseconds (cumulative count 116800)
30.640% <= 1.303 milliseconds (cumulative count 306400)
33.380% <= 1.407 milliseconds (cumulative count 333800)
35.020% <= 1.503 milliseconds (cumulative count 350200)
36.180% <= 1.607 milliseconds (cumulative count 361800)
37.240% <= 1.703 milliseconds (cumulative count 372400)
37.950% <= 1.807 milliseconds (cumulative count 379500)
38.570% <= 1.903 milliseconds (cumulative count 385700)
39.490% <= 2.007 milliseconds (cumulative count 394900)
40.750% <= 2.103 milliseconds (cumulative count 407500)
49.700% <= 3.103 milliseconds (cumulative count 497000)
49.950% <= 4.103 milliseconds (cumulative count 499500)
81.540% <= 5.103 milliseconds (cumulative count 815400)
86.510% <= 6.103 milliseconds (cumulative count 865100)
91.950% <= 7.103 milliseconds (cumulative count 919500)
98.000% <= 8.103 milliseconds (cumulative count 980000)
99.550% <= 9.103 milliseconds (cumulative count 995500)
99.600% <= 10.103 milliseconds (cumulative count 996000)
99.740% <= 11.103 milliseconds (cumulative count 997400)
99.840% <= 12.103 milliseconds (cumulative count 998400)
99.880% <= 13.103 milliseconds (cumulative count 998800)
99.910% <= 14.103 milliseconds (cumulative count 999100)
99.940% <= 15.103 milliseconds (cumulative count 999400)
99.970% <= 16.103 milliseconds (cumulative count 999700)
99.990% <= 17.103 milliseconds (cumulative count 999900)
100.000% <= 18.111 milliseconds (cumulative count 1000000)

Summary:
  throughput summary: 526870.38 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        3.419     0.592     4.143     7.631     8.375    17.695
```
```
====== GET ======
  1000000 requests completed in 1.82 seconds
  20 parallel clients
  3 bytes payload
  keep alive: 1
  multi-thread: no

Latency by percentile distribution:
0.000% <= 0.111 milliseconds (cumulative count 100)
50.000% <= 3.263 milliseconds (cumulative count 520900)
75.000% <= 3.743 milliseconds (cumulative count 750000)
87.500% <= 4.695 milliseconds (cumulative count 875100)
93.750% <= 5.807 milliseconds (cumulative count 937500)
96.875% <= 6.095 milliseconds (cumulative count 969400)
98.438% <= 6.311 milliseconds (cumulative count 984500)
99.219% <= 6.431 milliseconds (cumulative count 992300)
99.609% <= 6.495 milliseconds (cumulative count 996600)
99.805% <= 6.535 milliseconds (cumulative count 998300)
99.902% <= 6.559 milliseconds (cumulative count 999300)
99.951% <= 6.567 milliseconds (cumulative count 999600)
99.976% <= 6.575 milliseconds (cumulative count 999800)
99.988% <= 6.583 milliseconds (cumulative count 1000000)
100.000% <= 6.583 milliseconds (cumulative count 1000000)

Cumulative distribution of latencies:
0.000% <= 0.103 milliseconds (cumulative count 0)
0.020% <= 0.207 milliseconds (cumulative count 200)
0.030% <= 0.607 milliseconds (cumulative count 300)
0.040% <= 0.703 milliseconds (cumulative count 400)
0.050% <= 0.903 milliseconds (cumulative count 500)
0.060% <= 1.007 milliseconds (cumulative count 600)
0.070% <= 1.207 milliseconds (cumulative count 700)
0.080% <= 1.303 milliseconds (cumulative count 800)
0.090% <= 1.503 milliseconds (cumulative count 900)
0.100% <= 1.607 milliseconds (cumulative count 1000)
0.160% <= 1.807 milliseconds (cumulative count 1600)
0.180% <= 1.903 milliseconds (cumulative count 1800)
2.500% <= 2.007 milliseconds (cumulative count 25000)
19.270% <= 2.103 milliseconds (cumulative count 192700)
38.420% <= 3.103 milliseconds (cumulative count 384200)
83.340% <= 4.103 milliseconds (cumulative count 833400)
89.590% <= 5.103 milliseconds (cumulative count 895900)
97.060% <= 6.103 milliseconds (cumulative count 970600)
100.000% <= 7.103 milliseconds (cumulative count 1000000)

Summary:
  throughput summary: 548546.38 requests per second
  latency summary (msec):
          avg       min       p50       p95       p99       max
        3.281     0.104     3.263     5.935     6.407     6.583
```