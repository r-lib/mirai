# mirai (Stop)

Stops a 'mirai' if still in progress, causing it to resolve immediately
to an 'errorValue' 20 (Operation canceled).

## Usage

``` r
stop_mirai(x)
```

## Arguments

- x:

  a 'mirai' object, or list of 'mirai' objects.

## Value

Logical TRUE if the cancellation request was successful (was awaiting
execution or in execution), or else FALSE (if already completed or
previously cancelled). Will always return FALSE if not using dispatcher.

**Or** a vector of logical values if supplying a list of 'mirai', such
as those returned by
[`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md).

## Details

Using dispatcher allows cancellation of 'mirai'. In the case that the
'mirai' is awaiting execution, it is discarded from the queue and never
evaluated. In the case it is already in execution, an interrupt will be
sent.

A successful cancellation request does not guarantee successful
cancellation: the task, or a portion of it, may have already completed
before the interrupt is received. Even then, compiled code is not always
interruptible. This should be noted, particularly if the code carries
out side effects during execution, such as writing to files, etc.

## Examples

``` r
if (FALSE) { # interactive()
m <- mirai(Sys.sleep(n), n = 5)
stop_mirai(m)
m$data
}
```
