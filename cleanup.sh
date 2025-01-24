#!/bin/sh
find queue/ -type f -mtime +7 | xargs --no-run-if-empty rm
rmdir queue/* 2>/dev/null
true
