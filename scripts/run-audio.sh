#!/bin/bash

while true; do
  ps cax | grep 'speaker-test' > /dev/null
  if [ $? -ne 0 ]; then
    #echo "Process is not running.  Starting"
    (speaker-test -r 32000 -t pink -S 1 -l 0 >/dev/null 2>/dev/null) &
  fi

  sleep 1
done

exit