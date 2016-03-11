# Bash Portscan
A simple TCP port scan using Bash purely

### How it works?
The connection test is done using the `/dev/tcp` protocol. Just send a command to this path, with the IP address and the desired port. More info [here](http://www.tldp.org/LDP/abs/html/devref1.html).

#### Example
```
$ cat </dev/tcp/time.nist.gov/13
57458 16-03-11 22:48:12 53 0 0 211.8 UTC(NIST) *
```

### Limitations
* UDP connection
 * Not possible to get a return code when using the UDP protocol
 
### TODO
- [ ] Multiple IPs
- [ ] Quiet / verbose mode
