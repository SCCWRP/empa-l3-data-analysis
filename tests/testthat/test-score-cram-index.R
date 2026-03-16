test_that("score_cram_index returns expected output for NC-TEN", {
  input <- read.csv(test_path("fixtures/score_cram_index/input.csv"))
  expected <- read.csv(test_path("fixtures/score_cram_index/expected.csv"))

  cram <- read.csv(
    system.file(
      "extdata",
      "EMPA_CRAM_2014-2024.csv",
      package = "EMPAFunctionAnalysis"
    )
  )

  result <- score_cram_index(
    vegetativecover_data = input,
    cram = cram
  )

  expect_equal(result$estuaryname, expected$estuaryname)
  expect_equal(result$siteid, expected$siteid)
  expect_equal(as.character(result$year), as.character(expected$year))
  expect_equal(result$function_name, expected$function_name)
  expect_equal(result$indicator_name, expected$indicator_name)
  expect_equal(result$metric_name, expected$metric_name)
  expect_equal(result$metric_score, expected$metric_score, tolerance = 0.1)
})

test_that("score_cram_index output has correct columns", {
  input <- read.csv(test_path("fixtures/score_cram_index/input.csv"))
  cram <- read.csv(
    system.file(
      "extdata",
      "EMPA_CRAM_2014-2024.csv",
      package = "EMPAFunctionAnalysis"
    )
  )

  result <- score_cram_index(vegetativecover_data = input, cram = cram)

  expect_named(
    result,
    c(
      "estuaryname",
      "siteid",
      "year",
      "function_name",
      "indicator_name",
      "metric_name",
      "metric_score"
    )
  )
})

test_that("score_cram_index produces one row per function_name", {
  input <- read.csv(test_path("fixtures/score_cram_index/input.csv"))
  cram <- read.csv(
    system.file(
      "extdata",
      "EMPA_CRAM_2014-2024.csv",
      package = "EMPAFunctionAnalysis"
    )
  )

  result_both <- score_cram_index(
    vegetativecover_data = input,
    cram = cram,
    function_name = c("Plant", "SLR")
  )
  result_plant <- score_cram_index(
    vegetativecover_data = input,
    cram = cram,
    function_name = "Plant"
  )

  expect_equal(nrow(result_both), 2 * nrow(result_plant))
  expect_setequal(result_both$function_name, c("Plant", "SLR"))
})

test_that("score_cram_index returns NA metric_score when site has no CRAM data", {
  input <- read.csv(test_path("fixtures/score_cram_index/input.csv"))
  input$siteid <- "XX-FAKE"

  cram <- read.csv(
    system.file(
      "extdata",
      "EMPA_CRAM_2014-2024.csv",
      package = "EMPAFunctionAnalysis"
    )
  )

  result <- score_cram_index(
    vegetativecover_data = input,
    cram = cram,
    function_name = "Plant"
  )

  expect_true(all(is.na(result$metric_score)))
})

test_that("score_cram_index filters by year correctly", {
  input <- read.csv(test_path("fixtures/score_cram_index/input.csv"))
  cram <- read.csv(
    system.file(
      "extdata",
      "EMPA_CRAM_2014-2024.csv",
      package = "EMPAFunctionAnalysis"
    )
  )

  result_2023 <- score_cram_index(
    vegetativecover_data = input,
    cram = cram,
    function_name = "Plant",
    year = 2023
  )
  result_all <- score_cram_index(
    vegetativecover_data = input,
    cram = cram,
    function_name = "Plant",
    year = "all"
  )

  expect_equal(unique(result_2023$year), "2023")
  expect_equal(result_2023, result_all)
})

test_that("score_cram_index metric_score uses correct normalization formula", {
  veg <- data.frame(
    estuaryname = "Test Estuary",
    siteid = "TEST",
    samplecollectiondate = "2023-06-01"
  )
  cram_df <- data.frame(
    Site = "TEST",
    Year_assessment = 2023,
    index = 85
  )

  result <- score_cram_index(
    vegetativecover_data = veg,
    cram = cram_df,
    function_name = "Plant"
  )

  expected_score <- round((85 - 25) / 75 * 100, 1)
  expect_equal(result$metric_score, expected_score)
})
