#include <cstdio>
#include <cstdlib>
#include <fcntl.h>         
#include <unistd.h>        
#include <sys/stat.h> 
#include <cstring>
#include <string>
#include <unistd.h>         
#include <arpa/inet.h>      
#include <sys/socket.h>     
#include <netinet/in.h>
#include <signal.h>

#define BUFFER_SIZE 0x100
#define MAX_SIZE 0x1000 // maximum file size 

using namespace std;

int sock;

// interacte with server
class FileServer {
    private:

    public:
    int conn(const char *ip, int port) {
        struct sockaddr_in serv_addr;

        if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
            perror("Socket creation error");
            return -1;
        }

        serv_addr.sin_family = AF_INET;
        serv_addr.sin_port = htons(port);

        // Convert IPv4 addresses from text to binary
        if (inet_pton(AF_INET, ip, &serv_addr.sin_addr) <= 0) {
            perror("Invalid address / Address not supported");
            return -1;
        }

        // Connect to server
        if (connect(sock, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) {
            perror("Connection failed");
            return -1;
        }

        return 0;
    }

    int put(const char* path) {
        char *contents = (char*)malloc(MAX_SIZE);
        int file = open(path, O_RDONLY);
        if (file == -1) {
            stderr;
            printf("Failed to open file\n");
            return  -1;
        }

        size_t bytesRead;
        while ((bytesRead = read(file, contents, MAX_SIZE)) > 0) {
            send(sock, contents, bytesRead, 0);
        }
        free(contents);
        return 0;

    }

    int get(const char* path) {
        char *contents = (char*)malloc(MAX_SIZE);
        int fd = open(path,  O_WRONLY|O_CREAT|O_TRUNC, 0644);
        if (fd == -1) {
            stderr;
            return -1;
        }
        size_t bytesRead;
        while ((bytesRead = recv(sock, contents, MAX_SIZE, 0)) > 0) {
            write(fd, contents, bytesRead);
        }
    
        free(contents);
        return 0;
    }

    int recv_list() {
        int bytes_received;
        int total = 0;
        char buffer[BUFFER_SIZE];
    
        while ((bytes_received = recv(sock, buffer + total, 1, 0)) > 0) {
            if (buffer[total] == '\n') {
                buffer[total] = '\0';
    
                // ✅ Check for sentinel
                if (strcmp(buffer, "__END__") == 0) {
                    break;
                }
    
                printf("Received filename: %s\n", buffer);
                total = 0;
            } else {
                total++;
                if (total >= BUFFER_SIZE - 1) {
                    fprintf(stderr, "Filename too long!\n");
                    total = 0;
                }
            }
        }
    
        if (bytes_received == 0) {
            printf("Connection closed by sender.\n");
        } else if (bytes_received < 0) {
            perror("recv failed");
        }
    
        return 0;
    }
    

};

class Authenticate {
    private:
    char username[BUFFER_SIZE];
    char password[BUFFER_SIZE];

    public:
    void log_in() {

        printf("Username : ");
        fgets(username, BUFFER_SIZE, stdin);
        username[strcspn(username, "\n")] = 0;

        printf("Password : ");
        fgets(password, BUFFER_SIZE, stdin);
        password[strcspn(password, "\n")] = 0;

    }
    // authenticate against server
    int auth_server() {
        // credentials

        send(sock, username, strlen(username), 0);
        send(sock ,password, strlen(password), 0);

        // status = 0 logged in (correct creds)| = -1 incorrect creds
        char status[4];
        recv(sock, status, sizeof(status), 0);
        int st = atoi(status);
        if (st == -1) {
            printf("Incorrect Credentials Try Again\n");
            return -1;
        } else if (st == 0) {
            printf("Logged In\n");
            return 0;
        }
        return 0;
    }   
};

// help for commands
void help_cmd() {
    char usage[0x300];
    snprintf(usage, sizeof(usage), "\nUsage\nls - list files and directories\nsend <file path> - send a file to server\nrecv <file path> - recv a file from the server \n"); 
    printf("%s", usage);
}


void commands(FileServer server) {
    char cmd[BUFFER_SIZE];
    char filepath[BUFFER_SIZE];
    char buffer[BUFFER_SIZE];
    char feedback[BUFFER_SIZE];

    while (1) {
        memset(cmd, 0, sizeof(BUFFER_SIZE));
        memset(filepath, 0, sizeof(BUFFER_SIZE));
        printf("> ");
        fgets(cmd, sizeof(cmd), stdin);
        cmd[strcspn(cmd, "\n")] = 0;

        send(sock, cmd, sizeof(cmd), 0);
        
        int tokens = sscanf(cmd, "%s %s", buffer, filepath);

        if (tokens >= 1) {
            if (strncmp(buffer, "put", 3) == 0) {
                if (tokens == 2)
                    server.put(filepath);
                else
                    printf("Usage: put <filename>\n");
            } 
            else if (strncmp(buffer, "get", 3) == 0) {
                if (tokens == 2)
                    server.get(filepath);
                else
                    printf("Usage: get <filename>\n");
            } 
            else if (strncmp(buffer, "cd", 2) == 0) {
                send(sock, cmd, strlen(cmd), 0);
                recv(sock, feedback, sizeof(feedback), 0);
                printf("%s\n", feedback);
            } 
            else if (strncmp(buffer, "exit", 4) == 0) {
                send(sock, cmd, strlen(cmd), 0);
                printf("Exiting...\n");
                break;  // prefer break over exit(0) for cleanup
            } 
            else if (strncmp(buffer, "ls", 2) == 0) {
                send(sock, cmd, strlen(cmd), 0);
                server.recv_list();
            } 
            else {
                help_cmd();
            }
        } else {
            help_cmd();
        }



        // cont from here
        // cont from here
        // cont from here
 

  }   
}

int main(int argc, char **argv) {
    signal(SIGPIPE, SIG_IGN); // Ignore SIGPIPE
    if (argc != 3) {
        printf("Usage : %s <server ip> <port>", argv[0]);
        exit(0);
    }

    FileServer server;
    if (server.conn(argv[1], atoi(argv[2])) == -1) {
        perror("Network connection failed");
        exit(0);
    }

    Authenticate auth;
    auth.log_in();
    if (auth.auth_server() == -1) {
        goto CLEANUP;
    }
    commands(server);

    CLEANUP:
    close(sock);
    return 0;
}
