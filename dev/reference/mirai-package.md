# mirai: Minimalist Async Evaluation Framework for R

*moving already*  
  
Evaluates R expressions asynchronously and in parallel, locally or
distributed across networks. An official parallel cluster type for R.
Built on 'nanonext' and 'NNG' (Nanomsg Next Generation), its
non-polling, event-driven architecture scales from a laptop to thousands
of processes across HPC clusters and cloud platforms. Features FIFO
scheduling with task cancellation, promises for reactive programming,
'OpenTelemetry' distributed tracing, and custom serialization for
cross-language data types.

## Notes

For local mirai requests, the default transport for inter-process
communications is platform-dependent: abstract Unix domain sockets on
Linux, Unix domain sockets on MacOS, Solaris and other POSIX platforms,
and named pipes on Windows.

This may be overriden, if desired, by specifying 'url' in the
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
interface and launching daemons using
[`launch_local()`](https://mirai.r-lib.org/dev/reference/launch_local.md).

## OpenTelemetry

mirai provides comprehensive OpenTelemetry tracing support for observing
asynchronous operations and distributed computation. Please refer to the
OpenTelemetry vignette for further details:
[`vignette("v05-opentelemetry", package = "mirai")`](https://mirai.r-lib.org/dev/articles/v05-opentelemetry.md)

## Reference Manual

[`vignette("mirai", package = "mirai")`](https://mirai.r-lib.org/dev/articles/mirai.md)

## See also

Useful links:

- <https://mirai.r-lib.org>

- <https://github.com/r-lib/mirai>

- Report bugs at <https://github.com/r-lib/mirai/issues>

## Author

**Maintainer**: Charlie Gao <charlie.gao@posit.co>
([ORCID](https://orcid.org/0000-0002-0750-061X))

Other contributors:

- Joe Cheng <joe@posit.co> \[contributor\]

- Posit Software, PBC ([ROR](https://ror.org/03wc8by49)) \[copyright
  holder, funder\]

- Hibiki AI Limited \[copyright holder\]
