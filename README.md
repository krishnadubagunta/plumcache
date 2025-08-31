# Plum

A simple, in-memory key-value store server written in Zig.

## Building

To build the project, you need to have Zig installed. Then, run the following command:

```sh
zig build
```

This will create an executable at `zig-out/bin/plum`.

## Running

To start the server, run the following command:

```sh
./zig-out/bin/plum
```

The server will start and listen on `127.0.0.1:8080`.

## Usage

You can interact with the server using a tool like `netcat`.

### PING

To check if the server is running, you can use the `PING` command.

```sh
echo "PING" | nc 127.0.0.1 8080
```

The server will respond with `PONG`.

### SET

To store a key-value pair, you can use the `SET` command.

```sh
echo "SET mykey myvalue" | nc 127.0.0.1 8080
```

The server will respond with `OK`.

### GET

To retrieve a value for a key, you can use the `GET` command.

```sh
echo "GET mykey" | nc 127.0.0.1 8080
```

The server will respond with the value, for example `myvalue`.
If the key is not found, the server will respond with `NOT_FOUND`.
