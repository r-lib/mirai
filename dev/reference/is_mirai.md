# Is mirai / mirai_map

Is the object a 'mirai' or 'mirai_map'.

## Usage

``` r
is_mirai(x)

is_mirai_map(x)
```

## Arguments

- x:

  an object.

## Value

Logical TRUE if `x` is of class 'mirai' or 'mirai_map' respectively,
FALSE otherwise.

## Examples

``` r
if (FALSE) { # interactive()
daemons(1, dispatcher = FALSE)
df <- data.frame()
m <- mirai(as.matrix(df), df = df)
is_mirai(m)
is_mirai(df)

mp <- mirai_map(1:3, runif)
is_mirai_map(mp)
is_mirai_map(mp[])
daemons(0)
}
```
