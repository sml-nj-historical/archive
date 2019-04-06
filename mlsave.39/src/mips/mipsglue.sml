structure MipsAC : ASSEMBLER = struct
    val diag_out = ref std_out
    structure MCN = struct
        open MipsCoder
	structure M = struct
	    open M
	    fun comment s = output (!diag_out) s
	end
    end
        
    structure CM = MipsCM(MCN)
	
    structure Gen = CPScomp(CM)
    fun generate (lexp, stream) = (
        diag_out := stream;
	Gen.compile lexp;
	MipsCoder.codestats stream;
	Emitters.address := 0;
	MipsCoder.codegen (Emitters.MipsAsm stream);
	())
end

structure MipsCodeStats : ASSEMBLER = struct
    val diag_out = ref std_out
    structure MCN = MipsCoder
        
    structure CM = MipsCM(MCN)
	
    structure Gen = CPScomp(CM)
    fun generate (lexp, stream) = (
	Gen.compile lexp;
	MipsCoder.codestats stream;
	())
end

structure MipsMCBig : CODEGENERATOR = struct
    structure CM = MipsCM(MipsCoder)
    structure Gen = CPScomp(CM)
 
    fun generate lexp = (
	Gen.compile lexp;
	MipsCoder.codegen (Emitters.BigEndian);
	Emitters.emitted_string ()
	)
end

structure MipsMCLittle : CODEGENERATOR = struct
    structure CM = MipsCM(MipsCoder)
    structure Gen = CPScomp(CM)
fun diag (s : string) f x =
	f x handle e =>
		(print "?exception "; print (System.exn_name e);
		 print " in mipsglue."; print s; print "\n";
		 raise e)
 
    fun generate lexp = (
	diag "Gen.compile" Gen.compile lexp;
	diag "MipsCoder.codegen" MipsCoder.codegen (Emitters.LittleEndian);
	diag "Emitters.emitted_string" Emitters.emitted_string ()
	)
end


structure CompMipsLittle = Batch(structure M=MipsMCLittle and A=MipsAC)
structure IntMipsLittle = IntShare(MipsMCLittle)

structure CompMipsBig = Batch(structure M=MipsMCBig and A=MipsAC)
structure IntMipsBig = IntShare(MipsMCBig)

structure CompMipsStats = Batch(structure M=MipsMCLittle and A=MipsCodeStats)
