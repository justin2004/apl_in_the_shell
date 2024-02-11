#!/bin/bash

RENDER=""
CSVOUTPUT=""
FINAL_OUTPUT="⎕←"
INPUT="SET"
# this allows trains to be rendered as ASCII trees
PREAMBLE="(⎕NS⍬).(_←enableSALT⊣⎕CY'salt')\n]Box on -trains=tree\n"

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
        -ch|--use-csv-headers) USE_CSV_HEADERS="SET"            
            # now try to get column names
            csv_headers_script+="col_names_raw ← ,1↑firstargument ⋄"
            csv_headers_script+="col_names← {⍵/⍨^\⍵∊(¯1∘⎕c⎕a),⎕a}¨ col_names_raw ⋄"
            # TODO if not col_names ≡ col_names_raw then print a warning? 
            csv_headers_script+="{⍎¨,/¯1⌽'←',1⌽({⍵},⍕∘⍪∘⍳∘≢)⍵} col_names ⋄"
            csv_headers_script+="firstargument ← 1↓firstargument ⋄"
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
        if [ ! -z $USE_CSV_HEADERS ]
        then
            script+=$csv_headers_script
        fi
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
        if [ ! -z $USE_CSV_HEADERS ]
        then
            script+=$csv_headers_script
        fi
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
            USE_PREAMBLE="SET"
            # we only want to use the preamble if --no-input is specified
            script+="$FINAL_OUTPUT $RENDER $CSVOUTPUT_EXPRESSION ($user_function)"
        fi
    fi
fi

# echo script is
# echo $script
# echo "-------"

if [ ! -z $USE_PREAMBLE ]
then
    dyalogscript <(echo -e $PREAMBLE ; echo $script)
else
    dyalogscript <(echo $script)
fi

