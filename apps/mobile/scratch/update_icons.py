import os
import shutil

source_img = "assets/images/logo.png"
res_dir = "android/app/src/main/res"

if not os.path.exists(source_img):
    print(f"Source image {source_img} not found.")
    exit(1)

# Find all drawable directories
for item in os.listdir(res_dir):
    if item.startswith("drawable") and os.path.isdir(os.path.join(res_dir, item)):
        target_dir = os.path.join(res_dir, item)
        target_file = os.path.join(target_dir, "ic_launcher_foreground.png")
        
        # Only overwrite if the file exists or if it's a standard density folder
        if os.path.exists(target_file):
            shutil.copyfile(source_img, target_file)
            print(f"Updated {target_file}")

# Do the same for mipmap just in case
for item in os.listdir(res_dir):
    if item.startswith("mipmap") and os.path.isdir(os.path.join(res_dir, item)):
        target_dir = os.path.join(res_dir, item)
        target_file_fg = os.path.join(target_dir, "ic_launcher_foreground.png")
        target_file_bg = os.path.join(target_dir, "ic_launcher_background.png")
        
        if os.path.exists(target_file_fg):
            shutil.copyfile(source_img, target_file_fg)
            print(f"Updated {target_file_fg}")

print("All icons successfully replaced with the new logo!")
