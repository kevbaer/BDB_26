library(gganimate)
library(glue)

makeViz <- function(
  inputDataset,
  outputDataset,
  playDataset,
  gid,
  pid,
  club1,
  club2,
  club1col,
  club2col,
  yearNum,
  weekNum,
  yardlow = 0,
  yardhigh = 120,
  frameStart = NA,
  frameEnd = NA,
  toSave = FALSE,
  saveName = NA,
  endFreeze = 4,
  startFreeze = 0,
  annotate = FALSE
) {
  full_df <- inputDataset |>
    filter(game_id == gid & play_id == pid) |>
    left_join(playDataset, by = join_by(game_id, play_id)) |>
    mutate(
      player_club = ifelse(
        player_side == "Defense",
        defensive_team,
        possession_team
      )
    )

  if (is.na(frameStart)) {
    begin <- full_df |> pull(frame_id) |> min()
  } else {
    begin <- frameStart
  }
  if (is.na(frameEnd)) {
    end <- full_df |> pull(frame_id) |> max()
  } else {
    end <- frameEnd
  }

  length <- (end - begin) + 1 + endFreeze + startFreeze

  ex <- full_df |>
    mutate(
      pt_color = case_when(
        if (annotate) {
          is_slot ~ "gold"
        },
        player_club == club1 ~ club1col,
        player_club == club2 ~ club2col,
      ),
      pt_size = 3.8
    )
  desc <- playDataset |>
    filter(game_id == gid & play_id == pid) |>
    pull(play_description) |>
    str_replace("\\)\\.", "\\)")

  qNum <- playDataset |>
    pull(quarter)

  anim <- ggplot() +
    annotate(
      "text",
      y = seq(20, 100, 10),
      x = 10,
      color = "#000000",
      family = "sans",
      label = c("1 0", "2 0", "3 0", "4 0", "5 0", "4 0", "3 0", "2 0", "1 0"),
      angle = 270
    ) +
    annotate(
      "text",
      y = seq(20, 100, 10),
      x = 40,
      color = "#000000",
      family = "sans",
      label = c("1 0", "2 0", "3 0", "4 0", "5 0", "4 0", "3 0", "2 0", "1 0"),
      angle = 90
    ) +
    annotate(
      "text",
      y = setdiff(seq(10, 110, 1), seq(10, 110, 5)),
      x = 0,
      color = "#000000",
      label = "—",
      angle = 0
    ) +
    annotate(
      "text",
      y = setdiff(seq(10, 110, 1), seq(10, 110, 5)),
      x = 160 / 3,
      color = "#000000",
      label = "—",
      angle = 0
    ) +
    annotate(
      "text",
      y = setdiff(seq(10, 110, 1), seq(10, 110, 5)),
      x = 23.36667,
      color = "#000000",
      label = "–",
      angle = 0
    ) +
    annotate(
      "text",
      y = setdiff(seq(10, 110, 1), seq(10, 110, 5)),
      x = 29.96667,
      color = "#000000",
      label = "–",
      angle = 0
    ) +
    annotate(
      "segment",
      x = c(-Inf, Inf),
      xend = c(-Inf, Inf),
      y = 0,
      yend = 120,
      color = "#000000"
    ) +
    geom_hline(yintercept = seq(10, 110, 5), color = "#000000") +
    geom_point(
      data = filter(
        ex,
        frame_id %in%
          {
            begin
          }:{
            end
          }
      ),
      shape = 21,
      aes(160 / 3 - x, y, size = pt_size, fill = pt_color)
    ) +
    scale_size_identity() +
    scale_fill_identity() +
    transition_time(frame_id) +
    ease_aes("linear") +
    coord_cartesian(
      ylim = c(yardlow, yardhigh),
      xlim = c(0, 160 / 3),
      expand = FALSE
    ) +
    theme_minimal() +
    labs(
      title = glue(
        "<span style = 'color:{club1col};'>**{club1}**</span> vs. <span style = 'color:{club2col};'>**{club2}**</span>, {yearNum} Week {weekNum}"
      ),
      subtitle = str_c("Q{qNum}: ", desc)
    ) +
    theme(
      panel.background = element_rect(fill = "white"),
      legend.position = "none",
      plot.subtitle = element_text(size = 9, face = "italic", hjust = 0.5),
      plot.title = ggtext::element_markdown(hjust = 0.5, size = 12),
      text = element_text(family = "sans", color = "#000000"),
      axis.text = element_blank(),
      panel.grid = element_blank(),
      axis.title = element_blank(),
      axis.ticks = element_blank()
    ) +
    {
      if (annotate) {
        geom_label(
          data = filter(
            ex,
            frameId %in%
              {
                begin
              }:{
                end
              }
          ),
          aes(160 / 3 - x + 1, 64, label = deets, fill = "lightblue", size = 3)
        )
      }
    }

  tot <- yardhigh - yardlow

  a1 <- animate(
    nframes = length,
    anim,
    width = 700,
    height = (40 * tot) / 3,
    fps = 10,
    end_pause = endFreeze,
    start_pause = startFreeze,
    res = 105,
  )

  if (toSave) {
    anim_save(glue("{saveName}.gif"), a1)
  }

  return(a1)
}

input2 <- input |>
  filter(game_id == "2023100809" & play_id == "2344") |>
  select(game_id, play_id, nfl_id, frame_id, x, y, player_side)


output2 <- output |>
  filter(game_id == "2023100809" & play_id == "2344") |>
  left_join(
    input2 |> select(nfl_id, player_side) |> distinct(),
    by = join_by(nfl_id)
  ) |>
  select(game_id, play_id, frame_id, x, y, player_side) |>
  mutate(frame_id = 58 + frame_id)

full2 <- input2 |>
  bind_rows(output2)

makeViz(
  full2,
  output,
  supp,
  2023100809,
  2344,
  "DEN",
  "NYJ",
  "#FB4F14",
  "#125740",
  "2023",
  "5",
  yardlow = 15,
  yardhigh = 70,
  # toSave = TRUE,
  # saveName = "Sutton_Gardner_Rep"
)
