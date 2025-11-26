# mirai - Serialization (Arrow, ADBC, polars, torch)

### 1. Serialization: Arrow, polars and beyond

Native R serialization transfers data between host and daemons. Objects
accessed via external pointers cannot be serialized and normally error
in mirai operations.

Using [`arrow`](https://arrow.apache.org/docs/r/) as an example:

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

[`serial_config()`](https://mirai.r-lib.org/dev/reference/serial_config.md)
creates custom serialization configurations with functions that hook
into R’s native serialization mechanism for reference objects
(‘refhooks’).

Pass this configuration to the ‘serial’ argument of
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md):

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

The arrow table now handles seamlessly, even when deeply nested in lists
or other structures.

Register multiple serialization functions for different object classes.
This example combines Arrow with
[`polars`](https://pola-rs.github.io/r-polars/), a Rust dataframe
library (requires polars \>= 1.0.0):

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

[`torch`](https://torch.mlverse.org/) tensors work seamlessly in mirai
computations.

**Setup:**

1.  Create serialization configuration with ‘class’ as ‘torch_tensor’
2.  Set up daemons, supplying configuration to ‘serial’
3.  (Optional) Use
    [`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md)
    to load `torch` on all daemons

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

**Example Usage:**

This creates a convolutional neural network with `torch::nn_module()`,
specifies parameters, then initializes them in a parallel process:

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
#> ── Modules ─────────────────────────────────────────────────────────────────────────────────
#> • conv1: <nn_conv2d> #520 parameters
#> • conv2: <nn_conv2d> #520 parameters
```

The returned model contains many tensor elements:

``` r
m$data$parameters$conv1.weight
#> torch_tensor
#> (1,1,.,.) = 
#>  -0.1218  0.1835 -0.1114 -0.1365 -0.1824
#>   0.1107 -0.0498 -0.1219 -0.0938 -0.1570
#>  -0.1944  0.0355  0.1750 -0.1612 -0.1590
#>  -0.0806 -0.1906 -0.0272 -0.1732 -0.0491
#>  -0.0079 -0.0874 -0.1256  0.1276  0.0664
#> 
#> (2,1,.,.) = 
#>  -0.1450 -0.0371  0.0601 -0.1578  0.0918
#>   0.1118 -0.0800  0.0359  0.0452  0.1182
#>   0.0516  0.0109  0.0186  0.1399 -0.1431
#>   0.1720 -0.0919  0.0616  0.0937  0.1511
#>  -0.0270  0.0936  0.1510  0.1995  0.1934
#> 
#> (3,1,.,.) = 
#>   0.1055  0.0056  0.0491 -0.0096  0.0655
#>   0.1950  0.0676  0.0254  0.0834 -0.0401
#>   0.1658  0.1767 -0.0338  0.1644  0.1806
#>  -0.0346 -0.1521  0.0490  0.1153  0.0755
#>  -0.0832  0.0074 -0.0607  0.1704  0.1454
#> 
#> (4,1,.,.) = 
#>   0.1091  0.1982  0.1185  0.1655  0.1716
#>   0.1987 -0.0517 -0.0115 -0.0641  0.0294
#>   0.0078 -0.0942 -0.1629 -0.1114 -0.0833
#>   0.0395 -0.0101  0.0837  0.1523  0.0673
#>  -0.0984  0.0988 -0.1154  0.0453 -0.1577
#> 
#> (5,1,.,.) = 
#>   0.0630 -0.0820 -0.1399  0.0528 -0.0896
#> ... [the output was truncated (use n=-1 to disable)]
#> [ CPUFloatType{20,1,5,5} ][ requires_grad = TRUE ]
```

Pass model parameters to an optimizer, also initialized in a parallel
process:

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

Tensors and complex objects containing tensors pass seamlessly between
host and daemons like any R object.

Custom serialization leverages R’s native ‘refhook’ mechanism for
transparent usage. Fast and efficient, it minimizes data copies and uses
official `torch` serialization methods directly.

### 3. Database Hosting using Arrow Database Connectivity

Use `DBI` to access and manipulate Apache Arrow data efficiently through
ADBC (Arrow Database Connectivity).

This creates an in-memory SQLite connection using the `adbcsqlite`
backend.

Serialization uses `arrow` functions in the
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) call.
The class is ‘nanoarrow_array_stream’ since `nanoarrow` backs all DBI
`db*Arrow()` queries:

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

Use [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) to write
or query the database in Arrow format:

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

Tight integration with R’s ‘refhook’ system allows returning complex
nested objects with multiple Arrow queries:

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

Use
[`everywhere()`](https://mirai.r-lib.org/dev/reference/everywhere.md) to
cleanly tear down databases before resetting daemons:

``` r
everywhere(dbDisconnect(con))
daemons(0)
```

### 4. Shiny / mirai / DBI / ADBC Integrated Example

This demonstrates database connections hosted in mirai daemons powering
a Shiny app.

One-time `serialization()` setup ensures seamless Arrow data transport
in the global environment outside `server()`.

Each Shiny session creates a new database connection in a new daemon
process, freeing resources when the session ends. This logic lives in
`server()`. A unique ID identifies each session and specifies the
daemons ‘compute profile’.

Non-dispatcher daemons work since scheduling isn’t needed (all queries
take a similar time, each session uses one daemon).

Shiny ExtendedTask performs queries via
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) using the
session-specific compute profile:

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
