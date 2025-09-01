#!/bin/bash

# Simple script to replace Zig docs with PlumCache template

# Copy template and fix permissions
sudo cp docs/templates/index.html zig-out/docs/index.html
sudo chown $(whoami):staff zig-out/docs/index.html
chmod 644 zig-out/docs/index.html

echo "✅ PlumCache template applied to zig-out/docs/index.html"
