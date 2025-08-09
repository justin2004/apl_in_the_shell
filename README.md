# apl_in_the_shell

<!-- ![apl_in_the_shell](media/ais_4.jpg) -->
<img src="media/ais_4.jpg" alt="APL in the Shell" width="512"/>

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

Put this into your .bashrc or similar for zsh, etc.

```bash
apl() {
  if [ -t 0 ]; then
    # stdin is a terminal, OK to use -t
    docker run --platform linux/amd64 --rm -it -v "$(pwd)":/mnt justin2004/apl_in_the_shell \
        /home/containeruser/apl.sh "$@" | tr '\r' '\n'
  else
    # stdin is a pipe or file, don't use -t
    docker run --platform linux/amd64 --rm -i -v "$(pwd)":/mnt justin2004/apl_in_the_shell \
        /home/containeruser/apl.sh "$@" |tr '\r' '\n'
  fi
}
```

Now source that file in your current shell: `source ~/.bashrc`

Test to see if it is working:

```bash
apl --no-input  '⍳5'
```

should yield:
```
1 2 3 4 5
```



Most often we want to read from stdin or a file so that is why we needed to specify `--no-input` above to indicate that we just want to evaluate an expression with no other input.

If you don't specify `--no-input` or `-ni` then the process will wait for you to type something and press enter.

## examples

Printing a function (train) tree:
```bash
apl -ni '(+/÷≢) dft 1'
  ┌─┼─┐
  / ÷ ≢
┌─┘    
+  
```

This is useful to reference while constructing function trains as it indicates how they are parsed.

