#!/usr/bin/perl

# Tur-Chess v0.1
#===================
# November 25, 2020
# Alejandro G. Bedoya nezumi@teosistemas.com)


# CONFIGURATION SECTION
#=======================


# TO DO:
#=======
# Use TERM:ANSIcolors
# Use Ncurses.
# Check for valid castling, passant and on check



########
# MAIN #
########
use strict;
my %Board; 
my %Allow= AllowInit();


my $Proc= $ARGV[0];
my $File= $ARGV[1];


open(my $FH, $File) or die "ERR: $!($File)\n";
if ($Proc eq "search" && $ARGV[2]) { &Search($ARGV[2]); }
close($FH);
exit;



#==> THE INMORTAL GAME: Anderssen - Kieseritzky (London 1851):
my $InmortalPNG= qq|
	1 e4 e5 2 f4 exf4 3 Bc4 Qh4+ 4 Kf1 b5 5 Bxb5 Nf6 6 Nf3 Qh6 7 d3 Nh5 8 Nh4 Qg5
	9 Nf5 c6 10 Rg1 cxb5 11 g4 Nf6 12 h4 Qg6 13 h5 Qg5 14 Qf3 Ng8 15 Bxf4 Qf6
	16 Nc3 Bc5 17 Nd5 Qxb2 18 Bd6 Qxa1+ 19 Ke2 Bxg1 20 e5 Na6 21 Nxg7+ Kd8
	22 Qf6+ Nxf6 23 Be7 Checkmate.
	|;


#==> TUROCHAMP: Turing's paper machine – Alick Glennie, Manchester 1952:
my $TuroChamp= qq|
	1.e4 e5 2.Nc3 Nf6 3.d4 Bb4 4.Nf3 d6 5.Bd2 Nc6 6.d5 Nd4 7.h4 Bg4 8.a4 Nxf3+
	9.gxf3 Bh5 10.Bb5+ c6 11.dxc6 0-0 12.cxb7 Rb8 13.Ba6 Qa5 14.Qe2 Nd7
	15.Rg1 Nc5 16.Rg5 Bg6 17.Bb5 Nxb7 18.0-0-0 Nc5 19.Bc6 Rfc8 20.Bd5 Bxc3
	21.Bxc3 Qxa4 22.Kd2 Ne6 23.Rg4 Nd4 24.Qd3 Nb5 25.Bb3 Qa6 26.Bc4 Bh5
	27.Rg3 Qa4 28.Bxb5 Qxb5 29.Qxd6 Rd8 0-1.
	|;

#Play($Png);


###########
# PROCESS #
###########

sub Search {
	my ($Strpos)= @_;
	my $GameNum;
	while(1) {
		my %Game= &NextGame();
		if ($Game{MOVES} eq "") { last; }
		$GameNum++;
		print "==> GAME #$GameNum\n";
		#&PrintGame(%Game);
		&Play($Game{MOVES});
		print "\n\n\n";
		#chomp(my $key = <STDIN>);
		}
	}


sub PrintGame {
	my (%Game)= @_;
	print "Event: $Game{Event}\n";
	print "Site: $Game{Site}\n";
	print "Date: $Game{Date}\n";
	print "Round: $Game{Round}\n";
	print "White: $Game{White}\n";
	print "Black: $Game{Black}\n";
	print "Result: $Game{Result}\n";

	my $Count;
	my @Moves= &ParseMoves($Game{MOVES});
	foreach my $Mov (@Moves) {
		my ($W, $B)= split(" ", $Mov);
		$Count++;
		print "$Count\t$W\t$B\n";
		}
	return;
	}


