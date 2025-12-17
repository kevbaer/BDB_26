CBs <- full_leaderboard |>
  left_join(partic_by_player, join_by(gsis_id == defense_players)) |>
  left_join(
    def_throw |>
      semi_join(approve_at_throw, join_by(game_id, play_id)) |>
      summarize(hq_targets = n(), .by = nfl_id),
    join_by(nfl_id)
  ) |>
  rename(turnover_opps = n.x, total_coverage_reps = n.y) |>
  mutate(
    turnover_opp_pct = turnover_opps / total_coverage_reps,
    hq_target_pct = hq_targets / total_coverage_reps,
    targets_that_are_hqio = turnover_opps / hq_targets,
  ) |>
  select(
    headshot,
    player = player_name,
    position = pff_position,
    team = recent_team,
    total_coverage_reps,
    ints = def_interceptions,
    passes_defensed = def_pass_defended,
    hq_targets,
    hq_target_pct,
    targets_that_are_hqio,
    turnover_opps,
    turnover_opp_pct
  ) |>
  arrange(desc(turnover_opp_pct)) |>
  filter(total_coverage_reps > 200 & position == "CB") |>
  slice_max(turnover_opp_pct, n = 5) |>
  mutate(
    row_id = str_glue(
      "{dplyr::row_number()}."
    ),
    .before = 1
  ) |>
  relocate(
    row_id,
    headshot,
    player,
    team,
    position,
    total_coverage_reps,
    passes_defensed,
    ints,
    hq_targets,
    hq_target_pct,
    turnover_opps,
    targets_that_are_hqio,
    turnover_opp_pct
  ) |>
  gt(groupname_col = "position") |>
  gt_theme_espn() |>
  gt_img_rows(headshot, height = 55) |>
  fmt_percent(c(turnover_opp_pct, hq_target_pct, targets_that_are_hqio)) |>
  gt_hulk_col_numeric(
    turnover_opp_pct,
    domain = c(0, .045),
  ) |>
  cols_align(align = "center") |>
  gt_nfl_logos(columns = team, height = 50) |>
  gt_merge_stack(
    headshot,
    player,
    small_cap = FALSE,
    palette = c("black", "grey20"),
    font_size = c("16px", "16px")
  ) |>
  tab_spanner(
    label = "Traditional Metrics",
    columns = c(passes_defensed, ints)
  ) |>
  tab_spanner(
    label = "New Metrics",
    columns = hq_targets:turnover_opp_pct
  ) |>
  gt_add_divider(
    c(
      team,
      total_coverage_reps,
      ints,
      turnover_opp_pct,
      hq_target_pct
    ),
    weight = "3px",
    color = "black"
  ) |>
  tab_style(
    style = cell_borders(
      sides = c("right"),
      weight = px(3),
      color = "black"
    ),
    locations = cells_column_spanners(
      c("Traditional Metrics", "New Metrics")
    )
  ) |>
  tab_header(
    title = str_glue(
      "High Quality Interception Opportunity Creation Rate"
    ),
    subtitle = str_glue(
      "Data from 2023 NFL Regular Season | 2026 BDB Entry | Kevin Baer and Daniel Wang"
    )
  ) |>
  cols_label(
    row_id = "#",
    headshot = "player",
    total_coverage_reps = "Coverage Snaps",
    passes_defensed = "PDS",
    turnover_opps = "HQIOs",
    turnover_opp_pct = "HQIOs / Coverage Snaps",
    hq_targets = "HQ Targets Allowed",
    hq_target_pct = "HQ Targets / Coverage Snaps",
    targets_that_are_hqio = "HQIOs / HQ Targets"
  ) |>
  cols_width(
    row_id ~ 35,
    player ~ 180,
    team ~ 80,
    passes_defensed ~ 70,
    ints ~ 70,
    hq_targets:turnover_opp_pct ~ 110,
    total_coverage_reps ~ 80
  ) |>
  tab_row_group(
    label = "CORNERBACK",
    rows = everything()
  ) |>
  tab_style(
    style = list(
      cell_fill("black"),
      cell_text(color = "white", weight = "bold")
    ),
    locations = cells_row_groups()
  ) |>
  tab_style(
    cell_fill(color = "gold1"),
    cells_column_spanners("New Metrics")
  ) |>
  tab_options(table.width = px(1050))


