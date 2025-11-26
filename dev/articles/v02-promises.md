# mirai - Promises (Shiny and Plumber)

### 1. Event-driven promises

`mirai` provides an
[`as.promise()`](https://rstudio.github.io/promises/reference/is.promise.html)
method for conversion to
[`promises`](https://rstudio.github.io/promises/) package promises. See
the [promises articles](https://rstudio.github.io/promises/) for a
comprehensive guide.

Use mirai directly with: - Promise pipe `%...>%` (implicitly calls
[`as.promise()`](https://rstudio.github.io/promises/reference/is.promise.html)) -
Promise-aware functions
([`promises::then()`](https://rstudio.github.io/promises/reference/then.html),
`shiny::ExtendedTask`)

Or explicitly convert with
[`as.promise()`](https://rstudio.github.io/promises/reference/is.promise.html)
to access `$then()`, `$finally()` methods.

Promises register actions triggered when mirai resolves. This happens
automatically when R is idle or within loops/functions calling
[`later::run_now()`](https://later.r-lib.org/reference/run_now.html)
(e.g., Shiny).

Mirai promises pass return values to `onFulfilled` (success) or
`errorValue` to `onRejected` (error).

**Event-driven advantages:**

- Actions trigger immediately on resolution (no time-polling)
- Data already received in background (no transfer delay)
- High responsiveness (zero latency) and massive scalability
  (thousands/millions of concurrent promises)

This outputs “hello” after one second:

``` r
library(mirai)
library(promises)

p <- mirai({Sys.sleep(1); "hello"}) %...>% cat()
p
#> <Promise [pending]>
```

Access mirai values at `$data` while using promises for side effects
(assigning to an environment):

``` r
env <- new.env()

m <- mirai({
  Sys.sleep(1)
  "hello"
})

promises::then(m, function(x) env$res <- x)

m[]
#> [1] "hello"
```

After returning to the top level prompt:

``` r
env$res
#> [1] "hello"
```

`mirai_map` also has an
[`as.promise()`](https://rstudio.github.io/promises/reference/is.promise.html)
method. It resolves when the entire map completes or any mirai is
rejected.

### 2. Shiny ExtendedTask: Introduction

mirai is the primary async backend for scaling
[Shiny](https://shiny.posit.co/) applications. Use
[`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md) to
distribute tasks across local parallel processes or network resources.

Shiny ExtendedTask creates scalable apps responsive both intra-session
(per user) and inter-session (multiple concurrent users).

In this example, the clock continues ticking while the expensive
computation runs asynchronously. The button disables and plot greys out
until completion.

> Call [`daemons()`](https://mirai.r-lib.org/dev/reference/daemons.md)
> at top level. Use `onStop()` to automatically shut down daemons when
> the app exits.

``` r
library(shiny)
library(bslib)
library(mirai)

ui <- page_fluid(
  p("The time is ", textOutput("current_time", inline = TRUE)),
  hr(),
  numericInput("n", "Sample size (n)", 100),
  numericInput("delay", "Seconds to take for plot", 5),
  input_task_button("btn", "Plot uniform distribution"),
  plotOutput("plot")
)

server <- function(input, output, session) {
  output$current_time <- renderText({
    invalidateLater(1000)
    format(Sys.time(), "%H:%M:%S %p")
  })

  task <- ExtendedTask$new(
    function(...) mirai({Sys.sleep(y); runif(x)}, ...)
  ) |> bind_task_button("btn")

  observeEvent(input$btn, task$invoke(x = input$n, y = input$delay))

  output$plot <- renderPlot(hist(task$result()))

}

# run app using 1 local daemon
daemons(1)

# automatically shutdown daemons when app exits
onStop(function() daemons(0))

shinyApp(ui = ui, server = server)
```

*Thanks to Joe Cheng for providing examples on which the above is
based.*

**Key ExtendedTask components:**

1.  **UI**: Use
    [`bslib::input_task_button()`](https://rstudio.github.io/bslib/reference/input_task_button.html)
    (disables during computation):

``` r
input_task_button("btn", "Plot uniform distribution")
```

2.  **Server**: Create ExtendedTask with `ExtendedTask$new()`, passing
    `...` to
    [`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md), bind to
    button:

``` r
task <- ExtendedTask$new(
  function(...) mirai({Sys.sleep(y); runif(x)}, ...)
) |> bind_task_button("btn")
```

3.  **Server**: Observe button input, invoke ExtendedTask with named
    arguments:

``` r
observeEvent(input$btn, task$invoke(x = input$n, y = input$delay))
```

4.  **Server**: Render output consuming ExtendedTask result:

``` r
output$plot <- renderPlot(hist(task$result()))
```

### 3. Shiny ExtendedTask: Cancellation

This demonstrates cancellation, which works identically for local or
remote tasks.

This adds an infinite sleep button that blocks execution (using one
daemon). New tasks queue behind it. A cancel button stops the blocking
task, resuming queued plots.

Assign a mirai reference in `ExtendedTask$new()`, then pass to
[`stop_mirai()`](https://mirai.r-lib.org/dev/reference/stop_mirai.md):

``` r
library(shiny)
library(bslib)
library(mirai)

ui <- page_fluid(
  p("The time is ", textOutput("current_time", inline = TRUE)),
  hr(),
  numericInput("n", "Sample size (n)", 100),
  numericInput("delay", "Seconds to take for plot", 5),
  input_task_button("btn", "Plot uniform distribution"),
  hr(),
  p("Click 'block' to suspend execution, and 'cancel' to resume"),
  input_task_button("block", "Block"),
  actionButton("cancel", "Cancel block"),
  hr(),
  plotOutput("plot")
)

server <- function(input, output, session) {
  output$current_time <- renderText({
    invalidateLater(1000)
    format(Sys.time(), "%H:%M:%S %p")
  })

  task <- ExtendedTask$new(
    function(...) mirai({Sys.sleep(y); runif(x)}, ...)
  ) |> bind_task_button("btn")

  m <- NULL
  block <- ExtendedTask$new(
    function() m <<- mirai(Sys.sleep(Inf))
  ) |> bind_task_button("block")

  observeEvent(input$btn, task$invoke(x = input$n, y = input$delay))
  observeEvent(input$block, block$invoke())
  observeEvent(input$cancel, stop_mirai(m))
  observe({
    updateActionButton(session, "cancel", disabled = block$status() != "running")
  })

  output$plot <- renderPlot(hist(task$result()))

}

# run app using 1 local daemon
daemons(1)

# automatically shutdown daemons when app exits
onStop(function() daemons(0))

shinyApp(ui = ui, server = server)
```

*Thanks to Joe Cheng for providing examples on which the above is
based.*

### 4. Shiny ExtendedTask: Generative Art

This app generates spiral patterns asynchronously.

Users add multiple plots via Shiny modules, each with different
calculation times.

Daemon limits become visible: with 3 daemons and 4 plots, the 4th waits
for another to finish.

Wrapping `runApp()` in `with(daemons(...), ...)` sets up daemons for the
app’s duration, exiting automatically on stop.

``` r
library(shiny)
library(mirai)
library(bslib)
library(ggplot2)
library(aRtsy)

# function definitions

run_task <- function(calc_time) {
  Sys.sleep(calc_time)
  list(
    colors = aRtsy::colorPalette(name = "random", n = 3),
    angle = runif(n = 1, min = - 2 * pi, max = 2 * pi),
    size = 1,
    p = 1
  )
}

plot_result <- function(result) {
  do.call(what = canvas_phyllotaxis, args = result)
}

# modules for individual plots

plotUI <- function(id, calc_time) {
  ns <- NS(id)
  card(
    strong(paste0("Plot (calc time = ", calc_time, " secs)")),
    input_task_button(ns("resample"), "Resample"),
    plotOutput(ns("plot"), height="400px", width="400px")
  )
}

plotServer <- function(id, calc_time) {
  force(id)
  force(calc_time)
  moduleServer(
    id,
    function(input, output, session) {

      task <- ExtendedTask$new(
        function(time, run) mirai(run(time), environment())
      ) |> bind_task_button("resample")

      observeEvent(input$resample, task$invoke(calc_time, run_task))

      output$plot <- renderPlot(plot_result(task$result()))

    }
  )
}

# ui and server

ui <- page_sidebar(fillable = FALSE,
  sidebar = sidebar(
    numericInput("calc_time", "Calculation time (secs)", 5),
    actionButton("add", "Add", class="btn-primary"),
  ),
  layout_column_wrap(id = "results", width = "400px", fillable = FALSE)
)

server <- function(input, output, session) {

  observeEvent(input$add, {
    id <- nanonext::random(4)
    insertUI("#results", where = "beforeEnd", ui = plotUI(id, input$calc_time))
    plotServer(id, input$calc_time)
  })
}

app <- shinyApp(ui, server)

# run app using 3 local daemons
with(daemons(3), runApp(app))
```

*The above example builds on original code by Joe Cheng, Daniel Woodie
and William Landau.*

This uses [`environment()`](https://rdrr.io/r/base/environment.html)
instead of `...` to pass calling environment variables to mirai.

**Key components:**

1.  **UI**: Use
    [`bslib::input_task_button()`](https://rstudio.github.io/bslib/reference/input_task_button.html):

``` r
input_task_button(ns("resample"), "Resample")
```

2.  **Server**: Create ExtendedTask with named arguments passed through
    [`environment()`](https://rdrr.io/r/base/environment.html):

``` r
task <- ExtendedTask$new(
  function(time, run) mirai(run(time), environment())
) |> bind_task_button("resample")
```

3.  **Server**: Observe button, invoke ExtendedTask with arguments:

``` r
observeEvent(input$resample, task$invoke(calc_time, run_task))
```

4.  **Server**: Render output consuming result:

``` r
output$plot <- renderPlot(plot_result(task$result()))
```

### 5. Shiny ExtendedTask: mirai map

`mirai_map` has an
[`as.promise()`](https://rstudio.github.io/promises/reference/is.promise.html)
method for direct use in ExtendedTask. Resolves when the entire map
completes or any mirai is rejected.

This performs multiple simultaneous calculations across daemons,
returning results asynchronously:

``` r
library(shiny)
library(bslib)
library(mirai)

ui <- page_fluid(
  titlePanel("ExtendedTask Map Demo"),
  hr(),
  p("The time is ", textOutput("current_time", inline = TRUE)),
  p("Perform 4 calculations that each take between 1 and 4 secs to complete:"),
  input_task_button("calculate", "Calculate"),
  p(textOutput("result")),
  tags$style(type="text/css", "#result {white-space: pre-wrap;}")
)

server <- function(input, output) {
  task <- ExtendedTask$new(function() {
    mirai_map(1:4, function(i) {
      # simulated long calculation
      Sys.sleep(i)
      sprintf(
        "Calc %d | PID %d | Finished at %s.", i, Sys.getpid(), format(Sys.time())
      )
    })
  }) |> bind_task_button("calculate")
  
  observeEvent(input$calculate, {
    task$invoke()
  })
  
  output$result <- renderText({
    # result of mirai_map() is a list
    as.character(task$result())
  }, sep = "\n")
  
  output$current_time <- renderText({
    invalidateLater(1000)
    format(Sys.time(), "%H:%M:%S %p")
  })
}

app <- shinyApp(ui, server)
with(daemons(4), runApp(app))
```

### 6. Shiny Async: Coin Flips

This integrates
[`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md) into
a Shiny observer without ExtendedTask.

The ‘.promise’ argument registers promise actions for each mapped
operation, updating reactive values or interacting with the app:

``` r
library(shiny)
library(mirai)

flip_coin <- function(...) {
  Sys.sleep(0.1)
  rbinom(n = 1, size = 1, prob = 0.501)
}

ui <- fluidPage(
  div("Is the coin fair?"),
  actionButton("task", "Flip 1000 coins"),
  textOutput("status"),
  textOutput("outcomes")
)

server <- function(input, output, session) {

  # Keep running totals of heads, tails, and task errors
  flips <- reactiveValues(heads = 0, tails = 0, flips = 0)

  # Button to submit a batch of coin flips
  observeEvent(input$task, {
    mirai_map(
      1:1000,
      flip_coin,
      .promise = \(x) {
        if (x) flips$heads <- flips$heads + 1 else flips$tails <- flips$tails + 1
      }
    )
    # Ensure there is something after mirai_map() in the observer, as it is
    # convertible to a promise, and will otherwise be waited for before returning
    flips$flips <- flips$flips + 1000
  })

  # Print time and task status
  output$status <- renderText({
    invalidateLater(millis = 1000)
    time <- format(Sys.time(), "%H:%M:%S")
    sprintf("%s | %s flips submitted", time, flips$flips)
  })

  # Print number of heads and tails
  output$outcomes <- renderText(
    sprintf("%s heads %s tails", flips$heads, flips$tails)
  )

}

app <- shinyApp(ui = ui, server = server)

# run app using 8 local non-dispatcher daemons (tasks are the same length)
with(daemons(8, dispatcher = FALSE), {
  # pre-load flip_coin function on all daemons for efficiency
  everywhere({}, flip_coin = flip_coin)
  runApp(app)
})
```

*This is an adaptation of an original example provided by Will Landau
for use of `crew` with Shiny. Please see
<https://wlandau.github.io/crew/articles/shiny.html>.*

### 7. Shiny Async: Progress Bar

This uses
[`mirai_map()`](https://mirai.r-lib.org/dev/reference/mirai_map.md) to
update a Shiny progress bar with custom messages and a reactive value
upon completion (asynchronously):

``` r
library(shiny)
library(mirai)
library(promises)

slow_squared <- function(x) {
  Sys.sleep(runif(1))
  x^2
}

ui <- fluidPage(
  titlePanel("Asynchronous Squares Calculator"),
  p("The time is ", textOutput("current_time", inline = TRUE)),
  hr(),
  actionButton("start", "Start Calculation"),
  br(), br(),
  uiOutput("progress_ui"),
  verbatimTextOutput("result")
)

server <- function(input, output, session) {
  x <- 1:100
  y <- reactiveVal()
  
  observeEvent(input$start, {
    
    progress <- Progress$new(session, min = 0, max = length(x))
    progress$set(message = "Parallel calculation in progress", detail = "Starting...")
    completed <- reactiveVal(0)
    mirai_map(
      x,
      slow_squared,
      slow_squared = slow_squared,
      .promise = function(result) {
        new_val <- completed() + 1
        completed(new_val)  # Increment completed counter
        progress$inc(1, detail = paste("Completed", new_val))  # Update progress
      }
    ) %...>% {
      y(unlist(.))
      progress$close()
    }
    # Ensure there is something after mirai_map() in the observer, as otherwise
    # the created promise will be waited for before returning
    y(0)
  })
  output$current_time <- renderText({
    invalidateLater(1000)
    format(Sys.time(), "%H:%M:%S %p")
  })
  output$result <- renderPrint({
    cat("Sum of squares calculated: ", sum(y()), "\n")
  })
}

app <- shinyApp(ui, server)
with(daemons(8), runApp(app))
```

*This example adapts a contribution from Davide Magno.*

### 8. Plumber GET Endpoint

mirai serves as an async backend for
[`plumber`](https://www.rplumber.io/) pipelines.

This runs the plumber router in a daemon process to avoid blocking
(useful in interactive sessions; otherwise use code within the outer
[`mirai()`](https://mirai.r-lib.org/dev/reference/mirai.md) call
directly).

The /echo endpoint accepts GET requests, sleeps 1 second (simulating
expensive computation), and returns the ‘msg’ header with timestamp and
process ID:

``` r
library(mirai)

daemons(1L, dispatcher = FALSE)

m <- mirai({
  library(plumber)
  library(promises) # to provide the promise pipe
  library(mirai)

  # more efficient not to use dispatcher if all requests are similar length
  daemons(4L, dispatcher = FALSE) # handles 4 requests simultaneously

  pr() |>
    pr_get(
      "/echo",
      function(req, res) {
        mirai(
          {
            Sys.sleep(1L)
            list(
              status = 200L,
              body = list(
                time = format(Sys.time()), msg = msg, pid = Sys.getpid()
              )
            )
          },
          msg = req$HEADERS$msg
        ) %...>% (function(x) {
          res$status <- x$status
          res$body <- x$body
        })
      }
    ) |>
    pr_run(host = "127.0.0.1", port = 8985)
})
```

Query the API using an async HTTP client like
[`nanonext::ncurl_aio()`](https://nanonext.r-lib.org/reference/ncurl_aio.html).

All 8 requests submit at once, but responses have differing timestamps
(only 4 process simultaneously due to daemon limit):

``` r
library(nanonext)
res <- lapply(
  1:8,
  function(i) ncurl_aio(
    "http://127.0.0.1:8985/echo",
    headers = c(msg = as.character(i))
  )
)
collect_aio(res)
#> [[1]]
#> [1] "{\"error\":\"500 - Internal server error\"}"
#> 
#> [[2]]
#> [1] "{\"error\":\"500 - Internal server error\"}"
#> 
#> [[3]]
#> [1] "{\"error\":\"500 - Internal server error\"}"
#> 
#> [[4]]
#> [1] "{\"error\":\"500 - Internal server error\"}"
#> 
#> [[5]]
#> [1] "{\"error\":\"500 - Internal server error\"}"
#> 
#> [[6]]
#> [1] "{\"error\":\"500 - Internal server error\"}"
#> 
#> [[7]]
#> [1] "{\"error\":\"500 - Internal server error\"}"
#> 
#> [[8]]
#> [1] "{\"error\":\"500 - Internal server error\"}"

daemons(0)
```

### 9. Plumber POST Endpoint

This uses a POST endpoint accepting JSON request data.

Always access `req$postBody` in the router process and pass to mirai as
an argument (it uses a non-serializable connection):

``` r
library(mirai)

daemons(1L, dispatcher = FALSE)

m <- mirai({
  library(plumber)
  library(promises) # to provide the promise pipe
  library(mirai)

  # uses dispatcher - suitable when requests take differing times to complete
  daemons(4L) # handles 4 requests simultaneously

  pr() |>
    pr_post(
      "/echo",
      function(req, res) {
        mirai(
          {
            Sys.sleep(1L) # simulate expensive computation
            list(
              status = 200L,
              body = list(
                time = format(Sys.time()),
                msg = jsonlite::parse_json(data)$msg,
                pid = Sys.getpid()
              )
            )
          },
          data = req$postBody
        ) %...>% (function(x) {
          res$status <- x$status
          res$body <- x$body
        })
      }
    ) |>
    pr_run(host = "127.0.0.1", port = 8986)
})
```

Querying produces the same output as the previous example:

``` r
library(nanonext)
res <- lapply(
  1:8,
  function(i) ncurl_aio(
    "http://127.0.0.1:8986/echo",
    method = "POST",
    data = sprintf('{"msg":"%d"}', i)
  )
)
collect_aio(res)
#> [[1]]
#> [1] "{\"time\":[\"2025-11-26 00:03:11\"],\"msg\":[\"1\"],\"pid\":[71207]}"
#> 
#> [[2]]
#> [1] "{\"time\":[\"2025-11-26 00:03:12\"],\"msg\":[\"2\"],\"pid\":[71207]}"
#> 
#> [[3]]
#> [1] "{\"time\":[\"2025-11-26 00:03:11\"],\"msg\":[\"3\"],\"pid\":[71217]}"
#> 
#> [[4]]
#> [1] "{\"time\":[\"2025-11-26 00:03:11\"],\"msg\":[\"4\"],\"pid\":[71205]}"
#> 
#> [[5]]
#> [1] "{\"time\":[\"2025-11-26 00:03:12\"],\"msg\":[\"5\"],\"pid\":[71217]}"
#> 
#> [[6]]
#> [1] "{\"time\":[\"2025-11-26 00:03:12\"],\"msg\":[\"6\"],\"pid\":[71223]}"
#> 
#> [[7]]
#> [1] "{\"time\":[\"2025-11-26 00:03:12\"],\"msg\":[\"7\"],\"pid\":[71205]}"
#> 
#> [[8]]
#> [1] "{\"time\":[\"2025-11-26 00:03:11\"],\"msg\":[\"8\"],\"pid\":[71223]}"

daemons(0)
```
