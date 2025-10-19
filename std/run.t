Test set
  $ schmu --no-std set.smu -o test_set
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./test_set
  0
  1
  2
  3
  
  0
  
  0
  1
  2
  
  1
  
  some 1
  none

Test deque
  $ schmu --no-std deque.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./deque
