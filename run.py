import subprocess
import sys
import time
import os
import threading

class DummyFile(object):
    def write(self, x): pass
    def flush(self): pass

    def debug(self, msg):
        if '[download]' in msg and '%' in msg:
            clean_msg = msg.replace('[download]', '').strip()
            sys.stdout.write(f"\r\033[K[ PROGRESS: {clean_msg} ]")
            sys.stdout.flush()

    def warning(self, msg): pass  
    def error(self, msg): pass

USER_HOME = os.path.dirname(os.path.abspath(__file__))
CONFIG_DIR = os.path.join(USER_HOME, ".mediaDownloader")
CONFIG_FILE = os.path.join(CONFIG_DIR, "weirdown-settings.txt")

def ensure_config_dir():
    if not os.path.exists(CONFIG_DIR):
        try:
            os.makedirs(CONFIG_DIR)
        except:
            pass

def load_config():
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                path = f.read().strip()
                if path: return path
        except:
            pass
    return os.path.join(os.getcwd(), "downloads")

def save_config(path):
    ensure_config_dir()
    try:
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            f.write(path)
    except Exception as e:
        print(f" ERROR SAVING CONFIG: {e}")

def install_requirements():
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "--upgrade", "yt-dlp", "--quiet"])
    except:
        pass

try:
    from yt_dlp import YoutubeDL
except ImportError:
    install_requirements()
    from yt_dlp import YoutubeDL


current_save_path = load_config()

def clear():
    os.system('cls' if os.name == 'nt' else 'clear')

def format_size(bytes):
    if bytes is None or bytes == 0: return "Unknown"
    for unit in ['B', 'KB', 'MB', 'GB']:
        if bytes < 1024:
            return f"{bytes:.1f} {unit}"
        bytes /= 1024
    return f"{bytes:.1f} TB"

def loading_animation(stop_event):
    chars = ["-", "/", "|", "\\"]
    i = 0
    while not stop_event.is_set():
        sys.stdout.write(f"\r[ ANALYZING {chars[i % 4]} ]")
        sys.stdout.flush()
        time.sleep(0.1)
        i += 1
    sys.stdout.write("\r" + " " * 30 + "\r")

def progress_hook(d):
    if d['status'] == 'downloading':
        percent = d.get('_percent_str', '0%').strip()
        speed = d.get('_speed_str', 'N/A').strip()
        
        output = f"\r\033[K[ PROGRESS: {percent} | SPEED: {speed} ]"
        sys.__stdout__.write(output)
        sys.__stdout__.flush()
        
    elif d['status'] == 'finished':
        sys.__stdout__.write(f"\r\033[K[ STATUS: PROCESSING / MERGING... ]")
        sys.__stdout__.flush()

def main():
    global current_save_path
    if not os.path.exists(current_save_path):
        try:
            os.makedirs(current_save_path)
        except:
            current_save_path = os.getcwd()

    appName = "weirdown  :3"
    harder3 = 50
    harder4 = int((harder3 - len(appName)) / 2)

    clear()
    print("=" * harder3)
    print(" " * harder4 + appName + " " * harder4)
    print("=" * harder3)
    print(f" SAVE PATH: {current_save_path}")
    print(f" CONFIG   : {CONFIG_FILE}")
    print("-" * harder3)
    print(" 1. Download Content")
    print(" 2. Change Download Directory")
    print(" 3. Exit")
    print("-" * harder3)
    
    choice = input(" SELECT > ")

    if choice == '1':
        clear()
        url = input(" PASTE LINK: ").strip()
        if not url: main()
        
        stop_loading = threading.Event()
        loader = threading.Thread(target=loading_animation, args=(stop_loading,))
        loader.start()

        try:
            with YoutubeDL({'quiet': True, 'logger': DummyFile(), 'nocheckcertificate': True}) as ydl:
                info = ydl.extract_info(url, download=False)
                formats = info.get('formats', [])
                title = info.get('title', 'Unknown')
                uploader = info.get('uploader', 'Unknown')
            
            stop_loading.set()
            loader.join()

            clear()
            print(f" TITLE   : {title[:50]}...")
            print(f" CHANNEL : {uploader}")
            print("-" * 40)
            print(" 1. Video (Select Quality)")
            print(" 2. Audio Only (MP3)")
            print("-" * 40)
            
            main_choice = input(" SELECT FORMAT > ")

            opts = {
                'quiet': True,
                'no_warnings': True,
                'logger': DummyFile(),
                #'progress_hooks': [progress_hook],
                'outtmpl': f"{current_save_path}/%(title)s.%(ext)s",
                'nocheckcertificate': True
            }

            if main_choice == '2':
                opts.update({
                    'format': 'bestaudio/best',
                    'postprocessors': [{'key': 'FFmpegExtractAudio', 'preferredcodec': 'mp3'}]
                })
            else:
                res_list = []
                seen_res = set()
                for f in formats:
                    height = f.get('height')
                    if f.get('vcodec') != 'none' and height:
                        if height not in seen_res:
                            size = f.get('filesize') or f.get('filesize_approx') or 0
                            res_list.append({'height': height, 'size': size})
                            seen_res.add(height)
                
                res_list.sort(key=lambda x: x['height'], reverse=True)
                
                clear()
                print(f" TITLE   : {title[:50]}...")
                print("-" * 40)
                header = f" {'ID':<12} {'QUALITY':<12} {'EST. SIZE':<12}"
                print(header)
                print("-" * 40)
                
                for i, item in enumerate(res_list, 1):
                    size_str = format_size(item['size'])
                    q_str = f"{item['height']}p"
                    print(f" {i:<12} {q_str:<12} {size_str:<12}")
                
                print("-" * 40)
                q_choice = input(" SELECT QUALITY NUMBER > ")
                
                try:
                    selected_res = res_list[int(q_choice)-1]['height']
                    opts.update({
                        'format': f'bestvideo[height<={selected_res}]+bestaudio/best[height<={selected_res}]',
                        'merge_output_format': 'mp4'
                    })
                except:
                    print("\n[ INVALID CHOICE - USING BEST ]")
                    opts.update({'format': 'bestvideo+bestaudio/best', 'merge_output_format': 'mp4'})

            print("\n[ STARTING DOWNLOAD ]")

            sys.__stdout__.write("\n")

            with YoutubeDL(opts) as ydl:
                ydl.download([url])

            sys.__stdout__.write(f"\r\033[K[ STATUS: DOWNLOAD COMPLETE ]\n")
            
            input("\n PRESS ENTER TO RETURN...")
            main()

        except Exception as e:
            if 'stop_loading' in locals(): stop_loading.set()
            print(f"\n ERROR: {str(e)[:100]}")
            time.sleep(3)
            main()

    elif choice == '2':
        clear()
        print(f" CURRENT SAVE PATH: {current_save_path}")
        new_path = input(" ENTER NEW FULL PATH: ").strip()
        if new_path:
            current_save_path = os.path.abspath(new_path)
            if not os.path.exists(current_save_path): 
                os.makedirs(current_save_path)
            save_config(current_save_path) 
            print("\n [ PATH UPDATED AND PERMANENTLY SAVED ]")
        time.sleep(1)
        main()
    
    elif choice == '3':
        sys.exit()

if __name__ == "__main__":
    main()