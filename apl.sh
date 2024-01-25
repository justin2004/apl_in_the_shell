#!/bin/bash

RENDER=""
CSVOUTPUT=""
FINAL_OUTPUT="⎕←"
INPUT="SET"

while :; do
    case $1 in
        -ni|--no-input) unset INPUT
        ;;
        -r|--render) 
            RENDER="$2"            
            script+="'display' 'disp'⎕CY'dfns' ⋄"
            shift
        ;;
        -oc|--output-csv) CSVOUTPUT="SET"            
            CSVOUTPUT_EXPRESSION="'/dev/stdout'(⎕CSV⍠'IfExists' 'Replace')⍨"
            FINAL_OUTPUT="" # ⎕CSV output will return the number of bytes written and we don't want 
            #                 that to gunk up stdout
        ;;
        -ic|--input-csv) CSVINPUT="SET"            
        ;;
        *) break
    esac
    shift
done

user_function=$1
first=$2
second=$3

if [ -z "$user_function" ]
then
    echo ERROR: TODO put a helpful usage message here
    echo "for now look at the README for usage (https://github.com/justin2004/apl_in_the_shell)"
    exit 1
fi

if [ ! -z "$first" ]
then
    if [ "-" = "$first" ]
    then
        first="/dev/stdin"
    fi
    if [ ! -z $CSVINPUT ]
    then
        script+="firstargument←⎕CSV"\'$first\'" ⋄"
    else
        script+="firstargument←⊃⎕NGET"\'$first\'" 1 ⋄"
    fi
    if [ ! -z "$second" ]
    then
        if [ "-" = "$second" ]
        then
            second="/dev/stdin"
        fi
        script+="secondargument←⊃⎕NGET"\'$second\'" 1 ⋄"
        script+="$FINAL_OUTPUT $RENDER $CSVOUTPUT_EXPRESSION firstargument ($user_function) secondargument"
    else
        script+="$FINAL_OUTPUT $RENDER $CSVOUTPUT_EXPRESSION ($user_function) firstargument"
    fi
else
    first="/dev/stdin"
    if [ ! -z $CSVINPUT ]
    then
        # we have csv input from stdin
        script+="firstargument←⎕CSV"\'$first\'" ⋄"
        script+="$FINAL_OUTPUT $RENDER $CSVOUTPUT_EXPRESSION ($user_function) firstargument"
    else
        # we have input from stdin but it isn't csv
        if [ ! -z $INPUT ]
        then
            # we have input from stdin but it isn't csv AND INPUT was specified (so look for a firstargument)
            script+="firstargument←⊃⎕NGET"\'$first\'" 1 ⋄"
            script+="$FINAL_OUTPUT $RENDER $CSVOUTPUT_EXPRESSION ($user_function) firstargument"
        else
            # we have input from stdin but it isn't csv AND INPUT was not specified (so don't look for a firstargument)
            script+="$FINAL_OUTPUT $RENDER $CSVOUTPUT_EXPRESSION ($user_function)"
        fi
    fi
fi

# echo script is
# echo $script
# echo "-------"

dyalogscript <(echo $script)
