library(ricu)
library(dplyr)
library(tidyr)
library(janitor)

clean_mimic_demo <- function(mimic, n = 50) {
# mimic <- ricu::mimic_demo
admissions <- data.frame(mimic$admissions)
icustays <- data.frame(mimic$icustays)

hadm_icustay_ids <- inner_join(admissions, icustays, by = "hadm_id") |>
  select(c(hadm_id, icustay_id))

load_dictionary("mimic_demo")
dict <- explain_dictionary() # concepts and description
dict$category <- factor(dict$category)

dict$category |> levels() # levels of categories to ease filtering

# FiO2 (%)
explain_dictionary() |> filter(category == "blood gas") # get name

fio2 <- load_concepts("fio2", verbose = FALSE) |> # load fio2
  full_join(icustays, by = "icustay_id") |> # add icustay data for times
  group_by(icustay_id) |>
  mutate(admission_length = difftime(
    intime,
    # calculate length of admission
    outtime,
    units = "hours"
  )) |>
  filter(charttime >= (admission_length - 24)) |> # filter for last 24 hours
  filter(fio2 == max(fio2)) |> # filter for worst value
  filter(row_number() == 1) |> # only 1 per patient
  select(c("icustay_id", "fio2")) # relevant columns

# PaO2 (mmHg)
# create concept
pao2_conc <- concept(
  "pao2",
  item("mimic_demo", "chartevents", "itemid", 770),
  description = "PaO2",
  unit = "mmHg"
)

pao2 <- load_concepts(pao2_conc, verbose = F) |> # load PaO2
  full_join(icustays, by = "icustay_id") |> # add icustay data for times
  group_by(icustay_id) |>
  mutate(admission_length = difftime(
    intime,
    # calculate length of admission
    outtime,
    units = "hours"
  )) |>
  filter(charttime >= (admission_length - 24)) |> # filter for last 24 hours
  filter(pao2 == min(pao2)) |> # filter for worst value
  filter(row_number() == 1) |> # only 1 per patient
  select(c("icustay_id", "pao2")) # relevant columns

# platelets * 10^3/mm^3
explain_dictionary() |> filter(category == "hematology")  # get name

platelets <- load_concepts("plt", verbose = F) |> # load platelets
  full_join(icustays, by = "icustay_id") |> # add icustay data for times
  group_by(icustay_id) |>
  mutate(admission_length = difftime(
    intime,
    # calculate length of admission
    outtime,
    units = "hours"
  )) |>
  filter(charttime >= (admission_length - 24)) |> # filter for last 24 hours
  filter(plt == min(plt)) |> # filter for worst value
  filter(row_number() == 1) |> # only 1 per patient
  select(c("icustay_id", "plt")) # relevant columns

# bilirubin
bilirubin <- load_concepts("bili", verbose = F) |> # load bili
  full_join(icustays, by = "icustay_id") |> # add icustay data for times
  group_by(icustay_id) |>
  mutate(admission_length = difftime(
    intime,
    # calculate length of admission
    outtime,
    units = "hours"
  )) |>
  filter(charttime >= (admission_length - 24)) |> # filter for last 24 hours
  filter(bili == max(bili)) |> # filter for worst value
  filter(row_number() == 1) |> # only 1 per patient
  select(c("icustay_id", "bili")) # relevant columns

# Glasgow Coma Score
explain_dictionary() |> filter(category == "neurological")  # get name

# non-sedated Glasgow Coma Scale
gcs <- load_concepts("gcs", verbose = F) |> # load gcs (non-sedated)
  full_join(icustays, by = "icustay_id") |> # add icustay data for times
  group_by(icustay_id) |>
  mutate(admission_length = difftime(
    intime,
    # calculate length of admission
    outtime,
    units = "hours"
  )) |>
  filter(charttime >= (admission_length - 24)) |> # filter for last 24 hours
  filter(gcs == min(gcs)) |> # filter for worst value
  filter(row_number() == 1) |> # only 1 per patient
  select(c("icustay_id", "gcs")) # relevant columns

# Total Glasgow Coma Scale
gcs_tot <- load_concepts("tgcs", verbose = F) |> # load tgcs
  full_join(icustays, by = "icustay_id") |> # add icustay data for times
  group_by(icustay_id) |>
  mutate(admission_length = difftime(
    intime,
    # calculate length of admission
    outtime,
    units = "hours"
  )) |>
  filter(charttime >= (admission_length - 24)) |> # filter for last 24 hours
  filter(tgcs == min(tgcs)) |> # filter for worst value
  filter(row_number() == 1) |> # only 1 per patient
  select(c("icustay_id", "tgcs")) # relevant columns

# MAP (mmHg)
explain_dictionary() |> filter(category == "vitals") # get name

map <- load_concepts("map", verbose = F) |> # load map
  full_join(icustays, by = "icustay_id") |> # add icustay data for times
  group_by(icustay_id) |>
  mutate(admission_length = difftime(
    intime,
    # calculate length of admission
    outtime,
    units = "hours"
  )) |>
  filter(charttime >= (admission_length - 24)) |> # filter for last 24 hours
  filter(map == max(map)) |> # filter for worst value
  filter(row_number() == 1) |> # only 1 per patient
  select(c("icustay_id", "map")) # relevant columns

# Creatinine (mg/dL)
explain_dictionary() |> filter(category == "chemistry") # get name

crea <- load_concepts("crea", verbose = F) |> # load crea
  full_join(icustays, by = "icustay_id") |> # add icustay data for times
  group_by(icustay_id) |>
  mutate(admission_length = difftime(
    intime,
    # calculate length of admission
    outtime,
    units = "hours"
  )) |>
  filter(charttime >= (admission_length - 24)) |> # filter for last 24 hours
  filter(crea == max(crea)) |> # filter for worst value
  filter(row_number() == 1) |> # only 1 per patient
  select(c("icustay_id", "crea")) # relevant columns

# Urine output
explain_dictionary() |> filter(category == "output") # get name

urine <- load_concepts("urine24", verbose = F) |> # load urine24
  na.omit() |> # remove missing values
  full_join(icustays, by = "icustay_id") |> # add icustay data for times
  group_by(icustay_id) |>
  mutate(admission_length = difftime(
    intime,
    # calculate length of admission
    outtime,
    units = "hours"
  )) |>
  filter(charttime >= (admission_length - 24)) |> # filter for last 24 hours
  filter(urine24 == min(urine24)) |> # filter for worst value
  filter(row_number() == 1) |> # only 1 per patient
  select(c("icustay_id", "urine24")) # relevant columns

# Mortality
death <- full_join(admissions, icustays, by = "hadm_id") |>
  select(c("icustay_id", hospital_expire_flag)) # 1 = death

# join all data
mimic_demo_subset <- fio2 |> # join all data
  full_join(pao2, by = "icustay_id") |>
  full_join(platelets, by = "icustay_id") |>
  full_join(bilirubin, by = "icustay_id") |>
  full_join(gcs, by = "icustay_id") |>
  full_join(gcs_tot, by = "icustay_id") |>
  full_join(map, by = "icustay_id") |>
  full_join(crea, by = "icustay_id") |>
  full_join(urine, by = "icustay_id") |>
  full_join(death, by = "icustay_id") |>
  as.data.frame()

# mimic_demo_subset
# saveRDS(mimic_demo_subset, "mimic_demo_subset.rds")
# mimic_demo_subset <- readRDS("mimic_demo_subset.rds")

dat <- head(mimic_demo_subset, n)
dat <- mutate(dat,
              mortality = as.logical(hospital_expire_flag),
              tgcs = as.factor(tgcs))
dat <- select(dat, -c("icustay_id", "hospital_expire_flag", "gcs"))

return(dat)
}
# ggmice::plot_pattern(dat)
# ggmice::plot_miss(dat)
