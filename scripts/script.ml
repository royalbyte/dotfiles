(* 1. Definindo a estrutura dos nossos dados *)
type element =
  | Title of string
  | Author of string
  | PlainText of string

(* 2. Função que transforma uma linha de texto em um "Element" *)
let parse_line line =
  if String.starts_with ~prefix:"TITLE: " line then
    let content = String.sub line 7 (String.length line - 7) in
    Title content
  else if String.starts_with ~prefix:"AUTHOR: " line then
    let content = String.sub line 8 (String.length line - 8) in
    Author content
  else
    PlainText line

(* 3. Função que decide como cada "Element" deve ser impresso *)
let render_element = function
  | Title t -> "============\n" ^ String.uppercase_ascii t ^ "\n============"
  | Author a -> "Escrito por: " ^ a
  | PlainText t -> t

(* 4. O "motor" que lê o arquivo e processa *)
let run_script filename =
  let ic = open_in filename in
  try
    let rec process_lines () =
      match input_line ic with
      | line -> 
          let element = parse_line line in
          print_endline (render_element element);
          process_lines () (* Recursão para a próxima linha *)
      | exception End_of_file -> close_in ic
    in
    process_lines ()
  with e ->
    close_in_noerr ic;
    raise e

(* Execução *)
let () = run_script "meu_texto.txt"