sub NextGame {
	my %Tags;
	while(my $Line=<$FH>) {
		$Line=~ s/\r//g;
		$Line=~ s/\n//g;
		$Line=~ s/\t/ /g;
		$Line=~ s/\s+/ /g;
		$Line=~ s/^\s+//;
		$Line=~ s/\s+$//;

		if (length($Line)<3) {
			if ($Tags{MOVES}) { last; }
			next;
			}

		if ($Line=~ /^\[(.*)\]$/) {
			my ($Key, $Value)= split(/ \"/, $1);
			chop $Value;
			$Tags{$Key}= $Value;
			next;
			}
		
		$Tags{MOVES}.= $Line." ";
		}
	return %Tags;
	}


############
# GAMEPLAY #
############
sub AllowInit {
	my %Allow;
	# Direction and Distance
	# 0, 45, 90, 180, etc...
	$Allow{P}= ['0,+1', '0,+2', '-1,+1', '+1,+1'];
	$Allow{p}= ['0,-1', '0,-2', '-1,-1', '+1,-1'];
	$Allow{N}= ['+1,+2', '+2,+1', '+2,-1', '+1,-2', '-1,-2', '-2,-1', '-2,+1', '-1,+2'];

	foreach my $J (1..7) {
		my @Hori= ("0,+$J", "+$J,0", "0,-$J", "-$J,0");			
		my @Diag= ("+$J,+$J", "+$J,-$J", "-$J,-$J", "-$J,+$J");
		push @{$Allow{B}}, @Diag;
		push @{$Allow{R}}, @Hori;
		push @{$Allow{Q}}, @Diag;
		push @{$Allow{Q}}, @Hori;

		if ($J==1) {
			push @{$Allow{K}}, @Diag;
			push @{$Allow{K}}, @Hori;
			}
		}
	return %Allow;
	}


sub BoardInit {
	%Board= ();
	$Board{FLAG}{active}="w";
	$Board{FLAG}{castling}="KQkq";
	$Board{FLAG}{passant}="-";
	$Board{FLAG}{halfmove}="0";
	$Board{FLAG}{fullmove}="";
	%Board= (%Board, a8=>"r", b8=>"n", c8=>"b", d8=>"q", e8=>"k", f8=>"b", g8=>"n", h8=>"r");
	%Board= (%Board, a7=>"p", b7=>"p", c7=>"p", d7=>"p", e7=>"p", f7=>"p", g7=>"p", h7=>"p");
	%Board= (%Board, a2=>"P", b2=>"P", c2=>"P", d2=>"P", e2=>"P", f2=>"P", g2=>"P", h2=>"P");
	%Board= (%Board, a1=>"R", b1=>"N", c1=>"B", d1=>"Q", e1=>"K", f1=>"B", g1=>"N", h1=>"R");
	return;
	}


sub BoardShow {
	binmode(STDOUT, ":utf8");
	print " -----------------\n";
	for (my $Row=8; $Row>0; $Row--) {
		print "$Row|";
		foreach my $Col(("a".."h")) {
			my $Piece=$Board{$Col.$Row} ? $Board{$Col.$Row} : " ";
			if ($^O=~ /linux/i) {
				$Piece=~ tr/KQRBNP/\N{U+2654}\N{U+2655}\N{U+2656}\N{U+2657}\N{U+2658}\N{U+2659}/;
				$Piece=~ tr/kqrbnp/\N{U+265A}\N{U+265B}\N{U+265C}\N{U+265D}\N{U+265E}\N{U+265F}/;
				}
			print "$Piece|";
			}
		print "\n"; #-----------------\n";
		}
	print " -----------------\n";
	print "  a b c d e f g h\n";

	}


sub ParseMoves {
	my ($Png)=@_;
	$Png=~ s/\{.*\}//g; #Remove pesky comentaries...
	$Png=~ s/\./ /g;

	my @Moves;
	my @Parts= split(" ", $Png);
	for (my $J; $J<@Parts; $J+=3) {
		my $Wht= $Parts[$J+1];
		my $Blk= $Parts[$J+2];
		
		if ($Wht=~ /^[0-9]/) {$Wht=""; }
		if ($Blk=~ /^[0-9]/) {$Blk=""; }
		if ($Wht eq "" && $Blk eq "") { last; }
		push @Moves, "$Wht $Blk";
		}
	return @Moves;
	}


sub Play {
	my ($Moves)= @_;

	my @Board= BoardInit();
	BoardShow();
	
	my @Game= ParseMoves($Moves);

	my $Count=0;
	for my $Mov (@Game) {
		$Count++;
		my ($W, $B)= split(" ", $Mov);
		print "$Count\.\t$W\t$B\n";
		&Move($W);
		&BoardShow();
		if ($B eq "") { last; }
		&Move($B);
		&BoardShow();
		}
	}


sub Move {
	my ($OriMove)= @_;
	my $Move= $OriMove;

	#==> CASTLING:
	if ($Move eq "O-O") {
		if ($Board{FLAG}{active} eq "w") {
			BoardMove("e1", "g1"); return;
			} else {
			BoardMove("e8", "g8"); return;
			}
		}
	if ($Move eq "O-O-O") {
		if ($Board{FLAG}{active} eq "w") {
			BoardMove("e1", "c1");
			return;
			} else {
			BoardMove("e8", "c8");
			return;
			}
		}

	#==> is Pawn empty?
	if ($Move=~ /^[a-h]/) { $Move= 'P'.$Move; }

	#==> Special Sigils...
	my $Captu= 0;
	my $Check= 0;
	my $Cmate= 0;
	my $Promo= 0;
	if ($Move=~ /x/) { $Captu++; $Move=~ s/x//; }
	if ($Move=~ /\+$/) { $Check++; $Move=~ s/\+$//; }
	if ($Move=~ /\#$/) { $Cmate++; $Move=~ s/\#$//; }
	if ($Move=~ /=([QRBN])/) { $Promo= $1; $Move=~ s/=.//; print "PROMO $Promo!\n";}

	#==> Lowercase black pieces...
	if ($Board{FLAG}{active} eq "b") {
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
	##my $Whon= $Board{$To};


	#==> MOVE IT!
	my @From= WhereIs($Piece, $Deta);

	my @Psb;
	foreach my $Fro (@From) {
		my @Allowable= $Piece eq "p" ? @{$Allow{'p'}} : @{$Allow{uc($Piece)}};
		if (uc($Piece) eq "P") {
			#if ($Board{$To} eq "") {
			if ($Board{$To} eq "" && $To ne $Board{FLAG}{passant}) {
				#REM: Disable capture.
				pop @Allowable;
				pop @Allowable;
				} else {
				#REM: Disable foward, must capture
				#shift @Allowable;
				#shift @Allowable;
				}
			}
		foreach my $Try (@Allowable) {
			my ($Ax, $Ay)= split(",", $Try);
			my $Tto= ToCoords($Fro, $Ax, $Ay);
			#print "ALLOW: $Fro($Try) -> $Tto\n";
			if ($Tto eq $To && scalar(CheckPath($Fro, $To))==0) {
				push @Psb, $Fro;
				}
			};
		}
	if (scalar @Psb==1) {
		BoardMove($Psb[0], $To);
		if ($Promo) { $Board{$To}= $Promo; }
		return;
		}

	print "ERR: Couldn't make move ($OriMove)!\n";
	print "DEBUG: Active=$Board{FLAG}{active} Piece=$Piece Deta=$Deta Captu=$Captu To=$To Promo=$Promo\n";
	exit 666;
	}


sub BoardMove {
	my ($From, $To)= @_;

	my $Piece= $Board{$From};
	my $Steps= Steps($From, $To);
	$Board{$To}= delete $Board{$From};
	
	#REM: Castling move rook.
	if (uc($Piece) eq "K" && $Steps==2) {
		if ($To eq "g1") { $Board{f1}= delete $Board{h1}; $Board{FLAG}{castling}=~ s/K//;}
		if ($To eq "c1") { $Board{d1}= delete $Board{a1}; $Board{FLAG}{castling}=~ s/Q//;}
		if ($To eq "g8") { $Board{f8}= delete $Board{h8}; $Board{FLAG}{castling}=~ s/k//;}
		if ($To eq "c8") { $Board{d8}= delete $Board{a8}; $Board{FLAG}{castling}=~ s/q//;}
		}

	#REM: Passant remove captured pawn
	if (uc($Piece) eq "P" && $To eq $Board{FLAG}{passant}) {
		my $X= substr($To, 0, 1);
		if ($To=~ /3$/) { delete $Board{$X."4"}; }
		if ($To=~ /6$/) { delete $Board{$X."5"}; }
		}

	$Board{FLAG}{passant}="-";
	if (uc($Piece) eq "P" && $Steps==2) {
		my $X= substr($From, 0, 1);
		if ($From=~ /2$/) { $Board{FLAG}{passant}= $X."3"; }
		if ($From=~ /7$/) { $Board{FLAG}{passant}= $X."6"; }
		}

	$Board{FLAG}{active}= $Board{FLAG}{active} eq "w" ? "b" : "w";
	return;
	}


sub WhereIs {
	my ($Piece, $Deta)= @_;
	my @Square;
	foreach my $Pos (sort keys %Board) {
		if (length($Pos)!=2) { next; }
		if ($Deta && $Pos!~ /$Deta/) { next; }
		if ($Board{$Pos} eq $Piece) { push @Square, $Pos; }
		}
	return @Square;
	}


sub ToCoords {
	my ($Square, $Px, $Py)= @_;
	my ($X, $Y)= split("", $Square);
	$X=~ tr/abcdefgh/12345678/;
	$X+= $Px;
	$Y+= $Py;
	if ($X<1 || $X>8) { return undef; }
	if ($Y<1 || $Y>8) { return undef; }
	$X=~ tr/12345678/abcdefgh/;
	$Square= $X.$Y;
	return $Square;	
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


sub CheckPath {
	my ($From, $To)= @_;
	my $Steps= &Steps($From, $To);
	my $From2= $From;
	my $To2= $To;
	$From2=~ tr/abcdefgh/12345678/;
	$To2=~ tr/abcdefgh/12345678/;
	my ($Fx,$Fy)= split("", $From2);
	my ($Tx,$Ty)= split("", $To2);
	my $Dx= $Fx-$Tx;
	my $Dy= $Fy-$Ty;
	my @Path;

	#==> It's a Knight...
	#Can use euclidian distance 1²+2²=5 always
	if (uc($Board{$From}) eq "N" && $Steps==2) {
		return @Path;
		}

	#==> Whatever else...
	my $Jx= 0;
	my $Jy= 0;
	foreach my $Mov(0..$Steps-2) {
		if ($Dx<0) { $Jx++;}
		if ($Dx>0) { $Jx--;}
		if ($Dy<0) { $Jy++;}
		if ($Dy>0) { $Jy--;}
		my $Pos= ToCoords($From, $Jx, $Jy);
		my $Pie= $Board{$Pos};
		if ($Pie ne "") { push @Path, "$Pie$Pos"; }
		}	
	return @Path;
	}


