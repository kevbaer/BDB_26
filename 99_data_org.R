library(tidyverse)
library(arrow)
library(DescTools)


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
  select(-c(new_x, new_y, new_ball_land_x, new_ball_land_y)) |>
  mutate(h_dist_from_ball = abs(ball_land_x - x)) |>
  mutate(v_dist_from_ball = abs(ball_land_y - y)) |>
  mutate(total_dist_from_ball = (h_dist_from_ball^2 + v_dist_from_ball^2)^.5) |>
  mutate(dir = DegToRad(dir)) |>
  mutate(o = DegToRad(o)) |>
  mutate(hcomp = cos(dir), vcomp = sin(dir)) |>
  mutate(h_speed = hcomp * s, v_speed = vcomp * s)

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
  select(-c(new_y, new_x)) |>
  mutate(
    x_lag_1 = lag(x, n = 1),
    x_lag_2 = lag(x, n = 2),
    x_lag_3 = lag(x, n = 3),
    y_lag_1 = lag(y, n = 1),
    y_lag_2 = lag(y, n = 2),
    y_lag_3 = lag(y, n = 3),
    .by = c(game_id, play_id, nfl_id)
  ) |>
  mutate(
    s_estimate = sqrt((x_lag_3 - x_lag_1)**2 + (y_lag_3 - y_lag_1)**2) / .2
  )


play_info <- input |>
  filter(player_to_predict) |>
  select(
    game_id,
    play_id,
    nfl_id,
    player_name,
    player_side,
    player_role,
    num_frames_output,
    ball_land_x,
    ball_land_y
  ) |>
  distinct()


enhanced_output <- output |>
  left_join(play_info, by = join_by(game_id, play_id, nfl_id)) |>
  select(-play_direction)


at_throw_df <- input |>
  filter(frame_id == (max(frame_id) - 5), .by = c(game_id, play_id, nfl_id)) |>
  filter(player_to_predict)

# write_parquet(at_throw_df, "transfer/at_throw_df.parquet")
