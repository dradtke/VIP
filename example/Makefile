# This is a basic Makefile that compiles src/main.c into an executable
# named 'hello'
TARGET := hello
SOURCES := src/main.c
OBJECTS := $(SOURCES:.c=.o)

CC = gcc
CFLAGS = -Wall
LDFLAGS =

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $(LDFLAGS) $^ -o $@

%.o: %.c
	$(CC) $(CFLAGS) $< -c -o $@

clean:
	rm -rf $(OBJECTS) $(TARGET)

.PHONY: all $(TARGET) clean
