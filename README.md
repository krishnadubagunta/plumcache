# Plumcache

A simple, in-memory key-value store server written in Zig.

Plumcache uses a Trie data structure to store namespaced keys, allowing for efficient storage and retrieval of hierarchical data.

## Features

- In-memory storage
- Support for namespaces using `:` as a separator.
- Simple text-based protocol.
- Pluggable architecture (in development).

## Configuration

Plumcache can be configured using a TOML file. By default, it looks for a `default_config.toml` file in the current directory.

You can also specify a different configuration file by setting the `CONFIG_FILE_PATH` environment variable.

The configuration file can be used to set the `port`, `delimiter`, and `plugins`.

**Note:** The configuration system is currently under development and not fully implemented.

## Plugin System

Plumcache has a plugin system that is managed by an Orchestrator. The Orchestrator is responsible for loading, initializing, and registering plugins.

The plugin system is designed to allow for extending the functionality of Plumcache with features like different eviction policies and command queues.

**Note:** The plugin system is currently under development and not fully implemented.

## Building

To build the project, you need to have Zig installed. Then, run the following command:

```sh
zig build
```

This will create an executable at `zig-out/bin/plum`.

## Running

You can run the server in two ways:

1.  Using the `run` step from the build script:

    ```sh
    zig build run
    ```

2.  Running the executable directly:

    ```sh
    ./zig-out/bin/plum
    ```

The server will start and listen on `127.0.0.1:8080`.

## Testing

To run the tests, use the `test` step from the build script:

```sh
zig build test
```

## Documentation

To generate the documentation, use the `docs` step from the build script:

```sh
zig build docs
```

The documentation will be generated in the `zig-out/docs` directory.

## Commands

You can interact with the server using a tool like `netcat`.

| Command | Description | Example |
| --- | --- | --- |
| `PING` | Checks if the server is running. | `echo "PING" \| nc 127.0.0.1 8080` |
| `SET <key> <value>` | Stores a key-value pair. | `echo "SET mykey myvalue" \| nc 127.0.0.1 8080` |
| `GET <key>` | Retrieves the value for a key. | `echo "GET mykey" \| nc 127.0.0.1 8080` |
| `SET <namespace>:<key> <value>` | Stores a key-value pair in a namespace. | `echo "SET users:1 name Alice" \| nc 127.0.0.1 8080` |
| `GET <namespace>:<key>` | Retrieves the value for a key in a namespace. | `echo "GET users:1" \| nc 127.0.0.1 8080` |
| `DELETE <key>` | **Not implemented.** | N/A |

## Future Work

- Implementation of a secondary store for less frequently accessed data.
- Implementation of the `DELETE` command.
- Complete the plugin system.
- Complete the configuration system.