
open Obj
open Type


type expression = 
  | Terminal of string * tp * unit ref
  | Application of tp * expression * expression


let rec runExpression (e:expression) : 'a = 
  match e with
    Terminal(_,_,thing) -> !(Obj.magic thing)
  | Application(_,f,x) -> 
      (Obj.magic (runExpression f)) (Obj.magic (runExpression x));;


let rec compare_expression e1 e2 = 
  match (e1,e2) with
    (Terminal(n1,_,_),Terminal(n2,_,_)) -> compare n1 n2
  | (Terminal(_,_,_),_) -> -1
  | (_,Terminal(_,_,_)) -> 1
  | (Application(_,l,r),Application(_,l_,r_)) -> 
      let c = compare_expression l l_ in
      if c == 0 then compare_expression r r_ else c
;;

let infer_type (e : expression) = 
  let rec infer c r = 
    match r with
      Terminal(_,t,_) -> instantiate_type c t
    | Application(_,f,x) -> 
	let (ft,c1) = infer c f in
	let (xt,c2) = infer c1 x in
	let (rt,c3) = makeTID c2 in
	let c4 = unify c3 ft (make_arrow xt rt) in
	chaseType c4 rt
  in fst (infer (1,TypeMap.empty) e)
;;


let rec string_of_expression e = 
  match e with
    Terminal(s,_,_) -> s
  | Application(_,f,x) ->
      "("^(string_of_expression f)^" "^(string_of_expression x)^")";;

let make_app f x = 
  Application(TCon("undefined",[]),f,x);;


(* compact representation of expressions sharing many subtrees *)
type expressionNode = ExpressionLeaf of expression
  | ExpressionBranch of int * int;;
type expressionGraph = 
    (int,expressionNode) Hashtbl.t * (expressionNode,int) Hashtbl.t int ref;;
let make_expression_graph size : expressionGraph = 
  (Hashtbl.create size,Hashtbl.create size,ref 0);;


let insert_expression_node (i2n,n2i,nxt) n =
  try
    Hashtbl.find n2i n
  with Not_found -> 
    Hashtbl.add (!nxt) n i2n;
    Hashtbl.add n (!nxt) n2i;
    incr nxt; !nxt - 1;;


let rec insert_expression g (e : expression) = 
  match e with
    Terminal(_,_,_) ->
      insert_expression_node (ExpressionLeaf(e))
  | Application(_,f,x) -> 
      insert_expression_node (ExpressionBranch(insert_expression g f,insert_expression g x));;





let test_expression () =
  let t1 = TID(0) in
  let e1 = Terminal("I", t1, Obj.magic (ref (fun x -> x))) in
  let e42 = Terminal("31", t1, Obj.magic (ref 31)) in
  let e2 = Terminal("1", t1, Obj.magic (ref 1)) in
  let e3 = Application(t1, Application(t1, e1,e1),e2) in
  let e4 = Terminal("+", t1, Obj.magic (ref (fun x -> fun y -> x+y))) in
  let e5 = Application(t1, Application(t1, e4,e3),e42) in
  print_int (runExpression e5);;
  


 (* main ();; *)
