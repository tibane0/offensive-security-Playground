# Makefile - Basic Version

# Compiler to use
CC = gcc

# Compiler flags
# -Wall: Enables all common warnings
# -g: Includes debugging information
CFLAGS = -Wall -g

# Libraries to link (for socket, network functions, and pthreads)
# -lrt: Real-time extensions (sometimes needed for older systems, but often implicitly linked now)
# -lpthread: For pthread functions
LDLIBS = -lrt -lpthread 

# Name of the executable
TARGET = server

# Default target: builds the program
all: $(TARGET)

$(TARGET): main.c
	$(CC) $(CFLAGS) $< -o $@ $(LDLIBS)

# Clean target: removes compiled files
clean:
	rm -f $(TARGET) *.o

.PHONY: all clean