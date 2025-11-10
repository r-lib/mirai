# On Daemon

Returns a logical value, whether or not evaluation is taking place
within a mirai call on a daemon.

## Usage

``` r
on_daemon()
```

## Value

Logical `TRUE` or `FALSE`.

## Examples

``` r
if (FALSE) { # interactive()
on_daemon()
mirai(mirai::on_daemon())[]
}
```
