# PGN Parser
A simple PGN Parser with tools. **MADE WITH PERL!**

## Objetive
**PGN Parser** is a simple PGN parser made with Perl.
It contains a set of tools to process the games in a PGN file.

## Install
Just copy the perl script to your Linux computer.
If you use somehow still use Windows, you can get [Linux Mint](https://linuxmint.com/).
If you insist in using Windows, you can install [Strawberry Perl](http://strawberryperl.com/).
	

## Usaga
```shell
./pgnparser.pl COMMAND file [options]
```

### Commands
search: Searchs a pattern


j: it's a special "detail" character and stands for Jump, to ignore other pieces in the move path.
Think "short-circuit" evaluation, faster and/or lesser common positions go first for speed.
Example for 'Greek gift sacrifice':
```shell
./pgnparser.pl search file.pgn 'w Bxh7 Ng5 Qjh5'
```

tofen: Converts games to FEN.
Example:
```shell
./pgnparser.pl search file.pgn
```


