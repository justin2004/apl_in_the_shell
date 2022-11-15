#!/bin/bash

user_function=$1
first=$2
second=$3

if [ -z "$user_function" ]
then
    echo ERROR: TODO put a helpful usage message here
    exit 1
fi
# script+="⍎']box'⋄"
# script+="]boxing on ⋄"

if [ ! -z "$first" ]
then
    if [ "-" = "$first" ]
    then
        first="/dev/stdin"
    fi
    script+="firstargument←⊃⎕NGET"\'$first\'" 1 ⋄"
    if [ ! -z "$second" ]
    then
        if [ "-" = "$second" ]
        then
            second="/dev/stdin"
        fi
        script+="secondargument←⊃⎕NGET"\'$second\'" 1 ⋄"
        script+="⎕←firstargument ($user_function) secondargument"
    else
        script+="⎕←($user_function) firstargument"
    fi
else
    # first="/dev/stdin"
    # script+="firstargument←⊃⎕NGET"\'$first\'" 1 ⋄"
    script+="⎕←$user_function"
fi

# echo script is
# echo $script
# echo "-------"

dyalogscript <(echo $script)
