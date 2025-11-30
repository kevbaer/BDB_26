# Mailroom
import numpy as np
import polars as pl
from scipy import stats
import pandas as pd
import timeit


at_throw_df = pl.read_parquet("transfer/at_throw_df.parquet")
at_arrival_df = pl.read_parquet("transfer/at_arrival_df.parquet")


x, y = np.mgrid[0 : (120 / 3) : 1, 0:120:1]
locations = np.dstack((x, y))
mean_x = 0
mean_y = 0


def defense_pdf_builder(data, game, play):
    mask = (
        (data["game_id"] == game) & 
        (data["play_id"] == play) & 
        (data["player_side"] == "Defense")
    )
    defense_data = data[mask]

    if defense_data.empty:
        return [stats.multivariate_normal([0, 0], [[1, 0], [0, 1]]).pdf(locations)]
    
    defense_pdfs = []

    for row in defense_data.itertuples(index=False):
            # the following steps are coded from Bornn and Fernandez's 2018 paper
            # with assist from Inayatali, Hocevar, and White's 2023 BDB entry.
        speedUsage = (row.s ** 2) / (121)
        upLeftScaling = (
            row.total_dist_from_ball + row.total_dist_from_ball * speedUsage
        ) / 2
        bottomRightScaling = (
            row.total_dist_from_ball - row.total_dist_from_ball * speedUsage
        ) / 2
        r_matrix = [(row.hcomp, -row.vcomp), (row.vcomp, row.hcomp)]
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
        mean_x = row.x + row.h_speed * 0.5
        mean_y = row.y + row.v_speed * 0.5
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
    mask = (
        (data["game_id"] == game) & 
        (data["play_id"] == play) & 
        (data["player_role"] == "Targeted Receiver")
    )
    filtered = data[mask]

    row = filtered.iloc[0]

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
    player_pdf = stats.multivariate_normal(means, covariance_matrix).pdf(
        locations
    )
    percent_player_pdf = player_pdf / np.sum(np.sum(player_pdf, axis=1), axis=0)
    return percent_player_pdf




def ball_landing_pdf_builder(data, game, play):
    mask = (
        (data["game_id"] == game) & 
        (data["play_id"] == play) & 
        (data["player_role"] == "Targeted Receiver")
    )
    filtered = data[mask]
    
    if filtered.empty:
        return None
    
    row = filtered.iloc[0]
    ball_landing_pdf = stats.multivariate_normal(
        [row["ball_land_x"], row["ball_land_y"]], 
        [[5, 0], [0, 5]]
    ).pdf(locations)
    
    return ball_landing_pdf


def evaluator(defenders, receiver, ball):
    def_control_vec = []
    for DefPlayerPDF in defenders:
        def_control_vec.append(np.array(DefPlayerPDF) * np.array(ball))
    
    def_control = sum(def_control_vec)
    off_control = np.array(receiver) * np.array(ball)

        # swarm_val = np.sum(np.sum(result, axis=1), axis=0) / np.sum(
        #     np.sum(carrier, axis=1), axis=0
        # )
        # def_control_vec.append(swarm_val)
    return np.sum(np.sum(off_control, axis = 1), axis = 0) / (np.sum(np.sum(def_control, axis = 1), axis = 0) +  np.sum(np.sum(off_control, axis = 1), axis = 0))


def supercheck(defenders, carrier):
  values = []
  for DefPlayerPDF in defenders:
    result = np.array(DefPlayerPDF) * np.array(carrier)
    swarm_val = np.sum(np.sum(result, axis=1), axis=0) / np.sum(np.sum(carrier, axis=1), axis=0)
    values.append(swarm_val)
  count = 0
  for value in values:
    if value > 0.0055:
      count = count + 1
    print(value)
    print(count)
  return(count)

# def DefpdfChecker(data, game, play):
#     DefensePdfs = []
#     for index, row in data.iterrows():
#         if (
#             row["game_id"] == game
#             and row["play_id"] == play
#             and row["player_side"] == "Defense"
#         ):
#             speedUsage=(row['s']**2)/(121)
#             upLeftScaling=(row['total_dist_from_ball']+row['total_dist_from_ball']*speedUsage)/2
#             bottomRightScaling=(row['total_dist_from_ball']-row['total_dist_from_ball']*speedUsage)/2
#             r_matrix = [(row['hcomp'], -row['vcomp']),(row['vcomp'], row['hcomp'])];
#             r_matrix = pd.DataFrame(data=r_matrix)
#             s_matrix=[(upLeftScaling+.0000001,0), (0, bottomRightScaling-.0000001)]
#             s_matrix=pd.DataFrame(data=s_matrix)
#             inverse_r_Matrix=np.linalg.inv(r_matrix)
#             Matrixmult=r_matrix.dot(s_matrix)
#             nextMatrix=Matrixmult.dot(s_matrix)
#             covariance_matrix=nextMatrix.dot(inverse_r_Matrix)
#             mean_x=row['x']+row['h_speed']*0.5
#             mean_y=row['y']+row['v_speed']*0.5
#             means=[mean_x,mean_y]
#             player_pdf=stats.multivariate_normal(means,covariance_matrix).pdf(locations)
#             percent_player_pdf = player_pdf/np.sum(np.sum(player_pdf, axis=1), axis=0)
#             DefensePdfs.append(percent_player_pdf)
#             print(row['player_name'])
#     return(DefensePdfs)


def playTester(data, game, play):
  print(supercheck(
    defense_pdf_builder(data, game, play),
    receiver_pdf_builder(data, game,play)
    ))
     

# ----------- Do the work -----------
game_and_play_pairs = at_throw_df.select("game_id", "play_id").unique()


at_throw_df_pd = at_throw_df.to_pandas()

def run():
    receiver_control = np.array([-1] * game_and_play_pairs.height, dtype = float) 
    for index, row, in game_and_play_pairs.to_pandas().iterrows():
        GS = row["game_id"]
        PS = row["play_id"]
        receiver_control[index] = evaluator(
                defense_pdf_builder(at_throw_df_pd, GS, PS),
                receiver_pdf_builder(at_throw_df_pd,  GS, PS),
                ball_landing_pdf_builder(at_throw_df_pd, GS, PS)
            )
    return receiver_control

final_throw_df = game_and_play_pairs.with_columns(pl.Series("Receiver_Control", run())) 

final_throw_df.write_parquet("sharing/final_throw_df.parquet")
