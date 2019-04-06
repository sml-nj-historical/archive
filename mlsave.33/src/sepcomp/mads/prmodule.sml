(* prmod_MOD.sml *)

structure PrModule : PR_MODULE=

(* Converts (topmost) module to a string of the format:             *)
(*                                                                  *)
(*         DIRECTORY(<directory>)                                   *)
(*         TABLE(<table>)                                           *)
(*         FROM STAMPS(<stampinfo>)                                 *)
(*         TO STAMPS(<stampinfo>)                                   *)
(*         LVARS(<lvars>)                                           *)
(*                                                                  *)
(* The third and fourth lines give information about the value of   *)
(* stamp counters                                                   *)
(* (which are incremented with datatype declarations and generative       *)
(* structure expresssions) before and after the elaboration of the        *)
(* module.                                                                *)
(* The last line gives the list of lvars generated by the module.   *)

struct
  structure Basics = Basics
  structure Env= Env

  type dir = PrBasics.dir


  infix ^^
  val op ^^ = op ^
  fun build (print_fcns: (dir -> string * dir) list)
            (operator: string)
            (dir: dir): string * dir =

(* here *operator* is a string to be put in front of a tuple of strings
representing a value constructed out of applying the operator to
constituent values. The strings representing the constituent values are
generated by applying the functions in the list *print_fcns* *)

      let exception  pr_module_impossible;
          fun loop([],dir)= raise pr_module_impossible
            | loop(first::second::rest,dir) =
                 let val (str',dir')= first dir
                     val (str'',dir'') = loop(second::rest,dir')
                 in (str' ^^ "," ^^ str'', dir'')
                 end
            | loop([last],dir)= last dir
       in  case print_fcns of 
                [] => (operator,dir)
           |    _  => let val (args,dir') = loop (print_fcns,dir)
                      in  (operator ^^ "(" ^^ args ^^ ")", dir')
                      end
      end

  fun pr_list (print: 'a -> dir -> 
                  (string * dir))  (* printing of one elt*)
              (l    : 'a list)                      (* list for printing  *)
              (dir  : dir): string * dir= 

      let fun asmb_conts ([],dir) = ("",dir)
            | asmb_conts ([last],dir)= print last dir
            | asmb_conts (first::second::rest,dir)=
                  let val (str',dir')= print first dir
                      val (str'',dir'') = asmb_conts (second::rest,dir')
                   in (str' ^ "," ^ str'', dir'')
                  end
          val (args,dir')= asmb_conts(l,dir)
       in ("[" ^ args ^ "]",dir')
      end


  fun pr_lvars lvars = pr_list PrBasics.pr_lvar lvars

  fun pr_module(Env.STATmodule{table,from,to,lvars}): string=
      let   
            val (from_str,dir0) = 
                (print "printing from\n"; 
                 PrBasics.pr_stampInfo from PrBasics.emptydir)
            val (to_str,dir1)= 
                (print "printing to\n";
                 PrBasics.pr_stampInfo to dir0)
            val (table_str,dir2)= 
                (print "printing table\n";
                 PrBasics.pr_symtable table dir1)
            val (lvars_str,dir3)= 
                (print "printing lvars\n";
                 pr_lvars lvars dir2)
            val dir_str= 
                (print "printing directory\n";
                 PrBasics.pr_dir dir3)
       in 
            "\n\nDIRECTORY(" ^^ dir_str ^^ ")" ^^
            "\n\nTABLE("    ^^ table_str ^^ ")" ^^
            "\n\nFROM STAMPS(" ^^ from_str ^^ ")" ^^
            "\nTO STAMPS(" ^^ to_str ^^ ")" ^^
            "\nLVARS(" ^^ lvars_str ^^ ")"
       end
end

