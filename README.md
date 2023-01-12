# apl_in_the_shell

## what

[Dyalog APL](https://dyalog.com/) in a docker container with a wrapper script that allows you to quickly use APL expressions/functions in your shell (in pipelines, etc.)

## why

[This](https://github.com/justin2004/clojure-unix/blob/master/clojure-unix.md#strangely-similar) got me thinking it would be fun to intersperse APL into my shell sessions.

The standard unix shell "primitives" might look arcane at first but once you learn them they are fantastic building blocks.
The same is true for the APL primitives but the APL primitives are even more primitive, as you'll see in some examples below, so you can do things that aren't convenient to do with unix shell primitives.


## how (build)

Have docker, make, and bash installed.

In a bash shell run:

`make`

## how (use)

In a bash shell run: 

```bash
alias apl='docker run --rm -i -v `pwd`:/mnt justin2004/apl_in_the_shell /home/containeruser/apl.sh'
```

or put a file, called `apl`, with this content in one of the directories in your PATH:

```bash
#!/bin/bash
docker run --rm -i -v `pwd`:/mnt justin2004/apl_in_the_shell /home/containeruser/apl.sh "$@"
```
and make it executable.


Test to see if it is working:

```bash
apl "⍳5"
```

should yield:
```
1 2 3 4 5
```


## examples

How many users are running processes?

```bash
justin@parens:/tmp$ ps -e -o user= | sort -u | wc -l
13
justin@parens:/tmp$ ps -e -o user= | apl '≢∪' -
13
justin@parens:/tmp$ ps -e -o user= | apl '≢∪' /dev/stdin
13
```


Generate a sequence of integers (one per line)

```bash
justin@parens:/tmp$ apl '⍪⍳10'
 1
 2
 3
 4
 5
 6
 7
 8
 9
10
justin@parens:/tmp$ seq 10
1
2
3
4
5
6
7
8
9
10
```

Generate 10 odd numbers

```bash
justin@parens:/tmp$ for (( i = 1; i < 20; i=i+2 )); do echo $i ; done
1
3
5
7
9
11
13
15
17
19
justin@parens:/tmp$ apl '⍪¯1+2×⍳10'
 1
 3
 5
 7
 9
11
13
15
17
19
```

Histogram on process executable names and users running them

```bash
justin@parens:/tmp$ ps -e -o comm,user | sort | uniq -c | sort -nr  | head
     69 chrome          justin
     38 bash            justin
      8 docker          justin
      6 vi              justin
      6 containerd-shim root
      5 vim             justin
      5 ranger          justin
      4 java            root
      3 sh              justin
      3 kdmflush        root
justin@parens:/tmp$
justin@parens:/tmp$ ps -e -o comm,user | apl "{v⌷⍨⊂⍒v←{⍺,⍨≢⍵}⌸⍵}" - | head
69  chrome          justin
38  bash            justin
 9  docker          justin
 6  vi              justin
 6  containerd-shim root
 5  vim             justin
 5  ranger          justin
 4  java            root
 3  sh              justin
 3  kdmflush        root
```

You can also use two of Dyalog APL's General Utility Functions for rendering results:
[disp](https://dfns.dyalog.com/n_disp.htm)
and
[display](https://dfns.dyalog.com/n_display.htm)

To do this specify one of the rendering functions with `-r`:

```
justin@parens:~/Downloads$ ps -e -o comm,user | apl -r disp "{5↑v⌷⍨⊂⍒v←{⍺,⍨≢⍵}⌸⍵}" -
┌──┬──────────────────────┐
│41│chrome          justin│
├──┼──────────────────────┤
│34│bash            justin│
├──┼──────────────────────┤
│8 │vim             justin│
├──┼──────────────────────┤
│5 │vi              justin│
├──┼──────────────────────┤
│4 │sh              justin│
└──┴──────────────────────┘
justin@parens:~/Downloads$ ps -e -o comm,user | apl -r display "{5↑v⌷⍨⊂⍒v←{⍺,⍨≢⍵}⌸⍵}" -
┌→────────────────────────────┐
↓    ┌→─────────────────────┐ │
│ 40 │chrome          justin│ │
│    └──────────────────────┘ │
│    ┌→─────────────────────┐ │
│ 34 │bash            justin│ │
│    └──────────────────────┘ │
│    ┌→─────────────────────┐ │
│ 8  │vim             justin│ │
│    └──────────────────────┘ │
│    ┌→─────────────────────┐ │
│ 5  │vi              justin│ │
│    └──────────────────────┘ │
│    ┌→─────────────────────┐ │
│ 4  │sh              justin│ │
│    └──────────────────────┘ │
└∊────────────────────────────┘
```




Get 10 random words from the dictionary file

```bash
justin@parens:/tmp$ head -400 /usr/share/hunspell/en_US.dic | tail -5
Amie/M
Amiga/M
Amish/M
Amman/M
Amoco/M
justin@parens:/tmp$
justin@parens:/tmp$ cat /usr/share/hunspell/en_US.dic | apl "{↑v/¨⍨~∨\¨'/'=v←⍵[10?⍴⍵]}" -
Kewpie
Jarlsberg
Delphinus
Nepal
Priceline
Khazar
Emmy
Lillie
Alba
Dropbox
justin@parens:/tmp$
justin@parens:/tmp$ cat /usr/share/hunspell/en_US.dic | shuf | head -10 | sed -e 's,/.*,,'
Okefenokee
Meyers
merited
prude
migrate
occultist
spotter
swift
murmurer
adopt
```

Just some dyadic examples

```bash
justin@parens:/tmp$ cat nums.txt
1
2
3
4
justin@parens:/tmp$ echo -e 'one\ntwo\nthree\nfour' | apl "{⍺}" nums.txt -
 1  2  3  4
justin@parens:/tmp$ echo -e 'one\ntwo\nthree\nfour' | apl "{⍵}" nums.txt -
 one  two  three  four
justin@parens:/tmp$ echo -e 'one\ntwo\nthree\nfour' | apl "{⍎¨⍺}" nums.txt -
1 2 3 4
justin@parens:/tmp$ echo -e 'one\ntwo\nthree\nfour' | apl "{+/⍎¨⍺}" nums.txt -
10
justin@parens:/tmp$ echo -e 'one\ntwo\nthree\nfour' | apl "{⍺ ⍵}" nums.txt -
  1  2  3  4    one  two  three  four
justin@parens:/tmp$ echo -e 'one\ntwo\nthree\nfour' | apl "{(⍎¨⍺)∘.⍴⍵}" nums.txt -
 o     t     t     f
 on    tw    th    fo
 one   two   thr   fou
 oneo  twot  thre  four
justin@parens:/tmp$ echo -e 'one\ntwo\nthree\nfour' | apl -r disp "{(⍎¨⍺)∘.⍴⍵}" nums.txt -
┌────┬────┬────┬────┐
│o   │t   │t   │f   │
├────┼────┼────┼────┤
│on  │tw  │th  │fo  │
├────┼────┼────┼────┤
│one │two │thr │fou │
├────┼────┼────┼────┤
│oneo│twot│thre│four│
└────┴────┴────┴────┘
justin@parens:/tmp$ echo -e 'one\ntwo\nthree\nfour' | apl -r display "{(⍎¨⍺)∘.⍴⍵}" nums.txt -
┌→────────────────────────────┐
↓ ┌→┐    ┌→┐    ┌→┐    ┌→┐    │
│ │o│    │t│    │t│    │f│    │
│ └─┘    └─┘    └─┘    └─┘    │
│ ┌→─┐   ┌→─┐   ┌→─┐   ┌→─┐   │
│ │on│   │tw│   │th│   │fo│   │
│ └──┘   └──┘   └──┘   └──┘   │
│ ┌→──┐  ┌→──┐  ┌→──┐  ┌→──┐  │
│ │one│  │two│  │thr│  │fou│  │
│ └───┘  └───┘  └───┘  └───┘  │
│ ┌→───┐ ┌→───┐ ┌→───┐ ┌→───┐ │
│ │oneo│ │twot│ │thre│ │four│ │
│ └────┘ └────┘ └────┘ └────┘ │
└∊────────────────────────────┘
```

## entering APL glyphs

I use [this](https://aplwiki.com/wiki/Typing_glyphs_on_Linux#setxkbmap) approach on Linux.
You run that single command mentioned there.
Then you'll be able to use your keyboard's right Alt key as a modifier to enter APL characters. 
For instance, you enter can the iota character ⍳ by pressing the right Alt + i, the rho character ⍴ by pressing the right Alt + r and so on.

Also see [here](https://aplwiki.com/wiki/Typing_glyphs_on_Linux) for other input methods.

I sometimes use [this](https://github.com/phantomics/april#enabling-apl-input-in-vim) vim input approach as well.

## NOTES

Dyalog APL is free for non-commercial use.
See [here](https://www.dyalog.com/prices-and-licences.htm) for license details.

Dyalog APL is running in a docker container with your host's PWD bindmounted into the container at the container's PWD.
If you reference a file name it must use relative (from your PWD) paths.
So you can't reference files above your host PWD.
And you can't `..` to get above your host's PWD.
