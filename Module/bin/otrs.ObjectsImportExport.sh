#!/bin/sh

CMD=bin/otrs.Console.pl
for OTRS_DIR in /ws/otrs /opt/otrs; do
    if [ -f $OTRS_DIR/$CMD ]; then
        CONSOLE="$OTRS_DIR/$CMD"
    fi
done

if [ -z "$CONSOLE" ]; then
    echo "OTRS installation was not found."
    exit 1
fi

# Check operation
if [ "$1" = "-e" ]; then
    OPERATION="Export"
elif [ "$1" = "-i" ]; then
    OPERATION="Import"
else
    echo "Specify either -e (export) or -i (import) parameter."
    exit 1
fi
shift

# Check if object type is specified on the command line
if [ -z "$1" ]; then
    OBJECTS="Group SystemAddress Queue Service Signature Salutation"
else
    OBJECTS="$1"
fi

# export or import selected object types
for object in $OBJECTS; do
    OBJECTNAME=`echo $object | tr 'A-Z' 'a-z'`
    if echo $OBJECTNAME | grep -q 's$'; then
        FILENAME="${OBJECTNAME}es.csv"
    else
        FILENAME="${OBJECTNAME}s.csv"
    fi
    $CONSOLE Admin::$object::$OPERATION $FILENAME
done
