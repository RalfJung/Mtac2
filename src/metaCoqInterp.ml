open Constrs
open Pp

type mrun_arg_type =
  | Program of (EConstr.types)
  | GTactic

type mrun_arg =
  | StaticallyChecked of (mrun_arg_type * Globnames.global_reference)
  | DynamicallyChecked of (Glob_term.closed_glob_constr)

let ifTactic env sigma ty c =
  let (sigma, gtactic) = MCTactics.mkGTactic env sigma in
  let unitType = Constrs.CoqUnit.mkType in
  let gtactic = EConstr.mkApp(EConstr.of_constr gtactic, [|unitType|]) in
  let open Evarsolve in
  let res = Munify.unify_evar_conv Names.full_transparent_state env sigma Reduction.CONV gtactic ty in
  match res with
  | Success sigma -> (true, sigma)
  | _ -> (false, sigma)


module MetaCoqRun = struct
  (** This module run the interpretation of a constr
  *)

  let ifM env sigma concl ty c =
    let sigma, metaCoqType = MtacNames.mkT_lazy sigma env in
    let (h, args) = Reductionops.whd_all_stack env sigma ty in
    if EConstr.eq_constr_nounivs sigma metaCoqType h && List.length args = 1 then
      try
        let sigma = Evarconv.the_conv_x_leq env concl (List.hd args) sigma in
        (true, sigma)
      with Evarconv.UnableToUnify(_,_) -> CErrors.user_err (str "Different types")
    else
      (false, sigma)

  (** Given a type concl and a term c, it checks that c has type:
      - [M concl]: then it returns [c]
      - [tactic]: then it returns [c (Goal concl evar)] *)
  let pretypeT env sigma concl evar c =
    let ty = Retyping.get_type_of env sigma c in
    let b, sigma = ifM env sigma concl ty c in
    if b then
      (false, sigma, c)
    else
      let b, sigma = ifTactic env sigma ty c in
      if b then
        (true, sigma, c)
      else
        CErrors.user_err (str "Not a Mtactic")

  let run env sigma concl evar istactic t =
    (* [run] is also the entry point for code that doesn't go through
       [pretypeT] so we have to do the application to the current goal
       for tactics in here instead of [pretypeT].
    *)
    let sigma, t = if istactic then
        let sigma, goal = Run.Goal.mkTheGoal concl evar sigma env in
        (sigma, EConstr.mkApp(t, [|goal|]))
      else sigma, t
    in
    match Run.run (env, sigma) t with
    | Run.Val (sigma, v) ->
        let open Proofview in let open Proofview.Notations in
        Unsafe.tclEVARS sigma >>= fun _->
        if not istactic then
          Refine.refine ~typecheck:false begin fun evd -> evd, v end
        else
          let goals = Constrs.CoqList.from_coq sigma env v in
          let goals = List.map (fun x -> snd (Constrs.CoqPair.from_coq (env, sigma) x)) goals in
          let goals = List.map (Run.Goal.evar_of_goal sigma env) goals in
          let goals = List.filter Option.has_some goals in
          let goals = List.map Option.get goals in
          Unsafe.tclSETGOALS goals

    | Run.Err (_, e) ->
        CErrors.user_err (str "Uncaught exception: " ++ (Termops.print_constr e))

  let evar_of_goal gl =
    let open Proofview.Goal in
    let ids = List.map (fun d->Term.mkVar (Context.Named.Declaration.get_id d)) (Environ.named_context (env gl)) in
    Term.mkEvar (goal gl, Array.of_list ids)

  (** Get back the context given a goal, interp the constr_expr to obtain a constr
      Then run the interpretation fo the constr, and returns the tactic value,
      according to the value of the data returned by [run].
  *)
  let run_tac t =
    let open Proofview.Goal in
    nf_enter begin fun gl ->
      let env = env gl in
      let concl = concl gl in
      let sigma = sigma gl in
      let evar = EConstr.of_constr (evar_of_goal gl) in
      let (sigma, t) = Constrintern.interp_open_constr env sigma t in
      let (istactic, sigma, t) = pretypeT env sigma concl evar t in
      run env sigma concl evar istactic t
    end


  let understand env sigma {Glob_term.closure=closure;term=term} =
    let open Glob_ops in
    let open Glob_term in
    let open Pretyping in
    let flags = all_no_fail_flags in
    let lvar = { empty_lvar with
                 ltac_constrs = closure.typed;
                 ltac_uconstrs = closure.untyped;
                 ltac_idents = closure.idents;
               } in
    understand_ltac flags env sigma lvar WithoutTypeConstraint term

  let run_tac_constr t =
    let open Proofview.Goal in
    nf_enter begin fun gl ->
      let env = env gl in
      let concl = concl gl in
      let sigma = sigma gl in
      let evar = EConstr.of_constr (evar_of_goal gl) in
      let (istactic, sigma, t) = match t with
        | StaticallyChecked (Program ty, c) ->
            begin
              try
                let sigma = Evarconv.the_conv_x_leq env concl ty sigma in
                let sigma, t = EConstr.fresh_global env sigma c in
                (false, sigma, t)
              with Evarconv.UnableToUnify(_,_) -> CErrors.user_err (str "Different types")
            end
        | StaticallyChecked (GTactic, c) ->
            let sigma, t = EConstr.fresh_global env sigma c in
            (true, sigma, t)
        | DynamicallyChecked t ->
            let sigma, t = understand env sigma t in
            pretypeT env sigma concl evar t
      in
      run env sigma concl evar istactic t
    end

  let run_cmd t =
    let (sigma, env) = Pfedit.get_current_context () in
    let sigma, c = Constrintern.interp_open_constr env sigma t in
    match Run.run (env, sigma) c with
    | Run.Val _ -> ()
    | Run.Err (_, e) ->
        CErrors.user_err (str "Uncaught exception: " ++ Termops.print_constr e)

