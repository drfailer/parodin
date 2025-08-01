package parodin

import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:unicode/utf8"
import "core:log"

Location :: struct {
    row: int,
    col: int,
    file: string,
}

ParserState :: struct {
    content: ^string,
    pos: int,
    cur: int,
    loc: Location,
    user_data: rawptr,
}

state_eat_one :: proc(state: ParserState) -> (new_state: ParserState, ok: bool) {
    if state.cur >= len(state.content^) do return state, false
    new_state = state
    if state_char(state) == '\n' {
        new_state.loc.row += 1
        new_state.loc.col = 0
    }
    new_state.cur += 1
    new_state.loc.col += 1
    return new_state, true
}

state_advance :: proc(state: ParserState) -> (new_state: ParserState, ok: bool) {
    if state.cur >= len(state.content^) do return state, false
    new_state = state
    new_state.cur += 1
    new_state.pos += 1
    return new_state, true
}

state_eof :: proc(state: ParserState) -> bool {
    return state.cur >= len(state.content^)
}

state_save_pos :: proc(state: ^ParserState) {
    state.pos = state.cur
}

state_char_at :: proc(state: ParserState, idx: int) -> rune {
    return utf8.rune_at_pos(state.content^, idx)
}

state_char :: proc(state: ParserState) -> rune {
    return state_char_at(state, state.cur)
}

state_string_at :: proc(state: ParserState, begin: int, end: int) -> string {
    // TODO: how to deal with an error here?
    result, _ := strings.substring(state.content^, begin, end)
    return result
}

state_string :: proc(state: ParserState) -> string {
    return state_string_at(state, state.pos, state.cur)
}

@(private="file")
find_line_start :: proc(state: ParserState) -> int {
    cur := min(state.cur, len(state.content^) - 1)
    for i := cur; i >= 0; i -= 1 {
        if state_char_at(state, i) == '\n' do return i
    }
    return 0
}

@(private="file")
find_line_end :: proc(state: ParserState) -> int {
    for i := state.cur; i < len(state.content^); i += 1 {
        if state_char_at(state, i) == '\n' do return i
    }
    return len(state.content^)
}

@(private="file")
indent :: proc(n: int) {
    for i := 0; i < n; i += 1 {
        fmt.print(" ")
    }
}

state_print_context :: proc(state: ParserState) {
    begin := find_line_start(state)
    end := find_line_end(state)
    row_bytes: [10]u8
    sb := strings.builder_from_bytes(row_bytes[:])

    // row to string
    strings.write_int(&sb, state.loc.row)
    row_str := strings.to_string(sb)

    fmt.printfln(" {} | {}", row_str, state_string_at(state, begin, end));
    indent(len(row_str))
    fmt.print("  | ")
    indent(state.cur - begin)
    fmt.print("^\n")
}
