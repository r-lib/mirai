# Register Serialization Configuration

Registers a serialization configuration, which may be set to perform
custom serialization and unserialization of normally non-exportable
reference objects, allowing these to be used seamlessly between
different R sessions. Once registered, the functions apply to all
[`daemons()`](https://mirai.r-lib.org/reference/daemons.md) calls where
the `serial` argument is `NULL`.

## Usage

``` r
register_serial(class, sfunc, ufunc)
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

Invisible NULL.