SAFs <- full_leaderboard |>
  left_join(partic_by_player, join_by(gsis_id == defense_players)) |>
  left_join(
    def_throw |>
      semi_join(approve_at_throw, join_by(game_id, play_id)) |>
      summarize(hq_targets = n(), .by = nfl_id),
    join_by(nfl_id)
  ) |>
  rename(turnover_opps = n.x, total_coverage_reps = n.y) |>
  mutate(
    turnover_opp_pct = turnover_opps / total_coverage_reps,
    hq_target_pct = hq_targets / total_coverage_reps,
    targets_that_are_hqio = turnover_opps / hq_targets
  ) |>
  select(
    headshot,
    player = player_name,
    position = pff_position,
    team = recent_team,
    total_coverage_reps,
    ints = def_interceptions,
    passes_defensed = def_pass_defended,
    hq_targets,
    hq_target_pct,
    targets_that_are_hqio,
    turnover_opps,
    turnover_opp_pct
  ) |>
  arrange(desc(turnover_opp_pct)) |>
  filter(total_coverage_reps > 200 & position == "S") |>
  slice_max(turnover_opp_pct, n = 5) |>
  mutate(
    row_id = str_glue(
      "{dplyr::row_number()}."
    ),
    .before = 1
  ) |>
  relocate(
    row_id,
    headshot,
    player,
    team,
    position,
    total_coverage_reps,
    passes_defensed,
    ints,
    hq_targets,
    hq_target_pct,
    turnover_opps,
    targets_that_are_hqio,
    turnover_opp_pct
  ) |>
  gt(groupname_col = "position") |>
  gt_theme_espn() |>
  gt_img_rows(headshot, height = 55) |>
  fmt_percent(c(turnover_opp_pct, hq_target_pct, targets_that_are_hqio)) |>
  gt_hulk_col_numeric(
    turnover_opp_pct,
    domain = c(0, .0325),
  ) |>
  cols_align(align = "center") |>
  gt_nfl_logos(columns = team, height = 50) |>
  gt_merge_stack(
    headshot,
    player,
    small_cap = FALSE,
    palette = c("black", "grey20"),
    font_size = c("16px", "16px")
  ) |>
  tab_spanner(
    label = "Traditional Metrics",
    columns = c(passes_defensed, ints)
  ) |>
  tab_spanner(
    label = "New Metrics",
    columns = hq_targets:turnover_opp_pct
  ) |>
  gt_add_divider(
    c(
      team,
      total_coverage_reps,
      ints,
      turnover_opp_pct,
      hq_target_pct
    ),
    weight = "3px",
    color = "black"
  ) |>
  tab_style(
    style = cell_borders(
      sides = c("right"),
      weight = px(3),
      color = "black"
    ),
    locations = cells_column_spanners(
      c("Traditional Metrics", "New Metrics")
    )
  ) |>
  cols_width(
    row_id ~ 35,
    player ~ 180,
    team ~ 80,
    passes_defensed ~ 70,
    ints ~ 70,
    hq_targets:turnover_opp_pct ~ 110,
    total_coverage_reps ~ 80
  ) |>
  tab_row_group(
    label = "SAFETY",
    rows = everything()
  ) |>
  tab_style(
    style = list(
      cell_fill("black"),
      cell_text(color = "white", weight = "bold")
    ),
    locations = cells_row_groups()
  ) |>
  tab_style(
    cell_fill(color = "gold1"),
    cells_column_spanners("New Metrics")
  ) |>
  rm_stubhead() |>
  tab_options(table.border.top.width = 0, row_group.border.top.width = 0) |>
  tab_options(column_labels.hidden = TRUE) |>
  tab_options(table.width = px(1050))


