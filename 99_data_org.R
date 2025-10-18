library(tidyverse)
library(arrow)


output <- read_parquet("data/output.parquet")
supp <- read_parquet("data/supp.parquet")


input <- read_parquet("data/input.parquet") |>
  mutate(player_to_predict = as.logical(player_to_predict)) |>
  mutate(
    new_y = if_else(play_direction == "left", 120 - x, x),
    new_x = if_else(play_direction == "left", 160 / 3 - y, y),
    new_ball_land_x = ifelse(
      play_direction == "left",
      160 / 3 - ball_land_y,
      ball_land_y
    ),
    new_ball_land_y = ifelse(
      play_direction == "left",
      120 - ball_land_x,
      ball_land_x
    ),
    dir = ifelse(play_direction == "left", dir + 180, dir),
    dir = ifelse(dir > 360, dir - 360, dir),
    o = ifelse(play_direction == "left", o + 180, o),
    o = ifelse(o > 360, o - 360, o)
  ) |>
  mutate(
    y = new_y,
    x = new_x,
    ball_land_x = new_ball_land_x,
    ball_land_y = new_ball_land_y
  ) |>
  select(-c(new_x, new_y, new_ball_land_x, new_ball_land_y))

output <- read_parquet("data/output.parquet") |>
  left_join(
    read_parquet("data/input.parquet") |>
      select(game_id, play_id, play_direction) |>
      unique(),
    by = join_by(game_id, play_id)
  ) |> 
  mutate(
    new_y = if_else(play_direction == "left", 120 - x, x),
    new_x = if_else(play_direction == "left", 160 / 3 - y, y)
) |> 
  mutate(
    y = new_y,
    x = new_x,
  ) |> 
  select(-c(new_y, new_x))
  