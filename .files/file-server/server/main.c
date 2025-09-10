#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <stdint.h>
#include <fcntl.h>
#include <dirent.h>
#include <pthread.h>
//#include <math.h>

#define PORT 9999
#define BUFFER_SIZE 0x100
#define MAX_SIZE 0x1000 // maximum file size 

//char banner[BUFFER_SIZE];
char log_buffer[BUFFER_SIZE];

void Log(char *info) {
    FILE *log = fopen("main.log", "a");
    fwrite(info, sizeof(char), (size_t)strlen(info), log);
    fclose(log);
}

int get(int sock, char* path) {
    char *contents = malloc(MAX_SIZE);
    int fd = open(path, O_RDONLY);
    if (fd == -1) {
        perror("Failed to open file");
        free(contents);
        return -1;
    }

    size_t bytesRead;
    while ((bytesRead = read(fd, contents, MAX_SIZE)) > 0) {
        send(sock, contents, bytesRead, 0);
    }
    free(contents);
    return 0;
}


int put(int sock, char *path) {
    char *contents = malloc(MAX_SIZE);
    int fd = open(path,  O_WRONLY|O_CREAT|O_TRUNC, 0644);
    if (fd == -1) {
        perror("Failed to open file");
        free(contents);
        return -1;
    }
    size_t bytesRead;
    while ((bytesRead = recv(sock, contents, MAX_SIZE, 0)) > 0) {
        write(fd, contents, bytesRead);
    }

    free(contents);
    return 0;
}
void list(int sock) {
    DIR *d;
    struct dirent *dir;
    d = opendir(".");
    int count = 0;
    char *filenames[BUFFER_SIZE];

    if (d) {
        while ((dir = readdir(d)) != NULL && count < BUFFER_SIZE) {
            filenames[count] = (char *)malloc(strlen(dir->d_name) + 1);
            if (filenames[count] == NULL) {
                perror("Failed to allocate memory for filename");
                for (int i = 0; i < count; i++) {
                    free(filenames[i]);
                }
                closedir(d);
                return;
            }

            strcpy(filenames[count], dir->d_name);
            count++;
        }

        closedir(d);

        for (int i = 0; i < count; i++) {
            send(sock, filenames[i], strlen(filenames[i]), 0);
            send(sock, "\n", 1, 0);
            free(filenames[i]);
        }

        // ✅ Add sentinel string to signal end of list
        send(sock, "__END__\n", strlen("__END__\n"), 0);

    } else {
        perror("Failed to open directory");
    }
}




// authentication 
int auth(int sock, char *USER, char* PASS) {
    char username[BUFFER_SIZE];
    char password[BUFFER_SIZE];
    char status[4];

    recv(sock, username, sizeof(username), 0);
    recv(sock, password, sizeof(password), 0);
    
    if (strcmp(username, USER) == 0 && strcmp(password, PASS) == 0) {
        strncpy(status, "0", 2);
        send(sock, status, strlen(status), 0);
        return 0;
    }
    strncpy(status, "-1", 3);
    send(sock, status, strlen(status), 0);
    return -1;
}


void *client_handler(void *sock1) {
    // get username and password from json file
    //FILE *conf = fopen("conf.json", "r");


    //close(conf);

    int sock = *(int*)sock1;
    free(sock1);

    if (auth(sock, "user", "pass") == -1) {
        return NULL;
    };
    char cmd[BUFFER_SIZE];
    char buffer[BUFFER_SIZE];
    char path[BUFFER_SIZE];
    
    while (1) {
        memset(cmd, 0, sizeof(cmd));
        memset(buffer, 0, sizeof(buffer));
        memset(path, 0, sizeof(path));

        recv(sock, buffer, sizeof(buffer), 0);
        
        memset(log_buffer, 0, sizeof(log_buffer));
        snprintf(log_buffer, strlen(buffer)+1, "Recieved %s ", buffer);
        Log(log_buffer);


        int tokens = sscanf(buffer, "%s %s", cmd, path) == 2; 


        if (tokens >= 1) {
            if (strcmp(cmd, "ls") == 0) {
                list(sock);
            } else if (strcmp(cmd, "get") == 0 && tokens == 2) {
                get(sock, path);
            } else if (strcmp(cmd, "put") == 0 && tokens == 2) {
                put(sock, path);
            } else if (strcmp(cmd, "cd") == 0 && tokens == 2) {
                if (chdir(path) != 0) {
                    strcpy(buffer, "Failed to change directory\n");
                } else {
                    strcpy(buffer, "Changed directory successfully\n");
                }
                send(sock, buffer, strlen(buffer), 0);
            } else if (strcmp(cmd, "exit") == 0) {
                close(sock);
                return NULL;
            } else {
                char err[] = "Unknown command\n";
                send(sock, err, strlen(err), 0);
            }
        }
        

    }
}


int main() {
    struct sockaddr_in clientAddr;
    socklen_t client_len = sizeof(clientAddr);
    int serverSock;

    serverSock = socket(AF_INET, SOCK_STREAM, 0);
    if (serverSock == -1) {
        perror("Socket creation failed");
        return -1;
    }

    struct sockaddr_in serverAddr;
    serverAddr.sin_addr.s_addr = INADDR_ANY;
    serverAddr.sin_port = htons(PORT);
    serverAddr.sin_family = AF_INET;

    if (bind(serverSock, (struct sockaddr*)&serverAddr, sizeof(serverAddr))) {
        perror("binding failed");
        close(serverSock);
        return -1;
    }

    if (listen(serverSock, SOMAXCONN) == -1) {
        perror("Listen Failed");
        close(serverSock);
        return -1;
    }
    
    while (1) {
        int sock;
        if ((sock = accept(serverSock, (struct sockaddr*)&clientAddr, (socklen_t*)&client_len)) < 0) {
            perror("Accept failed");
            continue;
        }
        
        // port = ntohs(clientAddr.sin_port) 
        // ip = inet_ntoa(client_addr.sin_addr)
        memset(log_buffer, 0, sizeof(log_buffer));
        snprintf(log_buffer, sizeof(log_buffer), "Connection from %s : %d \n", inet_ntoa(clientAddr.sin_addr), ntohs(clientAddr.sin_port));
        Log(log_buffer);
        //

        pthread_t thread;
        int *new_sock = malloc(sizeof(int));
        *new_sock = sock;
        if (pthread_create(&thread, NULL, client_handler, (void*)new_sock) < 0) {
            perror("could not create thread");
            free(new_sock);
            continue;6
        }
        // Detach thread so resources are automatically freed on exit
        pthread_detach(thread);
    }

    close(serverSock);

    return 0;
}
