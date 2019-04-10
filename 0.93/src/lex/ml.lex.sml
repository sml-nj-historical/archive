functor MLLexFun(structure Tokens : ML_TOKENS)=
   struct
    structure UserDeclarations =
      struct
(* Copyright 1989 by AT&T Bell Laboratories *)

open ErrorMsg;

structure TokTable = TokenTable(Tokens);
type svalue = Tokens.svalue
type pos = int
type lexresult = (svalue,pos) Tokens.token
type lexarg = {comLevel : int ref, 
	       lineNum : int ref,
               linePos : int list ref, (* offsets of lines in file *)
	       charlist : string list ref,
	       stringstart : int ref, (* start of current string or comment*)
               brack_stack : int ref list ref, (* for frags *)
	       err : pos*pos -> ErrorMsg.complainer}
type arg = lexarg
type ('a,'b) token = ('a,'b) Tokens.token
val eof = fn ({comLevel,err,linePos,stringstart,
               lineNum,charlist, brack_stack}:lexarg) => 
	   let val pos = Integer.max(!stringstart+2, hd(!linePos))
	    in if !comLevel>0 then err (!stringstart,pos) COMPLAIN
					 "unclosed comment" nullErrorBody
		  	      else ();
	       Tokens.EOF(pos,pos)
	   end	
fun addString (charlist,s:string) = charlist := s :: (!charlist)
fun makeString charlist = (implode(rev(!charlist)) before charlist := nil)
fun makeHexInt sign s = let
      fun digit d = if (d < Ascii.uc_a) then (d - Ascii.zero)
	    else (10 + (if (d < Ascii.lc_a) then (d - Ascii.uc_a) else (d - Ascii.lc_a)))
      in
	revfold (fn (c,a) => sign(a*16, digit(ord c))) (explode s) 0
      end
fun makeInt sign s =
    revfold (fn (c,a) => sign(a*10, ord c - Ascii.zero)) (explode s) 0

local
val quote = ord "`"
in
fun has_quote s =
   let fun loop i = (ordof(s,i) = quote orelse loop (i+1))
                    handle Ord => false
   in
   loop 0
   end
end;
   
end (* end of user routines *)
exception LexError (* raised if illegal leaf action tried *)
structure Internal =
	struct

