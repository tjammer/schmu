exception Error of Ast.loc * string

open Types

let format_type_err pre mname t1 t2 =
  (* Construct a nice type error like in mlton. We don't know where the types
     begin to differ so we go through both types in parellel. Additionally we
     highlight the differences with [<type>]. We can afford to write this in a
     naive way like using string comparisons etc. It will only be called if an
     error has been raised *)
  let sotl = create_string_of_type mname in
  let sotr = create_string_of_type mname in
  let rec aux t1 t2 =
    let plist sot ps = String.concat " " (List.map (fun p -> sot p.pt) ps) in
    let flist sot fs =
      String.concat " " (Array.map (fun f -> sot f.ftyp) fs |> Array.to_list)
    in
    (* TODO parameter version with passing *)
    let difflist l r =
      let _, found, l, r =
        List.fold_left2
          (fun (i, accfound, l, r) lt rt ->
            let found, ls, rs = aux lt rt in
            let found, ls, rs =
              if String.equal ls rs then (found, "_", "_")
              else if found then (found, ls, rs)
              else (true, "[" ^ ls ^ "]", "[" ^ rs ^ "]")
            in
            if i <> 0 then (i + 1, found || accfound, l ^ " " ^ ls, r ^ " " ^ rs)
            else (i + 1, found || accfound, l ^ ls, r ^ rs))
          (0, false, "", "") l r
      in
      (found, l, r)
    in
    let pdifflist l r =
      let _, found, l, r =
        List.fold_left2
          (fun (i, accfound, l, r) lt rt ->
            let pattr = function
              | Ast.Dnorm -> ""
              | Dmut -> "&"
              | Dmove -> "!"
              | Dset -> "&"
            in
            let found, ls, rs = aux lt.pt rt.pt in
            let ls = ls ^ pattr lt.pattr and rs = rs ^ pattr rt.pattr in
            let found, ls, rs =
              if String.equal ls rs then (found, "_", "_")
              else if found then (found, ls, rs)
              else (true, "[" ^ ls ^ "]", "[" ^ rs ^ "]")
            in
            if i <> 0 then (i + 1, found || accfound, l ^ " " ^ ls, r ^ " " ^ rs)
            else (i + 1, found || accfound, l ^ ls, r ^ rs))
          (0, false, "", "") l r
      in
      (found, l, r)
    in

    match (t1, t2) with
    | Tfun (ls, l, _), Tfun (rs, r, _) ->
        (* If the number of arguments doesn't match, highlight the whole list *)
        if List.length rs <> List.length ls then
          let ls = "(fun [" ^ plist sotl ls ^ "] _)"
          and rs = "(fun [" ^ plist sotr rs ^ "] _)" in
          (true, ls, rs)
        else
          let found, ls, rs =
            (* Find different argument types *)
            pdifflist ls rs
          in
          (* Check if return type matches *)
          let rfound, l, r = aux l r in
          let found, l, r =
            if String.equal ls rs then
              (* Return type could be different *)
              (rfound, "(fun _ " ^ l ^ ")", "(fun _ " ^ r ^ ")")
            else if String.equal l r then
              (found, "(fun " ^ ls ^ " _)", "(fun " ^ rs ^ " _)")
            else
              ( found || rfound,
                "(fun " ^ ls ^ " " ^ l ^ ")",
                "(fun " ^ rs ^ " " ^ r ^ ")" )
          in
          (* This could be an inner function. If the strings are the same, we only
             return a placeholder *)
          if String.equal l r then (found, "_", "_") else (found, l, r)
    | Trecord (_, None, ls), Trecord (_, None, rs) ->
        if Array.length ls <> Array.length rs then
          let ls = "[{" ^ flist sotl ls ^ "}]"
          and rs = "[{" ^ flist sotr rs ^ "}]" in
          (true, ls, rs)
        else
          let ls = Array.to_list ls |> List.map (fun f -> f.ftyp)
          and rs = Array.to_list rs |> List.map (fun f -> f.ftyp) in
          let found, l, r = difflist ls rs in
          if String.equal l r then (found, "_", "_")
          else (found, "{" ^ l ^ "}", "{" ^ r ^ "}")
    | Tarray l, Tarray r ->
        let found, l, r = aux l r in
        if String.equal l r then (found, "_", "_")
        else if found then (found, "(array " ^ l ^ ")", "(array " ^ r ^ ")")
        else (found, "(array [" ^ l ^ "])", "(array [" ^ r ^ "])")
    | l, r ->
        let l = sotl l and r = sotr r in
        if String.equal l r then (false, l, r)
        else (true, "[" ^ l ^ "]", "[" ^ r ^ "]")
  in
  let _, l, r = aux t1 t2 in
  if String.length l + String.length r + String.length pre < 50 then
    Printf.sprintf "%s expecting %s but found %s" pre l r
  else Printf.sprintf "%s\nexpecting %s\nbut found %s" pre l r
