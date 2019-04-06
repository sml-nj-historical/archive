(* Copyright 1989 by AT&T Bell Laboratories *)
structure Initial =
struct

structure  Inside : sig structure System : SYSTEM
			structure List : LIST
			structure ByteArray : BYTEARRAY
			structure IO : IO
			structure Bool : BOOL
			structure String : STRING
		    end =
struct

open Core

(* create a type-safe version of the InLine structure while preserving
   the inline property of the functions. *)
structure InLine =
  struct
    infix 7 * div
    infix 6 + -
    infix 4 < > <= >=
    infix 3 :=
    val callcc : ('a cont -> 'a) -> 'a = InLine.callcc
    val throw : 'a cont -> 'a -> 'b = InLine.throw
    val ! : 'a ref -> 'a = InLine.!
    val op * : int * int -> int = InLine.*
    val op + : int * int -> int = InLine.+
    val op - : int * int -> int = InLine.-
    val op := : 'a ref * 'a -> unit = InLine.:=
    val op < : int * int -> bool = InLine.<
    val op <= : int * int -> bool = InLine.<=
    val op > : int * int -> bool = InLine.>
    val op >= : int * int -> bool = InLine.>=
    val alength : 'a array -> int = InLine.alength
    val boxed : 'a -> bool = InLine.boxed
    val cast : 'a -> 'b = InLine.cast
    val op div : int * int -> int = InLine.div
    val fadd : real * real -> real = InLine.fadd
    val fdiv : real * real -> real = InLine.fdiv
    val feql : real * real -> bool = InLine.feql
    val fge : real * real -> bool = InLine.fge
    val fgt : real * real -> bool = InLine.fgt
    val fle : real * real -> bool = InLine.fle
    val flt : real * real -> bool = InLine.flt
    val fmul : real * real -> real = InLine.fmul
    val fneq : real * real -> bool = InLine.fneq
    val fsub : real * real -> real = InLine.fsub
    val ieql : int * int -> bool = InLine.ieql
    val ineq : int * int -> bool = InLine.ineq
    val makeref : 'a -> 'a ref = InLine.makeref
    val ordof : string * int -> int = InLine.ordof
    val slength : string -> int = InLine.slength
    val store : string * int * int -> unit = InLine.store
    val byteof : Assembly.A.bytearray * int -> int = InLine.ordof
    val blength : Assembly.A.bytearray -> int = InLine.slength
    val bstore : Assembly.A.bytearray * int * int -> unit = InLine.store
    val subscript : 'a array * int -> 'a = InLine.subscript
    val update : 'a array * int * 'a -> unit = InLine.update
    val	~ : int -> int = InLine.~
    val reql : 'a ref * 'a ref -> bool = InLine.ieql
    val aeql : 'a array * 'a array -> bool = InLine.ieql
    val andb : int * int -> int = InLine.andb
    val orb : int * int -> int = InLine.orb
    val xorb : int * int -> int = InLine.xorb
    val rshift : int * int -> int = InLine.rshift
    val lshift : int * int -> int = InLine.lshift
    val notb : int -> int = InLine.notb
  end  (* structure InLine *)


(* The datatype ref is defined in the built-in structure PrimTypes.
   It is not mention here because it has a unique representation; an
   explicit datatype declaration would destroy this representation.
   Similarly, there is no datatype specification in the REF signature
   itself. *)
structure Ref = 
  struct
    infix 3 :=
    val ! = InLine.!
    val op := = InLine.:=
    fun inc r = r := InLine.+(!r,1)
    fun dec r = r := InLine.-(!r,1)
  end (* structure Ref *)
   
structure List : LIST =
  struct
    infixr 5 :: @
    open PrimTypes InLine
    exception Hd
    exception Tl
    exception Nth
    exception NthTail
    fun hd (a::r) = a | hd nil = raise Hd
    fun tl (a::r) = r | tl nil = raise Tl    
    fun null nil = true | null _ = false
    fun length l = 
	let fun j(k,nil) = k
	      | j(k, a::x) = j(k+1,x)
	 in j(0,l)
	end
    fun op @ (nil,l) = l
      | op @ (a::r, l) = a :: (r@l)
    fun rev l =
	let fun f (nil, h) = h
	      | f (a::r, h) = f(r, a::h)
	in  f(l,nil)
	end
    fun map f =
	let fun m nil = nil
	      | m (a::r) = f a :: m r
	in  m
	end
    fun fold f [] = (fn b => b)
      | fold f (a::r) = (fn b => let fun f2(e,[]) = f(e,b)
				       | f2(e,a::r) = f(e,f2(a,r))
				 in f2(a,r)
				 end)
    fun revfold f [] = (fn b => b)
      | revfold f (a::r) = (fn b => let fun f2(e,[],b) = f(e,b)
					  | f2(e,a::r,b) = f2(a,r,f(e,b))
				    in f2(a,r,b)
				    end)	
    fun app f = let fun a2 (e::r) = (f e; a2 r) | a2 nil = () in a2 end
    fun revapp f = let fun a2 (e::r) = (a2 r; f e; ()) | a2 nil = () in a2 end
    fun nthtail(e,0) = e 
      | nthtail(e::r,n) = nthtail(r,n-1)
      | nthtail _ = raise NthTail
    fun nth x = hd(nthtail x) handle NthTail => raise Nth | Hd => raise Nth
    fun exists pred =
	let fun f nil = false
	      | f (hd::tl) = pred hd orelse f tl
	in  f
	end
  end (* structure List *)

structure PreString : sig exception Substring
			  infix 6 ^
			  val substring : string * int * int -> string
			  val ^ : string * string -> string
			  val imakestring : int -> string
		      end =
  struct
    open InLine
    exception Substring
    fun substring("",0,0) = "" (* never call create_s with 0 *)
      | substring("",_,_) = raise Substring
      | substring(s,i,0) = if i>=0 
			    then if boxed s then if i <= slength s
					         then "" else raise Substring
 					    else if i<=1 
					         then "" else raise Substring
			    else raise Substring
      | substring(s,0,1) = if boxed s then cast(ordof(s,0)) else s
      | substring(s,i,1) =
	     if boxed s then if i>=0 andalso i < slength s 
				    then cast(ordof(s,i))
				    else raise Substring
			else if ieql(i,0) then s else raise Substring
      | substring(s,i,len) = 
	  if boxed s andalso i>=0 andalso i+len <= slength s
		andalso len >= 0
	  then let val a = Assembly.A.create_s(len)
		   fun copy j = if ieql(j,len) then ()
				else (store(a,j,ordof(s,i+j)); copy(j+1))
	       in  copy 0; a
	       end
	  else raise Substring

    infix 6 ^
    fun op ^ ("",s) = s
      | op ^ (s,"") = s
      | op ^ (x,y) =
	  if boxed x 
	  then if boxed y
	       then let val xl = slength x and yl = slength y
			val a = Assembly.A.create_s(xl+yl)
			fun copyx n = if ieql(n,xl) then ()
			      else (store(a,n,ordof(x,n)); copyx(n+1))
			fun copyy n = if ieql(n,yl) then ()
			      else (store(a,xl+n,ordof(y,n)); copyy(n+1))
		     in copyx 0; copyy 0; a
		    end
	      else let val xl = slength x
		       val a = Assembly.A.create_s(xl+1)
			fun copyx n = if ieql(n,xl) then ()
			      else (store(a,n,ordof(x,n)); copyx(n+1))
		    in copyx 0; store(a,xl,cast y); a
		   end
	  else if boxed y		       
	       then let val yl = slength y
			val a = Assembly.A.create_s(1+yl)
			fun copyy n = if ieql(n,yl) then ()
			      else (store(a,1+n,ordof(y,n)); copyy(n+1))
		     in store(a,0,cast x); copyy 0; a
		    end
	      else let val a = Assembly.A.create_s 2
		    in store(a,0,cast x); store(a,1,cast y); a
		   end
    fun imakestring i =
	  if i<0 then "~" ^ imakestring(~i)
	  else if i<10 then InLine.cast(InLine.cast "0" + i)
	  else let val j = i div 10
	       in  imakestring j ^ imakestring(i-j*10)
	       end

  end (* structure PreString *)	   