end

(**
   This module manages the interpretation of the MetaCoq tactics
   and the vernac MProof command.
*)

(** Interpreter of the MProof vernac command :
    - Get back and focus on the current proof
    - Set the proof mode to "MProof" mode.
    - Print subgoals *)
[@@@ocaml.warning "-3"] (* deprecated use of set_proof_mode *)
let interp_mproof_command () =
  let pf = Proof_global.give_me_the_proof () in
  if Proof.is_done pf then
    CErrors.user_err (str "Nothing left to prove here.")
  else
    begin
      Proof_global.set_proof_mode "MProof";
      Feedback.msg_info @@ Printer.pr_open_subgoals ();
    end

(** Interpreter of a mtactic *)
let interp_instr = function
  | MetaCoqInstr.MetaCoq_constr c -> MetaCoqRun.run_tac c

let exec f =
  ignore (Pfedit.by (f ()))

(** Interpreter of a constr :
    - Interpretes the constr
    - Unfocus on the current proof *)
let interp_proof_constr instr =
  exec (fun () -> interp_instr instr)


(** [end_proof] is "Qed" customized for MetaCoq.

    The standard "Qed" does not accept dangling evars even if they do
    not appear in the final ground proof term. This should probably
    be changed mainstream.

    In MetaCoq, we first check that the final proof term is ground
    and if it is, we explicitly remove the dangling evars from the
    environment so that the standard "Qed" does not complain.
*)
let end_proof () =
  let proof_is_closed_wrt_to_evars () =
    Proof_global.with_current_proof (fun _ proof ->
      proof, Proof.in_proof proof (fun evarmap ->
        let proofs = Proof.partial_proof proof in
        List.for_all (Evarutil.is_ground_term evarmap) proofs
      ))
  in
  let remove_dangling_evars () =
    ignore (Pfedit.by Proofview.(Unsafe.(Monad.(
      tclSETGOALS [] >>
      (tclEVARMAP >>= (fun evarmap ->
         let evarmap =
           Evd.fold_undefined (fun evar _ evarmap ->
             Evd.remove evarmap evar) evarmap evarmap
         in
         tclEVARS evarmap))))
    ));
  in
  if proof_is_closed_wrt_to_evars () then
    remove_dangling_evars ();
  (* The following invokes the usual Qed. *)
  let open Vernacexpr in
  Lemmas.save_proof (Proved (Opaque None,None))
