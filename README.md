# Bash Portscan
A simple TCP port scan using Bash purely

### How it works?
The connection test is done using the `/dev/tcp` protocol. Just send a command to this path, with the IP address and the desired port. More info [here](http://www.tldp.org/LDP/abs/html/devref1.html).

#### Example
```
$ cat </dev/tcp/time.nist.gov/13
57458 16-03-11 22:48:12 53 0 0 211.8 UTC(NIST) *
```

### Usage
```
$ sh bash-portscan.sh 192.168.1.1 1-100
Bash TCP Port Scan v0.5
=======================

[+] Start scanning: 192.168.1.1 / 1-100
[+] 22 open (ssh)
[+] 80 open (http)
[+] Done.
```

#### Verbose mode

```
$ sh bash-portscan.sh -v 192.168.1.1 1-100
Bash TCP Port Scan v0.5
=======================

[+] Start scanning: 192.168.1.1 / 1-100
[-] 1 closed
[-] 2 closed
[-] 3 closed
[-] 4 closed
[-] 5 closed
...
[-] 21 closed
[+] 22 open (ssh)
[-] 23 closed
[-] 24 closed
...
[-] 51 closed
[-] 52 closed
[!] 53 filtered
[-] 54 closed
...
[-] 79 closed
[+] 80 open (http)
[-] 81 closed
...
[-] 97 closed
[-] 98 closed
[-] 99 closed
[-] 100 closed
[+] Done.
```

### Limitations
* UDP connection
   * Not possible to get a return code when using the UDP protocol
 
### TODO
- [ ] Multiple IPs
- [x] Quiet / verbose mode
