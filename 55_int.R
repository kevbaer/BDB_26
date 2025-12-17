set.seed(11042004)
int_viz <- load_player_stats(seasons = 2023, summary_level = "reg") |>
  filter(def_interceptions > 0) |>
  select(player_id, player_display_name, def_int_23 = def_interceptions) |>
  full_join(
    load_player_stats(seasons = 2024, summary_level = "reg") |>
      filter(def_interceptions > 0) |>
      select(player_id, player_display_name, def_int_24 = def_interceptions),
    join_by(player_id, player_display_name)
  ) |>
  mutate(
    def_int_24 = replace_na(def_int_24, 0),
    def_int_23 = replace_na(def_int_23, 0)
  )


int_viz_final <- int_viz |>
  ggplot() +
  aes(x = def_int_23, def_int_24) +
  geom_jitter(width = .5, height = .5, size = 1, alpha = .85) +
  theme_bw(base_size = 16, base_family = "Barlow") +
  ggview::canvas(8, 8) +
  labs(
    x = "Defensive Interceptions in 2023",
    y = "Defensive Interceptions in 2024",
    title = "Interception Numbers Don't Correlate Year Over Year",
    subtitle = str_c(
      "Comparing Interceptions with a Jitter",
      " of 0.5 to Spread the Points Out"
    )
  ) +
  theme(
    plot.title.position = "plot"
  ) +
  scale_y_continuous(
    breaks = c(0, 2, 4, 6, 8)
  ) +
  scale_x_continuous(
    breaks = c(0, 2, 4, 6, 8)
  )

# ggview::save_ggplot(int_viz_final, "viz/int_comp_23_to_24.png")

cor(int_viz$def_int_23, int_viz$def_int_24)