(NOTE: in the current Dyalog 19.x we need to use this `dft` function but once user commands (specifically `]box`) are fixed the `dft` function won't be needed.)


How many users are running processes?

```bash
ps -e -o user= | sort -u | wc -l
13
```

```bash
ps -e -o user= | apl '≢∪'
13
ps -e -o user= | apl '≢∪' -
13
ps -e -o user= | apl '≢∪' /dev/stdin
13
```

Notice that reading from stdin is assumed so you don't have to specify it.

---

Generate a sequence of integers (one per line)

```bash
apl -ni '⍪⍳10'
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

seq 10
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

---

Generate 10 odd numbers

```bash
for (( i = 1; i < 20; i=i+2 )); do echo $i ; done
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

apl -ni '⍪¯1+2×⍳10'
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

---

Histogram on process executable names and users running them

```bash
ps -e -o comm,user | sort | uniq -c | sort -nr  | head
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

ps -e -o comm,user | apl "{10↑v⌷⍨⊂⍒v←{⍺,⍨≢⍵}⌸⍵}"
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

To do this specify one of the rendering functions with `-r` (r as in render):

```bash
ps -e -o comm,user | apl -r disp "{5↑v⌷⍨⊂⍒v←{⍺,⍨≢⍵}⌸⍵}"
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

ps -e -o comm,user | apl -r display "{5↑v⌷⍨⊂⍒v←{⍺,⍨≢⍵}⌸⍵}"
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


Putting a csv file in an ASCII table using [⎕CSV](http://help.dyalog.com/latest/Content/Language/System%20Functions/csv.htm):

```bash
cat a.csv 
name,pet,age
bob,fido,33
fred,sam,10
jane,sal,3


apl -r disp --input-csv "⊢" a.csv
┌────┬────┬───┐
│name│pet │age│
├────┼────┼───┤
│bob │fido│33 │
├────┼────┼───┤
│fred│sam │10 │
├────┼────┼───┤
│jane│sal │3  │
└────┴────┴───┘
```

The `--input-csv` (or `-ic`) option is equivalent to:

```bash
apl -ni -r disp "⎕CSV 'a.csv'"
```

Note we specify `--no-input` (`-ni`) there because the csv file name is specified inside the APL expression (as a character vector) and not as one of the command line arguments.

---

Transpose a csv file:

```bash
cat a.csv | apl --output-csv -ic '⍉'
name,bob,fred,jane
pet,fido,sam,sal
age,33,10,3

cat a.csv | apl -r disp -ic '⍉'
┌────┬────┬────┬────┐
│name│bob │fred│jane│
├────┼────┼────┼────┤
│pet │fido│sam │sal │
├────┼────┼────┼────┤
│age │33  │10  │3   │
└────┴────┴────┴────┘
```

Notice above that `--output-csv` (or `-oc`) prints csv to stdout.
If you don't specify `--output-csv` Dyalog APL's matrix rendering would be used.

---

Add an `id` column to a csv file:

```bash
apl -oc -ic "{⍵,⍨(⊂'id'),⍳¯1+≢⍵}" a.csv
id,name,pet,age
1,bob,fido,33
2,fred,sam,10
3,jane,sal,3
```

The awk solution isn't bad:

```bash
awk -v OFS="," 'NR==1{print "id",$0} {print NR,$0}' a.csv
id,name,pet,age
1,name,pet,age
2,bob,fido,33
3,fred,sam,10
4,jane,sal,3
```

But since awk isn't csv aware (which matters if you have quoted cells with the delimiter character in them) it can't easily handle the general case where you might want to put the id column somewhere in the middle:

```bash
apl -oc -ic "{2⌽⍵,⍨(⊂'id'),⍳¯1+≢⍵}" a.csv
pet,age,id,name
fido,33,1,bob
sam,10,2,fred
sal,3,3,jane
```

Of course column ordering of csv is mostly meaningless but I've seen cases where it matters.

---

If you want to use the column names in csv files use the `-ch` (or `--use-csv-headers`) option:

```bash
cat some.csv
name,weight
opal,62
owen,65
justin,195

apl -ch -ic "{⍵[;name]}" some.csv
┌────┬────┬──────┐
│opal│owen│justin│
└────┴────┴──────┘

apl -ch -ic  "{⍵[;weight]}" some.csv
62 65 195

# sum of all the weights
apl -ch -ic  "{+/⍵[;weight]}" some.csv
322

# average of the weights
cat some.csv | apl  -ch -ic  "{(+/÷≢)⍵[;weight]}"
107.3333333
```

Note that the column names that are available are just the leading alpha characters (upper and lower case).
So if you have a column name "Name on business card" the column will be simply "Name".
"Name4you" will be "Name".

Also note when you use this option the header row is dropped.

---

Putting the /etc/passwd file in an ASCII table (inspired by [this](https://www.reddit.com/r/apljk/comments/yvmn9z/apl_in_the_shell_an_implementation/j24llo7/)):
```bash
head -2 /etc/passwd
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin

apl -r disp "{↑':'(≠⊆⊢)¨⍵}" /etc/passwd
┌─────────────┬─┬─────┬─────┬──────────────────────────────────┬─────────────────┬─────────────────┐
│root         │x│0    │0    │root                              │/root            │/bin/bash        │
├─────────────┼─┼─────┼─────┼──────────────────────────────────┼─────────────────┼─────────────────┤
│daemon       │x│1    │1    │daemon                            │/usr/sbin        │/usr/sbin/nologin│
├─────────────┼─┼─────┼─────┼──────────────────────────────────┼─────────────────┼─────────────────┤
│bin          │x│2    │2    │bin                               │/bin             │/usr/sbin/nologin│
├─────────────┼─┼─────┼─────┼──────────────────────────────────┼─────────────────┼─────────────────┤
...
```

---

Get 10 random words from the dictionary file

```bash
head -400 /usr/share/hunspell/en_US.dic | tail -5
Amie/M
Amiga/M
Amish/M
Amman/M
Amoco/M

cat /usr/share/hunspell/en_US.dic | apl "{↑v/¨⍨~∨\¨'/'=v←⍵[10?⍴⍵]}"
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

cat /usr/share/hunspell/en_US.dic | shuf | head -10 | sed -e 's,/.*,,'
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

---

Just some dyadic examples

```bash
cat nums.txt
1
2
3
4

echo -e 'one\ntwo\nthree\nfour' | apl "{⍺}" nums.txt -
 1  2  3  4

echo -e 'one\ntwo\nthree\nfour' | apl "{⍵}" nums.txt -
 one  two  three  four

echo -e 'one\ntwo\nthree\nfour' | apl "{⍎¨⍺}" nums.txt -
1 2 3 4

echo -e 'one\ntwo\nthree\nfour' | apl "{+/⍎¨⍺}" nums.txt -
10

echo -e 'one\ntwo\nthree\nfour' | apl "{⍺ ⍵}" nums.txt -
  1  2  3  4    one  two  three  four

echo -e 'one\ntwo\nthree\nfour' | apl "{(⍎¨⍺)∘.⍴⍵}" nums.txt -
 o     t     t     f
 on    tw    th    fo
 one   two   thr   fou
 oneo  twot  thre  four

echo -e 'one\ntwo\nthree\nfour' | apl -r disp "{(⍎¨⍺)∘.⍴⍵}" nums.txt -
┌────┬────┬────┬────┐
│o   │t   │t   │f   │
├────┼────┼────┼────┤
│on  │tw  │th  │fo  │
├────┼────┼────┼────┤
│one │two │thr │fou │
├────┼────┼────┼────┤
│oneo│twot│thre│four│
└────┴────┴────┴────┘
```

## entering APL glyphs

I use [this](https://aplwiki.com/wiki/Typing_glyphs_on_Linux#setxkbmap) approach on Linux.
You run that single command mentioned there.
Then you'll be able to use your keyboard's right Alt key as a modifier to enter APL characters. 
For instance, you enter can the iota character ⍳ by pressing the right Alt + i, the rho character ⍴ by pressing the right Alt + r and so on.

Also see [here](https://aplwiki.com/wiki/Typing_glyphs_on_Linux) for other input methods.

I sometimes use [this](https://github.com/phantomics/april#enabling-apl-input-in-vim) vim input approach as well.

## similar projects

For q there is [awq](https://github.com/adavies42/qist/blob/master/lib/awq.q).

For j there is [this](https://topaz.github.io/paste/#XQAAgAD//////////wARiEJGPfQYaqZnr3qfcB//srbYI6pNxoin1UgFBxUFegNZnW0crudtmhW/2jpcTJPZYgurbkV0/cxNLTtf4Ia2i2Tl2MLlJ0drB2SIdCgWf2N3TjHzS4X7lGSgSECr5+Z3C5uyg3avmxw1Bj+NScdyFtEB3VsC/6Zs/MhK8N8o1Ud5ZgVoo/TpVuVCPO9edQbL2zKI0IEOuISzIWAh+WuSAVqNeuYiOsAhJf8cF2A507uHqM2xwdmgQWrI5Xe1go+5wpB96yBid/Vgz5icBskwt1xaSoeg74+qxE1ROrWXPgbNoJ2/HTk+prb9b48kJT4yEymWR8KNwUm643Dq/Xd4UUaaEcz1dtAeSDCfc6w1of3/5PI=).

[jacinda](https://hackage.haskell.org/package/jacinda) "APL meets AWK"


## NOTES

Dyalog APL is free for non-commercial use.
See [here](https://www.dyalog.com/prices-and-licences.htm) for license details.

Dyalog APL is running in a docker container with your host's PWD bindmounted into the container at the container's PWD.
If you reference a file name it must use relative (from your PWD) paths.
So you can't reference files above your host PWD.
And you can't `..` to get above your host's PWD.
