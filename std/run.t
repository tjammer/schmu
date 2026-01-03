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
   64 bit: 0x96b4392d687 0x96b4392d687 0x12d6870 0x7dee96b43eda74a 0x6ce38a7ac2db687b 0xc0096ff6a06f583d
  
  round 2
   64 bit: 0x995a4e0b0d4e37f2 0xf0cbfdbb48cd7c55 0xa1f65b6633acf156 0xeff8e921d6334063 0xcee74660fb7fe2fd 0xa78e44484de6b75f
  
  round 3
   64 bit: 0x31a2b75cb91aa82a 0x5fb0373adcf0a442 0x5342ed963d4d131f 0x9726c0c5f045f83c 0xd02086b07a0b3f8a 0xa645dc259791de81
  
  round 4
   64 bit: 0x2851d79e033a922 0x8c7f14b97c3184a0 0x732742649f1e9e75 0x2cf99ac499458777 0xa974c5cc448ae56a 0x7157c4d20fe78153
  
  round 5
   64 bit: 0x8dade782ae740719 0x172d3195149926ff 0xa8adbab2fd979895 0x94bf57c6cad822f 0x7bc2411518b8f5ba 0x9610fad0741de3e1
  
  splitmix64
  6457827717110365317
  3203168211198807973
  9817491932198370423
  4593380528125082431
  16408922859458223821
  done
