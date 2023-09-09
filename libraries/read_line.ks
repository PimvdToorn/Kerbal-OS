@LAZYGLOBAL off.

function read_line {
    parameter terminalX to 0.
    parameter terminalY to 0.
    local line to "".

    until false {
        local input is terminal:input:getchar().

        if input = terminal:input:return return line.
        if input = terminal:input:backspace and line:length > 0 {
            set line to line:substring(0, line:length - 1).
        }
        else set line to line + input.

        print line at (terminalX, terminalY).
    }
}