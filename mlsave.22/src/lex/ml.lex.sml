structure Mlex =
   struct
    structure UserDeclarations =
      struct
open ErrorMsg Symbols
type lexresult = Token.token
val eof = fn () => Token.EOF
val comLevel = ref 0
val charlist = ref (nil : string list)
fun addString (s:string) = charlist := s :: (!charlist)
fun makeInt (s : string) =
    let val limit = length s
	fun loop (i,n) = if i = limit
			 then n
			 else loop (i+1,n*10 + ordof(s,i)-Ascii.zero)
    in loop (0,0) handle Overflow => (complain "integer too large"; 0)
    end

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
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"
val s1 =
"\009\009\009\009\009\009\009\009\009\049\051\009\009\009\009\009\
\\009\009\009\009\009\009\009\009\009\009\009\009\009\009\009\009\
\\049\027\048\047\027\027\027\045\043\042\041\027\040\027\037\027\
\\035\035\035\035\035\035\035\035\035\035\034\033\027\032\027\031\
\\027\024\024\024\024\024\024\024\024\024\024\024\024\024\024\024\
\\024\024\024\024\024\024\024\024\024\024\024\030\027\029\027\028\
\\027\024\024\024\024\024\024\024\024\024\024\024\024\024\024\024\
\\024\024\024\024\024\024\024\024\024\024\024\023\022\021\010\009"
val s3 =
"\052\052\052\052\052\052\052\052\052\052\059\052\052\052\052\052\
\\052\052\052\052\052\052\052\052\052\052\052\052\052\052\052\052\
\\052\052\052\052\052\052\052\052\057\056\054\052\052\052\052\052\
\\052\052\052\052\052\052\052\052\052\052\052\052\052\052\052\052\
\\052\052\052\052\052\052\052\052\052\052\052\052\052\052\052\052\
\\052\052\052\052\052\052\052\052\052\052\052\052\052\052\052\052\
\\052\052\052\052\052\052\052\052\052\052\052\052\052\052\052\052\
\\052\052\052\052\052\052\052\052\052\052\052\052\052\052\052\052"
val s5 =
"\060\060\060\060\060\060\060\060\060\060\076\060\060\060\060\060\
\\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060\
\\060\060\075\060\060\060\060\060\060\060\060\060\060\060\060\060\
\\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060\
\\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060\
\\060\060\060\060\060\060\060\060\060\060\060\060\061\060\060\060\
\\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060\
\\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060"
val s7 =
"\077\077\077\077\077\077\077\077\077\079\081\077\077\077\077\077\
\\077\077\077\077\077\077\077\077\077\077\077\077\077\077\077\077\
\\079\077\077\077\077\077\077\077\077\077\077\077\077\077\077\077\
\\077\077\077\077\077\077\077\077\077\077\077\077\077\077\077\077\
\\077\077\077\077\077\077\077\077\077\077\077\077\077\077\077\077\
\\077\077\077\077\077\077\077\077\077\077\077\077\078\077\077\077\
\\077\077\077\077\077\077\077\077\077\077\077\077\077\077\077\077\
\\077\077\077\077\077\077\077\077\077\077\077\077\077\077\077\077"
val s10 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\011\000\011\011\011\011\000\000\000\011\011\000\011\000\011\
\\012\012\012\012\012\012\012\012\012\012\011\000\011\011\011\011\
\\011\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\011\000\011\000\
\\011\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\011\000\011\000"
val s11 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\011\000\011\011\011\011\000\000\000\011\011\000\011\000\011\
\\000\000\000\000\000\000\000\000\000\000\011\000\011\011\011\011\
\\011\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\011\000\011\000\
\\011\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\011\000\011\000"
val s12 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\016\000\
\\012\012\012\012\012\012\012\012\012\012\000\000\000\000\000\000\
\\000\000\000\000\000\013\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"
val s13 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\015\015\015\015\015\015\015\015\015\015\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\014\000"
val s14 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\015\015\015\015\015\015\015\015\015\015\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"
val s16 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\017\017\017\017\017\017\017\017\017\017\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"
val s17 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\017\017\017\017\017\017\017\017\017\017\000\000\000\000\000\000\
\\000\000\000\000\000\018\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"
val s18 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\020\020\020\020\020\020\020\020\020\020\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\019\000"
val s19 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\020\020\020\020\020\020\020\020\020\020\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"
val s24 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\025\000\000\000\000\000\000\026\000\
\\025\025\025\025\025\025\025\025\025\025\000\000\000\000\000\000\
\\000\025\025\025\025\025\025\025\025\025\025\025\025\025\025\025\
\\025\025\025\025\025\025\025\025\025\025\025\000\000\000\000\025\
\\000\025\025\025\025\025\025\025\025\025\025\025\025\025\025\025\
\\025\025\025\025\025\025\025\025\025\025\025\000\000\000\000\000"
val s35 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\016\000\
\\036\036\036\036\036\036\036\036\036\036\000\000\000\000\000\000\
\\000\000\000\000\000\013\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"
val s37 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\038\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"
val s38 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\039\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"
val s43 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\044\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"
val s45 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\046\000\000\000\000\000\000\026\000\
\\046\046\046\046\046\046\046\046\046\046\000\000\000\000\000\000\
\\000\046\046\046\046\046\046\046\046\046\046\046\046\046\046\046\
\\046\046\046\046\046\046\046\046\046\046\046\000\000\000\000\046\
\\000\046\046\046\046\046\046\046\046\046\046\046\046\046\046\046\
\\046\046\046\046\046\046\046\046\046\046\046\000\000\000\000\000"
val s49 =
"\000\000\000\000\000\000\000\000\000\050\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\050\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"
val s52 =
"\053\053\053\053\053\053\053\053\053\053\000\053\053\053\053\053\
\\053\053\053\053\053\053\053\053\053\053\053\053\053\053\053\053\
\\053\053\053\053\053\053\053\053\000\000\000\053\053\053\053\053\
\\053\053\053\053\053\053\053\053\053\053\053\053\053\053\053\053\
\\053\053\053\053\053\053\053\053\053\053\053\053\053\053\053\053\
\\053\053\053\053\053\053\053\053\053\053\053\053\053\053\053\053\
\\053\053\053\053\053\053\053\053\053\053\053\053\053\053\053\053\
\\053\053\053\053\053\053\053\053\053\053\053\053\053\053\053\053"
val s54 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\055\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"
val s57 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\058\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"
val s60 =
"\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060\
\\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060\
\\060\060\000\060\060\060\060\060\060\060\060\060\060\060\060\060\
\\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060\
\\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060\
\\060\060\060\060\060\060\060\060\060\060\060\060\000\060\060\060\
\\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060\
\\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060\060"
val s61 =
"\062\062\062\062\062\062\062\062\062\073\074\062\062\062\062\062\
\\062\062\062\062\062\062\062\062\062\062\062\062\062\062\062\062\
\\073\062\072\062\062\062\062\062\062\062\062\062\062\062\062\062\
\\069\069\069\069\069\069\069\069\069\069\062\062\062\062\062\062\
\\062\062\062\062\062\062\062\062\062\062\062\062\062\062\062\062\
\\062\062\062\062\062\062\062\062\062\062\062\062\068\062\065\062\
\\062\062\062\062\062\062\062\062\062\062\062\062\062\062\064\062\
\\062\062\062\062\063\062\062\062\062\062\062\062\062\062\062\062"
val s65 =
"\066\066\066\066\066\066\066\066\066\066\000\066\066\066\066\066\
\\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066\
\\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066\
\\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066\
\\067\067\067\067\067\067\067\067\067\067\067\067\067\067\067\067\
\\067\067\067\067\067\067\067\067\067\067\067\067\067\067\067\067\
\\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066\
\\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066\066"
val s69 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\070\070\070\070\070\070\070\070\070\070\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"
val s70 =
"\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\071\071\071\071\071\071\071\071\071\071\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"
val s79 =
"\000\000\000\000\000\000\000\000\000\080\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\080\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"
in arrayoflist
[{fin = [], trans = s0},
{fin = [(N 1)], trans = s1},
{fin = [(N 1)], trans = s1},
{fin = [(N 96)], trans = s3},
{fin = [(N 96)], trans = s3},
{fin = [(N 105)], trans = s5},
{fin = [(N 105)], trans = s5},
{fin = [], trans = s7},
{fin = [], trans = s7},
{fin = [(N 89)], trans = s0},
{fin = [(N 55),(N 89)], trans = s10},
{fin = [(N 55)], trans = s11},
{fin = [(N 82)], trans = s12},
{fin = [], trans = s13},
{fin = [], trans = s14},
{fin = [(N 75)], trans = s14},
{fin = [], trans = s16},
{fin = [(N 75)], trans = s17},
{fin = [], trans = s18},
{fin = [], trans = s19},
{fin = [(N 75)], trans = s19},
{fin = [(N 23),(N 89)], trans = s0},
{fin = [(N 7),(N 55),(N 89)], trans = s11},
{fin = [(N 21),(N 89)], trans = s0},
{fin = [(N 55),(N 89)], trans = s24},
{fin = [(N 55)], trans = s24},
{fin = [(N 37)], trans = s0},
{fin = [(N 55),(N 89)], trans = s11},
{fin = [(N 13),(N 55),(N 89)], trans = s24},
{fin = [(N 27),(N 89)], trans = s0},
{fin = [(N 25),(N 89)], trans = s0},
{fin = [(N 15),(N 55),(N 89)], trans = s11},
{fin = [(N 11),(N 55),(N 89)], trans = s11},
{fin = [(N 29),(N 89)], trans = s0},
{fin = [(N 9),(N 55),(N 89)], trans = s11},
{fin = [(N 78),(N 89)], trans = s35},
{fin = [(N 78)], trans = s35},
{fin = [(N 89)], trans = s37},
{fin = [], trans = s38},
{fin = [(N 41)], trans = s0},
{fin = [(N 19),(N 89)], trans = s0},
{fin = [(N 5),(N 55),(N 89)], trans = s11},
{fin = [(N 33),(N 89)], trans = s0},
{fin = [(N 31),(N 89)], trans = s43},
{fin = [(N 87)], trans = s0},
{fin = [(N 44),(N 55),(N 89)], trans = s45},
{fin = [(N 44),(N 55)], trans = s45},
{fin = [(N 17),(N 55),(N 89)], trans = s11},
{fin = [(N 84),(N 89)], trans = s0},
{fin = [(N 1),(N 89)], trans = s49},
{fin = [(N 1)], trans = s49},
{fin = [(N 3)], trans = s0},
{fin = [(N 96),(N 101)], trans = s52},
{fin = [(N 96)], trans = s52},
{fin = [(N 101)], trans = s54},
{fin = [(N 99)], trans = s0},
{fin = [(N 101)], trans = s0},
{fin = [(N 101)], trans = s57},
{fin = [(N 92)], trans = s0},
{fin = [(N 94)], trans = s0},
{fin = [(N 105)], trans = s60},
{fin = [(N 150),(N 153)], trans = s61},
{fin = [(N 135)], trans = s0},
{fin = [(N 123),(N 135)], trans = s0},
{fin = [(N 126),(N 135)], trans = s0},
{fin = [(N 135)], trans = s65},
{fin = [(N 145)], trans = s0},
{fin = [(N 141),(N 145)], trans = s0},
{fin = [(N 129),(N 135)], trans = s0},
{fin = [(N 135),(N 150),(N 153)], trans = s69},
{fin = [(N 150)], trans = s70},
{fin = [(N 150)], trans = s0},
{fin = [(N 132),(N 135)], trans = s0},
{fin = [(N 111),(N 135)], trans = s0},
{fin = [(N 108)], trans = s0},
{fin = [(N 103)], trans = s0},
{fin = [(N 105),(N 137)], trans = s60},
{fin = [(N 120)], trans = s0},
{fin = [(N 118),(N 120)], trans = s0},
{fin = [(N 116),(N 120)], trans = s79},
{fin = [(N 116)], trans = s79},
{fin = [(N 113)], trans = s0}]
end
structure StartStates =
	struct
	datatype yystartstate = STARTSTATE of int

