---
name: lg_ssh_manager
description: Standardized best practices for establishing SSH connections to a Liquid Galaxy Master Node using Flutter.
---
# Liquid Galaxy SSH Rules
When generating SSH functionality, the agent MUST follow these rules:
1. Always use the `dartssh2` package.
2. Assume the target is a local VirtualBox Master Node. Wrap all SSH connection attempts in a `try-catch` block to gracefully handle `SocketException`.
3. Provide a UI configuration screen utilizing `shared_preferences` so the user can dynamically save and load the Rig IP, Username, and Password.