LBs <- full_leaderboard |>
  left_join(partic_by_player, join_by(gsis_id == defense_players)) |>
  left_join(
    def_throw |>
      semi_join(approve_at_throw, join_by(game_id, play_id)) |>
      summarize(hq_targets = n(), .by = nfl_id),
    join_by(nfl_id)
  ) |>
  rename(turnover_opps = n.x, total_coverage_reps = n.y) |>
  mutate(
    turnover_opp_pct = turnover_opps / total_coverage_reps,
    hq_target_pct = hq_targets / total_coverage_reps,
    targets_that_are_hqio = turnover_opps / hq_targets
  ) |>
  select(
    headshot,
    player = player_name,
    position = pff_position,
    team = recent_team,
    total_coverage_reps,
    ints = def_interceptions,
    passes_defensed = def_pass_defended,
    hq_targets,
    hq_target_pct,
    targets_that_are_hqio,
    turnover_opps,
    turnover_opp_pct
  ) |>
  arrange(desc(turnover_opp_pct)) |>
  filter(total_coverage_reps > 200 & position == "LB") |>
  slice_max(turnover_opp_pct, n = 5) |>
  mutate(
    row_id = str_glue(
      "{dplyr::row_number()}."
    ),
    .before = 1
  ) |>
  relocate(
    row_id,
    headshot,
    player,
    team,
    position,
    total_coverage_reps,
    passes_defensed,
    ints,
    hq_targets,
    hq_target_pct,
    turnover_opps,
    targets_that_are_hqio,
    turnover_opp_pct
  ) |>
  gt(groupname_col = "position") |>
  gt_theme_espn() |>
  gt_img_rows(headshot, height = 55) |>
  fmt_percent(c(turnover_opp_pct, hq_target_pct, targets_that_are_hqio)) |>
  gt_hulk_col_numeric(
    turnover_opp_pct,
    domain = c(0, .035),
  ) |>
  cols_align(align = "center") |>
  gt_nfl_logos(columns = team, height = 50) |>
  gt_merge_stack(
    headshot,
    player,
    small_cap = FALSE,
    palette = c("black", "grey20"),
    font_size = c("16px", "16px")
  ) |>
  tab_spanner(
    label = "Traditional Metrics",
    columns = c(passes_defensed, ints)
  ) |>
  tab_spanner(
    label = "New Metrics",
    columns = hq_targets:turnover_opp_pct
  ) |>
  gt_add_divider(
    c(
      team,
      total_coverage_reps,
      ints,
      turnover_opp_pct,
      hq_target_pct
    ),
    weight = "3px",
    color = "black"
  ) |>
  tab_style(
    style = cell_borders(
      sides = c("right"),
      weight = px(3),
      color = "black"
    ),
    locations = cells_column_spanners(
      c("Traditional Metrics", "New Metrics")
    )
  ) |>
  cols_width(
    row_id ~ 35,
    player ~ 180,
    team ~ 80,
    passes_defensed ~ 70,
    ints ~ 70,
    hq_targets:turnover_opp_pct ~ 110,
    total_coverage_reps ~ 80
  ) |>
  tab_row_group(
    label = "LINEBACKER",
    rows = everything()
  ) |>
  tab_style(
    style = list(
      cell_fill("black"),
      cell_text(color = "white", weight = "bold")
    ),
    locations = cells_row_groups()
  ) |>
  tab_style(
    cell_fill(color = "gold1"),
    cells_column_spanners("New Metrics")
  ) |>
  rm_stubhead() |>
  tab_options(table.border.top.width = 0, row_group.border.top.width = 0) |>
  tab_options(column_labels.hidden = TRUE) |>
  tab_options(table.width = px(1050)) |>
  tab_footnote(
    footnote = str_c(
      "PDs = Passes Defensed, ",
      "HQ = High Quality, ",
      "HQIOs = High Quality Interception Opportunities"
    )
  )

gt_group(CBs, SAFs, LBs)
