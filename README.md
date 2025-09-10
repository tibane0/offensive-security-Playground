# infosec-lab

### CTF-style Vulnerable Binaries (via socat)

Purpose: Practice binary exploitation and reverse engineering

Implementation: 
A bash [script](./pwn-lab/pwn.sh) is used to select random binary and and binary info is shown in `/challengs/` web page socat listener for the vulnerable ctf binary 

```bash
socat TCP-LISTEN:4444,reuseaddr,fork EXEC:./vulnerable_binary,stderr
```

PORTS
- Web page - 8000
- Vulnerable binaries - (9000 - 9999)

Download binaries from old ctfs from this [archive](https://github.com/sajjadium/ctf-archives/) 
