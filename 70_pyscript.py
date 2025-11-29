# Mailroom
import numpy as np
import polars as pl
from scipy import stats
import pandas as pd


at_throw_df = pl.read_parquet("transfer/at_throw_df.parquet")


x, y = np.mgrid[0 : (120 / 3) : 1, 0:120:1]
locations = np.dstack((x, y))
mean_x = 0
mean_y = 0


def defense_pdf_builder(data, game, play):
    defense_pdfs = []
    for index, row in data.iterrows():
        if (
            row["game_id"] == game
            and row["play_id"] == play
            and row["player_side"] == "Defense"
        ):
            # the following steps are coded from Bornn and Fernandez's 2018 paper
            # with assist from Inayatali, Hocevar, and White's 2023 BDB entry.
            speedUsage = (row["s"] ** 2) / (121)
            upLeftScaling = (
                row["total_dist_from_ball"] + row["total_dist_from_ball"] * speedUsage
            ) / 2
            bottomRightScaling = (
                row["total_dist_from_ball"] - row["total_dist_from_ball"] * speedUsage
            ) / 2
            r_matrix = [(row["hcomp"], -row["vcomp"]), (row["vcomp"], row["hcomp"])]
            r_matrix = pd.DataFrame(data=r_matrix)
            s_matrix = [
                (upLeftScaling + 0.0000001, 0),
                (0, bottomRightScaling - 0.0000001),
            ]
            s_matrix = pd.DataFrame(data=s_matrix)
            inverse_r_Matrix = np.linalg.inv(r_matrix)
            Matrixmult = r_matrix.dot(s_matrix)
            nextMatrix = Matrixmult.dot(s_matrix)
            covariance_matrix = nextMatrix.dot(inverse_r_Matrix)
            mean_x = row["x"] + row["h_speed"] * 0.5
            mean_y = row["y"] + row["v_speed"] * 0.5
            means = [mean_x, mean_y]
            # player_pdf creates the influence map
            player_pdf = stats.multivariate_normal(means, covariance_matrix).pdf(
                locations
            )
            # percent_player_pdf shows the percentage of their total influence at any one point
            percent_player_pdf = player_pdf / np.sum(np.sum(player_pdf, axis=1), axis=0)
            defense_pdfs.append(percent_player_pdf)

    return defense_pdfs


def receiver_pdf_builder(data, game, play):
    m = 0
    for index, row in data.iterrows():
        if (
            row["game_id"] == game
            and row["play_id"] == play
            and row["player_role"] == "Targeted Receiver"
        ):
            ballCarrierX = row["x"] + row["h_speed"] * 0.5
            ballCarrierY = row["y"] + row["v_speed"] * 0.5
            ballCarrierCoord = [ballCarrierX, ballCarrierY]
            ballCarrier_pdf = stats.multivariate_normal(
                [ballCarrierX, ballCarrierY], [[5, 0], [0, 5]]
            ).pdf(locations)
            m = 1
            if m == 1:
                return ballCarrier_pdf


def evaluator(defenders, carrier):
    values = []
    for DefPlayerPDF in defenders:
        result = np.array(DefPlayerPDF) * np.array(carrier)
        swarm_val = np.sum(np.sum(result, axis=1), axis=0) / np.sum(
            np.sum(carrier, axis=1), axis=0
        )
        values.append(swarm_val)
    count = 0
    for value in values:
        if value > 0.0055:
            # 0.0055 was the arbitrary value I found to give the results that most accurately represented the film
            # (0.006 was more often than not impacting the play, while 0.005 was not.)
            count = count + 1
    return count


# ----------- Do the work -----------
rally_Score = np.array([])

game_and_play_pairs = at_throw_df.select("game_id", "play_id").unique()

for GS, PS in game_and_play_pairs.iter_rows():
    swarm_Score = np.append(
        rally_Score,
        evaluator(
            defense_pdf_builder(at_throw_df.to_pandas(), GS, PS),
            receiver_pdf_builder(at_throw_df.to_pandas(), GS, PS),
        ),
    )
