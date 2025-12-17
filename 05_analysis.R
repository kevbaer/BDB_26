source("99_data_org.R")
library(nflreadr)
library(nflplotR)

results_throw <- read_parquet("sharing/final_throw_df_mon15.parquet")

def_throw <- read_parquet("sharing/final_throw_df_2_mon15.parquet")

results_arrival <- read_parquet("sharing/final_arrival_df_mon15.parquet")

valid_arrivals <- results_arrival |>
  filter(!is.na(Def_Player_Control))


invalid_arrivals <- results_arrival |>
  filter(is.na(Def_Player_Control))

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
  mutate(nfl_id = as.numeric(nfl_id)) |>
  left_join(
    load_player_stats(seasons = 2023, summary_level = "reg") |>
      select(
        player_id,
        nu_position = position,
        recent_team,
        def_interceptions,
        def_pass_defended
      ),
    join_by(gsis_id == player_id)
  )

player_df <- input |>
  select(nfl_id, player_name, player_position) |>
  unique() |>
  left_join(pl_nflfastr, join_by(nfl_id))


# leaderboard -------------------------------------------------------------

approve_at_throw <- results_throw |>
  filter(Receiver_Control > .5)

approve_at_catch <- results_arrival |>
  filter(Def_Player_Control > .5)

full_leaderboard <- approve_at_catch |>
  inner_join(approve_at_throw, by = join_by(game_id, play_id)) |>
  summarize(n = n(), .by = nfl_id) |>
  arrange(desc(n)) |>
  left_join(player_df, by = join_by(nfl_id)) |>
  relocate(n, .after = last_col())


# Load in More Data Sources -----------------------------------------------

sumer_dat <- read_parquet("data/sumer_coverages_player_play.parquet")

thirds_sumer <- sumer_dat |>
  filter(coverage_responsibility == "THIRD")

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


# Daniel ------------------------------------------------------------------

# final_throw_df2 <- read_parquet("sharing/final_throw_df_3_mon15.parquet") |>
#   rename(Def_Player_Control_at_Throw = Def_Player_Control)
#
# final_arrival_df2 <- read_parquet(
#   "sharing/final_arrival_df_daniel_mon15.parquet"
# ) |>
#   rename(Def_Player_Control_at_Arrival = Def_Player_Control)
#
# frame_df <- input |>
#   select(game_id, play_id, num_frames_output) |>
#   distinct()
#
# final_throw_df2 |>
#   inner_join(approve_at_throw, by = join_by(game_id, play_id)) |>
#   select(-Receiver_Control) |>
#   left_join(final_arrival_df2, by = join_by(game_id, play_id, nfl_id)) |>
#   left_join(frame_df, by = join_by(game_id, play_id)) |>
#   mutate(
#     delta_def_control = (Def_Player_Control_at_Arrival -
#       Def_Player_Control_at_Throw) /
#       num_frames_output
#   ) |>
#   summarize(
#     n = n(),
#     ave_delta_def_control = mean(delta_def_control, na.rm = TRUE),
#     .by = nfl_id
#   ) |>
#   arrange(desc(ave_delta_def_control)) |>
#   left_join(player_df, by = join_by(nfl_id)) |>
#   select(nfl_id, player_name, player_position, n, ave_delta_def_control) |>
#   filter(n > 10) |>
View()
