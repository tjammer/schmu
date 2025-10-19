Test deque
  $ schmu --no-std deque.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./deque
