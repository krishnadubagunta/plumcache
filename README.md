# PlumCache

A high-performance, plugin-managed in-memory key-value store with a trie-based architecture.

PlumCache is designed as a flexible, extensible in-memory data store that leverages a trie (prefix tree) data structure for efficient key operations. The system features a plugin architecture that allows for dynamic extension of functionality through modular components.

## Architecture Overview

PlumCache is built around several core components:

- **Core Engine**: The main trie-based storage engine that handles data operations
- **Plugin System**: Extensible architecture for adding custom functionality
- **Command Processing**: Unified command interface with parsing and validation
- **Handler Layer**: Request/response handling with plugin integration
- **Orchestrator**: Coordinates between components and manages plugin lifecycle

## Key Features

- **Trie-Based Storage**: Efficient prefix-based key operations with O(m) complexity where m is the key length, enabling fast lookups, insertions, and prefix queries
- **Plugin Architecture**: Dynamic loading and management of plugins to extend database functionality without core modifications
- **In-Memory Performance**: Optimized for speed with all data kept in memory
- **Namespaced Keys**: Support for hierarchical data organization using `:` as a separator
- **Command Tokenization**: Robust parsing system for command processing
- **Modular Design**: Clean separation of concerns for maintainability
- **Simple Text Protocol**: Easy-to-use text-based communication protocol

## Module Structure

### Core Components
- `plum`: Main storage engine implementing the trie data structure
- `orchestration`: Plugin lifecycle management and component coordination

### Utilities
- `commands`: Command definitions and validation logic
- `tokenize`: Command parsing and tokenization utilities

### Interface Layer
- `handlers`: Request processing and response generation

## Building

To build the project, you need to have Zig installed. Then, run the following command:

```bash
zig build
```

This will create an executable at `zig-out/bin/plum`.

## Running

You can run the server in two ways:

1. Using the `run` step from the build script:
   ```bash
   zig build run
   ```

2. Running the executable directly:
   ```bash
   ./zig-out/bin/plum
   ```

The server will start and listen on `127.0.0.1:7379` (default port).

## Usage Examples

### 1. Start the PlumCache Server

Build and run the server binary (default port: `7379`):

```bash
zig build run
```

The server will listen on `127.0.0.1:7379`.

### 2. Connect with Netcat

You can interact with PlumCache directly using `netcat`:

```bash
nc 127.0.0.1 7379
```

Once connected, you can issue commands line by line:

```text
PING
+PONG

SET user:1001:name Alice
+OK

GET user:1001:name
$5
Alice

SET session:token abc123
+OK

GET session:token
$6
abc123
```

### 3. Using Plugins (Example: TTL)

If the TTL plugin is registered, you can set keys with expiration:

```text
SET cache:item1 value EX 5
+OK

GET cache:item1
$5
value

# after 5 seconds
GET cache:item1
$-1
```

### 4. Prefix / Trie Features

PlumCache's trie-based storage allows efficient prefix operations. Example command (if supported by installed plugin):

```text
KEYS user:*
*1
user:1001:name
```

### 5. Exit

Simply close the netcat session with `Ctrl+D` or `Ctrl+C`.

## Commands

| Command | Description | Example |
| --- | --- | --- |
| `PING` | Checks if the server is running. | `echo "PING" \| nc 127.0.0.1 7379` |
| `SET <key> <value>` | Stores a key-value pair. | `echo "SET mykey myvalue" \| nc 127.0.0.1 7379` |
| `GET <key>` | Retrieves the value for a key. | `echo "GET mykey" \| nc 127.0.0.1 7379` |
| `SET <namespace>:<key> <value>` | Stores a key-value pair in a namespace. | `echo "SET users:1001:name Alice" \| nc 127.0.0.1 7379` |
| `GET <namespace>:<key>` | Retrieves the value for a key in a namespace. | `echo "GET users:1001:name" \| nc 127.0.0.1 7379` |
| `DELETE <key>` | **Not implemented.** | N/A |

## Configuration

PlumCache can be configured using a TOML file. By default, it looks for a `default_config.toml` file in the current directory. You can also specify a different configuration file by setting the `CONFIG_FILE_PATH` environment variable.

The configuration file can be used to set the `port`, `delimiter`, and `plugins`.

**Note:** The configuration system is currently under development and not fully implemented.

## Plugin System

PlumCache has a plugin system that is managed by an Orchestrator. The Orchestrator is responsible for loading, initializing, and registering plugins. The plugin system is designed to allow for extending the functionality of PlumCache with features like different eviction policies and command queues.

Plugins can extend PlumCache functionality by implementing the plugin interface. The orchestrator manages plugin lifecycle, dependency resolution, and ensures proper integration with the core engine.

**Note:** The plugin system is currently under development and not fully implemented.

## Testing

To run the tests, use the `test` step from the build script:

```bash
zig build test
```

## Documentation

To generate the documentation, use the `docs` step from the build script:

```bash
zig build docs
```

The documentation will be generated in the `zig-out/docs` directory.

## Development Status

This is an active development project focused on creating a production-ready in-memory database with plugin capabilities. Current development priorities include plugin API stabilization, performance optimization, and comprehensive testing coverage.

## Future Work

- Implementation of a secondary store for less frequently accessed data
- Implementation of the `DELETE` command
- Complete the plugin system
- Complete the configuration system
- Plugin API stabilization
- Performance optimization
- Comprehensive testing coverage
