A build.zig package for libftdi

Upstream source is at: https://www.intra2net.com/en/developer/libftdi/index.php
But since they only offer `git://` or `.tar.bz2`, both of which zig's package
manager does not support, we point to Debian's Salsa server (GitLab):
https://salsa.debian.org/aurel32/libftdi1

# Dependencies

- libudev

## Debian/Ubuntu

```bash
sudo apt update && \
    sudo apt install libudev-dev
```
