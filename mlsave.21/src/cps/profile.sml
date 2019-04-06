(* This should be duplicated in runtime/prof.h *)

structure Profile =
struct
  val ARRAYS =		0
  val ARRAYSIZE =	1
  val STRINGS =		2
  val STRINGSIZE =	3
  val REFCELLS =	4
  val REFLISTS =	5
  val CLOSURES =	6
  val CLOSURESLOTS =	11
  val CLOSUREOVFL =	(CLOSURES + CLOSURESLOTS)
  val KCLOSURES =	(CLOSUREOVFL + 1)
  val KCLOSURESLOTS =	11
  val KCLOSUREOVFL =	(KCLOSURES + KCLOSURESLOTS)
  val CCLOSURES =	(KCLOSUREOVFL + 1)
  val CCLOSURESLOTS =	11
  val CCLOSUREOVFL =	(CCLOSURES + CCLOSURESLOTS)
  val LINKS =		(CCLOSUREOVFL + 1)
  val LINKSLOTS =	11
  val LINKOVFL =	(LINKS + LINKSLOTS)
  val SPLINKS =		(LINKOVFL + 1)
  val SPLINKSLOTS =	11
  val SPLINKOVFL =	(SPLINKS + SPLINKSLOTS)
  val RECORDS =		(SPLINKOVFL + 1)
  val RECORDSLOTS =	11
  val RECORDOVFL =	(RECORDS + RECORDSLOTS)
  val SPILLS =		(RECORDOVFL + 1)
  val SPILLSLOTS =	21
  val SPILLOVFL =	(SPILLS + SPILLSLOTS)
  val KNOWNCALLS =	(SPILLOVFL + 1)
  val STDKCALLS =	(KNOWNCALLS + 1)
  val STDCALLS =	(STDKCALLS + 1)
  val CNTCALLS =	(STDCALLS + 1)
  val PROFSIZE =	(CNTCALLS + 1)
  val profPrim =
   let fun position(s:string) =
       let fun find(s'::rest,n) = 
	         if s = s' then n else find(rest,n+1)
       in  find(Prim.inLineNames,0)
       end
   in  position "profile"
   end
end

