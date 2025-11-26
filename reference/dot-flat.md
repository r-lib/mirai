# mirai Map Options

Expressions to be provided to the `[]` method for 'mirai_map' objects.

## Usage

``` r
.flat

.progress

.stop
```

## Format

An object of class `bytecode` of length 1.

An object of class `bytecode` of length 1.

An object of class `bytecode` of length 1.

## Collection Options

`x[]` collects the results of a 'mirai_map' `x` and returns a list. This
will wait for all asynchronous operations to complete if still in
progress, blocking but user-interruptible.

`x[.flat]` collects and flattens map results to a vector, checking that
they are of the same type to avoid coercion. Note: errors if an
'errorValue' has been returned or results are of differing type.

`x[.progress]` collects map results whilst showing a progress bar from
the cli package, if installed, with completion percentage and ETA, or
else a simple text progress indicator. Note: if the map operation
completes too quickly then the progress bar may not show at all.

`x[.stop]` collects map results applying early stopping, which stops at
the first failure and cancels remaining operations.

The options above may be combined in the manner of:  
`x[.stop, .progress]` which applies early stopping together with a
progress indicator.
