#!/bin/bash

# Check if can login to docker hub
if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PASSWORD" ]; then
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" "docker.io" --password-stdin
fi

# setup environment
. $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/env.sh

if [ $# -gt 0 ]
then
    # ignore the old basedir argument
    dir=$1
    if [ -d $dir ] && [ -f $dir/RELEASE.md ]
    then
        shift
    fi
fi

# Fetch previously released stacks
. $script_dir/prefetch.sh

# Allow multiple stacks to be selected
if [ $# -gt 0 ]
then
  export STACKS_LIST="$@"
  echo "STACKS_LIST=$STACKS_LIST"

  echo "Stacks listed on command line, overriding BUILD_ALL to be false"
  export BUILD_ALL=false

  for stack_name in $STACKS_LIST
  do
    if [ "${stack_name: -1}" == "/" ]
    then
      stack_name=${stack_name%?}
    fi
     
    stack_no_slash="$stack_no_slash $stack_name"
  done

  STACKS_LIST=$stack_no_slash
fi

if [ -z "$STACKS_LIST" ]
then
  . $script_dir/list.sh
fi

. $script_dir/package.sh
