# load data and libraries
set.seed(11)
library(dplyr)
dat_raw <- read.csv("~/Downloads/table_2CE4F5AC7A7A48E9A5AFC8D7E2DF7C9C.csv", header=FALSE)
nms <- as.character(dat_raw[1, -1])
dat_pre <- dat_raw[-1, -1] |> setNames(nms)
dat_pre[dat_pre == ""] <- NA
dat_wide <- dat_pre |> 
  na.omit() |>
  t() |>
  as.data.frame()

row.names(dat_wide)[-1] 
age_cats <- c("15-24", "25-44", "45-64", "65+")
names(age_cats) <- age_cats
queer_cats <- c(rep(1, length(age_cats)), rep(0, length(age_cats))) 

dat <- data.frame(age = rep(age_cats, 2), LGBTQIA = factor(queer_cats, levels = 0:1, labels = c("no", "yes")), prop = c(dat_wide[-1, 1], dat_wide[-1, 2]))  





dat <- dat[-c(1:4, 55), ]
dat$Y <- (1:nrow(dat) * 2) - 2

dat_25 <- purrr::map_dfr(1:nrow(dat), ~{
  if (dat$tot.25.jaar[.x] > 0) {
    data.frame(
      age = sample(18:25, dat$tot.25.jaar[.x], replace = TRUE),
      income = rep(dat$Y[.x], dat$tot.25.jaar[.x])
    )
  } else {
    data.frame(age = NA, income = NA)
  }
}) |> filter(!is.na(age))

dat_35 <- purrr::map_dfr(1:nrow(dat), ~{
  if (dat$X25.tot.35.jaar[.x] > 0) {
    data.frame(
      age = sample(25:35, dat$X25.tot.35.jaar[.x] , replace = TRUE),
      income = rep(dat$Y[.x], dat$X25.tot.35.jaar[.x])
    )
  } else {
    data.frame(age = NA, income = NA)
  }
}) |> filter(!is.na(age))

dat_45 <- purrr::map_dfr(1:nrow(dat), ~{
  if (dat$X35.tot.45.jaar[.x] > 0) {
    data.frame(
      age = sample(35:45, dat$X35.tot.45.jaar[.x], replace = TRUE),
      income = rep(dat$Y[.x], dat$X35.tot.45.jaar[.x])
    )
  } else {
    data.frame(age = NA, income = NA)
  }
}) |> filter(!is.na(age))

dat_55 <- purrr::map_dfr(1:nrow(dat), ~{
  if (dat$X45.to.55.jaar[.x] > 0) {
    data.frame(
      age = sample(45:55, dat$X45.to.55.jaar[.x], replace = TRUE),
      income = rep(dat$Y[.x], dat$X45.to.55.jaar[.x])
    )
  } else {
    data.frame(age = NA, income = NA)
  }
}) |> filter(!is.na(age))

dat_65 <- purrr::map_dfr(1:nrow(dat), ~{
  if (dat$X55.tot.65.jaar[.x] > 0) {
    data.frame(
      age = sample(55:65, dat$X55.tot.65.jaar[.x], replace = TRUE),
      income = rep(dat$Y[.x], dat$X55.tot.65.jaar[.x])
    )
  } else {
    data.frame(age = NA, income = NA)
  }
}) |> filter(!is.na(age))

dat_75 <- purrr::map_dfr(1:nrow(dat), ~{
  if (dat$X65.tot.75.jaar[.x] > 0) {
    data.frame(
      age = sample(65:75, dat$X65.tot.75.jaar[.x], replace = TRUE),
      income = rep(dat$Y[.x], dat$X65.tot.75.jaar[.x])
    )
  } else {
    data.frame(age = NA, income = NA)
  }
}) |> filter(!is.na(age))

dat_85 <- purrr::map_dfr(1:nrow(dat), ~{
  if (dat$X75.jaar.en.ouder[.x] > 0) {
    data.frame(
      age = sample(75:85, dat$X75.jaar.en.ouder[.x], replace = TRUE),
      income = rep(dat$Y[.x], dat$X75.jaar.en.ouder[.x])
    )
  } else {
    data.frame(age = NA, income = NA)
  }
}) |> filter(!is.na(age))

dat <- rbind(dat_25, dat_35, dat_45, dat_55, dat_65, dat_75, dat_85)
write.csv2(dat, file = "data/income_2022_long.csv", row.names = FALSE)
saveRDS(dat, file = "data/income_2022_long.rds")

dat$ind_mcar <- runif(nrow(dat)) < 0.1
dat$ind_mar <- rownames(dat) %in% sample(rownames(dat[dat$age < 36, ]), size = floor(nrow(dat)/10))
dat$ind_mnar <- rownames(dat) %in% sample(rownames(dat[dat$income > 40, ]), size = floor(nrow(dat)/10))

dat$income_mcar <- ifelse(dat$ind_mcar, NA, dat$income)
dat$income_mar <- ifelse(dat$ind_mar, NA, dat$income)
dat$income_mnar <- ifelse(dat$ind_mnar, NA, dat$income)

dat <- dat |> mutate(ind_mcar = as.factor(ind_mcar),
                     ind_mcar = factor(ind_mcar, levels = c(TRUE, FALSE), labels = c("missing", "observed")),
                     ind_mar = as.factor(ind_mar),
                     ind_mar = factor(ind_mar, levels = c(TRUE, FALSE), labels = c("missing", "observed")),
                     ind_mnar = as.factor(ind_mnar),
                     ind_mnar = factor(ind_mnar, levels = c(TRUE, FALSE), labels = c("missing", "observed")))

saveRDS(dat, file = "data/income_2022_incomplete.rds")

