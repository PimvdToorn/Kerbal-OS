@LAZYGLOBAL off.

local line to "".
global readingInput to false.

function readLine {
    parameter terminalX to 0.
    parameter terminalY to 0.
    set line to "".

    until false {
        local input is terminal:input:getchar().

        if input = terminal:input:return return line.
        if input = terminal:input:backspace and line:length > 0 {
            set line to line:substring(0, line:length - 1).
            print " " at (terminalX + line:length, terminalY).
        }
        else set line to line + input.

        print line at (terminalX, terminalY).
    }
}

function readLineNonBlocking {
    parameter terminalX to 0.
    parameter terminalY to 0.
    if not readingInput {
        set line to "".
        set readingInput to true.
    }

    local input is "".
    if terminal:input:haschar set input to terminal:input:getchar().
    else return terminal:input:return.

    if input = terminal:input:return {
        set readingInput to false.
        return line.
    }
    if input = terminal:input:backspace and line:length > 0 {
        set line to line:substring(0, line:length - 1).
        print " " at (terminalX + line:length, terminalY).
    }
    else set line to line + input.

    print line at (terminalX, terminalY).
    return terminal:input:return.
}