datatype yyfinstate = N of int
type statedata = {fin : yyfinstate list, trans: string}
(* transition & final state table *)
val tab = let
val s0 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
val s1 =
"\014\014\014\014\014\014\014\014\014\063\065\014\063\014\014\014\
\\014\014\014\014\014\014\014\014\014\014\014\014\014\014\014\014\
\\063\031\062\060\031\031\031\055\053\052\050\031\049\031\046\031\
\\042\040\040\040\040\040\040\040\040\040\031\039\031\031\031\031\
\\031\033\033\033\033\033\033\033\033\033\033\033\033\033\033\033\
\\033\033\033\033\033\033\033\033\033\033\033\038\031\037\031\036\
\\035\033\033\033\033\033\033\033\033\033\033\033\033\033\033\033\
\\033\033\033\033\033\033\033\033\033\033\033\032\031\030\015\014\
\\013"
val s3 =
"\066\066\066\066\066\066\066\066\066\066\071\066\066\066\066\066\
\\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066\
\\066\066\066\066\066\066\066\066\069\066\067\066\066\066\066\066\
\\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066\
\\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066\
\\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066\
\\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066\
\\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066\
\\066"
val s5 =
"\072\072\072\072\072\072\072\072\072\072\086\072\072\072\072\072\
\\072\072\072\072\072\072\072\072\072\072\072\072\072\072\072\072\
\\072\072\085\072\072\072\072\072\072\072\072\072\072\072\072\072\
\\072\072\072\072\072\072\072\072\072\072\072\072\072\072\072\072\
\\072\072\072\072\072\072\072\072\072\072\072\072\072\072\072\072\
\\072\072\072\072\072\072\072\072\072\072\072\072\073\072\072\072\
\\072\072\072\072\072\072\072\072\072\072\072\072\072\072\072\072\
\\072\072\072\072\072\072\072\072\072\072\072\072\072\072\072\072\
\\072"
val s7 =
"\087\087\087\087\087\087\087\087\087\089\091\087\089\087\087\087\
\\087\087\087\087\087\087\087\087\087\087\087\087\087\087\087\087\
\\089\087\087\087\087\087\087\087\087\087\087\087\087\087\087\087\
\\087\087\087\087\087\087\087\087\087\087\087\087\087\087\087\087\
\\087\087\087\087\087\087\087\087\087\087\087\087\087\087\087\087\
\\087\087\087\087\087\087\087\087\087\087\087\087\088\087\087\087\
\\087\087\087\087\087\087\087\087\087\087\087\087\087\087\087\087\
\\087\087\087\087\087\087\087\087\087\087\087\087\087\087\087\087\
\\087"
val s9 =
"\092\092\092\092\092\092\092\092\092\092\095\092\092\092\092\092\
\\092\092\092\092\092\092\092\092\092\092\092\092\092\092\092\092\
\\092\092\092\092\092\092\092\092\092\092\092\092\092\092\092\092\
\\092\092\092\092\092\092\092\092\092\092\092\092\092\092\092\092\
\\092\092\092\092\092\092\092\092\092\092\092\092\092\092\092\092\
\\092\092\092\092\092\092\092\092\092\092\092\092\092\092\094\092\
\\093\092\092\092\092\092\092\092\092\092\092\092\092\092\092\092\
\\092\092\092\092\092\092\092\092\092\092\092\092\092\092\092\092\
\\092"
val s11 =
"\096\096\096\096\096\096\096\096\096\102\104\096\102\096\096\096\
\\096\096\096\096\096\096\096\096\096\096\096\096\096\096\096\096\
\\102\097\096\097\097\097\097\096\101\096\097\097\096\097\096\097\
\\096\096\096\096\096\096\096\096\096\096\097\096\097\097\097\097\
\\097\099\099\099\099\099\099\099\099\099\099\099\099\099\099\099\
\\099\099\099\099\099\099\099\099\099\099\099\096\097\096\097\096\
\\096\099\099\099\099\099\099\099\099\099\099\099\099\099\099\099\
\\099\099\099\099\099\099\099\099\099\099\099\096\097\096\097\096\
\\096"
val s15 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\016\000\016\016\016\016\000\000\000\016\016\000\016\000\016\
\\027\018\018\018\018\018\018\018\018\018\016\000\016\016\016\016\
\\016\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\016\000\016\000\
\\017\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\016\000\016\000\
\\000"
val s16 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\016\000\016\016\016\016\000\000\000\016\016\000\016\000\016\
\\000\000\000\000\000\000\000\000\000\000\016\000\016\016\016\016\
\\016\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\016\000\016\000\
\\017\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\016\000\016\000\
\\000"
val s17 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\017\000\017\017\017\017\000\000\000\017\017\000\017\000\017\
\\000\000\000\000\000\000\000\000\000\000\017\000\017\017\017\017\
\\017\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\017\000\017\000\
\\017\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\017\000\017\000\
\\000"
val s18 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\022\000\
\\018\018\018\018\018\018\018\018\018\018\000\000\000\000\000\000\
\\000\000\000\000\000\019\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
val s19 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\021\021\021\021\021\021\021\021\021\021\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\020\000\
\\000"
val s20 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\021\021\021\021\021\021\021\021\021\021\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
val s22 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\023\023\023\023\023\023\023\023\023\023\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
val s23 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\023\023\023\023\023\023\023\023\023\023\000\000\000\000\000\000\
\\000\000\000\000\000\024\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
val s24 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\026\026\026\026\026\026\026\026\026\026\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\025\000\
\\000"
val s25 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\026\026\026\026\026\026\026\026\026\026\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
val s27 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\022\000\
\\018\018\018\018\018\018\018\018\018\018\000\000\000\000\000\000\
\\000\000\000\000\000\019\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\028\000\000\000\000\000\000\000\
\\000"
val s28 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\029\029\029\029\029\029\029\029\029\029\000\000\000\000\000\000\
\\000\029\029\029\029\029\029\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\029\029\029\029\029\029\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
val s33 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\034\000\000\000\000\000\000\000\000\
\\034\034\034\034\034\034\034\034\034\034\000\000\000\000\000\000\
\\000\034\034\034\034\034\034\034\034\034\034\034\034\034\034\034\
\\034\034\034\034\034\034\034\034\034\034\034\000\000\000\000\034\
\\000\034\034\034\034\034\034\034\034\034\034\034\034\034\034\034\
\\034\034\034\034\034\034\034\034\034\034\034\000\000\000\000\000\
\\000"
val s40 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\022\000\
\\041\041\041\041\041\041\041\041\041\041\000\000\000\000\000\000\
\\000\000\000\000\000\019\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
val s42 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\022\000\
\\045\045\045\045\045\045\045\045\045\045\000\000\000\000\000\000\
\\000\000\000\000\000\019\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\043\000\000\000\000\000\000\000\
\\000"
val s43 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\044\044\044\044\044\044\044\044\044\044\000\000\000\000\000\000\
\\000\044\044\044\044\044\044\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\044\044\044\044\044\044\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
val s45 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\022\000\
\\045\045\045\045\045\045\045\045\045\045\000\000\000\000\000\000\
\\000\000\000\000\000\019\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
val s46 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\047\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
val s47 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\048\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
val s50 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\016\000\016\016\016\016\000\000\051\016\016\000\016\000\016\
\\000\000\000\000\000\000\000\000\000\000\016\000\016\016\016\016\
\\016\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\016\000\016\000\
\\017\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\016\000\016\000\
\\000"
val s53 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\054\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
val s55 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\059\000\000\000\000\000\000\000\000\
\\058\058\058\058\058\058\058\058\058\058\000\000\000\000\000\000\
\\000\056\056\056\056\056\056\056\056\056\056\056\056\056\056\056\
\\056\056\056\056\056\056\056\056\056\056\056\000\000\000\000\057\
\\000\056\056\056\056\056\056\056\056\056\056\056\056\056\056\056\
\\056\056\056\056\056\056\056\056\056\056\056\000\000\000\000\000\
\\000"
val s56 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\056\000\000\000\000\000\000\000\000\
\\056\056\056\056\056\056\056\056\056\056\000\000\000\000\000\000\
\\000\056\056\056\056\056\056\056\056\056\056\056\056\056\056\056\
\\056\056\056\056\056\056\056\056\056\056\056\000\000\000\000\056\
\\000\056\056\056\056\056\056\056\056\056\056\056\056\056\056\056\
\\056\056\056\056\056\056\056\056\056\056\056\000\000\000\000\000\
\\000"
val s57 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\056\056\056\056\056\056\056\056\056\056\056\056\056\056\056\
\\056\056\056\056\056\056\056\056\056\056\056\000\000\000\000\000\
\\000\056\056\056\056\056\056\056\056\056\056\056\056\056\056\056\
\\056\056\056\056\056\056\056\056\056\056\056\000\000\000\000\000\
\\000"
val s58 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\058\058\058\058\058\058\058\058\058\058\000\000\000\000\000\000\
\\000\056\056\056\056\056\056\056\056\056\056\056\056\056\056\056\
\\056\056\056\056\056\056\056\056\056\056\056\000\000\000\000\000\
\\000\056\056\056\056\056\056\056\056\056\056\056\056\056\056\056\
\\056\056\056\056\056\056\056\056\056\056\056\000\000\000\000\000\
\\000"
val s59 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\058\058\058\058\058\058\058\058\058\058\000\000\000\000\000\000\
\\000\056\056\056\056\056\056\056\056\056\056\056\056\056\056\056\
\\056\056\056\056\056\056\056\056\056\056\056\000\000\000\000\057\
\\000\056\056\056\056\056\056\056\056\056\056\056\056\056\056\056\
\\056\056\056\056\056\056\056\056\056\056\056\000\000\000\000\000\
\\000"
val s60 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\016\000\016\016\016\016\000\000\000\016\016\000\016\000\016\
\\000\000\000\000\000\000\000\000\000\000\016\000\016\016\016\016\
\\016\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\061\016\000\016\000\
\\017\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\016\000\016\000\
\\000"
val s63 =
"\000\000\000\000\000\000\000\000\000\064\000\000\064\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\064\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
val s67 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\068\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
val s69 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\070\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
val s72 =
"\072\072\072\072\072\072\072\072\072\072\000\072\072\072\072\072\
\\072\072\072\072\072\072\072\072\072\072\072\072\072\072\072\072\
\\072\072\000\072\072\072\072\072\072\072\072\072\072\072\072\072\
\\072\072\072\072\072\072\072\072\072\072\072\072\072\072\072\072\
\\072\072\072\072\072\072\072\072\072\072\072\072\072\072\072\072\
\\072\072\072\072\072\072\072\072\072\072\072\072\000\072\072\072\
\\072\072\072\072\072\072\072\072\072\072\072\072\072\072\072\072\
\\072\072\072\072\072\072\072\072\072\072\072\072\072\072\072\072\
\\072"
val s73 =
"\000\000\000\000\000\000\000\000\000\083\084\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\083\000\082\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\079\079\079\079\079\079\079\079\079\079\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\078\000\076\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\075\000\
\\000\000\000\000\074\000\000\000\000\000\000\000\000\000\000\000\
\\000"
val s76 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\077\077\077\077\077\077\077\077\077\077\077\077\077\077\077\077\
\\077\077\077\077\077\077\077\077\077\077\077\077\077\077\077\077\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
val s79 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\080\080\080\080\080\080\080\080\080\080\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
val s80 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\081\081\081\081\081\081\081\081\081\081\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
val s89 =
"\000\000\000\000\000\000\000\000\000\090\000\000\090\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\090\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
val s97 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\098\000\098\098\098\098\000\000\000\098\098\000\098\000\098\
\\000\000\000\000\000\000\000\000\000\000\098\000\098\098\098\098\
\\098\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\098\000\098\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\098\000\098\000\
\\000"
val s99 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\100\000\000\000\000\000\000\000\000\
\\100\100\100\100\100\100\100\100\100\100\000\000\000\000\000\000\
\\000\100\100\100\100\100\100\100\100\100\100\100\100\100\100\100\
\\100\100\100\100\100\100\100\100\100\100\100\000\000\000\000\100\
\\000\100\100\100\100\100\100\100\100\100\100\100\100\100\100\100\
\\100\100\100\100\100\100\100\100\100\100\100\000\000\000\000\000\
\\000"
val s102 =
"\000\000\000\000\000\000\000\000\000\103\000\000\103\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\103\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000"
in Vector.vector
[{fin = [], trans = s0},
{fin = [(N 2)], trans = s1},
{fin = [(N 2)], trans = s1},
{fin = [], trans = s3},
{fin = [], trans = s3},
{fin = [(N 131)], trans = s5},
{fin = [(N 131)], trans = s5},
{fin = [(N 142)], trans = s7},
{fin = [(N 142)], trans = s7},
{fin = [], trans = s9},
{fin = [], trans = s9},
{fin = [(N 182)], trans = s11},
{fin = [(N 182)], trans = s11},
{fin = [(N 113),(N 115)], trans = s0},
{fin = [(N 115)], trans = s0},
{fin = [(N 51),(N 60),(N 115)], trans = s15},
{fin = [(N 51),(N 60)], trans = s16},
{fin = [(N 51)], trans = s17},
{fin = [(N 92)], trans = s18},
{fin = [], trans = s19},
{fin = [], trans = s20},
{fin = [(N 82)], trans = s20},
{fin = [], trans = s22},
{fin = [(N 82)], trans = s23},
{fin = [], trans = s24},
{fin = [], trans = s25},
{fin = [(N 82)], trans = s25},
{fin = [(N 92)], trans = s27},
{fin = [], trans = s28},
{fin = [(N 103)], trans = s28},
{fin = [(N 12),(N 115)], trans = s0},
{fin = [(N 51),(N 60),(N 115)], trans = s16},
{fin = [(N 10),(N 115)], trans = s0},
{fin = [(N 42),(N 115)], trans = s33},
{fin = [(N 42)], trans = s33},
{fin = [(N 51),(N 62),(N 115)], trans = s17},
{fin = [(N 6),(N 115)], trans = s0},
{fin = [(N 19),(N 115)], trans = s0},
{fin = [(N 14),(N 115)], trans = s0},
{fin = [(N 21),(N 115)], trans = s0},
{fin = [(N 85),(N 88),(N 115)], trans = s40},
{fin = [(N 85),(N 88)], trans = s40},
{fin = [(N 88),(N 115)], trans = s42},
{fin = [], trans = s43},
{fin = [(N 97)], trans = s43},
{fin = [(N 88)], trans = s45},
{fin = [(N 27),(N 115)], trans = s46},
{fin = [], trans = s47},
{fin = [(N 31)], trans = s0},
{fin = [(N 8),(N 115)], trans = s0},
{fin = [(N 51),(N 60),(N 115)], trans = s50},
{fin = [(N 111)], trans = s0},
{fin = [(N 25),(N 115)], trans = s0},
{fin = [(N 23),(N 115)], trans = s53},
{fin = [(N 108)], trans = s0},
{fin = [(N 115)], trans = s55},
{fin = [(N 39)], trans = s56},
{fin = [], trans = s57},
{fin = [], trans = s58},
{fin = [], trans = s59},
{fin = [(N 51),(N 60),(N 115)], trans = s60},
{fin = [(N 17)], trans = s0},
{fin = [(N 105),(N 115)], trans = s0},
{fin = [(N 2),(N 115)], trans = s63},
{fin = [(N 2)], trans = s63},
{fin = [(N 4)], trans = s0},
{fin = [(N 125)], trans = s0},
{fin = [(N 125)], trans = s67},
{fin = [(N 123)], trans = s0},
{fin = [(N 125)], trans = s69},
{fin = [(N 118)], trans = s0},
{fin = [(N 120)], trans = s0},
{fin = [(N 131)], trans = s72},
{fin = [(N 169)], trans = s73},
{fin = [(N 149)], trans = s0},
{fin = [(N 152)], trans = s0},
{fin = [], trans = s76},
{fin = [(N 162)], trans = s0},
{fin = [(N 155)], trans = s0},
{fin = [], trans = s79},
{fin = [], trans = s80},
{fin = [(N 167)], trans = s0},
{fin = [(N 158)], trans = s0},
{fin = [(N 137)], trans = s0},
{fin = [(N 134)], trans = s0},
{fin = [(N 127)], trans = s0},
{fin = [(N 129)], trans = s0},
{fin = [(N 146)], trans = s0},
{fin = [(N 144),(N 146)], trans = s0},
{fin = [(N 142),(N 146)], trans = s89},
{fin = [(N 142)], trans = s89},
{fin = [(N 139)], trans = s0},
{fin = [(N 177)], trans = s0},
{fin = [(N 173),(N 177)], trans = s0},
{fin = [(N 171),(N 177)], trans = s0},
{fin = [(N 175)], trans = s0},
{fin = [(N 198)], trans = s0},
{fin = [(N 194),(N 198)], trans = s97},
{fin = [(N 194)], trans = s97},
{fin = [(N 185),(N 198)], trans = s99},
{fin = [(N 185)], trans = s99},
{fin = [(N 196),(N 198)], trans = s0},
{fin = [(N 182),(N 198)], trans = s102},
{fin = [(N 182)], trans = s102},
{fin = [(N 179)], trans = s0}]
end
structure StartStates =
	struct
	datatype yystartstate = STARTSTATE of int

