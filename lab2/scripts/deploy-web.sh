#!/usr/bin/env bash
set -euo pipefail

sudo dnf install -y httpd

echo "<h1>ACS730 — deployed by acs730 user</h1>" | sudo tee /var/www/html/index.html

sudo chown acs730:acs730 /var/www/html/index.html
