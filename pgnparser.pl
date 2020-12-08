#!/usr/bin/perl
# PGN Parser v0.1
#===================
# November 25, 2020
# Alejandro G. Bedoya nezumi@teosistemas.com

# CONFIGURATION SECTION
#=======================
my $Pedantic= 1;
my $OnError= 0;  #0=die 1=debug 2=silent


########
# MAIN #
########
use strict;
my $Lapse= time;
my $GameNum;
my $GameLin;
my %Search;
my @Pattern;

my $FH;
my %GAME;
my %BOARD;


#REM: PROCESS...
my $Proc= $ARGV[0];
my $File= $ARGV[1];
if ($Proc eq "justplay") { &JustPlay(); }
if ($Proc eq "search" && $ARGV[2]) { &Search($ARGV[2]); }


#REM: Finally...
$Lapse= time-$Lapse;
my $Persec= $GameNum>0 ? sprintf("%.1f", $Lapse>0 ? $GameNum/$Lapse : 0) : 0;
print "$GameNum games processed in $Lapse\s ($Persec gps)\n";
exit;


############
# COMMANDS #
############

sub JustPlay {
	while(1) {
		&NextGame();
		if ($GAME{MOVES} eq "") { last; }
		&Play();
		}
	return;
	}


sub Search {
	my ($Str)= @_;
	@Pattern= split(" ", $Str);
	while(1) {
		$Search{MoveCount}=0;
		&NextGame();
		if ($GAME{MOVES} eq "") { last; }
		&Play($GAME{MOVES});
		}
	}



########
# FILE #
########

