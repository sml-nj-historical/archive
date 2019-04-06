(* notes:
     OFFSET should not be generated by this module
     RECORD fields should contain only empty paths (pure variables)
*)

(* xgrep '[^a-z]n[^a-z]' cps/convert.sml *)
structure Convert = 
struct

open CPS
fun sublist test =
  let fun subl(a::r) = if test a then a::(subl r) else subl r
        | subl nil = nil
  in  subl
  end


local open Lambda Basics
in
  fun translatepath [v] = VAR v
    | translatepath (x::p) = SELECT(x,translatepath p)
    | translatepath nil = ErrorMsg.impossible "convert.translatepath nil"

  fun isboxedRep(CONSTANT _) = false
    | isboxedRep(TRANSU) = false
    | isboxedRep(_) = true

  fun isboxed (DATAcon(DATACON{rep,...})) = isboxedRep(rep)
    | isboxed (REALcon _) = true
    | isboxed (STRINGcon s) = (length s <> 1)
    | isboxed _ = false
end

val mkLvar = Access.mkLvar
fun mk f = f (mkLvar())

val sortcases = Sort.sort (fn ((i:int,_),(j,_)) => i>j)

structure P = 
struct
   fun position(s:string) =
       let fun find(s'::rest,n) = 
	         if s = s' then n else find(rest,n+1)
        in find(Prim.inLineNames,0)
       end

local val a = array(length Prim.inLineNames,(0,0,0))
      fun set v s = update(a, position s, v)
      val _ = app (set (1,0,2))
		    ["boxed"]
      val _ = app (set (2,0,2))
		    ["<", "<=", ">", ">=","ieql","ineq",
		       "feql","fge","fgt","fle","flt","fneq"]
      val _ = app (set (3,0,2))
		    ["sceql"]
      val _ = app (set (0,1,1))
		    ["gethdlr"]
      val _ = app (set (2,1,1))
		    ["*",  "+",  "-", "div","fadd","fdiv","fmul","fsub",
			"subscript","ordof"]
      val _ = app (set (1,1,1))
		    ["!","alength","create","cast","fneg","makeref",
		 	"slength","~"]
      val _ = app (set (1,0,1))
		    ["sethdlr"]
      val _ = app (set (2,0,1))
		    [":=","unboxedassign"]
      val _ = app (set (3,0,1))
		    [	"store", "unboxedupdate", "update"]
      val _ = app (set (0,0,0))  (* bogus ops *)
		     ["=","<>"]
 in fun calling i = a sub i
end

       val op - = position "-"
       val op > = position ">"
       val op < = position "<"
       val boxed = position "boxed"
       val ineq = position "ineq"
       val fneq = position "fneq"
       val sceql = position "sceql"
       val slength = position "slength"
       val gethdlr = position "gethdlr"
       val sethdlr = position "sethdlr"
end

  fun nthcdr(l, 0) = l 
    | nthcdr(a::r, n) = nthcdr(r, n-1)
    | nthcdr _ = ErrorMsg.impossible "nthcdr in convert"

  fun count test =
    let fun subl(a::r) = if test a then 1+(subl r) else subl r
          | subl nil = 0
    in  subl
    end

fun convert lexp =
let
    local open Intmap
	  val m : const intmap = new Ctable
	  val enter = add m
     in fun bindconst(c,cont) = mk(fn v => (enter(v,c); cont v))
	val ctable = m
    end

    local open Intmap
	  exception Rename
	  val m : lvar intmap = new Rename
	  val rename = map m
     in fun ren v = rename v handle Rename => v
	val newname = add m
    end

    fun switch1(e : lvar, cases : (int*cexp) list, d : lvar, (lo,hi)) =
      let val delta = 2
	  fun collapse (l as (li,ui,ni,xi)::(lj,uj,nj,xj)::r ) =
			if ((ni+nj) * delta > ui-lj) 
			    then collapse((lj,ui,ni+nj,xj)::r)
			    else l
	    | collapse l = l
	  fun f (z, x as (i,_)::r) = f(collapse((i,i,1,x)::z), r)
	    | f (z, nil) = z
	  fun tackon (stuff as (l,u,n,x)::r) = 
		    if n*delta > u-l andalso n>4 andalso hi>u
			then tackon((l,u+1,n+1,x@[(u+1,APP(d,nil))])::r)
			else stuff
	  fun separate((z as (l,u,n,x))::r) =
		if n<4 andalso n>1 
		    then let val ix as (i,_) = nth(x, (n-1))
			  in (i,i,1,[ix])::separate((l,l,n-1,x)::r)
			 end
		    else z :: separate r
	    | separate nil = nil
	  val chunks = rev (separate (tackon (f (nil,cases))))
	  fun g(1,(l,h,1,(i,b)::_)::_,(lo,hi)) = 
		if lo=i andalso hi=i then b
		    else bindconst(INTconst i, fn i' =>
			  PRIMOP(P.ineq,[e, i'], nil, [APP(d,nil), b]))
	    | g(1,(l,h,n,x)::_,(lo,hi)) =
		let fun f(0,_,_) = nil
		      | f(n,i,l as (j,b)::r) =
			   if i+lo = j then b::f(n-1,i+1,r)
				       else (APP(d,nil))::f(n,i+1,l)
	              | f _ = ErrorMsg.impossible "convert.284"  
		    val list = f(n,0,x)
		    val body = if lo=0 then SWITCH(e,list)
			       else bindconst(INTconst lo, fn lo' =>
				  mk(fn e' =>
				      PRIMOP(P.-,[e, lo'], [e'], 
					       [SWITCH(e', list)])))
		    val a = if (lo<l)
			     then bindconst(INTconst l, fn l' =>
				   PRIMOP(P.<,[e, l'], nil, [APP(d,nil), body]))
			     else body
		    val b = if (hi > h)
			     then bindconst(INTconst h, fn h' =>
				   PRIMOP(P.>,[e, h'], nil, [APP(d,nil), a]))
			     else a
		 in b
		end
	    | g(n,cases,(lo,hi)) =
	       let val n2 = n div 2
		   val c2 as (l,_,_,_)::r = nthcdr(cases, n2)
		in bindconst(INTconst l, fn l' =>
			PRIMOP(P.<,[e,l'],nil, [g(n2,cases,(lo,l-1)),
					        g(n-n2,c2,(l,hi))]))
	       end
       in g (length chunks, chunks, (lo, hi))
      end

    fun switch(e, l, d, inrange) =
     let val len = List.length l
	 val d' = case d of SOME d' => d' | NONE => mkLvar()
	 fun ifelse nil = APP(d',nil)
	   | ifelse ((i,b)::r) = 
		bindconst(INTconst i, fn v => 
			PRIMOP(P.ineq,[v, e], nil, [ifelse r, b]))
	 fun ifelseN [(i,b)] = b
	   | ifelseN ((i,b)::r) = 
		bindconst(INTconst i, fn v => 
		    PRIMOP(P.ineq,[v, e], nil, [ifelseN r, b]))
	   | ifelseN _ = ErrorMsg.impossible "convert.224"  
	 val l = sortcases l
	in case (len<4, inrange)
	  of (true, NONE) => ifelse l
	   | (true, SOME n) =>  if n+1=len then ifelseN l else ifelse l
	   | (false, NONE) =>
		 let fun last [x] = x | last (_::r) = last r
			| last _ = ErrorMsg.impossible "convert.227"
		     val (hi,_) = last l and (low,_)::r = l
		  in bindconst(INTconst low, fn low' =>
		      bindconst(INTconst hi, fn hi' =>
		      PRIMOP(P.>,[low', e], nil, [APP(d',[]), 
			 PRIMOP(P.<,[hi', e], nil, [APP(d',[]),
			      switch1(e, l, d', (low,hi))])])))
		 end
	   | (false, SOME n) => switch1(e, l, d', (0,n))
      end



    val zero = bindconst(INTconst 0, fn x => x)
    val one =  bindconst(INTconst 1, fn x => x)

    fun convlist (el,c) =
      let fun f(le::r, vl) = conv(le, fn v => f(r,v::vl))
	    | f(nil, vl) = c (rev vl)
       in f (el,nil)
      end

     and getargs(1,a,g) = conv(a, fn z => g[z])
       | getargs(n,Lambda.RECORD l,g) = convlist(l,g)
       | getargs(n, a, g) = conv(a,  fn v =>
			     let fun f (j,wl) = if j=n
				      then g(rev wl)
				      else mk(fn w => SELECT(j,v,w,f(j+1,w::wl)))
			      in f(0,nil)
			     end)

    and conv (le, c) =
     case le
      of Lambda.APP(Lambda.SELECT(i, Lambda.VAR 0), a) =>
	  (case P.calling i
	    of (n,1,1) => 
		getargs(n,a, fn vl =>
		     mk(fn w => PRIMOP(i, vl, [w], [c w])))
	     | (n,0,1) =>
		 getargs(n,a, fn vl => PRIMOP(i, vl, nil, [c zero]))
             | (n,0,2) => getargs(n,a,
			fn vl => mk(fn cv => mk (fn v => 
			  FIX([(cv,[v],c v)],
			    PRIMOP(i, vl, [],
			    [APP(cv,[one]),APP(cv,[zero])])))))
	     |  (a,b,c) => (print "convert.332: "; print i; print " ";
		            app print [a,b,c]; print " ";
			    print (nth(Prim.inLineNames,i)); print "\n";
			    ErrorMsg.impossible "convert.332"))
   | Lambda.SELECT(i, Lambda.VAR 0) =>
	mk(fn v => conv(Lambda.FN (v, Lambda.APP(le, Lambda.VAR v)), c))
   | Lambda.VAR v => c (ren v)
   | Lambda.APP(Lambda.FN(v,e),a) =>
 	    conv(a, fn w => (newname(v,w);Access.sameName(v,w);
			    conv(e, c)))
   | Lambda.FN (v,e) => mk(fn f => mk(fn w => 
			 FIX([(f,[v,w],conv(e, fn z => APP(w,[z])))], c f)))
   | Lambda.APP(f, a as Lambda.RECORD _) =>
        conv(f, fn vf => mk(fn fc => mk(fn x =>
	    FIX([(fc,[x],c x)], conv(a, fn va => APP(vf,[va,fc]))))))
   | Lambda.APP (f,a) => 
	conv(f, fn vf => conv(a, fn va =>
	   mk(fn fc => mk(fn x => FIX([(fc,[x],c x)],APP(vf,[va,fc]))))))
   | Lambda.FIX (fl, el, body) =>
      let fun g(f::fl, Lambda.FN(v,b)::el) =
	        mk(fn w => (f,[v,w], conv(b, fn z => APP(w,[z])))) :: g(fl,el)
            | g(nil,nil) = nil
       in FIX(g(fl,el), conv(body,c))
      end
   | Lambda.INT i => bindconst(INTconst i, c)
   | Lambda.REAL i => bindconst(REALconst i, c)
   | Lambda.STRING i => (case length i
			  of 1 => bindconst(INTconst(ord i),c)
			   | _ => bindconst(STRINGconst i, c))
   | Lambda.RECORD nil => c zero
   | Lambda.RECORD l => convlist(l, fn vl => mk(fn x => RECORD(recordpath vl, x, c x)))
   | Lambda.SELECT(i, e) => mk(fn w => conv(e, fn v => SELECT(i, v, w, c w)))
   | Lambda.SWITCH(e,l as (Lambda.DATAcon(Basics.DATACON{
			    rep=Basics.VARIABLE _,...}), _)::_, SOME d) =>
      conv(Lambda.SELECT(1,e), fn w =>
	let val cf = mkLvar() and vf = mkLvar()
	    fun g((Lambda.DATAcon(Basics.DATACON{
			    rep=Basics.VARIABLE(Access.PATH p),const=true,...}), x)::r) =
		    conv(translatepath(1::p), fn v =>
			        PRIMOP(P.ineq, [w,v], [],
					 [g r, conv(x, fn z => APP(cf,[z]))]))
	      | g((Lambda.DATAcon(Basics.DATACON{
			    rep=Basics.VARIABLE(Access.PATH p),...}), x)::r) =
		    conv(translatepath p, fn v =>
			        PRIMOP(P.ineq, [w,v], [],
					 [g r, conv(x, fn z => APP(cf,[z]))]))
	      | g nil = conv(d, fn z => APP(cf,[z]))
	      | g _ = ErrorMsg.impossible "convert.21"
	 in FIX([(cf, [vf], c vf)], g l)
	end)
   | Lambda.SWITCH(e,l as (Lambda.REALcon _, _)::_, SOME d) =>
      conv(e, fn w =>
	let val cf = mkLvar() and vf = mkLvar()
	    fun g((Lambda.REALcon rval, x)::r) =
		bindconst(REALconst rval, fn v => 
		       PRIMOP(P.fneq, [w,v],[], 
				    [g r, conv(x,fn z => APP(cf,[z]))]))
	      | g nil = conv(d, fn z => APP(cf,[z]))
	      |  g _ = ErrorMsg.impossible "convert.81"
	 in FIX([(cf, [vf], c vf)], g l)
	end)
   | Lambda.SWITCH(e,l as (Lambda.INTcon _, _)::_, SOME d) =>
      conv(e, fn w =>
	let val cf = mkLvar() and vf = mkLvar() and df = mkLvar()
	    fun g (Lambda.INTcon j, a) = (j,conv(a, fn z => APP(cf,[z])))
	      |  g _ = ErrorMsg.impossible "convert.14"
	 in FIX([(cf, [vf], c vf),
		 (df, [], conv(d, fn z => APP(cf,[z])))],
	        switch(w, map g l, SOME df, NONE))
        end)
   | Lambda.SWITCH(e,l as (Lambda.STRINGcon _, _)::_, SOME d) =>
     conv(e, fn w =>
	let val cf = mkLvar() and vf = mkLvar() and df = mkLvar()
	    val cont = fn z => APP(cf,[z])
            fun isboxed (Lambda.STRINGcon s, _) = length s <> 1
	      | isboxed _ = ErrorMsg.impossible "convert.42"
	    val b = sublist isboxed l
	    val u = sublist (not o isboxed) l
            val vd = mkLvar()
	    fun g(Lambda.STRINGcon j, e) = (ord j, conv(e,cont))
	      |  g _ = ErrorMsg.impossible "convert.26"
            val genu = switch(w, map g u, SOME df, NONE)
	    fun genb nil = APP(df,[])
	      | genb cases = 
		let val len1 = mkLvar()
		    fun g((Lambda.STRINGcon s, x)::r) =
	              mk(fn k =>
	                FIX([(k,[], g r)],
	         	 bindconst(STRINGconst s, fn v =>
			  bindconst(INTconst(length s), fn len0 =>
			   bindconst(INTconst((length s + 3) div 4 - 1), fn len0' =>
				PRIMOP(P.ineq,[len0,len1],[],
				 [APP(k,[]),
				  (if length s = 0 then conv(x,cont)
				    else PRIMOP(P.sceql, [w,v,len0'],
						 [], [conv(x,cont),
						      APP(k,[])]))]))))))
		      | g nil = APP(df, [])
		      | g _ = ErrorMsg.impossible "convert.76"
		 in PRIMOP(P.slength,[w],[len1], [g cases])
		end
	 in FIX([(cf, [vf], c vf),
		 (df, [], conv(d, cont))],
		PRIMOP(P.boxed,[w],[],[genb b, genu]))
        end)
   | Lambda.SWITCH (x as (Lambda.APP(Lambda.SELECT(i,Lambda.VAR 0),args),
		        [(Lambda.DATAcon(Basics.DATACON{
				    rep=(Basics.CONSTANT c1),...}),e1),
		         (Lambda.DATAcon(Basics.DATACON{
				    rep=(Basics.CONSTANT c2),...}),e2)],
		        NONE)) =>
	let fun g(n,a,b) = getargs(n,args, fn vl =>
			    mk(fn cf => mk(fn v =>
			    FIX([(cf,[v], c v)],
			         PRIMOP(i, vl, nil, 
				    [conv(a, fn w => APP(cf,[w])),
				     conv(b, fn w => APP(cf,[w]))])))))
	 in case (P.calling i, c1, c2)
	     of ((n,0,2), 1, 0) => g(n,e1,e2)
	      | ((n,0,2), 0, 1) => g(n,e2,e1)
	      | _ => genswitch(x,c)
        end
   | Lambda.SWITCH x => genswitch(x,c)
   | Lambda.RAISE(e) => 
      conv(e, fn w => mk(fn h => PRIMOP(P.gethdlr, nil, [h], [APP(h,[w])])))
   | Lambda.HANDLE(a, Lambda.FN(v,b)) =>
	mk(fn h => mk(fn vb => mk(fn vc => mk(fn x =>
	    PRIMOP(P.gethdlr,[],[h],
		    [FIX([(vb,[v],PRIMOP(P.sethdlr,[h],[],
					[conv(b, fn w => APP(vc,[w]))])),
			 (vc,[x],c x)],
			PRIMOP(P.sethdlr,[vb],[],
			    [conv(a, fn va => 
			      PRIMOP(P.sethdlr,[h],[],
				[APP(vc,[va])]))]))])))))
   | Lambda.HANDLE(a, b) => 
	    mk(fn v => conv(Lambda.HANDLE(a, Lambda.FN(v, 
				Lambda.APP(b, Lambda.VAR v))), c))


 and genswitch ((e, l as (Lambda.DATAcon(Basics.DATACON{sign,...}),_)::_, d),c) =
     let val cf = mkLvar() and cv = mkLvar() and df = mkLvar()
	 val cont = fn z => APP(cf,[z])
	val boxed = sublist (isboxed o #1) l
	val unboxed = sublist (not o isboxed o #1) l
	val w = mkLvar() and t = mkLvar()
        fun tag (Lambda.DATAcon(Basics.DATACON{rep=Basics.CONSTANT i,...}), e) = (i, conv(e,cont))
          | tag (Lambda.DATAcon(Basics.DATACON{rep=Basics.TAGGED i,...}), e) = (i, conv(e,cont))
	  | tag (c,e) = (0, conv(e,cont))
    in conv(e, fn w =>
       FIX([(cf,[cv],c cv)]@
	    case d of NONE => []
	            | SOME d' => [(df,[],conv(d',cont))],
	case (count isboxedRep sign, count (not o isboxedRep) sign)
	 of (0, n) => 
	    switch(w, map tag l, SOME df, SOME(n-1))
	  | (n, 0) =>
	    SELECT(1, w, t, switch(t, map tag l, SOME df, SOME(n-1)))
	  | (1, nu) =>
	    PRIMOP(P.boxed, [w], [], 
		[switch(zero, map tag boxed, SOME df, SOME 0), 
		 switch(w, map tag unboxed, SOME df, SOME(nu-1))])
	  | (nb,nu) =>
	    PRIMOP(P.boxed, [w], [], 
		[SELECT(1,w,t, switch(t, map tag boxed, SOME df, SOME(nb-1))), 
		 switch(w, map tag unboxed, SOME df, SOME(nu-1))])))
    end
  | genswitch _ = ErrorMsg.impossible "convert.883"


 in mk(fn v => mk (fn x => 
       ( (mkLvar(), [v,x], conv(lexp, fn w => APP(w,[v,x]))), ctable)))
end

end

