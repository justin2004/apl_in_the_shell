#!/bin/bash

RENDER=""
CSVOUTPUT=""
FINAL_OUTPUT="⎕←"
INPUT="SET"
# this allows trains to be rendered as ASCII trees
PREAMBLE="(⎕NS⍬).(_←enableSALT⊣⎕CY'salt')\n]Box on -trains=tree\n"

print_usage() {
    echo "Usage: apl [OPTION] {FUNCTION} [input file ⍵]"
    echo "       apl [OPTION] {FUNCTION} [input file ⍺] [input file ⍵]"
    echo "       apl --no-input [OPTION] {EXPRESSION}"
    echo ""
    echo "  -d, --debug"
    echo "    print the generated APL expression, to stderr, before it is evaluated"
    echo ""
    echo "  -ni, --no-input"
    echo "    don't attempt to read from stdin"
    echo "    NOTE: reading from stdin is assumed so you need this option if you just"
    echo "    want to evaluate an expression with no other input"
    echo ""
    echo "  -r {function name}, --render {function name}"
    echo "    use function (either 'disp' or 'display') to render the final result"
    echo ""
    echo "  -oc, --output-csv"
    echo "    print the result of the evaluation as CSV"
    echo ""
    echo "  -ic, --input-csv"
    echo "    treat input file ⍵ as a CSV and read it in using ⎕CSV"
    echo "    then ⍵ to your function is the array produced by ⎕CSV"
    echo ""
    echo "  -ch, --use-csv-headers"
    echo "    make the column names of the CSV file available as variables"
    echo "    which evaluate to the position of the column and which can be"
    echo "    used to index into the array (by column name)"
    echo ""
    echo "Examples:"
    echo ""
    echo "  see https://github.com/justin2004/apl_in_the_shell"
    echo ""
}

while :; do
    case $1 in
        -h|--help)
            print_usage
        ;;
        -d|--debug) DEBUG="SET"
        ;;
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
    print_usage
    # echo ERROR: TODO put a helpful usage message here
    # echo "for now look at the README for usage (https://github.com/justin2004/apl_in_the_shell)"
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
        script+="firstargument←⎕CSV"\'$first\'" 'UTF-8' (4) ⋄"
        # the 4 above means: "The field is to be interpreted numeric data but invalid numeric data is tolerated. Empty fields and fields which cannot be converted to numeric values are returned instead as character data"
        # there are other options however: https://help.dyalog.com/18.2/Content/Language/System%20Functions/csv.htm
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
        script+="firstargument←⎕CSV"\'$first\'" 'UTF-8' (4) ⋄"
        # the 4 above means: "The field is to be interpreted numeric data but invalid numeric data is tolerated. Empty fields and fields which cannot be converted to numeric values are returned instead as character data"
        # there are other options however: https://help.dyalog.com/18.2/Content/Language/System%20Functions/csv.htm
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

if [ ! -z $DEBUG ]
then
    echo DEBUG: APL script is: >&2
    echo DEBUG: $script >&2
fi

if [ ! -z $USE_PREAMBLE ]
then
    dyalogscript <(echo -e $PREAMBLE ; echo $script)
else
    dyalogscript <(echo $script)
fi

