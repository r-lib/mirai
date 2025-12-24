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

  a character string (or vector) of the class of object custom
  serialization functions are applied to, e.g. `'ArrowTabular'` or
  `c('torch_tensor', 'ArrowTabular')`.

- sfunc:

  a function (or list of functions) that accepts a reference object
  inheriting from `class` and returns a raw vector.

- ufunc:

  a function (or list of functions) that accepts a raw vector and
  returns a reference object.

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
#> <environment: 0x56089017cb58>
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
#> <bytecode: 0x560890161700>
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
#> <environment: 0x56089017cb58>
#> 
#> [[2]][[2]]
#> function (x) 
#> serialize(x, NULL)
#> <environment: 0x56089017cb58>
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
#> <bytecode: 0x560890161700>
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
#> <bytecode: 0x560890161700>
#> <environment: namespace:base>
#> 
#> 
```
