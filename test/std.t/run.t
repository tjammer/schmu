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
  match In_channel.open("in_channel.smu"):
    Some(ic
  ):
     
  read 14 bytes
   let ic& = !ic
  read 33 bytes
      let buf& = Array.create(4096)
  read 1277 bytes
      In_channel.readn(&ic, &buf, 50) -> ignore
      let str& = !String.of_array(!buf)
      print(str)
  
      &buf <- String.to_array(!str)
      Array.clear(&buf)
      In_channel.readn(&ic, &buf, 6) -> ignore
      &str <- String.of_array(!buf)
      print(str)
  
      &buf <- String.to_array(!str)
      Array.clear(&buf)
      match In_channel.readline(&ic, &buf):
        Some(n): print(fmt("read ", n, " bytes"))
        None: print("read nothing")
      &str <- String.of_array(!buf)
      print(str)
  
      &buf <- String.to_array(!str)
      Array.clear(&buf)
      match In_channel.readline(&ic, &buf):
        Some(n): print(fmt("read ", n, " bytes"))
        None: print("read nothing")
      &str <- String.of_array(!buf)
      print(str)
  
      &buf <- String.to_array(!str)
      Array.clear(&buf)
      match In_channel.readrem(&ic, &buf):
        Some(n): print(fmt("read ", n, " bytes"))
        None: print("read nothing")
      &str <- String.of_array(!buf)
      print(str)
  
      In_channel.close(ic)
    None: ()
  
  match In_channel.open("in_channel.smu"):
    Some(ic):
      let ic& = !ic
      print(In_channel.readall(&ic))
      In_channel.close(ic)
    None: ()
  
  
  match In_channel.open("in_channel.smu"):
    Some(ic):
      let ic& = !ic
      In_channel.lines(&ic, fun line: print(line))
      In_channel.close(ic)
    None: ()
  
  match In_channel.open("in_channel.smu"):
    Some(ic):
      let ic& = !ic
      let buf& = Array.create(4096)
      In_channel.readn(&ic, &buf, 50) -> ignore
      let str& = !String.of_array(!buf)
      print(str)
  
      &buf <- String.to_array(!str)
      Array.clear(&buf)
      In_channel.readn(&ic, &buf, 6) -> ignore
      &str <- String.of_array(!buf)
      print(str)
  
      &buf <- String.to_array(!str)
      Array.clear(&buf)
      match In_channel.readline(&ic, &buf):
        Some(n): print(fmt("read ", n, " bytes"))
        None: print("read nothing")
      &str <- String.of_array(!buf)
      print(str)
  
      &buf <- String.to_array(!str)
      Array.clear(&buf)
      match In_channel.readline(&ic, &buf):
        Some(n): print(fmt("read ", n, " bytes"))
        None: print("read nothing")
      &str <- String.of_array(!buf)
      print(str)
  
      &buf <- String.to_array(!str)
      Array.clear(&buf)
      match In_channel.readrem(&ic, &buf):
        Some(n): print(fmt("read ", n, " bytes"))
        None: print("read nothing")
      &str <- String.of_array(!buf)
      print(str)
  
      In_channel.close(ic)
    None: ()
  
  match In_channel.open("in_channel.smu"):
    Some(ic):
      let ic& = !ic
      print(In_channel.readall(&ic))
      In_channel.close(ic)
    None: ()
  
  
  match In_channel.open("in_channel.smu"):
    Some(ic):
      let ic& = !ic
      In_channel.lines(&ic, fun line: print(line))
      In_channel.close(ic)
    None: ()
  
  match In_channel.open("in_channel.smu"):
    Some(ic):
      let ic& = !ic
      let buf& = Array.create(4096)
      In_channel.readn(&ic, &buf, 50) -> ignore
      let str& = !String.of_array(!buf)
      print(str)
  
      &buf <- String.to_array(!str)
      Array.clear(&buf)
      In_channel.readn(&ic, &buf, 6) -> ignore
      &str <- String.of_array(!buf)
      print(str)
  
      &buf <- String.to_array(!str)
      Array.clear(&buf)
      match In_channel.readline(&ic, &buf):
        Some(n): print(fmt("read ", n, " bytes"))
        None: print("read nothing")
      &str <- String.of_array(!buf)
      print(str)
  
      &buf <- String.to_array(!str)
      Array.clear(&buf)
      match In_channel.readline(&ic, &buf):
        Some(n): print(fmt("read ", n, " bytes"))
        None: print("read nothing")
      &str <- String.of_array(!buf)
      print(str)
  
      &buf <- String.to_array(!str)
      Array.clear(&buf)
      match In_channel.readrem(&ic, &buf):
        Some(n): print(fmt("read ", n, " bytes"))
        None: print("read nothing")
      &str <- String.of_array(!buf)
      print(str)
  
      In_channel.close(ic)
    None: ()
  
  match In_channel.open("in_channel.smu"):
    Some(ic):
      let ic& = !ic
      print(In_channel.readall(&ic))
      In_channel.close(ic)
    None: ()
  
  
  match In_channel.open("in_channel.smu"):
    Some(ic):
      let ic& = !ic
      In_channel.lines(&ic, fun line: print(line))
      In_channel.close(ic)
    None: ()
