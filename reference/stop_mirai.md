# mirai (Stop)

Stops a 'mirai' if still in progress, causing it to resolve immediately
to an 'errorValue' 20 (Operation canceled).

## Usage

``` r
stop_mirai(x)
```

## Arguments

- x:

  (mirai \| list) a 'mirai' object or list of 'mirai' objects.

## Value

Logical TRUE if the cancellation request was successful (was awaiting
execution or in execution), or else FALSE (if already completed or
previously cancelled). Will always return FALSE if not using dispatcher.

**Or** a vector of logical values if supplying a list of 'mirai', such
as those returned by
[`mirai_map()`](https://mirai.r-lib.org/reference/mirai_map.md).

## Details

Cancellation requires dispatcher. If the 'mirai' is awaiting execution,
it is discarded from the queue and never evaluated. If already
executing, an interrupt is sent.

A cancellation request does not guarantee the task stops: it may have
already completed before the interrupt is received, and compiled code is
not always interruptible. Take care if the code performs side effects
such as writing to files.

## Examples

``` r
if (FALSE) { # interactive()
m <- mirai(Sys.sleep(n), n = 5)
stop_mirai(m)
m$data
}
```
