# Makefile for C++ Program

# Compiler for C++
CXX = g++

# Compiler flags
# -Wall: Enables all common warnings
# -g: Includes debugging information (for use with debuggers like GDB)
# -std=c++17: Compiles code using the C++17 standard (can change to c++11, c++14, c++20, etc.)
# -O2: Optimization level 2 (good balance of speed and compile time) - often used for release builds
CXXFLAGS = -Wall -g -std=c++17 -O2

# Libraries to link
# For basic networking functions (arpa/inet, sys/socket), often no explicit -l flag is needed
# as they are part of the standard C library or implicitly linked.
# Add -lpthread if you were using <pthread.h> (which is not in your list for C++ in this request)
LDLIBS = 

# Name of the executable
TARGET = file_client

# List all your C++ source files here (e.g., main.cpp, MyClass.cpp, network_utils.cpp)
SRCS = main.cpp \
       # If you have other .cpp files, list them like this:
       # my_utility_file.cpp \
       # networking_logic.cpp

# Automatically derive object files from source files
# main.cpp -> main.o
OBJS = $(SRCS:.cpp=.o)

# Default target: builds the program
all: $(TARGET)

# Rule to link the executable from object files
$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) $(OBJS) -o $@ $(LDLIBS)

# Generic rule to compile .cpp files into .o files
# This rule says: to make any file ending in .o (e.g., main.o),
# look for a file with the same base name ending in .cpp (e.g., main.cpp).
# $@: the target (e.g., main.o)
# $<: the first prerequisite (e.g., main.cpp)
%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Clean target: removes compiled files
clean:
	rm -f $(TARGET) $(OBJS)

.PHONY: all clean