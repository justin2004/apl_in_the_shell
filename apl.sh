#!/bin/bash

if [ $1 = -r ] # r as in render
then
    script+="'display' 'disp'⎕CY'dfns' ⋄"
    render=$2
    user_function=$3
    first=$4
    second=$5
else
    render=""
    user_function=$1
    first=$2
    second=$3
fi

if [ -z "$user_function" ]
then
    echo ERROR: TODO put a helpful usage message here
    exit 1
fi

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
        script+="⎕←$render firstargument ($user_function) secondargument"
    else
        script+="⎕←$render ($user_function) firstargument"
    fi
else
    # first="/dev/stdin"
    # script+="firstargument←⊃⎕NGET"\'$first\'" 1 ⋄"
    script+="⎕←$render $user_function"
fi

# echo script is
# echo $script
# echo "-------"

dyalogscript <(echo $script)
