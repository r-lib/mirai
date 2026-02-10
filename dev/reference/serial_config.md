# Create Serialization Configuration

Returns a serialization configuration, which may be set to perform
custom serialization and unserialization of normally non-exportable
reference objects, allowing these to be used seamlessly between
different R sessions. Once set by passing to the `serial` argument of
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md), the
functions apply to all mirai requests for that compute profile.

## Usage

``` r
serial_config(class, sfunc, ufunc)
```

## Arguments

- class:

  (character) class name(s) for custom serialization, e.g.
  `'ArrowTabular'` or `c('torch_tensor', 'ArrowTabular')`.

- sfunc:

  (function \| list) serialization function(s) accepting a reference
  object and returning a raw vector.

- ufunc:

  (function \| list) unserialization function(s) accepting a raw vector
  and returning a reference object.

## Value

A list comprising the configuration. This should be passed to the
`serial` argument of
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md).

## Details

This feature utilises the 'refhook' system of R native serialization.

## Examples

``` r
cfg <- serial_config("test_cls", function(x) serialize(x, NULL), unserialize)
cfg
#> [[1]]
#> [1] "test_cls"
#> 
#> [[2]]
#> [[2]][[1]]
#> function (x) 
#> serialize(x, NULL)
#> <environment: 0x5617fbf743c0>
#> 
#> 
#> [[3]]
#> [[3]][[1]]
#> function (connection, refhook = NULL) 
#> {
#>     if (typeof(connection) != "raw" && !is.character(connection) && 
#>         !inherits(connection, "connection")) 
#>         stop("'connection' must be a connection")
#>     .Internal(unserialize(connection, refhook))
#> }
#> <bytecode: 0x5617fbf7a868>
#> <environment: namespace:base>
#> 
#> 

cfg2 <- serial_config(
  c("class_one", "class_two"),
  list(function(x) serialize(x, NULL), function(x) serialize(x, NULL)),
  list(unserialize, unserialize)
)
cfg2
#> [[1]]
#> [1] "class_one" "class_two"
#> 
#> [[2]]
#> [[2]][[1]]
#> function (x) 
#> serialize(x, NULL)
#> <environment: 0x5617fbf743c0>
#> 
#> [[2]][[2]]
#> function (x) 
#> serialize(x, NULL)
#> <environment: 0x5617fbf743c0>
#> 
#> 
#> [[3]]
#> [[3]][[1]]
#> function (connection, refhook = NULL) 
#> {
#>     if (typeof(connection) != "raw" && !is.character(connection) && 
#>         !inherits(connection, "connection")) 
#>         stop("'connection' must be a connection")
#>     .Internal(unserialize(connection, refhook))
#> }
#> <bytecode: 0x5617fbf7a868>
#> <environment: namespace:base>
#> 
#> [[3]][[2]]
#> function (connection, refhook = NULL) 
#> {
#>     if (typeof(connection) != "raw" && !is.character(connection) && 
#>         !inherits(connection, "connection")) 
#>         stop("'connection' must be a connection")
#>     .Internal(unserialize(connection, refhook))
#> }
#> <bytecode: 0x5617fbf7a868>
#> <environment: namespace:base>
#> 
#> 
```
