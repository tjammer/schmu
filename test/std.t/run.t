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
  match in_channel/open("in_channel.smu"):
    #some(i
  c):
    
  read 15 bytes
    let ic& = !ic
  read 33 bytes
      let buf& = array/create(4096)
  read 1288 bytes
      in_channel/readn(&ic, &buf, 50) -> ignore
      let str& = !string/of_array(!buf)
      print(str)
  
      &buf <- string/to_array(!str)
      array/clear(&buf)
      in_channel/readn(&ic, &buf, 6) -> ignore
      &str <- string/of_array(!buf)
      print(str)
  
      &buf <- string/to_array(!str)
      array/clear(&buf)
      match in_channel/readline(&ic, &buf):
        #some(n): print(fmt("read ", n, " bytes"))
        #none: print("read nothing")
      &str <- string/of_array(!buf)
      print(str)
  
      &buf <- string/to_array(!str)
      array/clear(&buf)
      match in_channel/readline(&ic, &buf):
        #some(n): print(fmt("read ", n, " bytes"))
        #none: print("read nothing")
      &str <- string/of_array(!buf)
      print(str)
  
      &buf <- string/to_array(!str)
      array/clear(&buf)
      match in_channel/readrem(&ic, &buf):
        #some(n): print(fmt("read ", n, " bytes"))
        #none: print("read nothing")
      &str <- string/of_array(!buf)
      print(str)
  
      in_channel/close(ic)
    #none: ()
  
  match in_channel/open("in_channel.smu"):
    #some(ic):
      let ic& = !ic
      print(in_channel/readall(&ic))
      in_channel/close(ic)
    #none: ()
  
  
  match in_channel/open("in_channel.smu"):
    #some(ic):
      let ic& = !ic
      in_channel/lines(&ic, fun line: print(line))
      in_channel/close(ic)
    #none: ()
  
  match in_channel/open("in_channel.smu"):
    #some(ic):
      let ic& = !ic
      let buf& = array/create(4096)
      in_channel/readn(&ic, &buf, 50) -> ignore
      let str& = !string/of_array(!buf)
      print(str)
  
      &buf <- string/to_array(!str)
      array/clear(&buf)
      in_channel/readn(&ic, &buf, 6) -> ignore
      &str <- string/of_array(!buf)
      print(str)
  
      &buf <- string/to_array(!str)
      array/clear(&buf)
      match in_channel/readline(&ic, &buf):
        #some(n): print(fmt("read ", n, " bytes"))
        #none: print("read nothing")
      &str <- string/of_array(!buf)
      print(str)
  
      &buf <- string/to_array(!str)
      array/clear(&buf)
      match in_channel/readline(&ic, &buf):
        #some(n): print(fmt("read ", n, " bytes"))
        #none: print("read nothing")
      &str <- string/of_array(!buf)
      print(str)
  
      &buf <- string/to_array(!str)
      array/clear(&buf)
      match in_channel/readrem(&ic, &buf):
        #some(n): print(fmt("read ", n, " bytes"))
        #none: print("read nothing")
      &str <- string/of_array(!buf)
      print(str)
  
      in_channel/close(ic)
    #none: ()
  
  match in_channel/open("in_channel.smu"):
    #some(ic):
      let ic& = !ic
      print(in_channel/readall(&ic))
      in_channel/close(ic)
    #none: ()
  
  
  match in_channel/open("in_channel.smu"):
    #some(ic):
      let ic& = !ic
      in_channel/lines(&ic, fun line: print(line))
      in_channel/close(ic)
    #none: ()
  
  match in_channel/open("in_channel.smu"):
    #some(ic):
      let ic& = !ic
      let buf& = array/create(4096)
      in_channel/readn(&ic, &buf, 50) -> ignore
      let str& = !string/of_array(!buf)
      print(str)
  
      &buf <- string/to_array(!str)
      array/clear(&buf)
      in_channel/readn(&ic, &buf, 6) -> ignore
      &str <- string/of_array(!buf)
      print(str)
  
      &buf <- string/to_array(!str)
      array/clear(&buf)
      match in_channel/readline(&ic, &buf):
        #some(n): print(fmt("read ", n, " bytes"))
        #none: print("read nothing")
      &str <- string/of_array(!buf)
      print(str)
  
      &buf <- string/to_array(!str)
      array/clear(&buf)
      match in_channel/readline(&ic, &buf):
        #some(n): print(fmt("read ", n, " bytes"))
        #none: print("read nothing")
      &str <- string/of_array(!buf)
      print(str)
  
      &buf <- string/to_array(!str)
      array/clear(&buf)
      match in_channel/readrem(&ic, &buf):
        #some(n): print(fmt("read ", n, " bytes"))
        #none: print("read nothing")
      &str <- string/of_array(!buf)
      print(str)
  
      in_channel/close(ic)
    #none: ()
  
  match in_channel/open("in_channel.smu"):
    #some(ic):
      let ic& = !ic
      print(in_channel/readall(&ic))
      in_channel/close(ic)
    #none: ()
  
  
  match in_channel/open("in_channel.smu"):
    #some(ic):
      let ic& = !ic
      in_channel/lines(&ic, fun line: print(line))
      in_channel/close(ic)
    #none: ()
