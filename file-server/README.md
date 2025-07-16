# Custom file server for home lab

might have intentional security bugs



# coding tasks

## Server
- Init Setup 
    - get credentials
    - server port
- Authentication
- Use multithreading to support multiple clients at once
- Commands
    - ls : list files and sub dirs
        - function to get all files and send over socket
    - cd : change dir
        - chdir(char *path);
    - put : recv file from client (GET from server perspective)
        - create function
    - get : send file to client (PUT from server perspective)
        - create function


## Client
- Authentication
- commands
    - ls : list files and sub dirs (in server) | just send "ls"
    - cd : change dir | just send cd <dir_path>
    - put : send a file to server
        - create function to open file and send via sockets
    - get : retrieve a file from the server
        - create function to recv contents and open file for writing locally.
