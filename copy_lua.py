import shutil
import os
import glob
import argparse

def copy_scripts(force=False):
    # Get the directory where this Python script is located
    source_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Destination directory (Aseprite scripts folder)
    dest_dir = "C:/Users/neil/AppData/Roaming/Aseprite/scripts"
    
    # Create destination directory if it doesn't exist
    if not os.path.exists(dest_dir):
        os.makedirs(dest_dir)
    
    # Get all .lua files from source directory
    lua_files = glob.glob(os.path.join(source_dir, "*.lua"))
    
    for file_path in lua_files:
        try:
            file_name = os.path.basename(file_path)
            dest_path = os.path.join(dest_dir, file_name)
            
            # Check if file exists and is newer
            if (force or 
                not os.path.exists(dest_path) or 
                os.path.getmtime(file_path) > os.path.getmtime(dest_path)):
                
                shutil.copy2(file_path, dest_path)
                print(f"Copied {file_name}")
            else:
                print(f"Skipped {file_name} - destination file is newer or same age")
                
        except Exception as e:
            print(f"Error copying {file_name}: {str(e)}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Copy Lua scripts to Aseprite")
    parser.add_argument("--force", action="store_true", 
                       help="Force copy all files regardless of timestamp")
    args = parser.parse_args()
    
    copy_scripts(args.force)
    print("Script copying complete!")