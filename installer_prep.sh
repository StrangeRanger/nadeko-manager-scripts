#!/bin/bash

curl -O "$_RAW_URL"/installer-prep
sudo chmod +x installer-prep && ./installer-prep
exit "$?"  # Uses the exit code passed by 'installer-prep'.