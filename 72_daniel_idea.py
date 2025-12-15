game_play_defender_trios_2 = (
    at_throw_df.filter(pl.col("player_role") == "Defensive Coverage")
    .select("game_id", "play_id", "nfl_id")
    .unique()
)

at_throw_df_pd = at_throw_df.to_pandas()


def ind_def_evaluator_2(defender, receiver, ball):
    def_control = np.array(defender) * np.array(ball)
    off_control = np.array(receiver) * np.array(ball)

    return np.sum(np.sum(def_control, axis=1), axis=0) / (
        np.sum(np.sum(off_control, axis=1), axis=0)
        + np.sum(np.sum(def_control, axis=1), axis=0)
    )


def build_arrival_final_2():
    defender_control = np.array([-1] * game_play_defender_trios_2.height, dtype=float)
    for (
        index,
        row,
    ) in game_play_defender_trios_2.to_pandas().iterrows():
        GS = row["game_id"]
        PS = row["play_id"]
        Def_Id = row["nfl_id"]
        defender_control[index] = ind_def_evaluator_2(
            ind_defense_pdf_builder(at_throw_df_pd, GS, PS, Def_Id),
            receiver_pdf_builder(at_throw_df_pd, GS, PS),
            ball_landing_pdf_builder(at_throw_df_pd, GS, PS),
        )
    return defender_control


final_throw_df_2 = game_play_defender_trios_2.with_columns(
    pl.Series("Def_Player_Control", build_arrival_final_2())
)

# final_throw_df_2.write_parquet("sharing/final_throw_df_mon15.parquet")

game_play_defender_trios_3 = (
    at_arrival_df.filter(pl.col("player_role") == "Defensive Coverage")
    .select("game_id", "play_id", "nfl_id")
    .unique()
)


def build_arrival_final_3():
    defender_control = np.array([-1] * game_play_defender_trios_3.height, dtype=float)
    for (
        index,
        row,
    ) in game_play_defender_trios_3.to_pandas().iterrows():
        GS = row["game_id"]
        PS = row["play_id"]
        Def_Id = row["nfl_id"]
        defender_control[index] = ind_def_evaluator_2(
            ind_defense_pdf_builder(at_arrival_df_pd, GS, PS, Def_Id),
            receiver_pdf_builder(at_arrival_df_pd, GS, PS),
            ball_landing_pdf_builder(at_arrival_df_pd, GS, PS),
        )
    return defender_control


final_throw_df_2 = game_play_defender_trios_3.with_columns(
    pl.Series("Def_Player_Control", build_arrival_final_3())
)

# final_throw_df_2.write_parquet("sharing/final_arrival_df_daniel_mon15.parquet")
