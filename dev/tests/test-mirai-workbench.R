# mirai Posit Workbench-Specific Tests
# =====================================
#
# Purpose: Tests that verify mirai's integration with the Posit Workbench job
#          launcher. Covers environment detection, http_config(), and daemon
#          launching via the Workbench API.
#
# Usage:   Run from an R session inside a Posit Workbench project:
#            testthat::test_file("dev/tests/test-mirai-workbench.R")
#
# Requirements:
#   - mirai, nanonext, testthat installed
#   - secretbase required for Workbench API data tests
#   - Must be run on Posit Workbench (RS_SERVER_ADDRESS set) for full coverage
#   - Tests gracefully skip when not running on Workbench

library(testthat)
library(mirai)

on_workbench <- nzchar(Sys.getenv("RS_SERVER_ADDRESS"))
timeout <- 5000L

# -- 1. Workbench Environment Detection ---------------------------------------

test_that("Workbench environment variables are set", {
  skip_if_not(on_workbench, "Not running on Posit Workbench")

  expect_match(Sys.getenv("RS_SERVER_ADDRESS"), "^https?://")
  expect_true(nzchar(Sys.getenv("RS_SESSION_RPC_COOKIE")))
})

# -- 2. http_config() ---------------------------------------------------------

test_that("http_config() returns correct default structure", {
  cfg <- http_config()
  expect_type(cfg, "list")
  expect_identical(cfg$type, "http")
  expect_identical(cfg$method, "POST")
  expect_type(cfg$url, "closure")
  expect_type(cfg$cookie, "closure")
  expect_type(cfg$data, "closure")
  expect_null(cfg$token)
})

test_that("http_config() accepts custom values", {
  cfg <- http_config(
    url = "https://custom.example.com/api/launch",
    method = "POST",
    cookie = "my_cookie",
    token = "my_token",
    data = '{"cmd":"%s"}'
  )
  expect_identical(cfg$url, "https://custom.example.com/api/launch")
  expect_identical(cfg$cookie, "my_cookie")
  expect_identical(cfg$token, "my_token")
  expect_identical(cfg$data, '{"cmd":"%s"}')
})

test_that("http_config() accepts function fields", {
  url_fn <- function() "https://dynamic.example.com"
  cookie_fn <- function() Sys.getenv("MY_COOKIE")
  cfg <- http_config(url = url_fn, cookie = cookie_fn)
  expect_type(cfg$url, "closure")
  expect_type(cfg$cookie, "closure")
})

# -- 3. Workbench Internal Functions -------------------------------------------

test_that("posit_workbench_url() constructs API URL", {
  url <- mirai:::posit_workbench_url()
  expect_type(url, "character")
  expect_match(url, "api/launch_job$")
})

test_that("posit_workbench_cookie() returns character", {
  cookie <- mirai:::posit_workbench_cookie()
  expect_type(cookie, "character")
})

test_that("posit_workbench_cookie() returns non-empty value on Workbench", {
  skip_if_not(on_workbench, "Not running on Posit Workbench")

  expect_true(nzchar(mirai:::posit_workbench_cookie()))
})

test_that("posit_workbench_data() returns valid JSON with expected fields", {
  skip_if_not(on_workbench, "Not running on Posit Workbench")
  skip_if_not_installed("secretbase")

  data <- mirai:::posit_workbench_data()
  expect_type(data, "character")
  expect_true(nzchar(data))

  decoded <- secretbase::jsondec(data)
  expect_identical(decoded[["method"]], "launch_job")

  job <- decoded[["kwparams"]][["job"]]
  expect_false(is.null(job[["cluster"]]))
  expect_false(is.null(job[["container"]][["image"]]))
  expect_false(is.null(job[["resourceProfile"]]))
  expect_identical(job[["name"]], "mirai_daemon")
  expect_identical(job[["exe"]], "Rscript")
  expect_match(paste(job[["args"]], collapse = " "), ".libPaths", fixed = TRUE)
})

test_that("posit_workbench_data() accepts custom rscript path", {
  skip_if_not(on_workbench, "Not running on Posit Workbench")
  skip_if_not_installed("secretbase")

  data <- mirai:::posit_workbench_data(rscript = "/usr/bin/Rscript")
  decoded <- secretbase::jsondec(data)
  expect_identical(decoded[["kwparams"]][["job"]][["exe"]], "/usr/bin/Rscript")
})

test_that("posit_workbench_data() errors when not on Workbench", {
  skip_if(on_workbench, "Running on Workbench; this test is for off-Workbench only")

  expect_error(mirai:::posit_workbench_data())
})

test_that("posit_workbench_fetch() errors when not on Workbench", {
  skip_if(on_workbench, "Running on Workbench; this test is for off-Workbench only")

  expect_error(mirai:::posit_workbench_fetch("api/test"), "Posit Workbench")
})

