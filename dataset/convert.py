from pathlib import Path
import csv

# File CSV gốc cần tách
INPUT_FILE = Path("mpu_data.csv")

# Thư mục lưu file sau khi tách
OUTPUT_DIR = Path("split/fall")

# Bắt đầu ghi từ mẫu số 90
START_INDEX = 90

# Nếu dữ liệu của bạn có header thì đổi thành True
HAS_HEADER = False


def is_zero_row(row):
    """
    Kiểm tra một dòng có phải toàn số 0 không.
    Ví dụ:
    0,0,0,0,0,0,0,0
    """
    if not row:
        return True

    try:
        return all(float(x.strip()) == 0 for x in row)
    except ValueError:
        return False


def save_segment(segment, index, header=None):
    """
    Lưu một đoạn fall thành file CSV riêng.
    """
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    output_file = OUTPUT_DIR / f"fall_{index}.csv"

    with open(output_file, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)

        if header:
            writer.writerow(header)

        writer.writerows(segment)

    print(f"Saved: {output_file} ({len(segment)} rows)")


def split_fall_csv():
    if not INPUT_FILE.exists():
        print(f"Không tìm thấy file: {INPUT_FILE}")
        return

    current_segment = []
    file_index = START_INDEX
    header = None

    with open(INPUT_FILE, "r", newline="", encoding="utf-8") as f:
        reader = csv.reader(f)

        if HAS_HEADER:
            header = next(reader, None)

        for row in reader:
            # Gặp dòng 0 => kết thúc 1 đoạn nếu đang có dữ liệu
            if is_zero_row(row):
                if current_segment:
                    save_segment(current_segment, file_index, header)
                    file_index += 1
                    current_segment = []

                # Nếu có 2, 3 dòng 0 liên tiếp thì bỏ qua hết
                continue

            # Dòng dữ liệu thật
            current_segment.append(row)

    # Lưu đoạn cuối nếu file không kết thúc bằng dòng 0
    if current_segment:
        save_segment(current_segment, file_index, header)

    print(f"\nHoàn tất. Đã tạo {file_index - START_INDEX} file mới.")
    print(f"File cuối cùng: fall_{file_index - 1}.csv")


if __name__ == "__main__":
    split_fall_csv()