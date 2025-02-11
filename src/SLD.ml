type item  = [ Ast.atom | `Cut of stack ]
and  goal  = item list
and  state = int * goal * Unify.subst * Ast.clause list
and  stack = state list

let extend is =
  List.map (function
            | `Cut -> `Cut []
            | #Ast.atom as a -> (a :> item)
           ) is

let pretty_goal goal = Ostap.Pretty.listByComma @@ GT.gmap(GT.list) Ast.pretty_body_item goal

let pretty_state (depth, goal, subst, clauses) =
  Ostap.Pretty.seq [
    Ostap.Pretty.int depth;
    Ostap.Pretty.newline;
    pretty_goal goal;
    Ostap.Pretty.newline;
    Unify.pretty_subst (Some subst)
  ]

let pretty_stack stack = Ostap.Pretty.seq @@
  GT.gmap(GT.list) (fun s -> Ostap.Pretty.seq [pretty_state s; Ostap.Pretty.newline]) stack

let rec solve env (bound, stack, pruned) =
  let find (a : Ast.atom) (s : Unify.subst) clauses cut =
    let name =
      let i = env#index in
      fun s -> Printf.sprintf "$%d_%s" i s
    in
    env#increment_index;
    let rec inner = function
    | [] -> None
    | `Clause (b, `Body bs) :: clauses' ->
        let module M = Map.Make (String) in
        let m = ref M.empty in
        let rename a =
          GT.transform(Ast.atom)
            (fun self -> object inherit [Ast.atom, _] @Ast.atom[gmap] self
               method c_Functor _ _ f ts =
                 `Functor (
                    f,
                    GT.gmap(GT.list)
                       (GT.transform(Ast.term)
                           (fun self -> object inherit [Ast.term, _] @Ast.term[gmap] self
                              method c_Var _ _ x =
                                try `Var (M.find x !m)
                                with Not_found ->
                                  let x' = name x in
                                  m := M.add x x' !m;
                                  `Var x'
                            end
                           )
                           ()
                       )
                       ts
                  )
             end)
            ()
            a
        in
        let b  = rename b in
        let bs =
          List.map (
            function
            | `Cut -> `Cut cut
            | #Ast.atom as a -> (rename a :> item)
          ) bs
        in
        match Unify.unify (Some s) (Ast.to_term a) (Ast.to_term b) with
        | None    -> inner clauses'
        | Some s' -> Some (s', bs, clauses')
    in
    inner clauses
  in
(*  env#trace "Stack:";
  env#trace (Ostap.Pretty.toString (pretty_stack stack));
  env#wait;
*)
  match stack with
  | [] -> (match pruned with [] -> `End | _ -> solve env (bound + env#increment, pruned, []))
  | (depth, goal, subst, clauses)::stack when depth < bound ->
      (match goal with
       | [] -> `Answer (subst, (bound, stack, pruned))
       | a::atoms ->
          (match a with
           | `Cut cut -> solve env (bound, (depth, atoms, subst, clauses)::cut, pruned)
           | #Ast.atom as a ->
              (match find a subst clauses stack with
              | None -> solve env (bound, stack, pruned)
              | Some (subst', btoms, clauses') ->
                  solve env @@ (
                     bound,
                     (depth+1, btoms @ atoms, subst', env#clauses)::(depth, goal, subst, clauses')::stack,
                     pruned
                  )
              )
          )
      )
  | state::stack -> solve env (bound, stack, state::pruned)
