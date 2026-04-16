import pandas as pd
import random


def split_segments(file):

    df = pd.read_csv(file)

    segments=[]
    current=[]

    for _,row in df.iterrows():

        if row["time"]==0:
            if current:
                segments.append(current)
                current=[]
        else:
            current.append(row.tolist())

    if current:
        segments.append(current)

    return segments


fall_segments = split_segments("processed_data.csv")
normal_segments = split_segments("processed_0.csv")

print("Fall segments:",len(fall_segments))
print("Normal segments:",len(normal_segments))


def generate_fall():
    return random.choice(fall_segments)


def generate_normal():
    return random.choice(normal_segments)