(*abstraction ByteArray : BYTEARRAY = *)
structure ByteArray : BYTEARRAY =
  struct
    open InLine PreString
    infix 3 sub
    type bytearray = Assembly.A.bytearray
    exception Subscript
    exception Range
    val length = blength
    fun array(len,v) =
	if len<0 then raise Subscript
	else if v<0 orelse v>=256 then raise Range
	else if ieql(len,0) then Assembly.bytearray0
	else let val a = Assembly.A.create_b len
		 fun init i = if ieql(i,len) then ()
			      else (bstore(a,i,v); init(i+1))
	      in init 0; a
	     end
    fun update(arg as (s,i,c)) =
	if i<0 orelse i >= length s then raise Subscript
	else if c<0 orelse c>255 then raise Range
	else bstore arg
    val op sub = fn (s,i) => if i<0 orelse i>= length s then raise Subscript
			     else byteof(s,i)
    fun extract(ba,i,1) = if i<0 orelse i >= length ba then raise Subscript
			  else cast(byteof(ba,i))
      | extract(ba,i,len) = 
	  if i<0 orelse i+len > length ba orelse len<0 then raise Subscript
	  else if ieql(len,0) then ""
	  else let val a = Assembly.A.create_s len
		   fun copy j =  if ieql(j,len) then ()
				 else (store(a,j,byteof(ba,i+j)); copy(j+1))
	       in  copy 0; a
	       end
    fun app f ba = 
	let val len = length ba
	    fun app' i = if i >= len then ()
			 else (f(ba sub i); app'(i+1))
	in  app' 0
	end
    fun revapp f ba = 
	let fun revapp' i = if i < 0 then ()
			    else (f(ba sub i); revapp'(i-1))
	in  revapp'(length ba - 1)
	end
    fun fold f ba x = 
	let fun fold'(i,x) = if i < 0 then x else fold'(i-1, f(byteof(ba,i),x))
	in  fold'(length ba - 1, x)
	end
    fun revfold f ba x = 
	let val len = length ba
	    fun revfold'(i,x) = if i >= len then x
				else revfold'(i+1,f(byteof(ba,i),x))
	in  revfold'(0,x)
	end
  end (* abstraction ByteArray *)

structure PreLim =
  struct
    val exn_name : exn -> string = InLine.cast(fn(_,ref s) => s)
    val interactive = Core.Refs.interactive
    val prLambda = Core.Refs.prLambda
  end (* structure PreLim *)

structure Time =
  struct
    datatype time = TIME of {sec : int, usec : int}    
  end (* Time *)

structure PreStats =
  struct
    open Time
    local open Assembly.A Ref
    in
    val zerotime = TIME{sec=0,usec=0}
    val lines = Core.Refs.lines
    val parse = InLine.cast Core.Refs.parse
    val translate = InLine.cast Core.Refs.translate
    val codeopt = InLine.cast Core.Refs.codeopt
    val convert = InLine.cast Core.Refs.convert
    val hoist = InLine.cast Core.Refs.hoistx
    val cpsopt = InLine.cast Core.Refs.cpsopt
    val closure = InLine.cast Core.Refs.closure
    val globalfix = InLine.cast Core.Refs.globalfix
    val spill = InLine.cast Core.Refs.spill
    val codegen = InLine.cast Core.Refs.codegen
    val freemap = InLine.cast Core.Refs.freemap
    val execution = InLine.cast Core.Refs.execution
    fun reset() = 
	(lines := 0;
	 parse := zerotime;
	 translate := zerotime;
	 codeopt := zerotime;
	 convert := zerotime;
	 cpsopt := zerotime;
	 closure := zerotime;
	 globalfix := zerotime;
	 spill := zerotime;
	 codegen := zerotime;
	 freemap := zerotime;
	 execution := zerotime)
    end
  end

structure CInterface =
  struct
    open Time

    exception CFunNotFound of string

    fun c_function s = let
	  fun f (Assembly.FUNC(p,t,rest)) = if stringequal(s,t) then p else (f rest)
	    | f Assembly.FUNCNIL = raise (CFunNotFound s)
          val cfun = f Assembly.external
	  in
	    fn x => (Assembly.A.callc (cfun, x))
	  end

  (* zero pad a string to make it acceptable to C; two zeros are required in
   * case s is a null string. *)
    fun c_string s = PreString.^(s, "\000\000")

  (* type-safe interface to the C functions *)
    val argv	    : unit -> string list = c_function "argv"
    val environ	    : unit -> string list = c_function "environ"
    val gethostname : unit -> string = c_function "gethostname"
    val exec	    : string -> (int * int) = c_function "exec"
    val system      : string -> int = c_function "system"
    val export      : int -> bool = c_function "export"
    val blas	    : (int * 'a) -> 'a = c_function "blas"
    val salb	    : string -> 'a = c_function "salb"
    val flush_cache : string -> unit = c_function "cach"
    val gc		    : int -> unit = c_function "gc"

    local
      val gettime' : unit -> (int * int * int * int) = c_function "gettime"
    in
    fun gettime () = let val (ts, tu, gs, gu) = gettime' ()
	  in
	    (TIME{sec=ts, usec=tu},TIME{sec=gs, usec=gu})
	  end
    end (* local *)

    local
      val setitimer' : (int * int * int * int * int) -> int = c_function "setitimer"
    in
      fun setitimer (which, TIME{sec=s1, usec=u1}, TIME{sec=s2, usec=u2}) =
	    setitimer' (which, s1, u1, s2, u2)
    end (* local *)

  (* type-safe interface to some system calls *)
    val syscall	    : (int * string list) -> int = c_function "syscall"
    exception SystemCall of string
    exception SysError = Assembly.SysError

    val exit : unit -> 'a = InLine.cast (fn () => syscall(1, [InLine.cast 0]))
    val chdir : string -> unit = (fn s => (syscall(12, [c_string s]); ()))
    val getpid : unit -> int = (fn () => (syscall(20, [])))
    val getuid : unit -> int = (fn () => (syscall(24, [])))
    val getgid : unit -> int = (fn () => (syscall(47, [])))

    local open PreString in
    fun wrap_sysfn name f x = (f x)
	  handle SysError(_, s) => raise (SystemCall(name ^ " failed, " ^ s))
    end (* local *)
  end (* structure CInterface *)


structure SysIO =
  struct
    type bytearray = ByteArray.bytearray
    open Time

    type fd = int
    type fileid = string
    datatype fname	= DESC of fd | PATH of string
    datatype mode	= O_READ | O_WRITE | O_APPEND
    datatype whence	= L_SET | L_INCR | L_XTND
    datatype access	= A_READ | A_WRITE | A_EXEC
    datatype file_type	= F_REGULAR | F_DIR | F_SYMLINK | F_SOCK | F_CHR | F_BLK

    local
      open CInterface InLine
      fun sysfn name = (wrap_sysfn name (c_function name))
      fun fileOf (DESC fd) = (cast fd)
	| fileOf (PATH s) = (c_string s)
      infix 3 o
      fun f o g = (fn x => f(g x))
    in

    val dtablesize = Assembly.dtablesize;

    local
      val openf' : (string * int) -> fd = sysfn "open"
    in
    fun openf (path, mode) = let
	  val flag = case mode of O_READ => 0 | O_WRITE => 1 | O_APPEND => 2
	  in
	      openf' (c_string path, flag)
	  end
    end (* local *)

    val closef : fd -> unit = wrap_sysfn "close"
	  (fn filid => (syscall(6, [cast filid]); ()))
    val unlink : string -> unit = wrap_sysfn "unlink"
	  (fn filid => (syscall(10, [cast filid]); ()))
    val mkdir : (string * int) -> unit = wrap_sysfn "mkdir"
	  (fn (path, mask) => (syscall(136, [path, cast mask]); ()))
    val dup : fd -> fd = wrap_sysfn "dup"
	  (fn filid => (syscall(41, [cast filid])))

    val pipe	      : unit -> (int * int) = sysfn "pipe"
    val connect_unix  : string -> fd = sysfn "connect_unix"
    val connect_inet  : (string * string) -> fd = sysfn "connect_inet"

    val read	  : (fd * bytearray * int) -> int = sysfn "read"
    val readi	  : (fd * bytearray * int * int) -> int = sysfn "readi"
    val write	  : (fd * bytearray * int) -> int = sysfn "write"
    val writei	  : (fd * bytearray * int * int) -> int = sysfn "writei"
    val writev	  : (fd * (bytearray * int) list) -> int = sysfn "writev"
    val send_obd  : (fd * bytearray * int) -> int = sysfn "send_obd"
    val getdirent : fd -> string list = sysfn "getdirent"
    val readlink  : string -> string = sysfn "readlink"

    local
      val link' : (bool * string * string) -> unit = (c_function "link")
    in
    val link = wrap_sysfn "link" (fn (name, lname) => link'(false, name, lname))
    val symlink = wrap_sysfn "symlink" (fn (name, lname) => link'(true, name, lname))
    end

    local
      val truncate' : (string * int) -> unit = sysfn "truncate"
    in
    fun truncate (f, len) = truncate'(fileOf f, len)
    end

    local
      val lseek' : int * int * int -> int = wrap_sysfn "lseek"
	    (fn (d, off, w) => (syscall(60, [cast d, cast off, cast w])))
    in
      fun lseek (d, off, whence) = let
	    val w = case whence of L_SET => 0 | L_INCR => 1 | L_XTND => 2
	    in
	      lseek' (d, off, w)
	    end
    end

    local
      val chmod' : (string * int) -> unit = sysfn "chmod"
    in
    fun chmod (f, m) = chmod'(fileOf f, m)
    end

    local
      val access' : (string * int list) -> bool = sysfn "access"
      val map_mode = List.map (fn A_READ => 0 | A_WRITE => 1 | A_EXEC => 2)
    in
    fun access (path, alist) = access' (path, map_mode alist)
    end (* local *)

    val umask : int -> int = wrap_sysfn "unlink" (fn m => (syscall(60, [cast m])))

    local
      val ftype' : string -> int = (sysfn "ftype")
    in
    fun ftype f = case (ftype' (fileOf f))
	   of 0 => F_REGULAR | 1 => F_DIR | 2 => F_SYMLINK
	    | 3 => F_SOCK | 4 => F_CHR | 5 => F_BLK
    end (* local val ftype' *)

    val getfid	    : fname -> fileid	    = sysfn "getfid" o fileOf
    val getmod	    : fname -> int	    = sysfn "getmod" o fileOf
    val isatty	    : int -> bool	    = sysfn "isatty"
    val fionread    : int -> int	    = sysfn "fionread"
    val getownid    : fname -> (int * int)  = (sysfn "getownid") o fileOf
    val fsize	    : fname -> int	    = (sysfn "fsize") o fileOf
    val atime	    : fname -> int	    = (sysfn "atime") o fileOf
    val ctime	    : fname -> int	    = (sysfn "ctime") o fileOf
    val mtime	    : fname -> int	    = (sysfn "mtime") o fileOf

    local
      val select' : (int list * int list * int list * (int * int))
		      -> (int list * int list * int list) = (sysfn "select")
    in
    fun select (rfds, wfds, efds, t) = let
	  val timeout =
		case t of NONE => (cast 0) | SOME(TIME{sec, usec}) => (sec, usec)
	  in
	    select' (rfds, wfds, efds, timeout)
	  end
    end (* local val select' *)
    end (* local *)
  end (* SysIO *)


structure IOx = 
struct
  local
    open InLine Ref PreString PrimTypes CInterface SysIO
    val charOf : (ByteArray.bytearray * int) -> string = cast byteof
  in
  type bytearray = ByteArray.bytearray
  exception Io of string
  type instream = {filid : int, pos : int ref, len : int ref, name : string,
		   closed : bool ref, buf : bytearray, tty : bool ref}
  type outstream = {filid : int, pos : int ref, name : string,
		    closed : bool ref, buf : bytearray, tty : bool ref}

  val bufsize = Core.bufsize

  val std_in : instream = Core.std_in
  val std_out : outstream = Core.std_out
  val _ = (#tty std_in := isatty 0; #tty std_out := isatty 1)

  (* should be closed on exportFn *)
  val instreams : instream list ref = Core.Refs.instreams
  (* should be flushed on exportML, flushed and closed on exportFn *)
  val outstreams : outstream list ref = Core.Refs.outstreams
  fun add_in s = instreams := s :: !instreams
  fun add_out s = outstreams := s :: !outstreams
  fun init_streams() =
      let val {pos=pos_in,tty=tty_in,closed=closed_in,len,...} = std_in
	  val {pos=pos_out,tty=tty_out,closed=closed_out,...} = std_out
      in  pos_in := 0; tty_in := isatty 0; closed_in := false; len := 0;
	  pos_out := 0; tty_out := isatty 1; closed_out := false;
	  PreLim.interactive := !tty_in;
	  instreams := [std_in];
	  outstreams := [std_out]
      end

  val close = wrap_sysfn "close" closef

  fun open_in s =
      let val f = openf(s, O_READ)
		      handle SystemCall message =>
			      raise Io("open_in \"" ^ s ^ "\": " ^ message)
	  val s = {filid = f, pos = ref 0, closed = ref false,
		   len = ref 0, name = s,
		   buf = Assembly.A.create_b bufsize,
		   tty = ref(isatty f)}
      in  add_in s; s
      end
  fun open_o mode = fn s =>
      let val f = openf(s, mode)
	  val s = {filid = f, pos = ref 0, closed = ref false, name=s,
		   buf = Assembly.A.create_b bufsize,
		   tty = ref(isatty f)}
      in  add_out s; s
      end

  fun open_out name = open_o O_WRITE name
	handle SystemCall message =>
	  raise Io("open_out \"" ^ name ^ "\": " ^ message)

  fun open_append name = open_o O_APPEND name
	handle SystemCall message =>
	  raise Io("open_append \"" ^ name ^ "\": " ^ message)


  fun open_string s =
      if boxed s
      then {filid = ~1, pos = ref 0, len = ref (slength s),
	    closed = ref false, tty = ref false, name="<string>",
	    buf = cast s}
      else {filid = ~1, pos = ref 0, len = ref 1,
	    closed = ref false, tty = ref false, name="<string>",
	    buf =let val a = Assembly.A.create_b 1
		  in  bstore(a,0,cast s); a
		 end}

  fun filbuf ({closed = ref true,len,pos,...}: instream) = (len := 0; pos := 0)
    | filbuf {filid = ~1,pos,len,...} = (len := 0; pos := 0)
    | filbuf {filid,pos,buf,len,...} =
	(pos := 0; len := read(filid, cast buf, bufsize))

  fun write_sure (filid, buf, nbytes) = let
	fun f i = let
	      val k = i + writei (filid, buf, i, nbytes-i)
	      in
		if (ieql(k, nbytes)) then () else (f k)
	      end
	in
	  f 0
	end

  fun flush_out ({closed = ref true,name,...} : outstream) = ()
    | flush_out {pos = ref 0,...} = ()
    | flush_out {filid,pos,buf,name,...} =
	(write_sure(filid, buf, !pos);
	 pos := 0)
	 handle SystemCall s =>
	   raise Io("flush_out \"" ^ name ^ "\": " ^ s)

  val flsbuf = flush_out

  fun close_in ({closed = ref true,name,...} : instream) = ()
    | close_in {filid = ~1,closed,len,pos,...} = 
	(closed := true; len := 0; pos := 1)
    | close_in {filid,pos,len,closed,name,...} = 
	(closed := true; len := 0; pos := 1;
	 instreams := List.fold
			(fn(s as {pos=p,...}:instream, tl) =>
			    if ieql(cast pos, cast p) then tl else s::tl)
			(!instreams)
			nil;
	 (close filid) handle SystemCall s =>
			      raise Io("close_in \"" ^ name ^ "\": " ^ s))

  fun close_out ({closed = ref true,name,...} : outstream) = ()
    | close_out (f as {filid,pos,closed,name,...}) = 
	(flsbuf f; pos := 0; closed := true;
	 outstreams := List.fold
			(fn(s as {filid=f,...}:outstream,tl) =>
			    if ieql(filid,f) then tl else s::tl)
			(!outstreams)
			nil;
	 close filid)
        handle SystemCall s =>
		      raise Io("close_out \"" ^ name ^ "\": " ^ s)

  fun look ({closed = ref true,...} : instream) = ""
    | look (f as {len,pos,buf,...}) =
	if !len > !pos
	then charOf(buf, !pos)
	else (filbuf f; if ieql(!len,0) then "" else look f)

  fun lookahead f = look f handle SystemCall s =>
			    raise Io("lookahead \"" ^ #name f ^ "\": " ^ s)

  fun end_of_stream ({closed = ref true,name,...} : instream) = true
    | end_of_stream f = case look f of "" => true | _ => false
	handle SystemCall s =>
		 raise Io("end_of_stream \"" ^ #name f ^ "\": " ^ s)

  fun biginput (filid, k) =   (* k must be larger than 1 *)
	let val a = Assembly.A.create_s k
	    val len = read(filid, cast a, k)
         in if ieql(len,k) then a
	    else PreString.substring(a,0,len)
	end

  fun mtime({filid, closed,name, ...}: instream): int =
	if !closed then
	  raise Io("mtime \"" ^ name ^ "\": closed stream")
	else
	  SysIO.mtime(DESC filid)

  fun inputc(f as {filid,pos,len,buf,closed,name,...} : instream) =
      let val filbuf = fn f => (filbuf f
				handle SystemCall s =>
				raise Io("input \"" ^ name ^ "\": " ^ s))
	  fun get i =
	    let val remaining = !len - !pos
             in if remaining >= i then
		 if ieql(i,1) then
		    let val p = !pos
		     in pos := p+1; charOf(buf, p)
		    end
		 else if i < 0 then
		    raise Io("input \"" ^ name ^ "\": negative character count")
		 else let val s = ByteArray.extract(buf, !pos, i)
		       in pos := !pos+i; s
		      end
	      else if remaining > 0
		   then let val s = ByteArray.extract(buf, !pos, remaining)
		         in pos := !len; s
		        end
	      else if !closed then ""
	      else let val avail = if filid < 0 then 0
				    else if i<=bufsize then i
				    else let val c = fionread filid
					  in if i<c then i else c
					 end
		   in  if avail >= bufsize
		       then biginput(filid,avail)
				handle SystemCall s =>
				raise Io("input \"" ^ name ^ "\": " ^ s)
		       else (filbuf f;
			     if ieql(!len,0) then "" else get i)
		   end
	    end
       in get
      end

  fun input(f,i) =
      let val s = inputc f i
          val len = if boxed s then InLine.slength s else 1
       in if ieql(len,0) then ""
	    else if ieql(len,i) then s
	    else s ^ input(f, i - len)
      end

  fun input_line({closed = ref true,name,...} : instream) = ""
    | input_line(f as {pos,len,buf,name,...}) =
	let val l = !len
	    val filbuf = fn f => (filbuf f
				  handle SystemCall s =>
				  raise Io("input_line \"" ^ name ^ "\": " ^ s))
	    fun next j = if ieql(j,l) then
			    let val s = ByteArray.extract(buf, !pos, l - !pos)
			     in  filbuf f;
				 if ieql(!len,0) then s
				 else s ^ input_line f
			    end
			 else if ieql(byteof(buf, j), 10 (* "\n" *))
			   then inputc f (j+1 - !pos)
			 else next(j+1)
	 in next (!pos)
	end

  fun outputc(f as {filid,buf,pos,tty,closed,name,...} : outstream) =
      let fun put s =
	      if !closed then raise Io("output \"" ^ name ^ "\": closed outstream")
	      else if boxed s then
		 let val l = slength s
		  in if l > 4 * bufsize
		     then (flsbuf f; write_sure(filid, cast s, l))
				 handle SystemCall s =>
				  raise Io("output \"" ^ name ^ "\": " ^ s)
		     else let val i = ref 0
			   in while !i < l
				do let val c = ordof(s, !i)
				    in bstore(buf,!pos,c);
				       pos := !pos + 1; i := !i + 1;
				       if ieql(!pos,bufsize)
					   orelse (!tty andalso ieql(c,10))
				       then flsbuf f 
					 handle SystemCall s =>
					  raise Io("output \"" ^ name ^ "\": " ^ s)
				       else ()
				   end
			  end
		 end
	      else (bstore(buf,!pos,cast s);
		    pos := !pos + 1;
		    if ieql(!pos,bufsize)
			      orelse (!tty andalso ieql(cast s,10))
		    then flsbuf f 
				 handle SystemCall s =>
				  raise Io("output \"" ^ name ^ "\": " ^ s)
		    else ())
       in put
      end

  fun output(f,s) = outputc f s

  fun can_input ({closed = ref true,name,...} : instream) = 0
    | can_input {filid = ~1,pos,len,...} = !len - !pos
    | can_input {filid,pos,len,name,...} = (!len - !pos + fionread filid)
	handle SysError (_, s) => raise (Io("can_input \"" ^ name ^ "\": " ^ s))	

  val pipe = wrap_sysfn "pipe" pipe

  fun execute s = let
	val (fdin, fdout) = exec (c_string s)
			      handle (SysError _) => raise (Io("Cannot execute "^s));
	val r = {filid = fdin, pos = ref 0, len = ref 0, 
		 closed = ref false, name="<pipe_in>",
		 buf = Assembly.A.create_b bufsize,
		 tty = ref false}
	val w = {filid = fdout, pos = ref 0, 
		 closed = ref false, name="<pipe_out>",
		 buf = Assembly.A.create_b bufsize,
		 tty = ref false}
	in
	  add_in r; add_out w;
	  (r,w)
	end

  fun is_term_in ({tty=ref x,...}:instream) = x

  fun is_term_out ({tty=ref x,...}:outstream) = x

  fun set_term_in ({tty,...}:instream,t) = tty := t

  fun set_term_out ({tty,...}:outstream,t) = tty := t

  fun exportML filename = 
      let val filid = openf (filename, O_WRITE)
	      handle SystemCall s =>
		raise Io("exportML \"" ^ filename ^ "\": " ^ s)
      in  List.app flush_out (!outstreams);
	  if export filid
	  then ((* mark previously opened streams as closed
		   without flushing them *)
		List.app (fn {closed,...} : outstream => closed := true)
			 (!outstreams);
		List.app (fn {closed,...} : instream => closed := true)
			 (!instreams);
		(* restore std_in and std_out *)
		init_streams();
		(* reset timing statistics *)
		PreStats.reset();
		true)
	  else (close filid; false)
      end

  val use_f = Core.Refs.use_f
  val use_s : (instream -> unit) ref = InLine.cast Core.Refs.use_s
  fun use f = !use_f f
  fun use_stream s = !use_s s

  (* close/flush all streams; watch out, some may be damaged. *)
  fun cleanup () =
      let fun c_out s = close_out s handle  _ => ()
	  fun c_in s = close_in s handle _ => ()
      in  List.app c_out (!outstreams);
	  List.app c_in (!instreams)
      end

  fun exportFn (filename,func) = 
      let val filid = openf (filename, O_WRITE)
	      handle SystemCall s =>
		raise Io("exportFn \"" ^ filename ^ "\": " ^ s)
	  val pr = outputc std_out
      in  cleanup();
	  use_f := (fn (_ : string) => ());
	  use_s := (fn (_ : instream) => ());
          Core.Refs.debugInterface := cast (fn () => ());
          Core.Refs.getDebugf := cast (fn () => ());
	  Core.Refs.lookup_r := cast(fn ()=>());
	  Core.Refs.compreturn := 
	    [cast(exit, fn e => (pr "uncaught exception ";
				 pr (PreLim.exn_name e);
				 pr "\n"; cleanup(); exit()), ref())];
	  PreLim.prLambda := (fn () => ());
	  if (export filid)
	  then (init_streams();
		func(argv(), environ());
		cleanup();
		exit())
	       handle exn =>
		 (pr "uncaught exception ";
		  pr (PreLim.exn_name exn);
		  pr "\n";
		  cleanup())
	  else ()
      end

  fun blast_write ((s as {filid,...}) : outstream, obj) = 
	(flush_out s; blas(filid, obj); ())
  fun blast_read f = salb (input(f,(can_input f)))

 end (* local open ... *)
end (* structure IOx *)

abstraction IO : IO = IOx;


structure Bool : BOOL =
  struct
    open PrimTypes (* for datatypes bool and option *)
    fun not true = false
      | not false = true
    fun makestring true = "true"
      | makestring false = "false"
    local val pr = IO.outputc IO.std_out in
    fun print b = pr(makestring b)
    end
  end (* structure Bool *)


structure String : STRING =
  struct
    open PrimTypes InLine
    infix 4 > < >= <=
    infix 6 ^
    type string = string
    fun length s = if boxed s then slength s else 1
    val size = length
    exception Substring = PreString.Substring
    val substring = PreString.substring
    fun explode s =
	  if boxed s
	    then let fun f(l,~1) = l
		       | f(l, i) = f(cast(ordof(s,i)) :: l, i-1)
		  in f(nil, slength s - 1)
		 end
	    else [s]
    val op ^ = PreString.^
    exception Chr
    fun chr i = if i<0 orelse i>255 then raise Chr else cast i
    exception Ord
    fun ord "" = raise Ord
      | ord s = if boxed s then ordof(s,0) else cast s
    val ordof = fn (s,i) =>
	  if boxed s
            then if i<0 orelse i>= slength s then raise Ord else ordof(s,i)
	    else if ieql(i,0) then cast s else raise Ord
    val print = IO.outputc IO.std_out
    fun implode (sl:string list) =
	  let val len = List.fold(fn(s,l) => length s + l) sl 0
	  in  case len
	       of 0 => ""
		| 1 => let fun find (""::tl) = find tl
			     | find (hd::_) = cast hd
			     | find nil = "" (* impossible *)
		       in  find sl
		       end
		| _ => let val new = Assembly.A.create_s len
			   fun copy (nil,_) = ()
			     | copy (s::tl,base) =
				let val len = length s
				    fun copy0 0 = ()
				      | copy0 i =
					let val next = i-1
					in  store(new,base+next,ordof(s,next));
					    copy0 next
					end
				in  copy0 len;
				    copy(tl,base+len)
				end
			in  copy(sl,0);
			    new
			end
	  end
    fun sgtr("","") = false
      | sgtr(_,"") = true
      | sgtr("",_) = false
      | sgtr(a,b) =
	if boxed a
        then if boxed b
	     then let val al = slength a and bl = slength b
		      val n = if al<bl then al else bl
		      fun f i = 
			  if ieql(i,n) then al > bl
			  else if ieql(InLine.ordof(a,i),InLine.ordof(b,i)) then f(i+1)
			  else InLine.ordof(a,i) > InLine.ordof(b,i)
		   in  f 0
		  end
	     else InLine.ordof(a,0) >= cast(b)
	else if boxed b
	     then cast(a) > InLine.ordof(b,0)
	     else cast(a) > cast(b)  
    fun op <= (a,b) = Bool.not(sgtr(a,b))
    fun op < (a,b) = sgtr(b,a)
    fun op >= (a,b) = Bool.not(sgtr(b,a))
    val op > = sgtr
  end  (* structure String *)

structure System : SYSTEM =
  struct
    structure ByteArray : BYTEARRAY = ByteArray
    structure Control : CONTROL =
      struct
	structure Runtime : RUNTIMECONTROL = Assembly
        structure MC : MCCONTROL =
	  struct
            val printArgs = Core.Refs.printArgs
            val printRet = Core.Refs.printRet
            val bindContainsVar = Core.Refs.bindContainsVar
            val bindExhaustive = Core.Refs.bindExhaustive
            val matchExhaustive = Core.Refs.matchExhaustive
            val matchRedundant = Core.Refs.matchRedundant
	    val expandResult = Core.Refs.expandResult
          end
        structure CG : CGCONTROL =
	  struct
	    structure M68 =
	      struct
	        val trapv = Core.Refs.trapv
	      end
	    open Core.Refs
	    val cpsopt = Core.Refs.do_cpsopt
          end
	structure Print : PRINTCONTROL =
	  struct
	    val printDepth = Core.Refs.printDepth
	    val printLength = Core.Refs.printLength
	    val stringDepth = Core.Refs.stringDepth
	    val signatures = Core.Refs.signatures
	  end
        structure ProfileInternals : PROFILEINTERNALS =
	  struct
            structure ByteArray = ByteArray
	    open InLine
	    val other : ByteArray.bytearray = cast(Core.other)
	    val toplevel : ByteArray.bytearray = cast(Core.toplevel)
	    val gc : ByteArray.bytearray = cast(Core.gc)
	    val globalProfile : ByteArray.bytearray list ref
			= InLine.cast Core.Refs.globalProfile

	    fun setToplevel () = 
		cast(Assembly.current) := toplevel

	    fun setOther () = 
		cast(Assembly.current) := other

	    fun listofarray a =
		let fun loop(~1,x) = x
		      | loop(i,x) = loop(i-1, InLine.subscript(a,i) :: x)
		in loop(InLine.alength a - 1, nil)
		end

            fun zeroCount e = (InLine.update(cast e,0,0);
			       InLine.update(cast e,1,0))

	    local
	      open PreStats
	      val t0 = TIME{sec=0, usec=0} and t10 = TIME{sec=0, usec=10000}
	    in
	    val timerval = (1 (* ITIMER_VIRTUAL *), t10, t10)
	    val timerval0 = (1 (* ITIMER_VIRTUAL *), t0, t0)
	    end

	    fun copy(ba,str) =
		let val len = slength str
		    fun loop i = 
			if ieql(i,len)
			then ()
			else (ByteArray.update(ba,i,ordof(str,i)); loop(i+1))
		 in loop 0
		end

	    val _ = copy(other,   "aaaaaaaa(unprofiled)")
	    val _ = copy(toplevel,"aaaaaaaa(toplevel)")
	    val _ = copy(gc,      "aaaaaaaa(gc)")

	    fun add profile =
	        if boxed profile
		then let val entries = listofarray profile
		      in List.app zeroCount entries;
		         globalProfile := List.@(entries,!globalProfile)
		     end
		else ()

	    fun extractInt(ba,start,len) =
		!(cast(ByteArray.extract(ba,start,len)):int ref)

	    fun trans ba =
		(extractInt(ba,0,4), extractInt(ba,4,4),
		 ByteArray.extract(ba,8,ByteArray.length ba - 8))

	    local fun insert (a,nil) = [a]
	            | insert (a0 as (a',a,_),l as (x0 as (x',x,_))::y) =
		       if a<x orelse ieql(a,x) andalso a'<x'
			 then x0::insert(a0,y)  else a0::l
	      in  fun sort nil = nil
	            | sort (a::b) = insert(a,sort b)
             end


	    fun field (st,w) = 
		let val s = PreString.^("                    ", st)
		 in PreString.substring(s,String.length s - w, w)
		end

	    fun decimal(st,w) =
	      PreString.^(PreString.^(
			        (PreString.substring(st,0,String.length st - w)
				  handle PreString.Substring => "")
			        ,"."),
		    let val st' = PreString.^("0000000000",st)
		     in PreString.substring(st',String.length st' - w,w)
		    end)

	    fun muldiv(i,j,k) =
		(i*j div k) 
		   handle Assembly.Overflow => muldiv(i,j div 2, k div 2)

	    fun decfield(n,j,k,w1,w2) = 
		field(decimal(PreString.imakestring (muldiv(n,j,k)),w1)
			handle Assembly.Div => "",w2)

	    fun printReport f l = 
	      let val l' as (_,_,_,ticks)::_
		    = List.fold (fn((n,m,s),l as (_,_,_,cum)::_)=>(n,m,s,m+cum)::l
				  |((n,m,s),nil)=>[(n,m,s,m)]) (sort l) nil
		  val pr = IO.outputc f
	      in pr(field("%time",6));
		 pr(field("cumsecs",9));
		 pr(field("#call",10));
		 pr(field("ms/call",10));
		 pr("  name\n");
		 List.app (fn (n,m,s,cumm) =>
			    (pr(decfield(m,10000,ticks,2,6));
			     pr(decfield((ticks-cumm+m),2,1,2,9));
			     pr(field(PreString.imakestring n,10));
			     pr(decfield(m,50000,n,4,10));
			     pr "  "; pr s; pr "\n"))
		          l';
		 ()
	       end

           structure P =
	     struct
	       structure IO = IO
	       val profiling = Core.Refs.profiling
	       fun profileOn () = (CInterface.setitimer timerval; ())
	       fun profileOff () = (CInterface.setitimer timerval0; ())
	       fun reset () = List.app zeroCount (!globalProfile)
	       fun clear () = (globalProfile := [toplevel,gc,other]; reset())
	       fun report f =
		   printReport f (List.map trans (!globalProfile))
	       val _ = clear()
             end
           val add = InLine.cast add
	  end (* structure ProfileInternals *)
        structure Profile = ProfileInternals.P
        structure Debug : DEBUG =
          struct
	    val debugging = Core.Refs.debug1
	    val getDebugf = InLine.cast Core.Refs.getDebugf
	    val interface = InLine.cast Core.Refs.debugInterface
          end
	val prLambda = PreLim.prLambda
        val debugging = Core.Refs.debugging
        val primaryPrompt = Core.Refs.primaryPrompt
        val secondaryPrompt = Core.Refs.secondaryPrompt
        val internals = Core.Refs.internals
	val weakUnderscore = Core.Refs.weakUnderscore
        val interp = Core.Refs.interp
        val debugLook = Core.Refs.debugLook
        val debugCollect = Core.Refs.debugCollect
        val debugBind = Core.Refs.debugBind
	val saveLambda = Core.Refs.saveLambda
	val saveLvarNames = Core.Refs.saveLvarNames
	val timings = Core.Refs.timings
        val reopen = Core.Refs.reopen
        val markabsyn = Core.Refs.markabsyn
      end (* structure Control *)
    structure Tags : TAGS = (* taken from runtime/tags.h *)
      struct
	val width_tags = 4
	val power_tags = 16
	val tag_record =	1
	val tag_array =	9
	val tag_bytearray =	11
	val tag_string =	15
	val tag_embedded =	7
	val tag_suspension =	13
	val tag_backptr =	5
	val tag_forwarded =	3
      end (* structure Tags *)
    structure Timer : TIMER =
      struct
	open Time InLine PreString

	type timer = time * time
	val timer = CInterface.gettime
           
	val start_timer = timer
	fun delta(s2,u2,s1,u1) =
	      let val (sec,usec) = (s2-s1,u2-u1)
		  val (sec,usec) = if usec < 0
				     then (sec-1,usec+1000000)
				     else (sec,usec)
	      in  (sec,usec)
	      end
	fun check_timer (TIME{sec=start_s,usec=start_u},
			 TIME{sec=gstart_s,usec=gstart_u}) =
	      let val (TIME{sec=curr_s,usec=curr_u},
		       TIME{sec=gcurr_s,usec=gcurr_u}) = timer()
		  val (sec,usec) = delta(curr_s,curr_u,start_s,start_u)
		  val (g_sec,g_usec) = delta(gcurr_s,gcurr_u,gstart_s,gstart_u)
		  val (sec,usec) = delta(sec,usec,g_sec,g_usec)
	      in  TIME{sec=sec,usec=usec}
	      end
	fun check_timer_gc (TIME{sec=start_s,usec=start_u},
			 TIME{sec=gstart_s,usec=gstart_u}) =
	      let val (TIME{sec=curr_s,usec=curr_u},
		       TIME{sec=gcurr_s,usec=gcurr_u}) = timer()
		  val (g_sec,g_usec) = delta(gcurr_s,gcurr_u,gstart_s,gstart_u)
	      in  TIME{sec=g_sec,usec=g_usec}
	      end
	fun makestring(TIME{sec,usec}) =
	      let val filler = if usec <= 0 then ""
			       else if usec < 10 then "00000"
			       else if usec < 100 then "0000"
			       else if usec < 1000 then "000"
			       else if usec < 10000 then "00"
			       else if usec < 100000 then "0"
			       else ""
	      in  imakestring sec ^ "." ^ filler ^ imakestring usec
	      end
	fun add_time(TIME{sec=s0,usec=u0},TIME{sec=s1,usec=u1}) =
	      let val (s,u) = (s0+s1,u0+u1)
		  val (s,u) = if u > 1000000 then (s+1,u-1000000)
			      else (s,u)
	      in  TIME{sec=s,usec=u}
	      end
	fun sub_time(TIME{sec=s2,usec=u2},TIME{sec=s1,usec=u1}) = let
	      val (s, u) = delta(s2, u2, s1, u1)
	      in
		TIME{sec=s, usec=u}
	      end
      end (* structure Timer *)
    structure Stats : STATS =
      struct
	open Timer Ref PreStats Control.Runtime PreString
	fun update(a,b) = a := add_time(!a, b)
	fun summary() =
	      let val pr = IO.outputc IO.std_out
		  val (total,garbagetime) = start_timer()
	      in  pr (imakestring(!lines));
		  pr " lines\n";
		  pr "parse, "; pr(makestring(!parse)); pr "s\n";
		  pr "translate, "; pr(makestring(!translate)); pr "s\n";
		  pr "codeopt, "; pr(makestring(!codeopt)); pr "s\n";
		  pr "convert, "; pr(makestring(!convert)); pr "s\n";
		  pr "cpsopt, "; pr(makestring(!cpsopt)); pr "s\n";
		  pr "closure, "; pr(makestring(!closure)); pr "s\n";
		  pr "globalfix, "; pr(makestring(!globalfix)); pr "s\n";
		  pr "spill, "; pr(makestring(!spill)); pr "s\n";
		  pr "codegen, "; pr(makestring(!codegen)); pr "s\n";
		  pr "freemap, "; pr(makestring(!freemap)); pr "s\n";
		  pr "execution, "; pr(makestring(!execution)); pr "s\n";
		  pr "garbagetime, "; pr(makestring garbagetime); pr "s\n";
		  pr "total "; pr(makestring total); pr "s\n";
		  pr "collections: "; pr(imakestring(!minorcollections));
		  pr " minor, "; pr(imakestring(!majorcollections));
		  pr " major\n"; pr(imakestring(!collected));
		  pr " collected from "; pr(imakestring(!collectedfrom));
		  pr " possible (";
		  case !collectedfrom of
		    0 => ()
		  | _ => pr(imakestring(InLine.div(InLine.*(!collected,100),
			 		    !collectedfrom)));
		  pr "%)\n";
		  ()
	      end
	abstraction Timer : TIMER = Timer
      end (* structure Stats *)
    abstraction Timer : TIMER = Timer (* to hide timer datatype *)

    structure Signals : SIGNALS = 
      struct
	datatype signal
	  = SIGHUP | SIGINT | SIGQUIT | SIGSYS | SIGPIPE | SIGALRM | SIGTERM
	  | SIGURG | SIGCHLD | SIGIO | SIGWINCH | SIGUSR1 | SIGUSR2

	datatype resume_act
	  = Continue of unit cont
	  | RaiseExn of (exn cont * exn)

	datatype sig_sts
	  = ENABLED of ((int * unit cont) -> resume_act)
	  | DISABLED

	val sigvec = Assembly.A.array(31, DISABLED)

      (* This duplicates the definition in structure General *)
	val exn_cont_of : 'a cont -> exn cont = InLine.cast (fn (_, e) => (e, e))

      (* sigHandler : (int * int * unit cont) -> 'a
       * This is the root ML signal handler
       *)
	fun sigHandler (code, count, resume_k) = (
	      case (InLine.subscript(sigvec, code))
	       of DISABLED => Assembly.A.sig_return (resume_k, ())
		| (ENABLED handler) => let
		    val sts = (handler (count, resume_k))
			  handle ex => RaiseExn(exn_cont_of resume_k, ex)
		    in
		      case sts
		       of (Continue k) => Assembly.A.sig_return (k, ())
			| (RaiseExn arg) => Assembly.A.sig_return arg
		    end)

      (* Install the root handler *)
	val _ = Ref.:= (Assembly.sighandler, sigHandler)

      (* convert SML signal names to UNIX signal codes *)
	fun sig2code SIGHUP = 1
	  | sig2code SIGINT = 2
	  | sig2code SIGQUIT = 3
	  | sig2code SIGSYS = 12
	  | sig2code SIGPIPE = 13
	  | sig2code SIGALRM = 14
	  | sig2code SIGTERM = 15
	  | sig2code SIGURG = 16
	  | sig2code SIGCHLD = 17
	  | sig2code SIGIO = 23
	  | sig2code SIGWINCH = 24
	  | sig2code SIGUSR1 = 30
	  | sig2code SIGUSR2 = 31

	val enableSig : (int * bool) -> unit = CInterface.c_function "enablesig"

	fun setHandler (signal, newHandler) = let
	      val code = sig2code signal
	      in
		case (newHandler, InLine.subscript(sigvec, code))
		 of (SOME h, DISABLED) => (
		      InLine.update (sigvec, code, ENABLED h);
		      enableSig(code, true))
		  | (SOME h, _) => InLine.update (sigvec, code, ENABLED h)
		  | (NONE, ENABLED _) => (
		      enableSig (code, false);
		      InLine.update (sigvec, code, DISABLED))
		  | _ => ()
	      end

	fun inqHandler signal = (
	      case (InLine.subscript(sigvec, sig2code signal))
	       of DISABLED => NONE
		| (ENABLED handler) => SOME handler)

	exception Interrupt

      (* Install some default handlers *)
	local
	  val pr = IO.outputc IO.std_out
	  fun quit s _ = (
		pr s; pr " (no coredump)\n";
		IOx.cleanup(); CInterface.exit())
	in
	val _ = setHandler(SIGHUP, SOME(quit "\nHangup"))
	val _ = setHandler(SIGINT, SOME(fn _ => raise Interrupt))
	val _ = setHandler(SIGQUIT, SOME(quit "\nQuit"))
	val _ = setHandler(SIGSYS,
		  SOME(fn _ => raise (CInterface.SystemCall "bad syscall")))
	val _ = setHandler(SIGTERM, SOME(quit "\nSoftware termination"))
	end (* local *)

      end (* Signals *)

    structure Unsafe : UNSAFE =
      struct
        structure Assembly : ASSEMBLY = Assembly
	structure CInterface : CINTERFACE = CInterface
	structure SysIO : SYSIO = SysIO
        type object = Assembly.object
        val boxed = InLine.cast()
        val ordof = InLine.cast()
        val slength = InLine.cast()
        val store = InLine.cast()
        val subscript = InLine.cast()
        val update = InLine.cast()
	val delay = InLine.cast()
	val force = InLine.cast()
	fun boot (x: string) : 'a -> 'b = 
	    InLine.cast(InLine.+(InLine.cast x, 4),0)
	val cast = InLine.cast
	val blast_write = cast IOx.blast_write
	val blast_read = cast IOx.blast_read
	val create_s = Assembly.A.create_s
	val store_s : string * int * int -> unit
			= InLine.cast ByteArray.update
	val lookup_r : (int->object) ref= cast Core.Refs.lookup_r
        val lookup = fn i => case lookup_r of ref f => f i

        val use_f = Core.Refs.use_f
        val use_s : ('instream -> unit) ref = cast Core.Refs.use_s
        val forcer_p = cast Core.forcer_p

	exception Top_level_callcc

        val do_it =
	  InLine.callcc(fn c0 => 
	   let val (f,arg,id) = 
		InLine.callcc(fn c => InLine.throw c0 (InLine.throw c))
	       val v = f arg
		handle e =>
		     let val ref(op ::((k,h,_),r)) = cast Core.Refs.compreturn
		      in InLine.:=(Core.Refs.compreturn, cast r); h e
		     end
	       val ref(op ::((k,h,id'),r)) = cast Core.Refs.compreturn
	    in InLine.:=(Core.Refs.compreturn, cast r);
	       if InLine.reql(id,id') then k v else h(Top_level_callcc)
	   end)

        fun isolate f arg = InLine.callcc(fn c => 
		raise(InLine.callcc(fn c' =>
		let val id = ref()
		 in InLine.:=(cast Core.Refs.compreturn,
		    op ::( (InLine.throw c, InLine.throw c',id),
			 cast(InLine.! Core.Refs.compreturn)));
		     do_it(f,arg,id)
		end)))

	val pstruct = cast Core.Refs.pstruct
	local
	    datatype A = unboxed | boxed of object
	    val cast = InLine.cast
	in  exception Boxity
	    val tuple : object -> object array
			= cast(fn unboxed => raise Boxity
				| x as boxed _ => x)
	    val string : object -> string = cast (fn x=>x)
	    val real : object -> real = cast (fn x=>x)
	    val int : object -> int
			= cast(fn x as unboxed => x
				| boxed _ => raise Boxity)
	end (* local datatype A ... *)
	structure AA : sig
	  datatype datalist = DATANIL | DATACONS of (string * string * datalist)
	  val datalist : datalist
	end = Assembly
	open AA
      end (* Unsafe *)

  structure Directory : DIRECTORY =
    struct
      local open CInterface SysIO List String
      in

      fun isDir path =
	    (case ftype(PATH path) of F_DIR => true | _ => false)
	      handle (SystemCall _) => false

      exception NotDirectory

      fun listDir path = let
	    val fd = openf (path, O_READ)
	    fun f l = (case (getdirent fd) of [] => l | l' => f(l' @ l))
	    val dirlist = rev (f [])
	    in
	      closef fd; dirlist
	    end
	      handle (SystemCall _) => raise NotDirectory

      val cd = chdir handle (SysError _) => raise NotDirectory

      fun getWD () = let
	    val root_id = getfid (PATH "/")
	    fun walk_up (path, curdir) = let
		  val curid = getfid(PATH curdir)
		  in
		    if (stringequal(curid, root_id))
		      then (case path of [] => "/" | _ => implode path)
		      else let
			val nextdir = curdir ^ "../"
(* NOTE: this code could be optimized by examining the directory entries incrementally *)
			fun scanDir nil = raise NotDirectory
			  | scanDir (f::r) = let
			      val fid = getfid(PATH(nextdir ^ f))
			      in
				if (stringequal(fid, curid)) then f else (scanDir r)
			      end
			val next = scanDir(listDir nextdir)
			in
			  walk_up ("/" :: next :: path, nextdir)
			end
		  end
	    in
	      walk_up ([], "./")
	    end
      end (* local *)
    end (* Directory *)

    open PreLim
    val version = "Standard ML of New Jersey, Version 0.57, 10 May 1990"
    val cleanup = IOx.cleanup
    local open CInterface in
    val system = wrap_sysfn "system" (fn x => (system(c_string x); ()))
    end

    val argv = CInterface.argv
    val environ = CInterface.environ

  end (* structure System *)

end (* structure Inside *)

open Inside PrimTypes

(* The following structures must be without signatures so that inlining 
   can take place *)

structure General =
  struct
    infix 3 o
    infix before
    exception Bind = Core.Bind
    exception Match = Core.Match
    exception Interrupt = System.Signals.Interrupt
    exception SystemCall = System.Unsafe.CInterface.SystemCall

    val callcc : ('a cont -> 'a) -> 'a = InLine.callcc
    val throw : 'a cont -> 'a -> 'b = InLine.throw
(** NOTE: this is duplicated in structure Signals **)
    val exn_cont_of : 'a cont -> exn cont = InLine.cast (fn (_, e) => (e, e))

    fun f o g = fn x => f(g x)
    fun a before b = a
    (*** datatype 'a option = NONE | SOME of 'a ***) (* moved to Bool *)
    type 'a cont = 'a cont
    type exn = exn
    type unit = unit
    infix 4 = <>
    val op = : ''a * ''a -> bool  = InLine.=
    val op <> : ''a * ''a -> bool = InLine.<>
  end (* structure General *)

structure Bits =
  struct
    val andb : int * int -> int = InLine.andb
    val orb : int * int -> int = InLine.orb
    val lshift : int * int -> int = InLine.lshift
    val rshift : int * int -> int = InLine.rshift
    val notb : int -> int = InLine.notb
    val xorb : int * int -> int = InLine.xorb
  end

structure Ref = 
  struct
    infix 3 :=
    val ! : 'a ref -> 'a = InLine.!
    val op := : 'a ref * 'a -> unit = InLine.:=
    fun inc r = r := (InLine.+ : int * int -> int) (!r,1)
    fun dec r = r := (InLine.- : int * int -> int) (!r,1)
  end

structure Array =
  struct
   local open InLine in
    infix 3 sub
    type 'a array = 'a array
    exception Subscript
    val array : int * '1a -> '1a array =
	  fn arg as (n,v) =>
	     if <=(n,0) then if <(n,0) then raise Subscript
			     else Core.Assembly.array0
	     else Core.Assembly.A.array arg
    val op sub : 'a array * int -> 'a =
	  fn (a,i) =>
	     if <(i,0) orelse >=(i,alength a) then raise Subscript
	     else subscript(a,i)
    val length : 'a array -> int = alength
    fun arrayoflist nil = Core.Assembly.array0
      | arrayoflist (l as (e::r)) =
	  let val a = array(List.length l, e)
	      fun init ((e::r),n) = (update(a,n,e); init(r,+(n,1)))
	        | init (nil,_) = ()
	  in  init(r,1); a
          end
    val update : 'a array * int * 'a -> unit =
	  fn (a,i,v) => 
	     if <(i,0) orelse >=(i,alength a) then raise Subscript
	     else update(a,i,v)
   end (* local open ... *)
  end (* structure Array *)

structure Integer =
  struct
    infix 7 * div mod quot rem
    infix 6 + -
    infix 4 > < >= <=
    exception Div = Core.Assembly.Div
    exception Mod = Div
    exception Overflow = Core.Assembly.Overflow
    exception Sum=Overflow and Diff=Overflow and Prod=Overflow and Neg=Overflow
    type int = int
    val ~ : int -> int = InLine.~
    val op * : int * int -> int = InLine.*
    val op + : int * int -> int = InLine.+
    val op - : int * int -> int = InLine.-
    val op > : int * int -> bool = InLine.>
    val op >= : int * int -> bool = InLine.>=
    val op < : int * int -> bool = InLine.<
    val op <= : int * int -> bool = InLine.<=
    fun op div(a:int,b:int):int =
		if a>=0
		    then if b>=0 then InLine.div(a,b)
				 else InLine.div(a-b-1,b)
		    else if b>=0 then InLine.div(a-b+1,b)
				 else InLine.div(a,b)
    fun op mod(a:int,b:int):int = a-(a div b)*b
    val op quot : int * int -> int = InLine.div
    fun op rem(a:int,b:int):int = a-(a quot b)*b
    fun min(a,b) = if a<b then a else b
    fun max(a,b) = if a>b then a else b
    fun abs a = if a<0 then ~a else a
    fun makestring i =
	  if i<0 then (String.^("~", makestring(~i))
			handle Overflow => "~1073741824")
	  else if i<10 then InLine.cast(InLine.cast "0" + i)
	  else let val j = i quot 10
	       in  String.^(makestring j, makestring(i-j*10))
	       end
    local val pr = IO.outputc IO.std_out in
    fun print i = pr(makestring i)
    end
  end  (* structure Integer *)

structure Real =
  struct
   local 
    open Math String
    val negone = ~1.0
    val zero = 0.0
    val half = 0.5
    val one = 1.0
    val two = 2.0
    val five = 5.0
    val ten = 10.0
   in
    infix 7 * /
    infix 6 + -
    infix 4 > < >= <=
    type real = real
    exception Div=Integer.Div
    exception Overflow=Integer.Overflow
    exception Sum=Overflow and Diff=Overflow and Prod=Overflow
    and Exp=Overflow and Floor=Overflow
    val ~ : real -> real = fn x => InLine.fsub(0.0,x)
    val op + : real * real -> real = InLine.fadd
    val op - : real * real -> real = InLine.fsub
    val op * : real * real -> real = InLine.fmul
    val op / : real * real -> real = InLine.fdiv
    val op > : real * real -> bool = InLine.fgt
    val op < : real * real -> bool = InLine.flt
    val op >= : real * real -> bool = InLine.fge
    val op <= : real * real -> bool = InLine.fle
    val sin = sin and cos = cos and sqrt = sqrt and arctan = arctan
    and exp = exp and ln = ln
    exception Sqrt = Sqrt and Ln = Ln
    local
      fun rtoi (pred,init) =
	  let fun loop n =
	      if pred n
	      then init
	      else let val (i,r) = loop(n * half)
		       val i' = InLine.lshift(i,1)
		       val r' = r+r
		   in if n-r' < one then (i',r') else (InLine.+(i',1),r'+one)
		   end
	   in loop
	  end
      val pton = rtoi(fn x => x < one, (0,zero))
      val nton = rtoi(fn x => x >= negone, (~1,negone))
      fun fl n = if n < zero then nton n else pton n
      fun tr n = #1(pton n)
    in 
      fun truncate n = if n < zero then InLine.~(tr(~n)) else tr n
      fun realfloor n = #2(fl n)
      fun floor n = Core.Assembly.A.floor n
      fun ceiling n : int = InLine.~(floor(~n))
    end
    fun abs x = if x < zero then ~x else x
    local
      fun loop 0 = zero
	| loop n = let val x = two * loop(InLine.rshift(n,1))
		    in case InLine.andb(n,1) of 0 => x | 1 => x + one
		   end
    in
      fun real n = if InLine.<(n,0) then ~(loop(InLine.~ n)) else loop n
    end
    fun makestring r =
	  let val itoa = Integer.makestring
	      fun scistr(a::b::tl,e) =
		    let fun trail nil = ""
			  | trail (0::tl) =
			    let val rest = trail tl
			    in  case rest of "" => ""
					   | _ => "0"^rest
			    end
			  | trail (hd::tl) = itoa hd ^ trail tl
			val rest = trail tl
		    in  itoa a ^ "." ^ itoa b ^ rest ^ "E" ^ itoa e
		    end
		| scistr _ = "" (* prevents non-exhaustive match *)
	      fun normstr(digits,e) =
		    let fun n(nil,_) = ""
			  | n(hd::nil,0) = itoa hd ^ ".0"
			  | n(hd::tl,0) = itoa hd ^ "." ^ n(tl,~1)
			  | n(0::tl,d) =
			      let val rest = n(tl,InLine.-(d,1))
			      in  case (InLine.<(d,~1),rest) of
				    (true,"") => rest
				    | _ => "0" ^ rest
			      end
			  | n(hd::tl,d) = itoa hd ^ n(tl,InLine.-(d,1))
			fun header n =
			  let fun zeros 1 = ""
				| zeros n = "0" ^ zeros(InLine.-(n,1))
			  in  "0." ^ zeros n
			  end
		    in  if InLine.<(e,0)
			then header(InLine.~ e) ^ n(digits,e)
			else n(digits,e)
		    end
	      fun mkdigits(f,0) = (nil,if f < five then 0 else 1)
		| mkdigits(f,i) =
		    let	val digit = floor f
			val new = ten * (f - real digit)
			val (digits,carry) = mkdigits(new,InLine.-(i,1))
			val (digit,carry) = case (digit,carry) of
					 (9,1) => (0,1)
					| _ => (InLine.+(digit,carry),0)
		    in  (digit::digits,carry)
		    end
	      (* should eventually speed this up by using log10 *)
	      fun mkstr(f,e) =
		  if f >= ten then mkstr(f/ten,InLine.+(e,1))
		  else if f < one then mkstr(f*ten,InLine.-(e,1))
		  else let val (digits,carry) = mkdigits(f,15)
			   val (digits,e) = case carry of
					      0 => (digits,e)
					    | _ => (1::digits,InLine.+(e,1))
		       in  if InLine.>(e,~5) andalso InLine.<(e,15)
			   then normstr(digits,e)
			   else scistr(digits,e)
		       end
	  in  if r < zero then "~" ^ mkstr(~r,0)
	      else if InLine.feql(r,zero) then "0.0"
	      else mkstr(r,0)
	  end (* fun makestring *)
    local
      val pr = IO.outputc IO.std_out
    in
      fun print r = pr(makestring r)
    end
   end (* local *)
  end (* structure Real *)

  structure System =
  struct open System
         structure Unsafe =
	 struct open Unsafe
		val cast : 'a -> 'b = InLine.cast
		val boxed : 'a -> bool = InLine.boxed
		val ordof : string * int -> int = InLine.ordof
		val slength : string -> int = InLine.slength
		val store : string * int * int -> unit = InLine.store
		val subscript : 'a array * int -> 'a = InLine.subscript
		val update : 'a array * int * 'a -> unit = InLine.update
		val delay : int * 'a -> 'a = InLine.delay
		val force : 'a -> 'a = InLine.force
		abstype 'a delay = D of 'a with end
		val delay' : 'a -> 'a delay = InLine.delay
		val force' : 'a delay -> 'a = InLine.force
	 end
	 val argv = Unsafe.CInterface.argv
	 val environ = Unsafe.CInterface.environ
  end
	
  open Array Ref String IO Bool List Integer Real General

  val _ = IO.outputc IO.std_out "Initial done\n"

end (* structure Initial *)
