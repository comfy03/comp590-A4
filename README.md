# comp590-A4

# Chain Servers in Erlang
# Team Member: Comfort Donkor
## Overview

This Erlang program demonstrates a chain of three servers that pass messages to each other. Each server handles specific types of messages, and unhandled messages are forwarded to the next server in the chain.

- **`serv1`**: Handles arithmetic operations.
- **`serv2`**: Handles lists of numbers.
- **`serv3`**: Handles error messages and keeps track of unhandled messages.

## Functions

- **`start/0`**: Starts the server chain.
- **`serv1/1`**: Processes arithmetic operations or forwards unhandled messages to `serv2`.
- **`serv2/1`**: Processes lists or forwards unhandled messages to `serv3`.
- **`serv3/1`**: Processes error messages and counts unhandled messages.

## Usage

1. **Start the server chain**:
   ```erlang
   c(chain_servers).
   chain_servers:start().
