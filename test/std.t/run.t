Test hashtbl
  $ schmu -m stbl.smu
  $ schmu hashtbl_test.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./hashtbl_test
  # hashtbl
  ## string
  1.1
  none
  it: 0, key: key, value: 1.1
  none
  ## key
  some v: 10
  ## mut array
  ## project mut

String module test
  $ schmu string.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./string
  hello, world, :)
  ao
  aoaoaoeoaoe
  aooaoa
  iii
  ao
  aoaoaoeoaoe
  aooaoa
  found at 2: aooaoa
  aopataoaoaoeoaoepataooaoapat

In channel module test
  $ schmu in_channel.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./in_channel
  match in_channel/open("in_channel.smu") {
    Some(i
  c) -> 
  read 1 bytes
  {
  read 23 bytes
      let mut ic = mov ic
  read 1598 bytes
      let mut buf = array/create(4096)
      in_channel/readn(mut ic, mut buf, 50) |> ignore
      let mut str = mov string/of_array(mov buf)
      println(str)
  
      mut buf = string/to_array(mov str)
      array/clear(mut buf)
      in_channel/readn(mut ic, mut buf, 6) |> ignore
      mut str = string/of_array(mov buf)
      println(str)
  
      mut buf = string/to_array(mov str)
      array/clear(mut buf)
      match in_channel/readline(mut ic, mut buf) {
        Some(n) -> fmt/(print1("read {} bytes\n", int, n))
        None -> println("read nothing")
      }
      mut str = string/of_array(mov buf)
      println(str)
  
      mut buf = string/to_array(mov str)
      array/clear(mut buf)
      match in_channel/readline(mut ic, mut buf) {
        Some(n) -> fmt/(print1("read {} bytes\n", int, n))
        None -> println("read nothing")
      }
      mut str = string/of_array(mov buf)
      println(str)
  
      mut buf = string/to_array(mov str)
      array/clear(mut buf)
      match in_channel/readrem(mut ic, mut buf) {
        Some(n) -> fmt/(print1("read {} bytes\n", int, n))
        None -> println("read nothing")
      }
      mut str = string/of_array(mov buf)
      println(str)
  
      in_channel/close(ic)
    }
    None -> ()
  }
  
  match in_channel/open("in_channel.smu") {
    Some(ic) -> {
      let mut ic = mov ic
      println(in_channel/readall(mut ic))
      in_channel/close(ic)
    }
    None -> ()
  }
  
  match in_channel/open("in_channel.smu") {
    Some(ic) -> {
      let mut ic = mov ic
      -- in_channel/lines(mut ic) |> iter/iter(println)
      in_channel/lines(mut ic) |> iter/iter(fun line {println(line)})
      in_channel/close(ic)
    }
    None -> ()
  }
  
  match in_channel/open("in_channel.smu") {
    Some(ic) -> {
      let mut ic = mov ic
      let mut buf = array/create(4096)
      in_channel/readn(mut ic, mut buf, 50) |> ignore
      let mut str = mov string/of_array(mov buf)
      println(str)
  
      mut buf = string/to_array(mov str)
      array/clear(mut buf)
      in_channel/readn(mut ic, mut buf, 6) |> ignore
      mut str = string/of_array(mov buf)
      println(str)
  
      mut buf = string/to_array(mov str)
      array/clear(mut buf)
      match in_channel/readline(mut ic, mut buf) {
        Some(n) -> fmt/(print1("read {} bytes\n", int, n))
        None -> println("read nothing")
      }
      mut str = string/of_array(mov buf)
      println(str)
  
      mut buf = string/to_array(mov str)
      array/clear(mut buf)
      match in_channel/readline(mut ic, mut buf) {
        Some(n) -> fmt/(print1("read {} bytes\n", int, n))
        None -> println("read nothing")
      }
      mut str = string/of_array(mov buf)
      println(str)
  
      mut buf = string/to_array(mov str)
      array/clear(mut buf)
      match in_channel/readrem(mut ic, mut buf) {
        Some(n) -> fmt/(print1("read {} bytes\n", int, n))
        None -> println("read nothing")
      }
      mut str = string/of_array(mov buf)
      println(str)
  
      in_channel/close(ic)
    }
    None -> ()
  }
  
  match in_channel/open("in_channel.smu") {
    Some(ic) -> {
      let mut ic = mov ic
      println(in_channel/readall(mut ic))
      in_channel/close(ic)
    }
    None -> ()
  }
  
  match in_channel/open("in_channel.smu") {
    Some(ic) -> {
      let mut ic = mov ic
      -- in_channel/lines(mut ic) |> iter/iter(println)
      in_channel/lines(mut ic) |> iter/iter(fun line {println(line)})
      in_channel/close(ic)
    }
    None -> ()
  }
  
  match in_channel/open("in_channel.smu") {
    Some(ic) -> {
      let mut ic = mov ic
      let mut buf = array/create(4096)
      in_channel/readn(mut ic, mut buf, 50) |> ignore
      let mut str = mov string/of_array(mov buf)
      println(str)
  
      mut buf = string/to_array(mov str)
      array/clear(mut buf)
      in_channel/readn(mut ic, mut buf, 6) |> ignore
      mut str = string/of_array(mov buf)
      println(str)
  
      mut buf = string/to_array(mov str)
      array/clear(mut buf)
      match in_channel/readline(mut ic, mut buf) {
        Some(n) -> fmt/(print1("read {} bytes\n", int, n))
        None -> println("read nothing")
      }
      mut str = string/of_array(mov buf)
      println(str)
  
      mut buf = string/to_array(mov str)
      array/clear(mut buf)
      match in_channel/readline(mut ic, mut buf) {
        Some(n) -> fmt/(print1("read {} bytes\n", int, n))
        None -> println("read nothing")
      }
      mut str = string/of_array(mov buf)
      println(str)
  
      mut buf = string/to_array(mov str)
      array/clear(mut buf)
      match in_channel/readrem(mut ic, mut buf) {
        Some(n) -> fmt/(print1("read {} bytes\n", int, n))
        None -> println("read nothing")
      }
      mut str = string/of_array(mov buf)
      println(str)
  
      in_channel/close(ic)
    }
    None -> ()
  }
  
  match in_channel/open("in_channel.smu") {
    Some(ic) -> {
      let mut ic = mov ic
      println(in_channel/readall(mut ic))
      in_channel/close(ic)
    }
    None -> ()
  }
  
  match in_channel/open("in_channel.smu") {
    Some(ic) -> {
      let mut ic = mov ic
      -- in_channel/lines(mut ic) |> iter/iter(println)
      in_channel/lines(mut ic) |> iter/iter(fun line {println(line)})
      in_channel/close(ic)
    }
    None -> ()
  }

Test unsafe/addr
  $ schmu unsafe_addr.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./unsafe_addr
  2

Use iter and print with dot call
  $ schmu iter_print.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./iter_print
  0
  2
  4
  6
  8
  20
  0
  1
  2
  3
  true
  0
  1
  false

Reverse an empty array
  $ schmu array.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./array

Formatting
  $ schmu fmt.smu
  $ valgrind-wrapper -q --leak-check=yes --show-reachable=yes ./fmt
  this prints to stderr
  heya
  heya 12 you
  heya 13
  14
  0, heya
  bla bla 0
  234u8
  i can now format a proper string with 1234 and 'h.h.'
  1000.009879879879
  1.23457e+19
  1.2e+19
  1.2345e-17
  120000020102.00003
  12345.6789
  -12345.6789
  0.000001234
  123456000.0
  { 12 }
  [1, 2]

