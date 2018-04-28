type arg = CClosure.fconstr

type arg_any = arg
type arg_type = arg
type arg_fun = arg
type arg_string = arg
type arg_N = arg
type arg_bool = arg
type arg_mlist = arg
type arg_case = arg

type arg_fix1_ty = arg_type
type arg_fix1_val = arg_any

type arg_fix2_ty = arg_type * arg_type
type arg_fix2_val = arg_any * arg_any

type arg_fix3_ty = arg_type * arg_type * arg_type
type arg_fix3_val = arg_any * arg_any * arg_any

type arg_fix4_ty = arg_type * arg_type * arg_type * arg_type
type arg_fix4_val = arg_any * arg_any * arg_any * arg_any

type arg_fix5_ty = arg_type * arg_type * arg_type * arg_type * arg_type
type arg_fix5_val = arg_any * arg_any * arg_any * arg_any * arg_any

type 'a mconstr_head =
  | Mret : (arg_type * arg_any) mconstr_head
  | Mbind : (arg_type * arg_type * arg_any * arg_fun) mconstr_head
  | Mmtry' : (arg_type * arg_any * arg_fun) mconstr_head
  | Mraise' : (arg_type * arg_any) mconstr_head
  | Mfix1 : (arg_fix1_ty * arg_type * arg_fun * arg_fix1_val) mconstr_head
  | Mfix2 : (arg_fix2_ty * arg_type * arg_fun * arg_fix2_val) mconstr_head
  | Mfix3 : (arg_fix3_ty * arg_type * arg_fun * arg_fix3_val) mconstr_head
  | Mfix4 : (arg_fix4_ty * arg_type * arg_fun * arg_fix4_val) mconstr_head
  | Mfix5 : (arg_fix5_ty * arg_type * arg_fun * arg_fix5_val) mconstr_head
  | Mis_var : (arg_type * arg_any) mconstr_head
  | Mnu : (arg_type * arg_type * arg_string * arg_any * arg_fun) mconstr_head
  | Mabs_fun : (arg_type * arg_fun * arg_any * arg_any) mconstr_head
  | Mabs_let : (arg_type * arg_fun * arg_any * arg_any * arg_any) mconstr_head
  | Mabs_prod_prop : (arg_type * arg_any * arg_type) mconstr_head
  | Mabs_prod_type : (arg_type * arg_any * arg_type) mconstr_head
  | Mabs_fix : (arg_type * arg_any * arg_any * arg_N) mconstr_head
  | Mget_binder_name : (arg_type * arg_any) mconstr_head
  | Mremove : (arg_type * arg_type * arg_any * arg_any) mconstr_head
  | Mgen_evar : (arg_type * arg_any) mconstr_head
  | Mis_evar : (arg_type * arg_any) mconstr_head
  | Mhash : (arg_type * arg_any * arg_N) mconstr_head
  | Msolve_typeclasses
  | Mprint : (arg_string) mconstr_head
  | Mpretty_print : (arg_type * arg_any) mconstr_head
  | Mhyps
  | Mdestcase : (arg_type * arg_any) mconstr_head
  | Mconstrs : (arg_type * arg_any) mconstr_head
  | Mmakecase : (arg_case) mconstr_head
  | Munify : (arg_type * arg_type * arg_any * arg_any * arg_any * arg_fun * arg_fun) mconstr_head
  | Munify_univ : (arg_type * arg_type * arg_any) mconstr_head
  | Mget_reference : (arg_string) mconstr_head
  | Mget_var : (arg_string) mconstr_head
  | Mcall_ltac : (arg_any * arg_any * arg_string * arg_mlist) mconstr_head
  | Mlist_ltac
  | Mread_line
  | Mdecompose : (arg_type * arg_any) mconstr_head
  | Msolve_typeclass : (arg_type) mconstr_head
  | Mdeclare : (arg_any * arg_string * arg_bool * arg_type * arg_any) mconstr_head
  | Mdeclare_implicits : (arg_type * arg_any * arg_mlist) mconstr_head
  | Mos_cmd : (arg_string) mconstr_head
  | Mget_debug_exceptions
  | Mset_debug_exceptions : (arg_bool) mconstr_head
  | Mget_trace
  | Mset_trace : (arg_bool) mconstr_head
  | Mdecompose_app' : (arg_type * arg_fun * arg_any * arg_any * arg_any * arg_any * arg_any * arg_any) mconstr_head
  | Mdecompose_forallT : (arg_fun * arg_type * arg_any * arg_any) mconstr_head
  | Mdecompose_forallP : (arg_fun * arg_type * arg_any * arg_any) mconstr_head
  | Mdecompose_app'' : (arg_fun * arg_fun * arg_any * arg_any) mconstr_head
  | Mnew_timer : (arg_type * arg_any) mconstr_head
  | Mstart_timer : (arg_type * arg_any * arg_bool) mconstr_head
  | Mstop_timer : (arg_type * arg_any) mconstr_head
  | Mreset_timer : (arg_type * arg_any) mconstr_head
  | Mprint_timer : (arg_type * arg_any) mconstr_head
  | Mkind_of_term : (arg_type * arg_any) mconstr_head
