Test hashtbl
  $ schmu -m stbl.smu
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
    Some(i
  c):{
   
  read 16 bytes
     let ic& = !ic
  read 33 bytes
      let buf& = array/create(4096)
  read 1404 bytes
      in_channel/readn(&ic, &buf, 50) |> ignore
      let str& = !string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      in_channel/readn(&ic, &buf, 6) |> ignore
      &str = string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      match in_channel/readline(&ic, &buf) {
        Some(n): println(fmt("read ", n, " bytes"))
        None: println("read nothing")
      }
      &str = string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      match in_channel/readline(&ic, &buf) {
        Some(n): println(fmt("read ", n, " bytes"))
        None: println("read nothing")
      }
      &str = string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      match in_channel/readrem(&ic, &buf) {
        Some(n): println(fmt("read ", n, " bytes"))
        None: println("read nothing")
      }
      &str = string/of_array(!buf)
      println(str)
  
      in_channel/close(ic)
    }
    None: ()
  }
  
  match in_channel/open("in_channel.smu") {
    Some(ic): {
      let ic& = !ic
      println(in_channel/readall(&ic))
      in_channel/close(ic)
    }
    None: ()
  }
  
  match in_channel/open("in_channel.smu") {
    Some(ic): {
      let ic& = !ic
      -- in_channel/lines(&ic) |> iter/iter(println)
      in_channel/lines(&ic) |> iter/iter(fun line {println(line)})
      in_channel/close(ic)
    }
    None: ()
  }
  
  match in_channel/open("in_channel.smu") {
    Some(ic):{
      let ic& = !ic
      let buf& = array/create(4096)
      in_channel/readn(&ic, &buf, 50) |> ignore
      let str& = !string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      in_channel/readn(&ic, &buf, 6) |> ignore
      &str = string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      match in_channel/readline(&ic, &buf) {
        Some(n): println(fmt("read ", n, " bytes"))
        None: println("read nothing")
      }
      &str = string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      match in_channel/readline(&ic, &buf) {
        Some(n): println(fmt("read ", n, " bytes"))
        None: println("read nothing")
      }
      &str = string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      match in_channel/readrem(&ic, &buf) {
        Some(n): println(fmt("read ", n, " bytes"))
        None: println("read nothing")
      }
      &str = string/of_array(!buf)
      println(str)
  
      in_channel/close(ic)
    }
    None: ()
  }
  
  match in_channel/open("in_channel.smu") {
    Some(ic): {
      let ic& = !ic
      println(in_channel/readall(&ic))
      in_channel/close(ic)
    }
    None: ()
  }
  
  match in_channel/open("in_channel.smu") {
    Some(ic): {
      let ic& = !ic
      -- in_channel/lines(&ic) |> iter/iter(println)
      in_channel/lines(&ic) |> iter/iter(fun line {println(line)})
      in_channel/close(ic)
    }
    None: ()
  }
  
  match in_channel/open("in_channel.smu") {
    Some(ic):{
      let ic& = !ic
      let buf& = array/create(4096)
      in_channel/readn(&ic, &buf, 50) |> ignore
      let str& = !string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      in_channel/readn(&ic, &buf, 6) |> ignore
      &str = string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      match in_channel/readline(&ic, &buf) {
        Some(n): println(fmt("read ", n, " bytes"))
        None: println("read nothing")
      }
      &str = string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      match in_channel/readline(&ic, &buf) {
        Some(n): println(fmt("read ", n, " bytes"))
        None: println("read nothing")
      }
      &str = string/of_array(!buf)
      println(str)
  
      &buf = string/to_array(!str)
      array/clear(&buf)
      match in_channel/readrem(&ic, &buf) {
        Some(n): println(fmt("read ", n, " bytes"))
        None: println("read nothing")
      }
      &str = string/of_array(!buf)
      println(str)
  
      in_channel/close(ic)
    }
    None: ()
  }
  
  match in_channel/open("in_channel.smu") {
    Some(ic): {
      let ic& = !ic
      println(in_channel/readall(&ic))
      in_channel/close(ic)
    }
    None: ()
  }
  
  match in_channel/open("in_channel.smu") {
    Some(ic): {
      let ic& = !ic
      -- in_channel/lines(&ic) |> iter/iter(println)
      in_channel/lines(&ic) |> iter/iter(fun line {println(line)})
      in_channel/close(ic)
    }
    None: ()
  }

Test unsafe/addr
  $ schmu unsafe_addr.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./unsafe_addr
  2

Use iter and print with dot call
  $ schmu iter_print.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./iter_print
  0
  2
  4
  6
  8
  20

Reverse an empty array
  $ schmu array.smu
  $ valgrind -q --leak-check=yes --show-reachable=yes ./array
