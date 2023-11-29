Test hashtbl
  $ schmu hashtbl_test.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./hashtbl_test
  # hashtbl
  ## string
  1.1
  none
  none

String module test
  $ schmu string.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./string
  hello, world, :)

In channel module test
  $ schmu in_channel.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./in_channel
  (match (in_channel/open "in_channel.smu")
    ((#som
  e ic)
  
  read 18 bytes
     (let ((ic& !ic)
  read 36 bytes
           (buf& (array/create 4096)))
  read 44 bytes
       (ignore (in_channel/readn &ic &buf 50))
  read 39 bytes
       (def str& !(string/of-array !buf))
  read 1836 bytes
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (ignore (in_channel/readn &ic &buf 6))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readrem &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (print (string/of-array !buf))
  
       (in_channel/close ic)))
    (#none ()))
  
  (match (in_channel/open "in_channel.smu")
    ((#some ic)
     (let ((ic& !ic))
       (print (in_channel/readall &ic))
       (in_channel/close ic)))
    (#none ()))
  
  (match (in_channel/open "in_channel.smu")
    ((#some ic)
     (let ((ic& !ic))
       (in_channel/lines &ic (fn (line) (print line)))
       (in_channel/close ic)))
    (#none ()))
  
  (match (in_channel/open "in_channel.smu")
    ((#some ic)
     (let ((ic& !ic)
           (buf& (array/create 4096)))
       (ignore (in_channel/readn &ic &buf 50))
       (def str& !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (ignore (in_channel/readn &ic &buf 6))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readrem &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (print (string/of-array !buf))
  
       (in_channel/close ic)))
    (#none ()))
  
  (match (in_channel/open "in_channel.smu")
    ((#some ic)
     (let ((ic& !ic))
       (print (in_channel/readall &ic))
       (in_channel/close ic)))
    (#none ()))
  
  (match (in_channel/open "in_channel.smu")
    ((#some ic)
     (let ((ic& !ic))
       (in_channel/lines &ic (fn (line) (print line)))
       (in_channel/close ic)))
    (#none ()))
  
  (match (in_channel/open "in_channel.smu")
    ((#some ic)
     (let ((ic& !ic)
           (buf& (array/create 4096)))
       (ignore (in_channel/readn &ic &buf 50))
       (def str& !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (ignore (in_channel/readn &ic &buf 6))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readline &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (set &str !(string/of-array !buf))
       (print str)
  
       (set &buf !(string/to-array !str))
       (array/clear &buf)
       (match (in_channel/readrem &ic &buf)
         ((#some n) (print (fmt-str "read " n " bytes")))
         (#none (print "read nothing")))
       (print (string/of-array !buf))
  
       (in_channel/close ic)))
    (#none ()))
  
  (match (in_channel/open "in_channel.smu")
    ((#some ic)
     (let ((ic& !ic))
       (print (in_channel/readall &ic))
       (in_channel/close ic)))
    (#none ()))
  
  (match (in_channel/open "in_channel.smu")
    ((#some ic)
     (let ((ic& !ic))
       (in_channel/lines &ic (fn (line) (print line)))
       (in_channel/close ic)))
    (#none ()))
