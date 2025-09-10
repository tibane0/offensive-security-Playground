# infosec-lab

[View The Overview of the Project](https://tibane0.github.io/posts/infosec-lab/)



### [Custom file server](./file-server/)

## SETUP
Networks
1. External (Internet)
2. DMZ
3. Internal (Uses AD)


## DMZ
Has 2 Servers
- server 1
    - **IP:** DMZ - 172.16.1.10/24 | EXT -  192.168.2.80/24 | INT - 
    - **Services:** Vuln Binaries, web application, mail, vuln services (vulhub)

- server 2
    - **IP:** DMZ - 172.16.1.20/24 | EXT - 192.168.2.90/24 | INT - 
    - **Services:** Vulnarable machine from vulnhub

### Server 1

This document describes the services running on the DMZ server in our offensive security lab environment. The DMZ (Demilitarized Zone) acts as our first line of exposure, hosting intentionally vulnerable services for security testing and training purposes.

Services Configuration
### Website
Website that describes what the lab is about.

### CTF-style Vulnerable Binaries (via socat)
Purpose: Practice binary exploitation and reverse engineering

Implementation: 
A bash [script](../scripts/pwn.sh) is used to select random binary and and binary info is shown in `/challengs/` web page socat listener for the vulnerable ctf binary 

```bash
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

### Server 2 




## Internal Active Directory

AD has 4 Users 




