# Register Serialization Configuration

Registers a serialization configuration, which may be set to perform
custom serialization and unserialization of normally non-exportable
reference objects, allowing these to be used seamlessly between
different R sessions. Once registered, the functions apply to all
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) calls
where the `serial` argument is `NULL`.

## Usage

``` r
register_serial(class, sfunc, ufunc)
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

Invisible NULL.
