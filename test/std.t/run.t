Test hashtbl
  $ schmu hashtbl_test.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./hashtbl_test
  # hashtbl
  ## string
  1.1
  none
  none
  ## key
  some v: 10
  ## mut array

String module test
  $ schmu string.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./string
  hello, world, :)

In channel module test
  $ schmu in_channel.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./in_channel
  match in_channel/open("in_channel.smu") {
    #some(
  ic):{
  
  read 17 bytes
      let ic& = !ic
  read 33 bytes
      let buf& = array/create(4096)
  read 1349 bytes
      in_channel/readn(&ic, &buf, 50).ignore()
      let str& = !string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      in_channel/readn(&ic, &buf, 6).ignore()
      &str = string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      match in_channel/readline(&ic, &buf) {
        #some(n): println(fmt("read ", n, " bytes"))
        #none: println("read nothing")
      }
      &str = string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      match in_channel/readline(&ic, &buf) {
        #some(n): println(fmt("read ", n, " bytes"))
        #none: println("read nothing")
      }
      &str = string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      match in_channel/readrem(&ic, &buf) {
        #some(n): println(fmt("read ", n, " bytes"))
        #none: println("read nothing")
      }
      &str = string/of_array(!buf)
      println(str)
  
      in_channel/close(ic)
    }
    #none: ()
  }
  
  match in_channel/open("in_channel.smu") {
    #some(ic): {
      let ic& = !ic
      println(in_channel/readall(&ic))
      in_channel/close(ic)
    }
    #none: ()
  }
  
  match in_channel/open("in_channel.smu") {
    #some(ic): {
      let ic& = !ic
      in_channel/lines(&ic, fun line {println(line)})
      in_channel/close(ic)
    }
    #none: ()
  }
  
  match in_channel/open("in_channel.smu") {
    #some(ic):{
      let ic& = !ic
      let buf& = array/create(4096)
      in_channel/readn(&ic, &buf, 50).ignore()
      let str& = !string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      in_channel/readn(&ic, &buf, 6).ignore()
      &str = string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      match in_channel/readline(&ic, &buf) {
        #some(n): println(fmt("read ", n, " bytes"))
        #none: println("read nothing")
      }
      &str = string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      match in_channel/readline(&ic, &buf) {
        #some(n): println(fmt("read ", n, " bytes"))
        #none: println("read nothing")
      }
      &str = string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      match in_channel/readrem(&ic, &buf) {
        #some(n): println(fmt("read ", n, " bytes"))
        #none: println("read nothing")
      }
      &str = string/of_array(!buf)
      println(str)
  
      in_channel/close(ic)
    }
    #none: ()
  }
  
  match in_channel/open("in_channel.smu") {
    #some(ic): {
      let ic& = !ic
      println(in_channel/readall(&ic))
      in_channel/close(ic)
    }
    #none: ()
  }
  
  match in_channel/open("in_channel.smu") {
    #some(ic): {
      let ic& = !ic
      in_channel/lines(&ic, fun line {println(line)})
      in_channel/close(ic)
    }
    #none: ()
  }
  
  match in_channel/open("in_channel.smu") {
    #some(ic):{
      let ic& = !ic
      let buf& = array/create(4096)
      in_channel/readn(&ic, &buf, 50).ignore()
      let str& = !string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      in_channel/readn(&ic, &buf, 6).ignore()
      &str = string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      match in_channel/readline(&ic, &buf) {
        #some(n): println(fmt("read ", n, " bytes"))
        #none: println("read nothing")
      }
      &str = string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      match in_channel/readline(&ic, &buf) {
        #some(n): println(fmt("read ", n, " bytes"))
        #none: println("read nothing")
      }
      &str = string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      match in_channel/readrem(&ic, &buf) {
        #some(n): println(fmt("read ", n, " bytes"))
        #none: println("read nothing")
      }
      &str = string/of_array(!buf)
      println(str)
  
      in_channel/close(ic)
    }
    #none: ()
  }
  
  match in_channel/open("in_channel.smu") {
    #some(ic): {
      let ic& = !ic
      println(in_channel/readall(&ic))
      in_channel/close(ic)
    }
    #none: ()
  }
  
  match in_channel/open("in_channel.smu") {
    #some(ic): {
      let ic& = !ic
      in_channel/lines(&ic, fun line {println(line)})
      in_channel/close(ic)
    }
    #none: ()
  }

Test unsafe/addr
  $ schmu unsafe_addr.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./unsafe_addr
  2
