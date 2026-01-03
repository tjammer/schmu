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

Test random
  $ schmu --no-std random.smu -o test_random
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./test_random
  round 1
   32 bit: 0xa15c02b7 0x7b47f409 0xba1d3330 0x83d2f293 0xbfa4784b 0xcbed606e
   coins:  HHTTTHTHHHTHTTTHHHHHTTTHHHTHTHTHTTHTTTHHHHHHTTTTHHTTTTTHTTTTTTTHT
  
  round 2
   32 bit: 0x9adf408c 0xa25544cf 0xefc6a738 0x1aa23a54 0xc5a13ebb 0xf739edc9
   coins:  THHTHHTTTHTTTTTTHTTHHHHHHTTHTHHTHHTTTTHHTHTHHHTHTTHTHTHTTTHTTHHTT
  
  round 3
   32 bit: 0x22d1fbe3 0xff8ad93c 0x1e62feaa 0x3851f4d9 0x76128cff 0x9ade0582
   coins:  HTHTTHHHTTHHHHHHHHHHHHHTHHHTHTHTHTHTTTTHHTTTHHTHHTHTTHHTTTHHHHHHT
  
  round 4
   32 bit: 0x56c1a259 0xc73d9b08 0x44d7d616 0x23f96ed3 0x27451078 0xf599179b
   coins:  TTTTTTTTTTTTHHTTHHHHTHHHHTHTHTHTHHHTTTHHHHHTHTTHHTTHTTHHHTTTHTTHH
  
  round 5
   32 bit: 0x62bf7230 0x29b4fec0 0xf812bdd6 0x3f5aa49c 0xb96c3636 0x55daaba9
   coins:  THHHHHTTHHTHHTHHTHHTHTTTHTHTTHHTTTTTHTTHHHTHTTHHTTHTHHTHTHTTTTHHT
  
  done