and mhead = | MHead : 'a mconstr_head -> mhead
and mconstr = | MConstr : 'a mconstr_head * 'a -> mconstr

val num_args_of_mconstr : 'a mconstr_head -> int
val mconstr_head_of : EConstr.t -> mhead
val mconstr_of : (int -> CClosure.fconstr) -> 'a mconstr_head -> mconstr

val isret : EConstr.t -> bool
val isbind : EConstr.t -> bool
val istry' : EConstr.t -> bool
val israise : EConstr.t -> bool
val isfix1 : EConstr.t -> bool
val isfix2 : EConstr.t -> bool
val isfix3 : EConstr.t -> bool
val isfix4 : EConstr.t -> bool
val isfix5 : EConstr.t -> bool
val isis_var : EConstr.t -> bool
val isnu : EConstr.t -> bool
val isabs_fun : EConstr.t -> bool
val isabs_let : EConstr.t -> bool
val isabs_prod_prop : EConstr.t -> bool
val isabs_prod_type : EConstr.t -> bool
val isabs_fix : EConstr.t -> bool
val isget_binder_name : EConstr.t -> bool
val isremove : EConstr.t -> bool
val isgen_evar : EConstr.t -> bool
val isis_evar : EConstr.t -> bool
val ishash : EConstr.t -> bool
val issolve_typeclasses : EConstr.t -> bool
val isprint : EConstr.t -> bool
val ispretty_print : EConstr.t -> bool
val ishyps : EConstr.t -> bool
val isdestcase : EConstr.t -> bool
val isconstrs : EConstr.t -> bool
val ismakecase : EConstr.t -> bool
val isunify : EConstr.t -> bool
val isunify_univ : EConstr.t -> bool
val isget_reference : EConstr.t -> bool
val isget_var : EConstr.t -> bool
val iscall_ltac : EConstr.t -> bool
val islist_ltac : EConstr.t -> bool
val isread_line : EConstr.t -> bool
val isbreak : EConstr.t -> bool
val isdecompose : EConstr.t -> bool
val issolve_typeclass : EConstr.t -> bool
val isdeclare : EConstr.t -> bool
val isdeclare_implicits : EConstr.t -> bool
val isos_cmd : EConstr.t -> bool
val isget_debug_ex : EConstr.t -> bool
val isset_debug_ex : EConstr.t -> bool
val isget_trace : EConstr.t -> bool
val isset_trace : EConstr.t -> bool
val isdecompose_app : EConstr.t -> bool
val isdecompose_forallT : EConstr.t -> bool
val isdecompose_forallP : EConstr.t -> bool
val isdecompose_app'' : EConstr.t -> bool
val isnew_timer : EConstr.t -> bool
val isstart_timer : EConstr.t -> bool
val isstop_timer : EConstr.t -> bool
val isreset_timer : EConstr.t -> bool
val isprint_timer : EConstr.t -> bool
val iskind_of_term : EConstr.t -> bool
