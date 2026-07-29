# Align Format

Aligns equals and function arguments in consequtive lines of selected buffer.

### Usage
It registers command `:Align` and mapping in visual mode to `<leader>lq`.

Selected lines:
```
a = 1
abc = 2

x = foo(a, bbb)
yy = foo(cc, d)
```
Formated:
```
a   = 1
abc = 2

x  = foo(a,  bbb)
yy = foo(cc, d)
```

## Lazyvim
```lua
return {
    {
        "FLeWz/ts-align-format.nvim",
        config = function()
            require("align-format")
        end,
    },
}
```