(* start state definitions *)

val A = STARTSTATE 3;
val AQ = STARTSTATE 11;
val F = STARTSTATE 7;
val INITIAL = STARTSTATE 1;
val Q = STARTSTATE 9;
val S = STARTSTATE 5;

end
type result = UserDeclarations.lexresult
	exception LexerError (* raised if illegal leaf action tried *)
	exception Reject	(* for implementing REJECT *)
end

fun makeLexer yyinput = 
let 
	val yyb = ref "\n" 		(* buffer *)
	val yybl = ref 1		(*buffer length *)
	val yybufpos = ref 1		(* location of next character to use *)
	val yygone = ref 1		(* position in file of beginning of buffer *)
	val yydone = ref false		(* eof found yet? *)
	val yybegin = ref 1		(*Current 'start state' for lexer *)

	val YYBEGIN = fn (Internal.StartStates.STARTSTATE x) =>
		 yybegin := x

	val REJECT = fn () => raise Internal.Reject

fun lex (yyarg as ({comLevel,lineNum,err,linePos,charlist,stringstart,brack_stack})) =
let fun continue() : Internal.result = 
  let fun scan (s,AcceptingLeaves : Internal.yyfinstate list list,l,i0) =
	let fun action (i,nil) = raise LexError
	| action (i,nil::l) = action (i-1,l)
	| action (i,(node::acts)::l) =
		case node of
		    Internal.N yyk => 
			(let val yytext = substring(!yyb,i0,i-i0)
			     val yypos = i0+ !yygone
			open UserDeclarations Internal.StartStates
 in (yybufpos := i; case yyk of 

			(* Application actions *)

  10 => (Tokens.LBRACE(yypos,yypos+1))
| 103 => (
		    Tokens.INT0(makeHexInt (op -) (substring(yytext, 3, size(yytext)-3))
		        handle Overflow => (err (yypos,yypos+size yytext)
					      COMPLAIN "integer too large"
					      nullErrorBody;
					    0),
		      yypos, yypos+size yytext))
| 105 => (charlist := [""]; stringstart := yypos;
			YYBEGIN S; continue())
| 108 => (YYBEGIN A; stringstart := yypos; comLevel := 1; continue())
| 111 => (err (yypos,yypos+1) COMPLAIN "unmatched close comment"
		        nullErrorBody;
		    continue())
| 113 => (err (yypos,yypos) COMPLAIN "non-Ascii character"
		        nullErrorBody;
		    continue())
| 115 => (err (yypos,yypos) COMPLAIN "illegal token" nullErrorBody;
		    continue())
| 118 => (inc comLevel; continue())
| 12 => (Tokens.RBRACE(yypos,yypos+1))
| 120 => (inc lineNum; linePos := yypos :: !linePos; continue())
| 123 => (dec comLevel; if !comLevel=0 then YYBEGIN INITIAL else (); continue())
| 125 => (continue())
| 127 => (YYBEGIN INITIAL; Tokens.STRING(makeString charlist,
				!stringstart,yypos+1))
| 129 => (err (!stringstart,yypos) COMPLAIN "unclosed string"
		        nullErrorBody;
		    inc lineNum; linePos := yypos :: !linePos;
		    YYBEGIN INITIAL; Tokens.STRING(makeString charlist,!stringstart,yypos))
| 131 => (addString(charlist,yytext); continue())
| 134 => (inc lineNum; linePos := yypos :: !linePos;
		    YYBEGIN F; continue())
| 137 => (YYBEGIN F; continue())
| 139 => (inc lineNum; linePos := yypos :: !linePos; continue())
| 14 => (Tokens.LBRACKET(yypos,yypos+1))
| 142 => (continue())
| 144 => (YYBEGIN S; stringstart := yypos; continue())
| 146 => (err (!stringstart,yypos) COMPLAIN "unclosed string"
		        nullErrorBody; 
		    YYBEGIN INITIAL; Tokens.STRING(makeString charlist,!stringstart,yypos+1))
| 149 => (addString(charlist,"\t"); continue())
| 152 => (addString(charlist,"\n"); continue())
| 155 => (addString(charlist,"\\"); continue())
| 158 => (addString(charlist,chr(Ascii.dquote)); continue())
| 162 => (addString(charlist,chr(ordof(yytext,2)-ord("@"))); continue())
| 167 => (let val x = ordof(yytext,1)*100
	     +ordof(yytext,2)*10
	     +ordof(yytext,3)
	     -(Ascii.zero*111)
  in (if x>255
      then err (yypos,yypos+4) COMPLAIN "illegal ascii escape" nullErrorBody
      else addString(charlist,chr x);
      continue())
  end)
| 169 => (err (yypos,yypos+1) COMPLAIN "illegal string escape"
		        nullErrorBody; 
		    continue())
| 17 => (Tokens.VECTORSTART(yypos,yypos+1))
| 171 => (YYBEGIN AQ;
                    let val x = makeString charlist
                    in
                    Tokens.OBJL(x,yypos,yypos+(size x))
                    end)
| 173 => ((* a closing quote *)
                    YYBEGIN INITIAL;
                    let val x = makeString charlist
                    in
                    Tokens.ENDQ(x,yypos,yypos+(size x))
                    end)
| 175 => (inc lineNum; addString(charlist,"\n"); continue())
| 177 => (addString(charlist,yytext); continue())
| 179 => (inc lineNum; continue())
| 182 => (continue())
| 185 => (YYBEGIN Q; 
                    let val hash = StrgHash.hashString yytext
                    in
                    Tokens.AQID(FastSymbol.rawSymbol(hash,yytext),
				yypos,yypos+(size yytext))
                    end)
| 19 => (Tokens.RBRACKET(yypos,yypos+1))
| 194 => (YYBEGIN Q; 
                    let val hash = StrgHash.hashString yytext
                    in
                    Tokens.AQID(FastSymbol.rawSymbol(hash,yytext),
				yypos,yypos+(size yytext))
                    end)
| 196 => (YYBEGIN INITIAL;
                    brack_stack := ((ref 1)::(!brack_stack));
                    Tokens.LPAREN(yypos,yypos+1))
| 198 => (err (yypos,yypos+1) COMPLAIN
		       ("ml lexer: bad character after antiquote "^yytext)
		       nullErrorBody;
                    Tokens.AQID(FastSymbol.rawSymbol(0,""),yypos,yypos))
| 2 => (continue())
| 21 => (Tokens.SEMICOLON(yypos,yypos+1))
| 23 => (if (null(!brack_stack))
                    then ()
                    else inc (hd (!brack_stack));
                    Tokens.LPAREN(yypos,yypos+1))
| 25 => (if (null(!brack_stack))
                    then ()
                    else if (!(hd (!brack_stack)) = 1)
                         then ( brack_stack := tl (!brack_stack);
                                charlist := [];
                                YYBEGIN Q)
                         else dec (hd (!brack_stack));
                    Tokens.RPAREN(yypos,yypos+1))
| 27 => (Tokens.DOT(yypos,yypos+1))
| 31 => (Tokens.DOTDOTDOT(yypos,yypos+3))
| 39 => (TokTable.checkTyvar(yytext,yypos))
| 4 => (inc lineNum; linePos := yypos :: !linePos; continue())
| 42 => (TokTable.checkToken(yytext,yypos))
| 51 => (if (!System.Control.quotation)
                            then if (has_quote yytext)
                                 then REJECT()
                                 else TokTable.checkToken(yytext,yypos)
                            else TokTable.checkToken(yytext,yypos))
| 6 => (Tokens.WILD(yypos,yypos+1))
| 60 => (TokTable.checkToken(yytext,yypos))
| 62 => (if (!System.Control.quotation)
                            then (YYBEGIN Q;
                                  charlist := [];
                                  Tokens.BEGINQ(yypos,yypos+1))
                            else (err(yypos, yypos+1)
                                     COMPLAIN "quotation implementation error"
				     nullErrorBody;
                                  Tokens.BEGINQ(yypos,yypos+1)))
| 8 => (Tokens.COMMA(yypos,yypos+1))
| 82 => (Tokens.REAL(yytext,yypos,yypos+size yytext))
| 85 => (Tokens.INT(makeInt (op +) yytext
		    handle Overflow => (err (yypos,yypos+size yytext)
					  COMPLAIN "integer too large"
					  nullErrorBody;
				        1),
			yypos,yypos+size yytext))
| 88 => (Tokens.INT0(makeInt (op +) yytext
		    handle Overflow => (err (yypos,yypos+size yytext)
					  COMPLAIN "integer too large"
					  nullErrorBody; 0),
			yypos,yypos+size yytext))
| 92 => (Tokens.INT0(makeInt (op -)
					(substring(yytext,1,size(yytext)-1))
		    handle Overflow => (err (yypos,yypos+size yytext)
					 COMPLAIN "integer too large"
					 nullErrorBody;
				        0),
			yypos,yypos+size yytext))
| 97 => (
		    Tokens.INT0(makeHexInt (op +) (substring(yytext, 2, size(yytext)-2))
		        handle Overflow => (err (yypos,yypos+size yytext)
					      COMPLAIN "integer too large"
					      nullErrorBody;
					    0),
		      yypos, yypos+size yytext))
| _ => raise Internal.LexerError

		) end handle Internal.Reject => action(i,acts::l))

	val {fin,trans} = Vector.sub(Internal.tab, s)
	val NewAcceptingLeaves = fin::AcceptingLeaves
	in if l = !yybl then
	     if trans = #trans(Vector.sub(Internal.tab,0))
	       then action(l,NewAcceptingLeaves
) else	    let val newchars= if !yydone then "" else yyinput 1024
	    in if (size newchars)=0
		  then (yydone := true;
		        if (l=i0) then UserDeclarations.eof yyarg
		                  else action(l,NewAcceptingLeaves))
		  else (if i0=l then yyb := newchars
		     else yyb := substring(!yyb,i0,l-i0)^newchars;
		     yygone := !yygone+i0;
		     yybl := size (!yyb);
		     scan (s,AcceptingLeaves,l-i0,0))
	    end
	  else let val NewChar = ordof(!yyb,l)
		val NewState = if NewChar<128 then ordof(trans,NewChar) else ordof(trans,128)
		in if NewState=0 then action(l,NewAcceptingLeaves)
		else scan(NewState,NewAcceptingLeaves,l+1,i0)
	end
	end
(*
	val start= if substring(!yyb,!yybufpos-1,1)="\n"
then !yybegin+1 else !yybegin
*)
	in scan(!yybegin (* start *),nil,!yybufpos,!yybufpos)
    end
in continue end
  in lex
  end
end
