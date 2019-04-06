(* Copyright 1989 by AT&T Bell Laboratories *)
(* notes:
     OFFSET should not be generated by this module
     RECORD fields should contain only empty paths (pure variables)
*)

(* xgrep '[^a-z]n[^a-z]' cps/convert.sml *)
structure Convert = 
struct

open CPS Access
fun sublist test =
  let fun subl(a::r) = if test a then a::(subl r) else subl r
        | subl x = x
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
    | isboxed (STRINGcon s) = (size s <> 1)
    | isboxed _ = false
end

fun mk f = f (mkLvar())

val sortcases = Sort.sort (fn ((i:int,_),(j,_)) => i>j)

val calling =
    fn P.boxed => (1,0,2)
     | P.< => (2,0,2)
     | P.<= => (2,0,2)
     | P.> => (2,0,2)
     | P.>= => (2,0,2)
     | P.rangechk => (2,0,2)
     | P.ieql => (2,0,2)
     | P.ineq => (2,0,2)
     | P.feql => (2,0,2)
     | P.fge => (2,0,2)
     | P.fgt => (2,0,2)
     | P.fle => (2,0,2)
     | P.flt => (2,0,2)
     | P.fneq => (2,0,2)
     | P.gethdlr => (0,1,1)
     | P.* => (2,1,1)
     | P.+ => (2,1,1)
     | P.- => (2,1,1)
     | P.div => (2,1,1)
     | P.orb => (2,1,1)
     | P.andb => (2,1,1)
     | P.xorb => (2,1,1)
     | P.rshift => (2,1,1)
     | P.lshift => (2,1,1)
     | P.fadd => (2,1,1)
     | P.fdiv => (2,1,1)
     | P.fmul => (2,1,1)
     | P.fsub => (2,1,1)
     | P.subscript => (2,1,1)
     | P.ordof => (2,1,1)
     | P.! => (1,1,1)
     | P.alength => (1,1,1)
     | P.makeref => (1,1,1)
     | P.delay => (2,1,1)
     | P.slength => (1,1,1)
     | P.~ => (1,1,1)
     | P.notb => (1,1,1)
     | P.sethdlr => (1,0,1)
     | P.:= => (2,0,1)
     | P.unboxedassign => (2,0,1)
     | P.store => (3,0,1)
     | P.unboxedupdate => (3,0,1)
     | P.update => (3,0,1)
     | _ => ErrorMsg.impossible "calling with bad primop"

  fun nthcdr(l, 0) = l 
    | nthcdr(a::r, n) = nthcdr(r, n-1)
    | nthcdr _ = ErrorMsg.impossible "nthcdr in convert"

  fun count test =
    let fun subl acc (a::r) = subl(if test a then 1+acc else acc) r
          | subl acc nil = acc
    in subl 0
    end