# -- 4. Daemon Launch via Workbench API ----------------------------------------

# Set up persistent daemons for the sequential integration tests.
# everywhere() blocks until all daemons have connected and responded.
if (on_workbench && requireNamespace("secretbase", quietly = TRUE)) {
  daemons(n = 1L, url = host_url(), remote = http_config())
  everywhere(TRUE)[]
}

test_that("daemons start and connect via Workbench job launcher", {
  skip_if_not(on_workbench, "Not running on Posit Workbench")
  skip_if_not_installed("secretbase")

  s <- status()
  expect_type(s, "list")
  expect_gte(s[["connections"]], 1L)
})

test_that("mirai evaluates on Workbench-launched daemon", {
  skip_if_not(on_workbench, "Not running on Posit Workbench")
  skip_if_not_installed("secretbase")
  skip_if_not(daemons_set(), "Daemons not connected")

  m <- mirai(Sys.getpid(), .timeout = timeout)
  result <- m[]
  expect_false(is_error_value(result))
  expect_type(result, "integer")
  expect_false(identical(result, Sys.getpid()))
})

test_that("mirai passes data to Workbench-launched daemon", {
  skip_if_not(on_workbench, "Not running on Posit Workbench")
  skip_if_not_installed("secretbase")
  skip_if_not(daemons_set(), "Daemons not connected")

  x <- 42L
  m <- mirai(x * 2L, .args = list(x = x), .timeout = timeout)
  expect_identical(m[], 84L)
})

test_that("everywhere() works on Workbench-launched daemons", {
  skip_if_not(on_workbench, "Not running on Posit Workbench")
  skip_if_not_installed("secretbase")
  skip_if_not(daemons_set(), "Daemons not connected")

  everywhere({}, wb_test_var = "workbench_ok")
  m <- mirai(wb_test_var, .timeout = timeout)
  expect_identical(m[], "workbench_ok")
})

test_that("mirai_map() works on Workbench-launched daemons", {
  skip_if_not(on_workbench, "Not running on Posit Workbench")
  skip_if_not_installed("secretbase")
  skip_if_not(daemons_set(), "Daemons not connected")

  results <- mirai_map(1:3, function(x) x^2)[]
  expect_type(results, "list")
  expect_length(results, 3L)
  expect_equal(results[[1]], 1)
  expect_equal(results[[3]], 9)
})

test_that("launch_remote() adds daemons via Workbench API", {
  skip_if_not(on_workbench, "Not running on Posit Workbench")
  skip_if_not_installed("secretbase")
  skip_if_not(daemons_set(), "Daemons not connected")

  res <- launch_remote(1L, remote = http_config())
  expect_type(res, "list")
  expect_length(res, 1L)

  # Wait for both daemons to be connected
  everywhere(TRUE, .min = 2L)[]
  expect_gte(status()[["connections"]], 2L)
})

# Reset daemons before the self-contained scoped tests
daemons(0L)

# -- 5. Scoped Workbench daemon tests (each self-contained) -------------------

test_that("multiple Workbench daemons run concurrently with dispatcher", {
  skip_if_not(on_workbench, "Not running on Posit Workbench")
  skip_if_not_installed("secretbase")

  result <- with(daemons(n = 2L, url = host_url(), remote = http_config()), {
    everywhere(TRUE, .min = 2L)[]
    t1 <- proc.time()[3L]
    m1 <- mirai(Sys.sleep(1), .timeout = timeout)
    m2 <- mirai(Sys.sleep(1), .timeout = timeout)
    m1[]; m2[]
    elapsed <- proc.time()[3L] - t1
    !is_error_value(m1$data) && !is_error_value(m2$data) && elapsed < 2.5
  })
  expect_true(result)
})

test_that("Workbench daemons work over TLS", {
  skip_if_not(on_workbench, "Not running on Posit Workbench")
  skip_if_not_installed("secretbase")

  result <- with(daemons(n = 1L, url = host_url(tls = TRUE), remote = http_config()), {
    m <- mirai("tls_workbench_ok", .timeout = timeout)
    m[]
  })
  expect_identical(result, "tls_workbench_ok")
})

test_that("Workbench daemons support reproducible RNG", {
  skip_if_not(on_workbench, "Not running on Posit Workbench")
  skip_if_not_installed("secretbase")

  r1 <- with(daemons(n = 1L, url = host_url(), remote = http_config(), seed = 42L), {
    everywhere(TRUE)[]
    mirai_map(1:4, function(x) rnorm(3))[]
  })
  r2 <- with(daemons(n = 1L, url = host_url(), remote = http_config(), seed = 42L), {
    everywhere(TRUE)[]
    mirai_map(1:4, function(x) rnorm(3))[]
  })
  expect_identical(r1, r2)
})

# -- Final Cleanup -------------------------------------------------------------

daemons(0L)
