import shutil
import os
import glob
import time
import logging
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Disable watchdog debug logging
logging.getLogger('watchdog').setLevel(logging.WARNING)

class LuaFileHandler(FileSystemEventHandler):
    def __init__(self, dest_dir):
        self.dest_dir = dest_dir
        
    def on_modified(self, event):
        if event.is_directory:
            return
            
        if event.src_path.endswith('.lua'):
            file_name = os.path.basename(event.src_path)
            try:
                dest_path = os.path.join(self.dest_dir, file_name)
                
                time.sleep(0.1)
                
                shutil.copy2(event.src_path, dest_path)
                print(f"{time.strftime('%H:%M:%S')} - Copied: {file_name}")
                
            except Exception as e:
                pass

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
        except Exception as e:
            pass
    
    event_handler = LuaFileHandler(dest_dir)
    observer = Observer()
    observer.schedule(event_handler, source_dir, recursive=False)
    observer.start()
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    
    observer.join()

if __name__ == "__main__":
    main()