sub NextGame {
	%GAME= ();
	my $Start=1;

	if ($GameLin==0) { open($FH, $File) or die "ERR: $!($File)\n"; }
	while(my $Line=<$FH>) {
		$GameLin++;
		$Line=~ s/\r//g;
		$Line=~ s/\n//g;
		$Line=~ s/\t/ /g;
		$Line=~ s/\s+/ /g;
		$Line=~ s/^\s+//;
		$Line=~ s/\s+$//;
		$Line=~ s/^;.*$//;

		if ($Line=~ /^\[(.*)\]$/) {
			if ($Start==1) {
				$GAME{GameNum}= ++$GameNum;
				$GAME{GameLin}= $GameLin;
				$Start=0;
				}
			my ($Key, $Value)= split(/ \"/, $1);
			chop $Value;
			$GAME{$Key}= $Value;
			next;
			}

		if (length($Line)<3) {
			if ($GAME{PRIME}) { last; }
			next;
			}
		$GAME{PRIME}.= $Line." ";
		}
	if (eof($FH)) { close($FH); }
	&ParsePrime();
	return;
	}


sub ParsePrime {
	my $Pgn= $GAME{PRIME};
	
	#REM: Remove balanced pesky comentaries...
	if ($Pedantic) {
		$Pgn=~ s/{.*}/ /g;
		} else {
		my @Balance;
		my $Pos1;
		my $Pos2;
		for (my $J=0; $J<length($Pgn); $J++) {
			my $Char= substr($Pgn, $J, 1);
			if ($Char=~ /[\{\(]/) {
				if (scalar(@Balance)==0) { $Pos1= $J; }
				push @Balance, $Char;
				}
			if ($Char=~ /[\}\)]/) {
				if (scalar(@Balance)==1) {
					$Pos2= $J+1;
					substr($Pgn, $Pos1, $Pos2-$Pos1) = " " x ($Pos2-$Pos1);
					}
				pop @Balance
				}
			}
		$Pgn=~ s/\d+\.\.\./ /g; #Remove elipsis...
		$Pgn=~ s/\$\d+/ /g; #I dont't know what $n means...	
		}


	#REM: Damn final results...
	$Pgn=~ s/1-0/ /g;
	$Pgn=~ s/0-1/ /g;
	$Pgn=~ s/1\/2-1\/2/ /g;

	
	#REM: Final Cleaning...
	$Pgn=~ s/\./ /g;
	$Pgn=~ s/\s+/ /g;


	#REM: Last check...
	if ($Pgn=~ /[^KQRBNPa-h0-9x O\=\-\+\#\!\?]/ ) {
		print "ERR: Moves not valid! (Game #$GAME{GameNum}, Line #$GAME{GameLin})\n";
		print "PRIME:\n$GAME{PRIME}\n";
		print "MOVES:\n$Pgn\n";
		exit 666;
		}

	$GAME{MOVES}= $Pgn;
	my @Moves;
	my @Parts= split(" ", $Pgn);
	for (my $J; $J<@Parts; $J+=3) {
		my $Wht= $Parts[$J+1];
		my $Blk= $Parts[$J+2];
		
		#if ($Wht=~ /^[0-9*]/) {$Wht=""; }
		#if ($Blk=~ /^[0-9*]/) {$Blk=""; }
		if ($Wht eq "" && $Blk eq "") { last; }
		push @Moves, "$Wht $Blk";
		}
	$GAME{ARRAY}= \@Moves;
	return;
	}


############
# GAMEPLAY #
############
sub BoardInit {
	%BOARD= ();
	$BOARD{FLAG}{active}="w";
	$BOARD{FLAG}{castling}="KQkq";
	$BOARD{FLAG}{passant}="-";
	$BOARD{FLAG}{halfmove}= 0;
	$BOARD{FLAG}{fullmove}= 1;
	%BOARD= (%BOARD, a8=>"r", b8=>"n", c8=>"b", d8=>"q", e8=>"k", f8=>"b", g8=>"n", h8=>"r");
	%BOARD= (%BOARD, a7=>"p", b7=>"p", c7=>"p", d7=>"p", e7=>"p", f7=>"p", g7=>"p", h7=>"p");
	%BOARD= (%BOARD, a2=>"P", b2=>"P", c2=>"P", d2=>"P", e2=>"P", f2=>"P", g2=>"P", h2=>"P");
	%BOARD= (%BOARD, a1=>"R", b1=>"N", c1=>"B", d1=>"Q", e1=>"K", f1=>"B", g1=>"N", h1=>"R");
	return;
	}


sub Play {
	my @Board= &BoardInit();	
	my $Count=0;
	for my $Mov (@{$GAME{ARRAY}}) {
		$Count++;
		my ($Wht, $Blk)= split(" ", $Mov);
		&Move($Wht);
		if ($Blk eq "") { last; }
		&Move($Blk);
		}
	return;
	}


sub Move {
	my ($OriMove)= @_;
	my $Move= $OriMove;

	#==> Special Sigils...
	my $Promo= 0;
	my $Captu= $Move=~ /x/ ? 1 : 0;
	my $Check= $Move=~ /\+$/ ? 1 : 0;
	my $Cmate= $Move=~ /\#$/ ? 1 : 0;
	if ($Move=~ /=([QRBN])/) { $Promo= $1; $Move=~ s/=.//; }
	$Move=~ s/[x\+\#\!\?]//g;

	#==> CASTLING:
	if ($Move eq "O-O") {
		if ($BOARD{FLAG}{active} eq "w") {
			BoardMove("e1", "g1"); return;
			} else {
			BoardMove("e8", "g8"); return;
			}
		}
	if ($Move eq "O-O-O") {
		if ($BOARD{FLAG}{active} eq "w") {
			BoardMove("e1", "c1");
			return;
			} else {
			BoardMove("e8", "c8");
			return;
			}
		}

	#==> is Pawn empty?
	if ($Move=~ /^[a-h]/) { $Move= 'P'.$Move; }

	#==> Lowercase black pieces...
	if ($BOARD{FLAG}{active} eq "b") {
		my $Chng=lc(substr($Move, 0, 1));
		$Move= $Chng.substr($Move, 1);
		$Promo= lc($Promo);
		}

	#==> Move structure...
	my $Piece= substr($Move, 0, 1);
	my $To= substr($Move, length($Move)-2, 2);
	substr($Move, 0, 1)= "";
	substr($Move, length($Move)-2, 2)= "";
	my $Deta= $Move;

	#==> MOVE IT!
	my @From= &WhereIs($Piece, $Deta);
	my @Psb;
	foreach my $Fro (sort @From) {
		if (&CanMove($Fro, $To)==1) { push @Psb, $Fro; }
		}
	if (scalar @Psb==1) {
		BoardMove($Psb[0], $To);
		if ($Promo) { $BOARD{$To}= $Promo; }
		return;
		}

	print "ERR: Couldn't make move! ($BOARD{FLAG}{fullmove}. ";
	if ($BOARD{FLAG}{active} eq "w") { print "$OriMove ...)\n" }
		else { print "... $OriMove)\n" }
	print "DBG:  Piece=$Piece Deta=$Deta Captu=$Captu To=$To Promo=$Promo Psb=".scalar(@Psb)."\n";
	&ShowData();
	exit 666;
	}


sub Enpass {
	my $Square= $BOARD{FLAG}{passant};
	if ($Square eq "-") { return ""; }
	my $X= substr($Square, 0, 1);
	if ($Square=~ /3$/) { return $X."4"; }
	if ($Square=~ /6$/) { return $X."5"; }
	return ""
	}


sub WhereIs {
	my ($Piece, $Deta)= @_;
	my @Square;
	foreach my $Pos (keys %BOARD) {
		if (length($Pos)!=2) { next; }
		if ($Deta && $Pos!~ /$Deta/) { next; }
		if ($BOARD{$Pos} eq $Piece) { push @Square, $Pos; }
		}
	return @Square;
	}


sub ToCoords {
	my ($Square, $Coords)= @_;
	my ($Fx, $Fy)= split("", $Square);
	my ($Tx, $Ty)= split(",", $Coords);
	$Fx=~ tr/abcdefgh/12345678/;
	$Fx+= $Tx;
	$Fy+= $Ty;
	if ($Fx<1 || $Fx>8) { return undef; }
	if ($Fy<1 || $Fy>8) { return undef; }
	$Fx=~ tr/12345678/abcdefgh/;
	return $Fx.$Fy;	
	}


sub WhatColor {
	my ($Piece)= @_;
	if ($Piece eq "") {return ""; }
	#if ($Piece=~ /[KQRBNP]/) { return "w"; }
	#if ($Piece=~ /[kqrbnp]/) { return "b"; }
	if ($Piece eq uc($Piece)) { return "w"; }
	if ($Piece eq lc($Piece)) { return "b"; }
	return "";
	}


sub Steps {
	my ($From, $To)= @_;
	$From=~ tr/abcdefgh/12345678/;
	$To=~ tr/abcdefgh/12345678/;
	my ($X1, $Y1)= split("", $From);
	my ($X2, $Y2)= split("", $To);
	my $X= abs($X1-$X2);
	my $Y= abs($Y1-$Y2);
	return $X>$Y ? $X : $Y; 
	}


sub IsFoe {
	my ($Piece, $Sqr)= @_;
	if ($BOARD{$Sqr} eq "") { return 0; }
	if (&WhatColor($Piece) ne &WhatColor($BOARD{$Sqr})) { return 1; }
	return -1; #Partner.
	}


sub Attacking {
	my ($Square)= @_;
	my $Piece= $BOARD{$Square};
	my @Enemies= qw(K Q R B N P);

	my @AttFrom= ();
	if (&WhatColor($Piece) eq "w") { @Enemies = map{lc $_} @Enemies; }
	#print "IsAttacked: $Piece $Square @Enemies\n";
	foreach my $Ene (@Enemies) {
		my @From= &WhereIs($Ene);
		foreach my $Fro (@From) {
			if (&CanMove($Fro, $Square, 1)==1) { push @AttFrom, $Fro; } 
			}
		}
	return @AttFrom;
	}


sub CanMove {
	my ($From, $To, $Jmp)= @_;

	my $Piece= $BOARD{$From};
	my $Pieto= $BOARD{$To};
	my $PieUC= uc($Piece);

	#REM: Square TO must not be ocuppied by same color...
	if ($Pieto ne "" && $Jmp==0 && &WhatColor($Piece) eq &WhatColor($Pieto)) { return 0; }

	my ($Fx, $Fy)= split("", $From);
	my ($Tx, $Ty)= split("", $To);
	$Fx=~ tr/abcdefgh/12345678/;
	$Tx=~ tr/abcdefgh/12345678/;

	my $X= $Tx-$Fx;
	my $Y= $Ty-$Fy;
	my $Steps= ($X**2)+($Y**2);

	#REM: It's a knight...
	if ($PieUC eq "N") {
		if ($Steps==5) { goto FINAL; }
			else { return 0; }
		}


	#REM: Whatever else...
	if ($X!=0 && $Y!=0 && abs($X)!=abs($Y)) { return 0; }
	if ($X==0 || $Y==0) {
		if ($PieUC eq "B") { return 0; }
		$Steps= abs($X+$Y);
		}
	if (abs($X)==abs($Y)) {
		if ($PieUC eq "R") { return 0; }
		$Steps= abs($X)+0.5;
		}
	if ($PieUC eq "K" && $Steps<2) { goto FINAL; }


	#REM: It's a pawn...
	if ($PieUC eq "P") {
		if ($Steps>2) { return 0; }
		my @Moves= ('0,+1', '0,+2', '+1,+1', '-1,+1');
		if ($Piece eq "p") { @Moves= ('0,-1', '0,-2', '-1,-1', '+1,-1'); }
		my $Step1= &ToCoords($From, $Moves[0]);
		my $Step2= &ToCoords($From, $Moves[1]);
		my $CaptR= &ToCoords($From, $Moves[2]);
		my $CaptL= &ToCoords($From, $Moves[3]);

		if ($Steps==1 && $Step1 eq $To && $BOARD{$Step1} eq "") { goto FINAL; }
		if ($Steps==2) {
			if ($Piece eq "P" && $From!~ /2/) { return 0; }
			if ($Piece eq "p" && $From!~ /7/) { return 0; }
			if ($BOARD{$Step1} ne "" || $BOARD{$Step2} ne "") { return 0; }
			goto FINAL;
			}
		if ($Steps==1.5) {
			if ($BOARD{FLAG}{passant} eq $To) { goto FINAL; }
			if (&IsFoe($Piece, $To)!=1) { return 0; }
			if ($CaptR eq $To || $CaptR eq $BOARD{FLAG}{passant}) { goto FINAL; }
			if ($CaptL eq $To || $CaptL eq $BOARD{FLAG}{passant}) { goto FINAL; }
			}
		return 0;
		}

	if ($Jmp==1) { goto FINAL; }

	my $Sx= $X<=>0;
	my $Sy= $Y<=>0;
	foreach my $Step (1..$Steps-1) {
		$Fx+= $Sx;
		$Fy+= $Sy;
		$Fx=~ tr/12345678/abcdefgh/;
		my $Curr= $Fx.$Fy;
		if ($BOARD{$Curr} ne "") { return 0; }
		$Fx=~ tr/abcdefgh/12345678/;
		}


	#REM: Legal Move, finally test for check state.
	FINAL: #REM: Dijkstra would hate this...
	my $King= &WhatColor($Piece) eq "w" ? "K" : "k";
	my %Save= %BOARD;
	$BOARD{$To}= delete $BOARD{$From};
	if (uc($Piece) eq "P" && $To eq $BOARD{FLAG}{passant}) {
		delete %BOARD{&Enpass()};
		}
	
	my $Check= &IsCheck($King);
	%BOARD= %Save;
	if ($Check==1) { return 0; }

	return 1;
	}


sub IsCheck {
	my ($King)= @_;
	my ($Origin)= &WhereIs($King);
	my $Color= &WhatColor($King);
	my $Enemy= $Color eq "w" ? "b" : "w";

	my @Direc= ("0,+1", "+1,+1", "+1,0", "+1,-1", "0,-1", "-1,-1", "-1,0", "-1,+1");
	my @Knight= ("+1,+2", "+2,+1", "+2,-1", "+1,-2", "-1,-2", "-2,-1", "-2,+1", "-1,+2");

	foreach my $J (0..7) {
		my $Pos= $Origin;
	
		#REM: Try knight...
		my $Try= &ToCoords($Origin,$Knight[$J]);
		if (uc($BOARD{$Try}) eq "N" && &WhatColor($BOARD{$Try}) eq $Enemy) { return 1;}

		foreach my $K (1..7) {
			$Pos= &ToCoords($Pos,$Direc[$J]);
			if ($Pos eq "") { last; }
			if ($BOARD{$Pos} eq "") { next; }
			my $Wc= &WhatColor($BOARD{$Pos});
			if ($Wc eq $Color ) { last; }
			if ($Wc eq $Enemy ) {
				if ($K==1 && $BOARD{$Pos}=~ /K/i) { return 1;}
				if (($J % 2)==0 && $BOARD{$Pos}=~ /[QR]/i) { return 1; }
				if (($J % 2)==1 && $BOARD{$Pos}=~ /[QB]/i) { return 1; }
				if ($K==1 && $BOARD{$Pos}=~ /P/i) {
					if ($Color eq "w" && ( $J==1 || $J==7)) { return 1; }
					if ($Color eq "b" && ( $J==3 || $J==5)) { return 1; }
					}
				last;
				}
			}
		}
	return 0;
	}


sub BoardMove {
	#REM: Makes move of pieces in the board and adjust flags.
	my ($From, $To)= @_;

	my $Piece= $BOARD{$From};
	my $Steps= Steps($From, $To);
	$BOARD{$To}= delete $BOARD{$From};
	
	#REM: Castling move rook.
	if (uc($Piece) eq "K" && $Steps==2) {
		if ($To eq "g1") { $BOARD{f1}= delete $BOARD{h1}; $BOARD{FLAG}{castling}=~ s/K//;}
		if ($To eq "c1") { $BOARD{d1}= delete $BOARD{a1}; $BOARD{FLAG}{castling}=~ s/Q//;}
		if ($To eq "g8") { $BOARD{f8}= delete $BOARD{h8}; $BOARD{FLAG}{castling}=~ s/k//;}
		if ($To eq "c8") { $BOARD{d8}= delete $BOARD{a8}; $BOARD{FLAG}{castling}=~ s/q//;}
		}

	#REM: Passant move...
	if (uc($Piece) eq "P" && $To eq $BOARD{FLAG}{passant}) {
		delete $BOARD{&Enpass()};
		}
	$BOARD{FLAG}{passant}="-";
	if (uc($Piece) eq "P" && $Steps==2) {
		my $X= substr($From, 0, 1);
		if ($From=~ /2$/) { $BOARD{FLAG}{passant}= $X."3"; }
		if ($From=~ /7$/) { $BOARD{FLAG}{passant}= $X."6"; }
		}

	#REM: Toggle color turn...
	if ($BOARD{FLAG}{active} eq "b") { $BOARD{FLAG}{fullmove}++; }
	$BOARD{FLAG}{active}= $BOARD{FLAG}{active} eq "w" ? "b" : "w";
	if (scalar @Pattern) { &Pattern(); }
	return;
	}



#########
# UTILS #
#########
sub BoardShow {
	binmode(STDOUT, ":utf8");
	print " -----------------\n";
	for (my $Row=8; $Row>0; $Row--) {
		print "$Row|";
		foreach my $Col(("a".."h")) {
			my $Piece=$BOARD{$Col.$Row} ? $BOARD{$Col.$Row} : " ";
			if ($^O=~ /linux/i) {
				$Piece=~ tr/KQRBNP/\N{U+2654}\N{U+2655}\N{U+2656}\N{U+2657}\N{U+2658}\N{U+2659}/;
				$Piece=~ tr/kqrbnp/\N{U+265A}\N{U+265B}\N{U+265C}\N{U+265D}\N{U+265E}\N{U+265F}/;
				}
			print "$Piece|";
			}
		print "\n";
		}
	print " -----------------\n";
	print "  a b c d e f g h\n";
	return;
	}


sub PrintGame {
	print "Event: $GAME{Event}\n";
	print "Site: $GAME{Site}\n";
	print "Date: $GAME{Date}\n";
	print "Round: $GAME{Round}\n";
	print "White: $GAME{White}\n";
	print "Black: $GAME{Black}\n";
	print "Result: $GAME{Result}\n";

	my $Count;
	foreach my $Mov (@{$GAME{ARRAY}}) {
		my ($W, $B)= split(" ", $Mov);
		$Count++;
		print "$Count\t$W\t$B\n";
		}
	return;
	}


sub ShowData {
	print "GAME #$GAME{GameNum}, line: $GAME{GameLin}\n";
	&BoardShow();
	print "PRIME(Original):\n";
	print "$GAME{PRIME}\n";
	print "MOVES(Cleaned):\n";
	print "$GAME{MOVES}\n";
	print "ARRAY(Internal):\n";
	my $Count=0;
	for my $Mov (@{$GAME{ARRAY}}) {
		$Count++;
		my ($Wht, $Blk)= split(" ", $Mov);
		print "$Count. $Wht $Blk ";
		}
	print "\n";
	return;
	}


sub Pattern {
	if ($Pattern[0] ne $BOARD{FLAG}{active}) {return;}
	#if ($Search{GameLimit}>$Search{GameFound}) { return; }
	foreach my $Pat (@Pattern) {
		if (length($Pat)<3) { next; }
		my $Piece= substr($Pat, 0, 1);
		my $Chr= length($Pat)==3 ? "" : substr($Pat, 1, 1);
		my $Sqr= substr($Pat, -2);
		if ($Chr eq "") {
			if ($BOARD{$Sqr} ne $Piece) { return; }
			}

		if ($Chr=~ /[mxj]/) { #Can Move/Capture
			my @From= &WhereIs($Piece);
			my $Flag;
			if ($Chr eq "x") {
				my $Enemy= $BOARD{$Sqr};
				if ($Enemy eq "") { return; }
				if (&WhatColor($Piece) eq &WhatColor($Enemy)) { return; }
				}

			my $Jmp= $Chr eq "j" ? 1 : 0;
			foreach my $Fro (@From) {
				if (&CanMove($Fro, $Sqr, $Jmp)) { $Flag++; } 
				}
			if ($Flag==0) { return; }
			}
		}
	print "FOUND: Game #$GAME{GameNum}(L$GAME{GameLin}), move $BOARD{FLAG}{fullmove}$BOARD{FLAG}{active}\n";
	&BoardShow();
	print "\n";
	$Search{GameLimit}++;
	return;
	}



