# With Daemons

Evaluate an expression using a specific compute profile.

## Usage

``` r
with_daemons(.compute, expr)

local_daemons(.compute, frame = parent.frame())
```

## Arguments

- .compute:

  character value for the compute profile to use (each has its own
  independent set of daemons), or NULL to use the 'default' profile.

- expr:

  an expression to evaluate.

- frame:

  the frame (environment) to which the daemons compute profile is
  scoped.

## Value

For **with_daemons**: the return value of `expr`.  
For **local_daemons**: invisible NULL.

## Details

Will error if the specified compute profile is not yet set up.

## Examples

``` r
if (FALSE) { # interactive()
daemons(1, dispatcher = FALSE, .compute = "cpu")
daemons(1, dispatcher = FALSE, .compute = "gpu")

with_daemons("cpu", {
  s1 <- status()
  m1 <- mirai(Sys.getpid())
})

with_daemons("gpu", {
  s2 <- status()
  m2 <- mirai(Sys.getpid())
  m3 <- mirai(Sys.getpid(), .compute = "cpu")
  local_daemons("cpu")
  m4 <- mirai(Sys.getpid())
})

s1$daemons
m1[]

s2$daemons
m2[] # different to m1

m3[] # same as m1
m4[] # same as m1

with_daemons("cpu", daemons(0))
with_daemons("gpu", daemons(0))
}
```
