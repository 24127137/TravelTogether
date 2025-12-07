import re
import argparse
import os

# --- CẤU HÌNH BIỂU THỨC CHÍNH QUY ---

# Regex để nhận diện comment kiểu 'AI' hoặc 'thông báo' thường dùng để phân đoạn code.
# Nhận diện:
# 1. Bắt đầu bằng dấu // hoặc # (tùy ngôn ngữ)
# 2. Theo sau là khoảng trắng tùy ý và các từ/kí tự viết HOA, dấu =, -, _, hoặc trống
#    Ví dụ: // === SỬA ĐỔI ===; // SỬA; // TODO; # GHI CHÚ
AI_COMMENT_PATTERN = re.compile(
    r"^\s*(//|#)\s*([A-Z\s\-=_/!@#$%^&*()]*?)\s*(?:[;:.])?\s*$",
    re.IGNORECASE # Bật tùy chọn không phân biệt chữ hoa/thường để bao quát hơn (ví dụ: 'todo' thay vì 'TODO')
)

# Regex để kiểm tra một dòng có phải là comment giải thích/hữu ích hay không.
# Giữ lại các comment giải thích có ít nhất 3 TỪ (bao gồm cả các từ tiếng Việt không dấu)
EXPLANATORY_COMMENT_PATTERN = re.compile(
    r"^\s*(//|#)\s*\w+.*\w+.*\w+" # Bắt đầu comment, theo sau là ít nhất 3 từ
)

def remove_ai_comments(file_path):
    """
    Đọc file, xóa các comment 'AI/thông báo', và ghi đè lại file.
    Giữ lại các comment giải thích (có ít nhất 3 từ).
    """
    print(f"-> Đang xử lý file: {file_path}")

    # 1. Đọc nội dung file
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"Lỗi: Không tìm thấy file {file_path}")
        return
    except Exception as e:
        print(f"Lỗi khi đọc file {file_path}: {e}")
        return

    new_lines = []
    changes_made = False

    # 2. Xử lý từng dòng
    for line in lines:
        stripped_line = line.strip()

        # Kiểm tra xem dòng đó có phải là comment bắt đầu bằng // hoặc # không
        is_comment_line = stripped_line.startswith('//') or stripped_line.startswith('#')

        if not is_comment_line:
            # Nếu không phải comment, giữ nguyên
            new_lines.append(line)
            continue

        # --- Dòng là comment ---

        # 2a. Kiểm tra nếu là comment giải thích (có > 2 từ) -> GIỮ LẠI
        if EXPLANATORY_COMMENT_PATTERN.search(stripped_line):
            new_lines.append(line)
            continue

        # 2b. Kiểm tra nếu là comment 'AI/thông báo' -> XÓA
        if AI_COMMENT_PATTERN.match(stripped_line):
            # Nếu dòng comment này phù hợp với mẫu 'AI/thông báo', KHÔNG thêm vào new_lines
            changes_made = True
            continue # Bỏ qua dòng này

        # 2c. Nếu không thuộc hai loại trên (có thể là comment ngắn hợp lệ, 1-2 từ) -> GIỮ LẠI
        new_lines.append(line)


    # 3. Ghi lại nội dung đã lọc vào file gốc
    if changes_made:
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.writelines(new_lines)
            print(f"-> Đã xóa các comment 'AI' và lưu lại file **{file_path}**.")
        except Exception as e:
            print(f"Lỗi khi ghi file {file_path}: {e}")
    else:
        print(f"-> Không tìm thấy comment 'AI' nào để xóa trong file **{file_path}**.")


def main():
    """Thiết lập đối số dòng lệnh để xử lý một hoặc nhiều file."""
    parser = argparse.ArgumentParser(
        description="Tool xóa các comment phân đoạn/thông báo ngắn kiểu AI/tự động (// ===, # SỬA, v.v.), chỉ giữ lại các comment giải thích hữu ích."
    )
    # Cho phép người dùng truyền vào nhiều tên file
    parser.add_argument(
        'files',
        metavar='FILE',
        type=str,
        nargs='+',
        help='Đường dẫn đến một hoặc nhiều file code cần xử lý.'
    )

    args = parser.parse_args()

    for file_path in args.files:
        # Kiểm tra sự tồn tại của file trước khi xử lý
        if os.path.exists(file_path):
            remove_ai_comments(file_path)
        else:
            print(f"**Lỗi: File '{file_path}' không tồn tại. Bỏ qua.**")

if __name__ == '__main__':
    main()