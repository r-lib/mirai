# Serialization - Arrow, ADBC, polars, torch

### 1. Serialization: Arrow, polars and beyond

Native R serialization is used for sending data between host and
daemons. Some R objects by their nature cannot be serialized, such as
those accessed via an external pointer. In these cases, performing mirai
operations on them would normally error.

Using the [`arrow`](https://arrow.apache.org/docs/r/) package as an
example:

``` r
library(mirai)
library(arrow, warn.conflicts = FALSE)
daemons(1)
everywhere(library(arrow))

x <- as_arrow_table(iris)

m <- mirai(list(a = head(x), b = "some text"), x = x)
m[]
#> 'miraiError' chr Error: Invalid <Table>, external pointer to null

daemons(0)
```

However,
[`serial_config()`](https://mirai.r-lib.org/dev/reference/serial_config.md)
can be used to create custom serialization configurations, specifying
functions that hook into R’s native serialization mechanism for
reference objects (‘refhooks’).

This configuration may then be passed to the ‘serial’ argument of a
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) call.

``` r
cfg <- serial_config(
  "ArrowTabular",
  arrow::write_to_raw,
  function(x) arrow::read_ipc_stream(x, as_data_frame = FALSE)
)

daemons(1, serial = cfg)

everywhere(library(arrow))

m <- mirai(list(a = head(x), b = "some text"), x = x)
m[]
#> $a
#> Table
#> 6 rows x 5 columns
#> $Sepal.Length <double>
#> $Sepal.Width <double>
#> $Petal.Length <double>
#> $Petal.Width <double>
#> $Species <dictionary<values=string, indices=int8>>
#> 
#> See $metadata for additional Schema metadata
#> 
#> $b
#> [1] "some text"

daemons(0)
```

It can be seen that this time, the arrow table is handled seamlessly.
This is the case even when the object is deeply nested inside lists or
other structures.

Multiple serialization functions may be registered to handle different
object classes. As an example, we can use Arrow in combination with
[`polars`](https://pola-rs.github.io/r-polars/), a ‘lightning fast’
dataframe library written in Rust (requires polars \>= 1.0.0), in the
following way:

``` r
daemons(
  n = 1,
  serial = serial_config(
    c("ArrowTabular", "polars_data_frame"),
    list(arrow::write_to_raw, \(x) x$serialize()),
    list(function(x) arrow::read_ipc_stream(x, as_data_frame = FALSE), polars::pl$deserialize_df)
  )
)

x <- polars::as_polars_df(iris)

m <- mirai(list(a = head(x), b = "some text"), x = x)
m[]
#> $a
#> shape: (6, 5)
#> ┌──────────────┬─────────────┬──────────────┬─────────────┬─────────┐
#> │ Sepal.Length ┆ Sepal.Width ┆ Petal.Length ┆ Petal.Width ┆ Species │
#> │ ---          ┆ ---         ┆ ---          ┆ ---         ┆ ---     │
#> │ f64          ┆ f64         ┆ f64          ┆ f64         ┆ cat     │
#> ╞══════════════╪═════════════╪══════════════╪═════════════╪═════════╡
#> │ 5.1          ┆ 3.5         ┆ 1.4          ┆ 0.2         ┆ setosa  │
#> │ 4.9          ┆ 3.0         ┆ 1.4          ┆ 0.2         ┆ setosa  │
#> │ 4.7          ┆ 3.2         ┆ 1.3          ┆ 0.2         ┆ setosa  │
#> │ 4.6          ┆ 3.1         ┆ 1.5          ┆ 0.2         ┆ setosa  │
#> │ 5.0          ┆ 3.6         ┆ 1.4          ┆ 0.2         ┆ setosa  │
#> │ 5.4          ┆ 3.9         ┆ 1.7          ┆ 0.4         ┆ setosa  │
#> └──────────────┴─────────────┴──────────────┴─────────────┴─────────┘
#> 
#> $b
#> [1] "some text"

daemons(0)
```

### 2. Serialization: Torch

Tensors from the [`torch`](https://torch.mlverse.org/) package may be
used seamlessly in mirai computations.

Setup Steps:

1.  Create the serialization configuration, specifying ‘class’ as
    ‘torch_tensor’.
2.  Set up daemons, supplying the configuration to the ‘serial’
    argument.
3.  (Optional) Use
    [`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md)
    to make the `torch` package available on all daemons for
    convenience.

``` r
library(mirai)
library(torch)

cfg <- serial_config(
  class = "torch_tensor",
  sfunc = torch::torch_serialize,
  ufunc = torch::torch_load
)

daemons(1, serial = cfg)

everywhere(library(torch))
```

Example Usage:

The below example creates a convolutional neural network using
`torch::nn_module()`.

A set of model parameters is also specified.

The model specification and parameters are then passed to and
initialized within a parallel process.

``` r
model <- nn_module(
  initialize = function(in_size, out_size) {
    self$conv1 <- nn_conv2d(in_size, out_size, 5)
    self$conv2 <- nn_conv2d(in_size, out_size, 5)
  },
  forward = function(x) {
    x <- self$conv1(x)
    x <- nnf_relu(x)
    x <- self$conv2(x)
    x <- nnf_relu(x)
    x
  }
)

params <- list(in_size = 1, out_size = 20)

m <- mirai(do.call(model, params), model = model, params = params)

m[]
#> An `nn_module` containing 1,040 parameters.
#> 
#> ── Modules ────────────────────────────────────────────────────────────────────────────────────────────────
#> • conv1: <nn_conv2d> #520 parameters
#> • conv2: <nn_conv2d> #520 parameters
```

The returned model is an object containing many tensor elements.

``` r
m$data$parameters$conv1.weight
#> torch_tensor
#> (1,1,.,.) = 
#>   0.0908  0.0460  0.1045 -0.0790  0.0880
#>  -0.0069  0.1784 -0.1328  0.1755 -0.1033
#>  -0.1428 -0.0733  0.0696  0.1000 -0.1565
#>   0.0460  0.0485  0.1853  0.0970 -0.1119
#>  -0.0799 -0.0552 -0.0889  0.0086  0.1952
#> 
#> (2,1,.,.) = 
#>  -0.0831 -0.1367  0.0896 -0.1574 -0.1586
#>  -0.1490 -0.0808 -0.1637 -0.1876  0.0190
#>  -0.1224  0.0978 -0.0446  0.1532 -0.1613
#>  -0.1477 -0.0427  0.1231  0.0174 -0.1507
#>   0.1036  0.1193  0.1798  0.1320  0.0741
#> 
#> (3,1,.,.) = 
#>  -0.0074  0.1343 -0.0903  0.1079  0.1009
#>  -0.1618  0.1391  0.1301 -0.0983 -0.1804
#>  -0.1534  0.0612  0.1402 -0.0081  0.0157
#>   0.1846  0.1652  0.1725 -0.0199 -0.0243
#>   0.0234  0.0039  0.0280 -0.1897  0.0476
#> 
#> (4,1,.,.) = 
#>  -0.0248  0.0536  0.1141 -0.1415  0.0791
#>  -0.1637  0.0823 -0.1708 -0.1474 -0.1588
#>  -0.0692  0.1054  0.0048 -0.0694  0.1760
#>   0.0049  0.1237  0.1670  0.1171 -0.0228
#>  -0.1769 -0.1000  0.1073  0.1777 -0.0203
#> 
#> (5,1,.,.) = 
#>  -0.0123  0.1480  0.1773 -0.0896 -0.1685
#> ... [the output was truncated (use n=-1 to disable)]
#> [ CPUFloatType{20,1,5,5} ][ requires_grad = TRUE ]
```

It is usual for model parameters to then be passed to an optimizer.

This can also be initialized within a parallel process.

``` r
optim <- mirai(optim_rmsprop(params = params), params = m$data$parameters)

optim[]
#> <optim_rmsprop>
#>   Inherits from: <torch_optimizer>
#>   Public:
#>     add_param_group: function (param_group) 
#>     clone: function (deep = FALSE) 
#>     defaults: list
#>     initialize: function (params, lr = 0.01, alpha = 0.99, eps = 1e-08, weight_decay = 0, 
#>     load_state_dict: function (state_dict, ..., .refer_to_state_dict = FALSE) 
#>     param_groups: list
#>     state: State, R6
#>     state_dict: function () 
#>     step: function (closure = NULL) 
#>     zero_grad: function (set_to_none = FALSE) 
#>   Private:
#>     deep_clone: function (name, value) 
#>     step_helper: function (closure, loop_fun)

daemons(0)
```

Above, tensors and complex objects containing tensors were passed
seamlessly between host and daemon processes, in the same way as any
other R object.

The custom serialization in mirai leverages R’s own native ‘refhook’
mechanism to allow completely transparent usage. Designed to be fast and
efficient, data copies are minimized and the ‘official’ serialization
methods from the `torch` package are used directly.

### 3. Database Hosting using Arrow Database Connectivity

It is possible using the `DBI` interface to access and manipulate data
in the Apache Arrow data format efficiently through ABDC (Arrow Database
Connectivity).

The example below creates an in-memory SQLite connection using the
`adbcsqlite` backend.

Serialization is set up with the relevant serialization functions from
the `arrow` package as part of the
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) call.
Note that the specified class is ‘nanoarrow_array_stream’ as `nanoarrow`
is the backend for all queries made by the DBI `db*Arrow()` functions.

``` r
library(mirai)

cfg <- serial_config(
  class = "nanoarrow_array_stream",
  sfunc = arrow::write_to_raw,
  ufunc = function(x) arrow::read_ipc_stream(x, as_data_frame = FALSE)
)

daemons(1, serial = cfg)

everywhere(
  {
    library(DBI) # `adbi` and `adbcsqlite` packages must also be installed
    con <<- dbConnect(adbi::adbi("adbcsqlite"), uri = ":memory:")
  }
)
```

[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) calls may
then be used to write to or query the database all in the Arrow format.

``` r
m <- mirai(dbWriteTableArrow(con, "iris", iris))
m[]
#> [1] TRUE
m <- mirai(dbReadTableArrow(con, "iris"))
m[]
#> Table
#> 150 rows x 5 columns
#> $Sepal.Length <double>
#> $Sepal.Width <double>
#> $Petal.Length <double>
#> $Petal.Width <double>
#> $Species <string>
m <- mirai(dbGetQueryArrow(con, 'SELECT * FROM iris WHERE "Sepal.Length" < 4.6'))
m[]
#> Table
#> 5 rows x 5 columns
#> $Sepal.Length <double>
#> $Sepal.Width <double>
#> $Petal.Length <double>
#> $Petal.Width <double>
#> $Species <string>
```

Due to the tight integration of the mirai serialization mechanism with
R’s ‘refhook’ system, we can easily return complex / nested objects
containing multiple queries in the Arrow format:

``` r
m <- mirai({
  a <- dbGetQueryArrow(con, 'SELECT * FROM iris WHERE "Sepal.Length" < 4.6')
  b <- dbGetQueryArrow(con, 'SELECT * FROM iris WHERE "Sepal.Width" < 2.6')
  x <- dbGetQueryArrow(con, 'SELECT * FROM iris WHERE "Petal.Length" < 1.5')
  y <- dbGetQueryArrow(con, 'SELECT * FROM iris WHERE "Petal.Width" < 0.2')
  list(sepal = list(length = a, width = b), petal = list(length = x, width = y))
})
m[]
#> $sepal
#> $sepal$length
#> Table
#> 5 rows x 5 columns
#> $Sepal.Length <double>
#> $Sepal.Width <double>
#> $Petal.Length <double>
#> $Petal.Width <double>
#> $Species <string>
#> 
#> $sepal$width
#> Table
#> 19 rows x 5 columns
#> $Sepal.Length <double>
#> $Sepal.Width <double>
#> $Petal.Length <double>
#> $Petal.Width <double>
#> $Species <string>
#> 
#> 
#> $petal
#> $petal$length
#> Table
#> 24 rows x 5 columns
#> $Sepal.Length <double>
#> $Sepal.Width <double>
#> $Petal.Length <double>
#> $Petal.Width <double>
#> $Species <string>
#> 
#> $petal$width
#> Table
#> 5 rows x 5 columns
#> $Sepal.Length <double>
#> $Sepal.Width <double>
#> $Petal.Length <double>
#> $Petal.Width <double>
#> $Species <string>
```

As before,
[`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md)
can be used to cleanly tear down the databases, prior to resetting
daemons.

``` r
everywhere(dbDisconnect(con))
daemons(0)
```

### 4. Shiny / mirai / DBI / ADBC Integrated Example

The following is an example of how database connections hosted in mirai
daemons may be used to power a Shiny app.

The one-time `serialization()` setup ensures seamless transport of
Apache Arrow data, and occurs in the global environment outside of
`server()`.

A new database connection is created in a new daemon process for every
new Shiny session. The resources are freed when a sesssion ends. This
logic is all defined within `server()`. A unique ID is used to identify
each session, and is specified as the ‘compute profile’ for daemons.

Non-dispatcher daemons are created as scheduling is not required (all
queries expected to take roughly the same time, and in this case each
session uses only one daemon anyway).

Shiny ExtendedTask is then used to perform each query via a
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) call, using
the session-specific compute profile.

``` r
library(mirai)
library(secretbase)
library(shiny)
library(bslib)

# create an Arrow serialization configuration
cfg <- serial_config(
  class = "nanoarrow_array_stream",
  sfunc = arrow::write_to_raw,
  ufunc = nanoarrow::read_nanoarrow
)

# write 'iris' dataset to temp database file (for this demonstration)
file <- tempfile()
con <- DBI::dbConnect(adbi::adbi("adbcsqlite"), uri = file)
DBI::dbWriteTableArrow(con, "iris", iris)
DBI::dbDisconnect(con)

# common input parameters
slmin <- min(iris$Sepal.Length)
slmax <- max(iris$Sepal.Length)

ui <- page_fluid(
  p("The time is ", textOutput("current_time", inline = TRUE)),
  hr(),
  h3("Shiny / mirai / DBI / ADBC demonstration"),
  p("New daemon-hosted database connection is created for every Shiny session"),
  sliderInput(
    "sl", "Query iris dataset based on Sepal Length", min = slmin, max = slmax,
    value = c(slmin, slmax), width = "75%"
  ),
  input_task_button("btn", "Return query"),
  tableOutput("table")
)

# uses Shiny ExtendedTask with mirai
server <- function(input, output, session) {

  # create unique session id by hashing current time with a random key
  id <- secretbase::siphash13(Sys.time(), key = nanonext::random(4L))

  # create new daemon for each session
  daemons(1L, serial = cfg, .compute = id)

  # tear down daemon when session ends
  session$onEnded(function() daemons(0L, .compute = id))

  # everywhere() loads DBI and creates ADBC connection in each daemon
  # and sets up serialization
  everywhere(
    {
      library(DBI) # `adbi` and `adbcsqlite` packages must also be installed
      con <<- dbConnect(adbi::adbi("adbcsqlite"), uri = file)
    },
    file = file,
    .compute = id
  )

  output$current_time <- renderText({
    invalidateLater(1000)
    format(Sys.time(), "%H:%M:%S %p")
  })

  task <- ExtendedTask$new(
    function(...) mirai(
      dbGetQueryArrow(
        con,
        sprintf(
          "SELECT * FROM iris WHERE \"Sepal.Length\" BETWEEN %.2f AND %.2f",
          sl[1L],
          sl[2L]
        )
      ),
      ...,
      .compute = id
    )
  ) |> bind_task_button("btn")

  observeEvent(input$btn, task$invoke(sl = input$sl))

  output$table <- renderTable(task$result())

}

# run Shiny app
shinyApp(ui = ui, server = server)

# deletes temp database file (for this demonstration)
unlink(file)
```
