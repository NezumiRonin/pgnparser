# PGN Parser
A simple PGN Parser with tools. **MADE WITH PERL!**
![ScreenShot](https://raw.githubusercontent.com/NezumiRonin/pgnparser/main/screenshot.png)



## OBJECTIVE
**PGN Parser** is a simple PGN parser made with Perl.
It contains a set of tools to process the games in a PGN file.



## INSTALL
* Just copy the perl script to your Linux computer.
* If you still somehow use Windows, you can get [Linux Mint](https://linuxmint.com/).
* If you insist in using Windows, well... you can install [Strawberry Perl](http://strawberryperl.com/).
	


## USAGE
```shell
./pgnparser.pl COMMAND file [options]
```



### COMMANDS
#### justplay
Just reads and silently plays the games, good for testing PGN file and benchmark.
#### search
Searchs a pattern in the game position. Upper/Lower case color applies. Think "short-circuit" evaluation, faster and/or lesser common positions go first for speed. In Windows, search pattern must go between double quotes.


* **w**	Evaluate only *w*hite or *b*lack active move, before the actual move. Must go first.
* **Qd1** White queen in 'd1'
* **Qma4** White queen can *m*ove/capture to 'a4', valid move with free path.
* **Qxd8** White queen can *x*capture to 'd8', destination square must be with enemy piece.
* **Qjh5** White queen can *j*ump to 'h5', ignore other pieces in path.
* **.a8**  Any piece on 'a8' (To be done)
* **!h8**  No piece on 'h8' (To be done)
* **K[Q,+1,+1]** White king has black queen one square northeast. (To de done?)

Example for 'King Usurper', white king on black throne:
```shell
./pgnparser.pl search file.pgn "w Ke8"
```

Example for 'Greek Gift Sacrifice', white turn:
```shell
./pgnparser.pl search file.pgn "w kg8 rf8 Bxh7 Nmg5 Qjh5"
```



## TO DO
* Convert game to FEN.
* Convert game to images.
* Reformat file nice.
* Code optimization.
* Nice option parser.
* Make GIF of the game.
* Patterns with OR operator.



## NOTES
* Made in a week of coding sprint, around 40 hours (because pandemic).
* Nov 28, 2020: ./pgnparser.pl justplay smyslov_2627.pgn -> 2627 games processed in 75s (35.0 gps)
* Nov 29, 2020: ./pgnparser.pl justplay smyslov_2627.pgn -> 2627 games processed in 68s (38.6 gps)
* Dec 07, 2020: ./pgnparser.pl justplay smyslov_2627.pgn -> 2627 games processed in 12s (218.9 gps)


