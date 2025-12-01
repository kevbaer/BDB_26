library(tidyverse)
library(arrow)

results_throw <- read_parquet("sharing/final_throw_df.parquet")

results_throw |> filter(is.na(Receiver_Control))

results_arrival <- read_parquet("sharing/final_arrival_Df.parquet")

valid_arrivals <- results_arrival |>
  filter(!is.na(Def_Player_Control))

valid_arrivals |>
  count(Def_Player_Control > 1)


invalid_arrivals <- results_arrival |>
  filter(is.na(Def_Player_Control))

at_arrival_df |>
  filter(game_id == 2023120700 & play_id == 1789) |>
  View()

player_df <- input |>
  select(nfl_id, player_name, player_position) |>
  unique()


# leaderboard -------------------------------------------------------------

approve_at_throw <- results_throw |>
  filter(Receiver_Control > .5)

approve_at_catch <- results_arrival |>
  filter(Def_Player_Control > 1)

approve_at_catch |>
  inner_join(approve_at_throw, by = join_by(game_id, play_id)) |>
  summarize(n = n(), .by = nfl_id) |>
  arrange(desc(n)) |>
  left_join(player_df, by = join_by(nfl_id)) |>
  relocate(n, .after = last_col()) |>
  View()
