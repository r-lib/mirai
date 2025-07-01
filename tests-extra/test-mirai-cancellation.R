library(testthat)
library(shinytest2)
library(shiny)
library(bslib)
library(mirai)

ui <- page_fluid(
  p("The time is ", textOutput("current_time", inline = TRUE)),
  hr(),
  p("Counter value: ", textOutput("counter_display", inline = TRUE)),
  input_task_button("increment", "Increment Counter"),
  hr(),
  p("Click 'block' to suspend execution, and 'cancel' to resume"),
  input_task_button("block", "Block"),
  actionButton("cancel", "Cancel block")
)

server <- function(input, output, session) {
  output$current_time <- renderText({
    invalidateLater(1000)
    format(Sys.time(), "%H:%M:%S %p")
  })

  counter <- reactiveVal(0)

  output$counter_display <- renderText({
    counter()
  })

  increment_task <- ExtendedTask$new(
    function() {
        mirai({
            Sys.sleep(0.1)
            1
        })
    }
  ) |>
    bind_task_button("increment")

  # Update counter when increment task completes
  observeEvent(increment_task$result(), {
    counter(counter() + increment_task$result())
  })

  # Block task using mirai
  m <- NULL
  block <- ExtendedTask$new(
    function() m <<- mirai(Sys.sleep(Inf))
  ) |>
    bind_task_button("block")

  observeEvent(input$increment, increment_task$invoke())
  observeEvent(input$block, block$invoke())
  observeEvent(input$cancel, stop_mirai(m))
  observe({
    updateActionButton(
        session,
        "cancel",
        disabled = block$status() != "running"
    )
})
}

# run app using 1 local daemon
daemons(1)

# automatically shutdown daemons when app exits
onStop(function() daemons(0))

block_app <- shinyApp(ui = ui, server = server)

timeout_ms <- 5 * 1000

app <- AppDriver$new(
  block_app,
  variant = shinytest2::platform_variant(),
  timeout = 20 * 1000,
  seed = 102
)
withr::defer(app$stop())

test_that("mirai cancellation and counter interaction", {

  initial_counter <- app$get_value(output = "counter_display")
  expect_equal(initial_counter, "0")

  expect_true(app$get_js("$('#block').is(':enabled')"))
  expect_true(app$get_js("$('#cancel').is(':disabled')"))

  app$click("increment")
  app$wait_for_value(
    output = "counter_display",
    ignore = list("0"),
    timeout = timeout_ms
  )
  app$wait_for_js("$('#increment').is(':enabled')", timeout = timeout_ms)

  counter_after_increment <- app$get_value(output = "counter_display")
  expect_equal(counter_after_increment, "1")

  app$click("block")
  app$wait_for_js("$('#block').is(':disabled')", timeout = timeout_ms)
  app$wait_for_js("$('#cancel').is(':enabled')", timeout = timeout_ms)

  expect_true(app$get_js("$('#block').is(':disabled')"))
  expect_true(app$get_js("$('#cancel').is(':enabled')"))

  app$click("increment")

  counter_during_block <- app$get_value(output = "counter_display")
  expect_equal(counter_during_block, "1")

  app$click("cancel")
  app$wait_for_js("$('#cancel').is(':disabled')", timeout = timeout_ms)
  app$wait_for_js("$('#block').is(':enabled')", timeout = timeout_ms)

  app$wait_for_value(
    output = "counter_display",
    ignore = list("1"),
    timeout = timeout_ms
  )
  final_counter <- app$get_value(output = "counter_display")
  expect_equal(final_counter, "2")
})