(* start state definitions *)

val A = STARTSTATE 3;
val F = STARTSTATE 7;
val INITIAL = STARTSTATE 1;
val S = STARTSTATE 5;

end
type result = UserDeclarations.lexresult
	exception LexerError (* raised if illegal leaf action tried *)
end

fun makeLexer yyinput : (unit -> Internal.result) = 
let 
	val yyb = ref "\n" 		(* buffer *)
	val yybl = ref 1		(*buffer length *)
	val yypos = ref 1		(* location of next character to use *)
	val yydone = ref false		(* eof found yet? *)
	val yybegin = ref 1		(*Current 'start state' for lexer *)

	val YYBEGIN = fn (Internal.StartStates.STARTSTATE x) =>
		 yybegin := x

fun lex () : Internal.result =
  let fun scan (s,AcceptingLeaves : Internal.yyfinstate list list,l,i0) =
	let fun action (i,nil) = raise LexError
	| action (i,nil::l) = action (i-1,l)
	| action (i,(node::acts)::l) =
		case node of
		    Internal.N yyk => 
			(let val yytext = substring(!yyb,i0,i-i0)
			open UserDeclarations Internal.StartStates
 in (yypos := i; case yyk of 

			(* Application actions *)

  1 => (lex())
| 101 => (lex())
| 103 => (YYBEGIN INITIAL; Token.STRING(implode(rev(!charlist))))
| 105 => (addString yytext; lex())
| 108 => (inc lineNum; YYBEGIN F; lex())
| 11 => (Token.EQUAL)
| 111 => (YYBEGIN F; lex())
| 113 => (inc lineNum; lex())
| 116 => (lex())
| 118 => (YYBEGIN S; lex())
| 120 => (complain "unclosed string"; YYBEGIN INITIAL; Token.STRING "")
| 123 => (addString "\t"; lex())
| 126 => (addString "\n"; lex())
| 129 => (addString "\\"; lex())
| 13 => (Token.WILD)
| 132 => (addString "\""; lex())
| 135 => (complain "illegal backslash escape"; lex())
| 137 => (complain "unclosed string"; YYBEGIN INITIAL; Token.STRING "")
| 141 => (addString(chr(ordof(yytext,1)-ord("@"))); lex())
| 145 => (complain "illegal ^ escape"; lex())
| 15 => (Token.QUERY)
| 150 => (let val x = ordof(yytext,1)*100
	     +ordof(yytext,2)*10
	     +ordof(yytext,3)
	     -(Ascii.zero*111)
  in (if x>255
      then complain ("illegal ascii escape '"^yytext^"'")
      else addString (chr x);
      lex())
  end)
| 153 => (complain "illegal string escape"; lex())
| 17 => (Token.HASH)
| 19 => (Token.COMMA)
| 21 => (Token.LBRACE)
| 23 => (Token.RBRACE)
| 25 => (Token.LBRACKET)
| 27 => (Token.RBRACKET)
| 29 => (Token.SEMICOLON)
| 3 => (inc lineNum; lex())
| 31 => (Token.LPAREN)
| 33 => (Token.RPAREN)
| 37 => (Token.IDDOT (stringToSymbol(substring(yytext,0,length(yytext)-1))))
| 41 => (Token.DOTDOTDOT)
| 44 => (Token.TYVAR(stringToSymbol yytext))
| 5 => (Token.ASTERISK)
| 55 => (lexClass(stringToSymbol yytext))
| 7 => (Token.BAR)
| 75 => (Token.REAL yytext)
| 78 => (Token.INT(makeInt yytext))
| 82 => (Token.INT(~(makeInt(substring(yytext,1,length(yytext)-1)))))
| 84 => (charlist := nil; YYBEGIN S; lex())
| 87 => (YYBEGIN A; inc comLevel; lex())
| 89 => (complain("illegal character"); lex())
| 9 => (Token.COLON)
| 92 => (inc comLevel; lex())
| 94 => (inc lineNum; lex())
| 96 => (lex())
| 99 => (dec comLevel; if !comLevel=0 then YYBEGIN INITIAL else (); lex())
| _ => raise Internal.LexerError

		) end )

	val {fin,trans} = Internal.tab sub s
	val NewAcceptingLeaves = fin::AcceptingLeaves
	in if l = !yybl then
	    let val newchars= if !yydone then "" else yyinput 2048
	    in if (length newchars)=0
		  then (yydone := true;
		        if (l=i0) then UserDeclarations.eof()
		                  else action(l,NewAcceptingLeaves))
		  else (if i0=l then yyb := newchars
		     else yyb := substring(!yyb,i0,l-i0)^newchars;
		     yybl := length (!yyb);
		     scan (s,AcceptingLeaves,l-i0,0))
	    end
	  else let val NewChar = ordof(!yyb,l)
		val NewState = ordof(trans,NewChar)
		in if NewState=0 then action(l,NewAcceptingLeaves)
		else scan(NewState,NewAcceptingLeaves,l+1,i0)
	end
	end
(*
	val start= if substring(!yyb,!yypos-1,1)="\n"
then !yybegin+1 else !yybegin
*)
	in scan(!yybegin (* start *),nil,!yypos,!yypos)
    end
  in lex
  end
end
