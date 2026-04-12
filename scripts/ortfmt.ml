type header = {
  name: string; subname: string; func: string;
  author: string; authorn: string; date: string;
}

let width = 67
let empty_header = { name = ""; subname = ""; func = ""; author = ""; authorn = ""; date = "" }

let parse_header_line line =
  let l = String.trim line in
  if String.starts_with ~prefix:"NAME: " l then ("name", String.sub l 6 (String.length l - 6))
  else if String.starts_with ~prefix:"SUBNAME: " l then ("subname", String.sub l 9 (String.length l - 9))
  else if String.starts_with ~prefix:"FUNCTION: " l then ("func", String.sub l 10 (String.length l - 10))
  else if String.starts_with ~prefix:"AUTHOR: " l then ("author", String.sub l 8 (String.length l - 8))
  else if String.starts_with ~prefix:"AUTHORN: " l then ("authorn", String.sub l 9 (String.length l - 9))
  else if String.starts_with ~prefix:"DATE: " l then ("date", String.sub l 6 (String.length l - 6))
  else ("", "")

let update_header h (key, value) =
  match key with
  | "name" -> { h with name = value } | "subname" -> { h with subname = value }
  | "func" -> { h with func = value } | "author" -> { h with author = value }
  | "authorn" -> { h with authorn = value } | "date" -> { h with date = value }
  | _ -> h

let pad_left s =
  let len = String.length s in
  if len >= width then s else String.make (width - len) ' ' ^ s

let render_header h =
  let border = String.make width '-' in
  let title = "○ " ^ h.name ^ " ~ " ^ h.subname in
  let auth = pad_left (h.author ^ " (" ^ h.authorn ^ ")") in
  String.concat "\n" [border; title; ""; String.uppercase_ascii h.func; ""; auth; pad_left h.date; border]

let run_script input_file output_override terminal_mode =
  let ic = open_in input_file in
  
  (* Coleta header e a primeira linha que NÃO é header *)
  let rec get_header h last_line =
    try
      let line = input_line ic in
      let (k, v) = parse_header_line line in
      if k <> "" then get_header (update_header h (k, v)) None
      else if String.trim line = "" then get_header h None
      else (h, Some line)
    with End_of_file -> (h, None)
  in
  
  let (header_data, first_content_line) = get_header empty_header None in
  
  let oc = if terminal_mode then stdout 
           else open_out (match output_override with 
                | Some n -> n 
                | None -> (if header_data.func = "" then "OUTPUT" else header_data.func) ^ ".txt") 
  in

  let write_l s = output_string oc (s ^ "\n") in

  let rec loop in_quote offset is_blank =
    match input_line ic with
    | exception End_of_file -> close_in ic; if not terminal_mode then close_out oc
    | raw_line ->
        let line = if is_blank then raw_line else String.trim raw_line in
        
        if not is_blank && String.starts_with ~prefix:"TOPIC" line then
          let c_idx = String.index line ':' in
          let num = String.sub line 5 (c_idx - 5) in
          let title = String.trim (String.sub line (c_idx + 1) (String.length line - c_idx - 1)) in
          let prefix = "■ " ^ num ^ ". " in
          write_l ("\n" ^ prefix ^ title);
          loop false (String.length prefix) false
        
        else if not is_blank && String.starts_with ~prefix:"BLANK:" line then
          (write_l ""; loop false 0 true) (* Pula linha antes do BLANK *)

        else if String.starts_with ~prefix:"\"" line then
          let content = String.sub line 1 (String.length line - 1) in
          let has_end = String.ends_with ~suffix:"\"" content in
          let clean = if has_end then String.sub content 0 (String.length content - 1) else content in
          write_l (String.make offset ' ' ^ clean);
          loop (not has_end) offset is_blank

        else if in_quote || is_blank then
          let has_end = String.ends_with ~suffix:"\"" raw_line in
          let content = if has_end then String.sub raw_line 0 (String.length raw_line - 1) else raw_line in
          write_l ((if is_blank then "" else String.make offset ' ' ) ^ (if is_blank then content else String.trim content));
          if has_end then loop false 0 false else loop in_quote offset is_blank
        else
          (if line <> "" then write_l line; loop false 0 false)
  in

  write_l (render_header header_data);
  (* Processa a linha que sobrou do parser do header *)
  (match first_content_line with 
   | Some l -> if String.starts_with ~prefix:"TOPIC" l then 
                 let c_idx = String.index l ':' in
                 let prefix = "■ " ^ String.sub l 5 (c_idx - 5) ^ ". " in
                 write_l ("\n" ^ prefix ^ String.trim (String.sub l (c_idx+1) (String.length l - c_idx - 1)));
                 loop false (String.length prefix) false
               else (write_l l; loop false 0 false)
   | None -> loop false 0 false);
  if not terminal_mode then Printf.printf "Finalizado!\n"

let () =
  let args = Array.to_list Sys.argv in
  try
    let term = List.mem "-t" args in
    let filtered = List.filter (fun x -> x <> "-t") args in
    match filtered with
    | _ :: inp :: "-o" :: out :: _ -> run_script inp (Some out) term
    | _ :: inp :: _ -> run_script inp None term
    | _ -> print_endline "Uso: ocaml script.ml input.txt [-t] [-o out.txt]"
  with e -> Printf.eprintf "Erro: %s\n" (Printexc.to_string e)
