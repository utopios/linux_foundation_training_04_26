#!/bin/bash
# A simple script to demonstrate how to run a bash script in a container.
echo "Hello, World!"
VAR="This is a variable in the container."
echo $VAR
# Expending the script to show how to use environment variables passed from the host.
echo "The value of the environment variable passed from the host is: $VAR"
# Control Flow example
if [ -n "$VAR" ]; then
    echo "The variable VAR is set and has a value."
else
    echo "The variable VAR is not set or is empty."
fi

# Loop example
for i in {1..5}; do
    echo "Loop iteration: $i"
done

# While loop example
count=1
while [ $count -le 5 ]; do
    echo "While loop iteration: $count"
    ((count++))
done

# Case statement example
case $VAR in
    "This is a variable in the container.")
        echo "The variable VAR has the expected value."
        ;;
    *)
        echo "The variable VAR does not have the expected value."
        ;;
esac

# Select statement example
select option in "Option 1" "Option 2" "Option 3"; do
    case $option in
        "Option 1")
            echo "You selected Option 1."
            ;;
        "Option 2")
            echo "You selected Option 2."
            ;;
        "Option 3")
            echo "You selected Option 3."
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
    break
done
