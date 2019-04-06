(* Copyright 1989 by AT&T Bell Laboratories *)
structure Opcodes = struct
val andb = Bits.andb
fun lshift(op1,amt) = 
    if amt<0 then Bits.rshift(op1,0-amt)
    else Bits.lshift(op1,amt)
nonfix sub
nonfix div
val S_fmt = 16+0
val D_fmt = 16+1
val W_fmt = 16+4
fun op'LO(A1) = 0
fun op'HI(A1) = lshift(A1,10)
fun rsLO(A1) = 0
fun rsHI(A1) = lshift(A1,5)
fun rtLO(A1) = 0
fun rtHI(A1) = lshift(A1,0)
fun immedLO(A1) = andb(lshift(A1,0),65535)
fun immedHI(A1) = 0
fun offsetLO(A1) = andb(lshift(A1,0),65535)
fun offsetHI(A1) = 0
fun baseLO(A1) = 0
fun baseHI(A1) = lshift(A1,5)
fun targetLO(A1) = andb(lshift(A1,0),65535)
fun targetHI(A1) = lshift(A1,~16)
fun rdLO(A1) = andb(lshift(A1,11),65535)
fun rdHI(A1) = 0
fun shamtLO(A1) = andb(lshift(A1,6),65535)
fun shamtHI(A1) = 0
fun functLO(A1) = andb(lshift(A1,0),65535)
fun functHI(A1) = 0
fun condLO(A1) = 0
fun condHI(A1) = lshift(A1,0)
fun ftLO(A1) = 0
fun ftHI(A1) = lshift(A1,0)
fun fmtLO(A1) = 0
fun fmtHI(A1) = lshift(A1,5)
fun fsLO(A1) = andb(lshift(A1,11),65535)
fun fsHI(A1) = 0
fun fdLO(A1) = andb(lshift(A1,6),65535)
fun fdHI(A1) = 0
fun add(A1,A2,A3) = (rdHI(A1)+rsHI(A2)+rtHI(A3)+op'HI(0)+functHI(32), rdLO(A1)+rsLO(A2)+rtLO(A3)+op'LO(0)+functLO(32))
fun addi(A1,A2,A3) = (rtHI(A1)+rsHI(A2)+immedHI(A3)+op'HI(8), rtLO(A1)+rsLO(A2)+immedLO(A3)+op'LO(8))
fun addiu(A1,A2,A3) = (rtHI(A1)+rsHI(A2)+immedHI(A3)+op'HI(9), rtLO(A1)+rsLO(A2)+immedLO(A3)+op'LO(9))
fun addu(A1,A2,A3) = (rdHI(A1)+rsHI(A2)+rtHI(A3)+op'HI(0)+functHI(33), rdLO(A1)+rsLO(A2)+rtLO(A3)+op'LO(0)+functLO(33))
fun and'(A1,A2,A3) = (rdHI(A1)+rsHI(A2)+rtHI(A3)+op'HI(0)+functHI(36), rdLO(A1)+rsLO(A2)+rtLO(A3)+op'LO(0)+functLO(36))
fun andi(A1,A2,A3) = (rtHI(A1)+rsHI(A2)+immedHI(A3)+op'HI(12), rtLO(A1)+rsLO(A2)+immedLO(A3)+op'LO(12))
fun beq(A1,A2,A3) = (rsHI(A1)+rtHI(A2)+offsetHI(A3)+op'HI(4), rsLO(A1)+rtLO(A2)+offsetLO(A3)+op'LO(4))
fun bgez(A1,A2) = (rsHI(A1)+offsetHI(A2)+op'HI(1)+condHI(1), rsLO(A1)+offsetLO(A2)+op'LO(1)+condLO(1))
fun bgezal(A1,A2) = (rsHI(A1)+offsetHI(A2)+op'HI(1)+condHI(17), rsLO(A1)+offsetLO(A2)+op'LO(1)+condLO(17))
fun bgtz(A1,A2) = (rsHI(A1)+offsetHI(A2)+op'HI(7), rsLO(A1)+offsetLO(A2)+op'LO(7))
fun blez(A1,A2) = (rsHI(A1)+offsetHI(A2)+op'HI(6), rsLO(A1)+offsetLO(A2)+op'LO(6))
fun bltz(A1,A2) = (rsHI(A1)+offsetHI(A2)+op'HI(1)+condHI(0), rsLO(A1)+offsetLO(A2)+op'LO(1)+condLO(0))
fun bltzal(A1,A2) = (rsHI(A1)+offsetHI(A2)+op'HI(1)+condHI(16), rsLO(A1)+offsetLO(A2)+op'LO(1)+condLO(16))
fun bne(A1,A2,A3) = (rsHI(A1)+rtHI(A2)+offsetHI(A3)+op'HI(5), rsLO(A1)+rtLO(A2)+offsetLO(A3)+op'LO(5))
val break = (op'HI(0)+functHI(13), op'LO(0)+functLO(13))
fun div(A1,A2) = (rsHI(A1)+rtHI(A2)+op'HI(0)+functHI(26), rsLO(A1)+rtLO(A2)+op'LO(0)+functLO(26))
fun divu(A1,A2) = (rsHI(A1)+rtHI(A2)+op'HI(0)+functHI(27), rsLO(A1)+rtLO(A2)+op'LO(0)+functLO(27))
fun j(A1) = (targetHI(A1)+op'HI(2), targetLO(A1)+op'LO(2))
fun jal(A1) = (targetHI(A1)+op'HI(3), targetLO(A1)+op'LO(3))
fun jalr(A1,A2) = (rsHI(A1)+rdHI(A2)+op'HI(0)+functHI(9), rsLO(A1)+rdLO(A2)+op'LO(0)+functLO(9))
fun jr(A1) = (rsHI(A1)+op'HI(0)+functHI(8), rsLO(A1)+op'LO(0)+functLO(8))
fun lb(A1,A2,A3) = (rtHI(A1)+offsetHI(A2)+baseHI(A3)+op'HI(32), rtLO(A1)+offsetLO(A2)+baseLO(A3)+op'LO(32))
fun lbu(A1,A2,A3) = (rtHI(A1)+offsetHI(A2)+baseHI(A3)+op'HI(36), rtLO(A1)+offsetLO(A2)+baseLO(A3)+op'LO(36))
fun lh(A1,A2,A3) = (rtHI(A1)+offsetHI(A2)+baseHI(A3)+op'HI(33), rtLO(A1)+offsetLO(A2)+baseLO(A3)+op'LO(33))
fun lb(A1,A2,A3) = (rtHI(A1)+offsetHI(A2)+baseHI(A3)+op'HI(32), rtLO(A1)+offsetLO(A2)+baseLO(A3)+op'LO(32))
fun lhu(A1,A2,A3) = (rtHI(A1)+offsetHI(A2)+baseHI(A3)+op'HI(37), rtLO(A1)+offsetLO(A2)+baseLO(A3)+op'LO(37))
fun lui(A1,A2) = (rtHI(A1)+immedHI(A2)+op'HI(15), rtLO(A1)+immedLO(A2)+op'LO(15))
fun lw(A1,A2,A3) = (rtHI(A1)+offsetHI(A2)+baseHI(A3)+op'HI(35), rtLO(A1)+offsetLO(A2)+baseLO(A3)+op'LO(35))
fun lwl(A1,A2,A3) = (rtHI(A1)+offsetHI(A2)+baseHI(A3)+op'HI(34), rtLO(A1)+offsetLO(A2)+baseLO(A3)+op'LO(34))
fun lwr(A1,A2,A3) = (rtHI(A1)+offsetHI(A2)+baseHI(A3)+op'HI(38), rtLO(A1)+offsetLO(A2)+baseLO(A3)+op'LO(38))
fun mfhi(A1) = (rdHI(A1)+op'HI(0)+functHI(16), rdLO(A1)+op'LO(0)+functLO(16))
fun mflo(A1) = (rdHI(A1)+op'HI(0)+functHI(18), rdLO(A1)+op'LO(0)+functLO(18))
fun mthi(A1) = (rsHI(A1)+op'HI(0)+functHI(17), rsLO(A1)+op'LO(0)+functLO(17))
fun mtlo(A1) = (rsHI(A1)+op'HI(0)+functHI(19), rsLO(A1)+op'LO(0)+functLO(19))
fun mult(A1,A2) = (rsHI(A1)+rtHI(A2)+op'HI(0)+functHI(24), rsLO(A1)+rtLO(A2)+op'LO(0)+functLO(24))
fun multu(A1,A2) = (rsHI(A1)+rtHI(A2)+op'HI(0)+functHI(25), rsLO(A1)+rtLO(A2)+op'LO(0)+functLO(25))
fun nor(A1,A2,A3) = (rdHI(A1)+rsHI(A2)+rtHI(A3)+op'HI(0)+functHI(39), rdLO(A1)+rsLO(A2)+rtLO(A3)+op'LO(0)+functLO(39))
fun or(A1,A2,A3) = (rdHI(A1)+rsHI(A2)+rtHI(A3)+op'HI(0)+functHI(37), rdLO(A1)+rsLO(A2)+rtLO(A3)+op'LO(0)+functLO(37))
fun ori(A1,A2,A3) = (rtHI(A1)+rsHI(A2)+immedHI(A3)+op'HI(13), rtLO(A1)+rsLO(A2)+immedLO(A3)+op'LO(13))
fun sb(A1,A2,A3) = (rtHI(A1)+offsetHI(A2)+baseHI(A3)+op'HI(40), rtLO(A1)+offsetLO(A2)+baseLO(A3)+op'LO(40))
fun sh(A1,A2,A3) = (rtHI(A1)+offsetHI(A2)+baseHI(A3)+op'HI(41), rtLO(A1)+offsetLO(A2)+baseLO(A3)+op'LO(41))
fun sll(A1,A2,A3) = (rdHI(A1)+rtHI(A2)+shamtHI(A3)+op'HI(0)+functHI(0), rdLO(A1)+rtLO(A2)+shamtLO(A3)+op'LO(0)+functLO(0))
fun sllv(A1,A2,A3) = (rdHI(A1)+rtHI(A2)+rsHI(A3)+op'HI(0)+functHI(4), rdLO(A1)+rtLO(A2)+rsLO(A3)+op'LO(0)+functLO(4))
fun slt(A1,A2,A3) = (rdHI(A1)+rsHI(A2)+rtHI(A3)+op'HI(0)+functHI(42), rdLO(A1)+rsLO(A2)+rtLO(A3)+op'LO(0)+functLO(42))
fun slti(A1,A2,A3) = (rtHI(A1)+rsHI(A2)+immedHI(A3)+op'HI(10), rtLO(A1)+rsLO(A2)+immedLO(A3)+op'LO(10))
fun sltiu(A1,A2,A3) = (rtHI(A1)+rsHI(A2)+immedHI(A3)+op'HI(11), rtLO(A1)+rsLO(A2)+immedLO(A3)+op'LO(11))
fun sltu(A1,A2,A3) = (rdHI(A1)+rsHI(A2)+rtHI(A3)+op'HI(0)+functHI(43), rdLO(A1)+rsLO(A2)+rtLO(A3)+op'LO(0)+functLO(43))
fun sra(A1,A2,A3) = (rdHI(A1)+rtHI(A2)+shamtHI(A3)+op'HI(0)+functHI(3), rdLO(A1)+rtLO(A2)+shamtLO(A3)+op'LO(0)+functLO(3))
fun srav(A1,A2,A3) = (rdHI(A1)+rtHI(A2)+rsHI(A3)+op'HI(0)+functHI(7), rdLO(A1)+rtLO(A2)+rsLO(A3)+op'LO(0)+functLO(7))
fun srl(A1,A2,A3) = (rdHI(A1)+rtHI(A2)+shamtHI(A3)+op'HI(0)+functHI(2), rdLO(A1)+rtLO(A2)+shamtLO(A3)+op'LO(0)+functLO(2))
fun srlv(A1,A2,A3) = (rdHI(A1)+rtHI(A2)+rsHI(A3)+op'HI(0)+functHI(6), rdLO(A1)+rtLO(A2)+rsLO(A3)+op'LO(0)+functLO(6))
fun sub(A1,A2,A3) = (rdHI(A1)+rsHI(A2)+rtHI(A3)+op'HI(0)+functHI(34), rdLO(A1)+rsLO(A2)+rtLO(A3)+op'LO(0)+functLO(34))
fun subu(A1,A2,A3) = (rdHI(A1)+rsHI(A2)+rtHI(A3)+op'HI(0)+functHI(35), rdLO(A1)+rsLO(A2)+rtLO(A3)+op'LO(0)+functLO(35))
fun sw(A1,A2,A3) = (rtHI(A1)+offsetHI(A2)+baseHI(A3)+op'HI(43), rtLO(A1)+offsetLO(A2)+baseLO(A3)+op'LO(43))
fun swl(A1,A2,A3) = (rtHI(A1)+offsetHI(A2)+baseHI(A3)+op'HI(42), rtLO(A1)+offsetLO(A2)+baseLO(A3)+op'LO(42))
fun swr(A1,A2,A3) = (rtHI(A1)+offsetHI(A2)+baseHI(A3)+op'HI(46), rtLO(A1)+offsetLO(A2)+baseLO(A3)+op'LO(46))
val syscall = (op'HI(0)+functHI(12), op'LO(0)+functLO(12))
fun xor(A1,A2,A3) = (rdHI(A1)+rsHI(A2)+rtHI(A3)+op'HI(0)+functHI(38), rdLO(A1)+rsLO(A2)+rtLO(A3)+op'LO(0)+functLO(38))
fun xori(A1,A2,A3) = (rtHI(A1)+rsHI(A2)+immedHI(A3)+op'HI(14), rtLO(A1)+rsLO(A2)+immedLO(A3)+op'LO(14))
fun add_fmt(A1,A2,A3,A4) = (fmtHI(A1)+fdHI(A2)+fsHI(A3)+ftHI(A4)+op'HI(17)+functHI(0), fmtLO(A1)+fdLO(A2)+fsLO(A3)+ftLO(A4)+op'LO(17)+functLO(0))
fun div_fmt(A1,A2,A3,A4) = (fmtHI(A1)+fdHI(A2)+fsHI(A3)+ftHI(A4)+op'HI(17)+functHI(3), fmtLO(A1)+fdLO(A2)+fsLO(A3)+ftLO(A4)+op'LO(17)+functLO(3))
fun lwc1(A1,A2,A3) = (ftHI(A1)+offsetHI(A2)+baseHI(A3)+op'HI(49), ftLO(A1)+offsetLO(A2)+baseLO(A3)+op'LO(49))
fun mul_fmt(A1,A2,A3,A4) = (fmtHI(A1)+fdHI(A2)+fsHI(A3)+ftHI(A4)+op'HI(17)+functHI(2), fmtLO(A1)+fdLO(A2)+fsLO(A3)+ftLO(A4)+op'LO(17)+functLO(2))
fun neg_fmt(A1,A2,A3) = (fmtHI(A1)+fdHI(A2)+fsHI(A3)+op'HI(17)+functHI(7), fmtLO(A1)+fdLO(A2)+fsLO(A3)+op'LO(17)+functLO(7))
fun sub_fmt(A1,A2,A3,A4) = (fmtHI(A1)+fdHI(A2)+fsHI(A3)+ftHI(A4)+op'HI(17)+functHI(1), fmtLO(A1)+fdLO(A2)+fsLO(A3)+ftLO(A4)+op'LO(17)+functLO(1))
fun swc1(A1,A2,A3) = (ftHI(A1)+offsetHI(A2)+baseHI(A3)+op'HI(57), ftLO(A1)+offsetLO(A2)+baseLO(A3)+op'LO(57))
fun c_seq(A1,A2,A3) = (fmtHI(A1)+fsHI(A2)+ftHI(A3)+op'HI(17)+functHI(58), fmtLO(A1)+fsLO(A2)+ftLO(A3)+op'LO(17)+functLO(58))
fun c_lt(A1,A2,A3) = (fmtHI(A1)+fsHI(A2)+ftHI(A3)+op'HI(17)+functHI(60), fmtLO(A1)+fsLO(A2)+ftLO(A3)+op'LO(17)+functLO(60))
fun cop1(A1,A2,A3) = (rsHI(A1)+rtHI(A2)+offsetHI(A3)+op'HI(17), rsLO(A1)+rtLO(A2)+offsetLO(A3)+op'LO(17))
end (* Opcodes *)
