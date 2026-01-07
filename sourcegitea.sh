#!/bin/sh
export GITEA_ACCESS_TOKEN=$(cat ~/.gitea_token)
PATH=~/.local/bin:$PATH
date=$(date -Iseconds -d "1 day ago")
obsbugzilla_source.py --scm=git --platform=gitea --gitea-url=https://src.suse.de/ fetch --since="${date}" --filter 'b[ns]c#|boo#|jsc#' --raw |
 RABBITTEST=1 perl ./sourcerabbit.pl