fun convert lexp =
let
    local open Intmap
	  val m : const intmap = new(32, Ctable)
	  val enter = add m
     in fun bindconst(c,cont) = mk(fn v => (enter(v,c); cont v))
	val ctable = m
    end

    local open Intmap
	  exception Rename
	  val m : lvar intmap = new(32, Rename)
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
    val neg1 =  bindconst(INTconst ~1, fn x => x)
    val unevaled =  bindconst(INTconst (System.Tags.tag_suspension div 2), fn x => x)
    val evaled =  bindconst(INTconst((System.Tags.tag_suspension
				     +System.Tags.power_tags)div 2), fn x => x)

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
     case le of
     Lambda.APP(Lambda.PRIM P.callcc, f) =>
     let val k = mkLvar() and k' = mkLvar()
	 and x = mkLvar() and h = mkLvar()
     in FIX([(k,[x],c x)],
         PRIMOP(P.gethdlr,[],[h],
           [RECORD([(k,OFFp 0),(h,OFFp 0)],k',
             conv(f, fn vf => APP(vf,[k',k])))]))
     end
   | Lambda.APP(Lambda.PRIM P.throw, v) => 
	let val k = mkLvar() and f = mkLvar() and k'' = mkLvar()
	    and k' = mkLvar() and h = mkLvar() and x = mkLvar()
	 in conv(v, fn k => 
	          FIX([(f,[x,k''],
			   SELECT(1,k,h,
			     PRIMOP(P.sethdlr,[h],[],[
			      SELECT(0,k,k',
				APP(k',[x]))])))],
			c f))
	end
   | Lambda.APP(Lambda.PRIM P.cast, k) => conv(k,c)
   | Lambda.APP(Lambda.PRIM P.force, k) => 
      let val c0=mkLvar() and c0v=mkLvar() and w=mkLvar() and x=mkLvar()
	  and y=mkLvar() and c1=mkLvar() and c1v=mkLvar()
       in conv(k, fn v =>
	  FIX([(c0,[c0v],c c0v)],
	   PRIMOP(P.boxed,[v],[],[PRIMOP(P.subscript,[v,neg1],[w],[
		 PRIMOP(P.ieql,[w,evaled],[],[PRIMOP(P.!,[v],[x],[APP(c0,[x])]),
		  PRIMOP(P.ineq,[w,unevaled],[],[APP(c0,[v]),
		     FIX([(c1,[c1v],
			      PRIMOP(P.:=,[v,c1v],[],[
			       PRIMOP(P.update,[v,neg1,evaled],[],[
				APP(c0,[c1v])])]))],
			PRIMOP(P.!,[v],[y],[APP(y,[zero,c1])]))])])]),
		 APP(c0,[v])])))
      end
   | Lambda.APP(Lambda.PRIM i, a) =>
     (case calling i of
        (n,1,1) => getargs(n,a,fn vl => mk(fn w => PRIMOP(i,vl,[w],[c w])))
      | (n,0,1) => getargs(n,a,fn vl => PRIMOP(i,vl,[],[c zero]))
      | (n,0,2) => getargs(n,a,fn vl =>
           let val cv = mkLvar() and v = mkLvar()
	   in FIX([(cv,[v],c v)],PRIMOP(i,vl,[],[APP(cv,[one]),APP(cv,[zero])]))
	   end))
   | Lambda.PRIM i => mk(fn v => conv(Lambda.FN(v,Lambda.APP(le,Lambda.VAR v)),c))
   | Lambda.VAR v => c (ren v)
   | Lambda.APP(Lambda.FN(v,e),a) =>
     conv(a, fn w => (newname(v,w);Access.sameName(v,w); conv(e, c)))
   | Lambda.FN (v,e) => let val f = mkLvar() and w = mkLvar()
			in FIX([(f,[v,w],conv(e, fn z => APP(w,[z])))], c f)
			end
   | Lambda.APP (f,a) =>
     let val fc = mkLvar() and x = mkLvar()
     in FIX([(fc,[x],c x)], conv(f,fn vf => conv(a,fn va => APP(vf,[va,fc]))))
     end
   | Lambda.FIX (fl, el, body) =>
     let fun g(f::fl, Lambda.FN(v,b)::el) =
	     mk(fn w => (f,[v,w], conv(b, fn z => APP(w,[z])))) :: g(fl,el)
           | g(nil,nil) = nil
     in FIX(g(fl,el), conv(body,c))
     end
   | Lambda.INT i =>
     ((i+i; bindconst(INTconst i, c))
      handle Overflow =>
	     let open Lambda
	     in conv(APP(PRIM P.+, RECORD[INT(i div 2), INT(i - i div 2)]),c)
	     end)
   | Lambda.REAL i => bindconst(REALconst i, c)
   | Lambda.STRING i => (case size i
			  of 1 => bindconst(INTconst(ord i),c)
			   | _ => bindconst(STRINGconst i, c))
   | Lambda.RECORD nil => c zero
   | Lambda.RECORD l => convlist(l,fn vl => mk(fn x => RECORD(recordpath vl,x,c x)))
   | Lambda.SELECT(i, e) => mk(fn w => conv(e, fn v => SELECT(i, v, w, c w)))
   | Lambda.SWITCH(e,l as (Lambda.DATAcon(Basics.DATACON{
			    rep=Basics.VARIABLE _,...}), _)::_, SOME d) =>
     let val cf = mkLvar() and vf = mkLvar()
     in FIX([(cf, [vf], c vf)],
         conv(Lambda.SELECT(1,e), fn w =>
	  let fun g((Lambda.DATAcon(Basics.DATACON{
		    rep=Basics.VARIABLE(Access.PATH p),const=true,...}), x)::r) =
		    conv(translatepath(1::p), fn v =>
		    PRIMOP(P.ineq, [w,v], [], [g r, conv(x, fn z => APP(cf,[z]))]))
	        | g((Lambda.DATAcon(Basics.DATACON{
		    rep=Basics.VARIABLE(Access.PATH p),...}), x)::r) =
		    conv(translatepath p, fn v =>
		    PRIMOP(P.ineq, [w,v], [], [g r, conv(x, fn z => APP(cf,[z]))]))
	        | g nil = conv(d, fn z => APP(cf,[z]))
	        | g _ = ErrorMsg.impossible "convert.21"
	  in g l
	  end))
     end
   | Lambda.SWITCH(e,l as (Lambda.REALcon _, _)::_, SOME d) =>
     let val cf = mkLvar() and vf = mkLvar()
     in FIX([(cf, [vf], c vf)],
         conv(e, fn w =>
	  let fun g((Lambda.REALcon rval, x)::r) =
		  bindconst(REALconst rval, fn v => 
		  PRIMOP(P.fneq, [w,v],[], [g r, conv(x,fn z => APP(cf,[z]))]))
	        | g nil = conv(d, fn z => APP(cf,[z]))
	        | g _ = ErrorMsg.impossible "convert.81"
	  in g l
	  end))
     end
   | Lambda.SWITCH(e,l as (Lambda.INTcon _, _)::_, SOME d) =>
     let val cf = mkLvar() and vf = mkLvar() and df = mkLvar()
     in FIX([(cf, [vf], c vf), (df, [], conv(d, fn z => APP(cf,[z])))],
         conv(e, fn w =>
	  let fun g (Lambda.INTcon j, a) = (j,conv(a, fn z => APP(cf,[z])))
	  in switch(w, map g l, SOME df, NONE)
	  end))
     end
   | Lambda.SWITCH(e,l as (Lambda.STRINGcon _, _)::_, SOME d) =>
     let val cf = mkLvar() and vf = mkLvar() and df = mkLvar() and vd = mkLvar()
	 val cont = fn z => APP(cf,[z])
	 fun isboxed (Lambda.STRINGcon s, _) = size s <> 1
	 val b = sublist isboxed l
	 val u = sublist (not o isboxed) l
	 fun g(Lambda.STRINGcon j, e) = (ord j, conv(e,cont))
	 val z = map g u
	 val [p1,p2] = !CoreInfo.stringequalPath
     in FIX([(cf, [vf], c vf), (df, [], conv(d, cont))],
	conv(e, fn w =>
	let val genu = switch(w, z, SOME df, NONE)
	    fun genb [] = APP(df,[])
	      | genb cases = 
		let val len1 = mkLvar()
		    fun g((Lambda.STRINGcon s, x)::r) =
		      let val ssize = size s
			  val k = mkLvar() and seq = mkLvar() and pair = mkLvar()
			  and c2 = mkLvar() and ans = mkLvar()
		      in FIX((k,[], g r)::
		             if ssize=0 then []
			     else [(c2,[ans],PRIMOP(P.ieql,[ans,zero],[],
				              [APP(k,[]), conv(x,cont)]))],
	         	 bindconst(STRINGconst s, fn v =>
			  bindconst(INTconst ssize, fn len0 =>
			   bindconst(INTconst((ssize + 3) div 4 - 1), fn len0' =>
 			     PRIMOP(P.ineq,[len0,len1],[],
 			       [APP(k,[]),
 				if ssize=0 then conv(x,cont)
 				else SELECT(p1,ren p2,seq,
				      RECORD([(w,OFFp 0),(v,OFFp 0)],
				       pair, APP(seq,[pair,c2])))])))))
		      end
		      | g nil = APP(df, [])
		in PRIMOP(P.slength,[w],[len1], [g cases])
		end
	in PRIMOP(P.boxed,[w],[],[genb b, genu])
        end))
     end
   | Lambda.SWITCH
     (x as (Lambda.APP(Lambda.PRIM i, args),
        [(Lambda.DATAcon(Basics.DATACON{rep=(Basics.CONSTANT c1),...}),e1),
	 (Lambda.DATAcon(Basics.DATACON{rep=(Basics.CONSTANT c2),...}),e2)],
	 NONE)) =>
     let fun g(n,a,b) =
	 let val cf = mkLvar() and v = mkLvar()
	     val cont = (fn w => APP(cf,[w]))
	 in FIX([(cf,[v],c v)],
	     getargs(n,args,fn vl => PRIMOP(i,vl,[],[conv(a,cont),conv(b,cont)])))
	 end
     in case (calling i, c1, c2) of
	  ((n,0,2), 1, 0) => g(n,e1,e2)
	| ((n,0,2), 0, 1) => g(n,e2,e1)
	| _ => genswitch(x,c)
     end
   | Lambda.SWITCH x => genswitch(x,c)
   | Lambda.RAISE(e) =>
     conv(e,fn w => mk(fn h => PRIMOP(P.gethdlr,[],[h],[APP(h,[w])])))
   | Lambda.HANDLE(a,b) =>
     let val h = mkLvar() and vb = mkLvar() and vc = mkLvar()
	 and x = mkLvar() and v = mkLvar ()
     in FIX([(vc,[x],c x)],
         PRIMOP(P.gethdlr,[],[h],
	  [FIX([(vb,[v],PRIMOP(P.sethdlr,[h],[],[conv(b,fn f => APP(f,[v,vc]))]))],
	    PRIMOP(P.sethdlr,[vb],[],
	     [conv(a, fn va => PRIMOP(P.sethdlr,[h],[], [APP(vc,[va])]))]))]))
     end

 and genswitch ((e, l as (Lambda.DATAcon(Basics.DATACON{sign,...}),_)::_, d),c) =
     let val cf = mkLvar() and cv = mkLvar() and df = mkLvar()
	 val cont = fn z => APP(cf,[z])
	 val boxed = sublist (isboxed o #1) l
	 val unboxed = sublist (not o isboxed o #1) l
	 val w = mkLvar() and t = mkLvar()
         fun tag (Lambda.DATAcon(Basics.DATACON{rep=Basics.CONSTANT i,...}), e) =
		   (i, conv(e,cont))
           | tag (Lambda.DATAcon(Basics.DATACON{rep=Basics.TAGGED i,...}), e) =
	           (i, conv(e,cont))
	   | tag (c,e) = (0, conv(e,cont))
     in FIX((cf,[cv],c cv) ::
	    case d of NONE => [] | SOME d' => [(df,[],conv(d',cont))],
        conv(e, fn w =>
	case (count isboxedRep sign, count (not o isboxedRep) sign)
	 of (0, n) => switch(w, map tag l, SOME df, SOME(n-1))
	  | (n, 0) => SELECT(1, w, t, switch(t, map tag l, SOME df, SOME(n-1)))
	  | (1, nu) =>
	    PRIMOP(P.boxed, [w], [], 
		[switch(zero, map tag boxed, SOME df, SOME 0), 
		 switch(w, map tag unboxed, SOME df, SOME(nu-1))])
	  | (nb,nu) =>
	    PRIMOP(P.boxed, [w], [], 
		[SELECT(1,w,t, switch(t, map tag boxed, SOME df, SOME(nb-1))), 
		 switch(w, map tag unboxed, SOME df, SOME(nu-1))])))
     end
 val v = mkLvar() and x = mkLvar() and f = mkLvar()
in ((f, [v,x], conv(lexp, fn w => APP(w,[v,x]))), ctable)
end

end

