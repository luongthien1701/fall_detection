import pandas as pd

file_path = "dataset/normal_test.csv"  # đổi thành đường dẫn file của bạn

# Đọc CSV với header
df = pd.read_csv(file_path)

# Lọc bỏ các dòng toàn 0 (trên các cột số, bỏ cột 'time' nếu cần)
num_cols = df.columns[1:]  # các cột số
df_filtered = df[~(df[num_cols] == 0).all(axis=1)]

# Ghi đè lên file cũ, giữ header
df_filtered.to_csv(file_path, index=False)

print(f"Done! {len(df) - len(df_filtered)} zero rows removed, file overwritten.")