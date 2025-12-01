game_play_defender_trios_2 = (
    at_throw_df
    .filter(pl.col("player_role") == "Defensive Coverage")
    .select("game_id", "play_id", "nfl_id").unique()
    )

at_throw_df_pd = at_throw_df.to_pandas()

def build_arrival_final_2():
    defender_control = np.array([-1] * game_play_defender_trios_2.height, dtype = float)
    for index, row, in game_play_defender_trios_2.to_pandas().iterrows():
        GS = row["game_id"]
        PS = row["play_id"]
        Def_Id = row["nfl_id"]
        defender_control[index] = ind_def_evaluator(
            ind_defense_pdf_builder(at_throw_df_pd, GS, PS, Def_Id),
            receiver_pdf_builder(at_throw_df_pd,  GS, PS),
            ball_landing_pdf_builder(at_throw_df_pd, GS, PS)
        )
    return(defender_control)

final_throw_df_2 = game_play_defender_trios_2.with_columns(pl.Series("Def_Player_Control", build_arrival_final_2())) 

# final_throw_df_2.write_parquet("sharing/final_throw_df_2.parquet")
