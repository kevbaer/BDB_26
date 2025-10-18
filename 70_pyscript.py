# Mailroom
import numpy as np
import polars as pl
from scipy import stats

dat_i = pl.read_parquet("data/input.parquet")
dat_o = pl.read_parquet("data/output.parquet")
supp = pl.read_parquet("data/supp.parquet")

x, y = np.mgrid[0:(120/3):1, 0:120:1]
locations = np.dstack((x, y))

