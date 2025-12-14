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

pl_nflfastr <- load_players() |>
  select(
    display_name,
    short_name,
    nfl_id,
    position_group,
    position,
    height,
    weight,
    headshot,
    pff_position,
    gsis_id
  ) |>
  mutate(nfl_id = as.numeric(nfl_id))


player_df <- input |>
  select(nfl_id, player_name, player_position) |>
  unique() |>
  left_join(pl_nflfastr, join_by(nfl_id))


# leaderboard -------------------------------------------------------------

approve_at_throw <- results_throw |>
  filter(Receiver_Control > .5)

approve_at_catch <- results_arrival |>
  filter(Def_Player_Control > 1)

full_leaderboard <- approve_at_catch |>
  inner_join(approve_at_throw, by = join_by(game_id, play_id)) |>
  summarize(n = n(), .by = nfl_id) |>
  arrange(desc(n)) |>
  left_join(player_df, by = join_by(nfl_id)) |>
  relocate(n, .after = last_col())


# Load in More Data Sources -----------------------------------------------

library(nflreadr)
sumer_dat <- read_parquet("data/sumer_coverages_player_play.parquet")

thirds_sumer <- sumer_dat |>
  filter(coverage_responsibility == "THIRD") |>
  View()

ftn_dat <- load_ftn_charting(seasons = 2023) |>
  select(
    nflverse_game_id,
    nflverse_play_id,
    is_interception_worthy,
    is_contested_ball
  )

fastr_dat <- load_pbp(seasons = 2023) |>
  mutate(old_game_id = as.numeric(old_game_id)) |>
  select(
    game_id,
    old_game_id,
    play_id,
    home_team,
    away_team,
    week,
    posteam,
    defteam,
    yards_gained,
    pass_length,
    pass_location,
    air_yards,
    yards_after_catch,
    wp,
    wpa,
    ep,
    epa,
    air_wpa,
    yac_wpa,
    air_epa,
    yac_epa,
    incomplete_pass,
    interception,
    interception_player_id,
    interception_player_name,
    cp,
    cpoe
  ) |>
  left_join(
    ftn_dat,
    join_by(game_id == nflverse_game_id, play_id == nflverse_play_id)
  ) |>
  select(-game_id)

partic <- load_participation(seasons = 2023) |>
  mutate(old_game_id = as.numeric(old_game_id)) |>
  select(
    old_game_id,
    play_id,
    number_of_pass_rushers,
    defense_players,
    n_defense,
    time_to_throw,
    was_pressure,
    defense_man_zone_type,
    defense_coverage_type
  ) |>
  semi_join(results_throw, by = join_by(old_game_id == game_id, play_id)) |>
  separate_wider_delim(defense_players, ";", names_sep = "_") |>
  mutate(
    number_of_pass_rushers = ifelse(
      number_of_pass_rushers > 11,
      NA,
      number_of_pass_rushers
    )
  )

partic_by_player <- load_participation(seasons = 2023) |>
  mutate(old_game_id = as.numeric(old_game_id)) |>
  select(
    old_game_id,
    play_id,
    number_of_pass_rushers,
    defense_players,
    n_defense,
    time_to_throw,
    was_pressure,
    defense_man_zone_type,
    defense_coverage_type
  ) |>
  semi_join(results_throw, by = join_by(old_game_id == game_id, play_id)) |>
  separate_longer_delim(defense_players, ";") |>
  summarize(n = n(), .by = defense_players) |>
  arrange(desc(n))


full_added_dat <- inner_join(
  sumer_dat,
  fastr_dat,
  by = join_by(game_id == old_game_id, play_id)
)

working_dat <- approve_at_catch |>
  inner_join(approve_at_throw, by = join_by(game_id, play_id)) |>
  left_join(full_added_dat, by = join_by(game_id, play_id, nfl_id))


# Joint Leaderboard -------------------------------------------------------

library(gt)
library(gtExtras)

full_leaderboard |>
  left_join(partic_by_player, join_by(gsis_id == defense_players)) |>
  mutate(turnover_opp_pct = n.x / n.y) |>
  select(
    headshot,
    player = player_name,
    position = pff_position,
    turnover_opps = n.x,
    total_coverage_reps = n.y,
    turnover_opp_pct
  ) |>
  arrange(desc(turnover_opp_pct)) |>
  filter(total_coverage_reps > 150) |>
  slice_max(turnover_opp_pct, n = 20) |>
  mutate(
    row_id = str_glue(
      "{dplyr::row_number()}."
    ),
    .before = 1
  ) |>
  gt() |>
  gt_theme_espn() |>
  gt_img_rows(headshot, height = 45) |>
  fmt_percent(turnover_opp_pct) |>
  gt_hulk_col_numeric(
    turnover_opp_pct,
    domain = c(0, .05)
  ) |>
  cols_align(align = "center")


# Daniel ------------------------------------------------------------------

final_throw_df2 <- read_parquet("sharing/final_throw_df_3.parquet") |>
  rename(Def_Player_Control_at_Throw = Def_Player_Control)

final_arrival_df2 <- read_parquet("sharing/final_arrival_df_daniel.parquet") |>
  rename(Def_Player_Control_at_Arrival = Def_Player_Control)

frame_df <- input |>
  select(game_id, play_id, num_frames_output) |>
  distinct()

final_throw_df2 |>
  inner_join(approve_at_throw, by = join_by(game_id, play_id)) |>
  select(-Receiver_Control) |>
  left_join(final_arrival_df2, by = join_by(game_id, play_id, nfl_id)) |>
  left_join(frame_df, by = join_by(game_id, play_id)) |>
  mutate(
    delta_def_control = (Def_Player_Control_at_Arrival -
      Def_Player_Control_at_Throw) /
      num_frames_output
  ) |>
  summarize(
    n = n(),
    ave_delta_def_control = mean(delta_def_control, na.rm = TRUE),
    .by = nfl_id
  ) |>
  arrange(desc(ave_delta_def_control)) |>
  left_join(player_df, by = join_by(nfl_id)) |>
  select(nfl_id, player_name, player_position, n, ave_delta_def_control) |>
  filter(n > 10) |>
  View()
