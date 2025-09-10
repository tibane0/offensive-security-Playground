This document describes the services running on the DMZ server in our offensive security lab environment. The DMZ (Demilitarized Zone) acts as our first line of exposure, hosting intentionally vulnerable services for security testing and training purposes.

Services Configuration
### Website
Website that describes what the lab is about.

### CTF-style Vulnerable Binaries (via socat)
Purpose: Practice binary exploitation and reverse engineering

Implementation: 
A bash [script](../scripts/pwn.sh) is used to select random binary and and binary info is shown in `/challengs/` web page socat listener for the vulnerable ctf binary 

```bash
# Example socat listener for a vulnerable service
socat TCP-LISTEN:4444,reuseaddr,fork EXEC:./vulnerable_binary,stderr
```

PORTS
- Web page - 8000
- Vulnerable binaries - (9000 - 9999)

Management:
- binaries stored in /opt/pwn/ctfs
- setup script in /opt/pwn/setup

Download binaries from old ctfs from this [archive](https://github.com/sajjadium/ctf-archives/) 

and you can use this [script](../scripts/filter_repo.sh) to download only pwnable challenges

### VulHub Containers
Purpose: Host known vulnerable applications for training

Implementation:
A bash [script](../scripts/vulhub_setup.sh) selects random services and downloads docker image.

[Vulhub](https://github.com/vulhub/vulhub/)

```bash
docker-compose -f /opt/vulnhub/[vulnerable_app]/docker-compose.yml up -d
```

### DNS Server
Purpose: DNS security testing and protocol analysis

Features:

Basic DNS resolution

Some intentionally vulnerable records

### SMTP Server
Purpose: Email protocol security testing
