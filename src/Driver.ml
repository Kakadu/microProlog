open GT
open Checked

let _ = 
  let env = new Env.c in
  let doCommand = function
  | `TraceOn  -> env#trace_on
  | `TraceOff -> env#trace_off
  | `BFS      -> env#bfs
  | `DFS      -> env#dfs
  | `Empty    -> ()
  | `Quit     -> exit 0
  | `Clear    -> env#clear
  | `Clause c -> env#add c
  | `Show     -> env#show
  | `Load f   -> 
      let f = String.sub f 1 (String.length f - 2) in
      (match Parser.Lexer.fromString Parser.spec (Ostap.Util.read f) with
       | Ok clauses  -> List.iter env#add clauses
       | Fail (m::_) -> Printf.printf "Syntax error: %s\n" (Ostap.Msg.toString m)
      )
  | `Unify (x, y) -> 
      Printf.printf "%s\n" 
	(Ostap.Pretty.toString (Unify.pretty_subst (Unify.unify (Some Unify.empty) x y)))
  | `Query goal ->
      let vars = Ast.vars goal in 
      let rec iterate stack =
        match SLD.solve env stack with
        | `End -> Printf.printf "No (more) answers.\n%!"
        | `Answer (s, stack) ->
	    (match vars with
	     | [] -> Printf.printf "yes\n"
	     | _  -> 
		List.iter 
		   (fun x ->
		      Printf.printf "%s = %s\n" 
                        x
                        (Ostap.Pretty.toString (Ast.pretty_term (Unify.walk' s (`Var x)))) 
                   ) 
		   vars
            );
            Printf.printf "Continue (y/n)? ";
            let a = read_line () in
	    if a = "y" || a = "Y" then iterate stack
      in iterate [(goal :> Ast.body_item list), Unify.empty]
  in
  while true do
    Printf.printf "> ";
    match Parser.Lexer.fromString Parser.main (read_line ()) with
    | Ok command -> doCommand command
    | Fail (m::_) -> 
	(match Ostap.Msg.loc m with
	 | Ostap.Msg.Locator.Point (1, n) -> 
             Printf.printf "%s^\n" (String.make (n-1) ' ')
	 | _ -> ()
	);
	Printf.printf "Syntax error: %s\n" (Ostap.Msg.toString m)
  done

