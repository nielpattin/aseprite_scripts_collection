import shutil
import os
import glob
import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class LuaFileHandler(FileSystemEventHandler):
    def __init__(self, dest_dir):
        self.dest_dir = dest_dir
        
    def on_modified(self, event):
        if event.is_directory:
            return
            
        if event.src_path.endswith('.lua'):
            try:
                file_name = os.path.basename(event.src_path)
                dest_path = os.path.join(self.dest_dir, file_name)
                
                time.sleep(0.1)
                
                shutil.copy2(event.src_path, dest_path)
                print(f"Copied modified file: {file_name}")
                
            except Exception as e:
                print(f"Error copying {file_name}: {str(e)}")

def main():
    source_dir = os.path.dirname(os.path.abspath(__file__))
    
    dest_dir = "/mnt/c/Users/neil/AppData/Roaming/Aseprite/scripts"
    
    if not os.path.exists(dest_dir):
        os.makedirs(dest_dir)
    
    lua_files = glob.glob(os.path.join(source_dir, "*.lua"))
    for file_path in lua_files:
        try:
            file_name = os.path.basename(file_path)
            dest_path = os.path.join(dest_dir, file_name)
            shutil.copy2(file_path, dest_path)
            print(f"Initial copy: {file_name}")
        except Exception as e:
            print(f"Error in initial copy of {file_name}: {str(e)}")
    
    event_handler = LuaFileHandler(dest_dir)
    observer = Observer()
    observer.schedule(event_handler, source_dir, recursive=False)
    observer.start()
    
    print(f"Watching for changes in {source_dir}")
    print("Press Ctrl+C to stop")
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
        print("\nStopped watching")
    
    observer.join()

if __name__ == "__main__":
    main()
